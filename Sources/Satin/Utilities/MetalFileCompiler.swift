//
//  MetalLibraryCompiler.swift
//  Satin
//
//  Created by Reza Ali on 8/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public enum MetalFileCompilerError: Error
{
    case invalidFile(_ fileURL: URL)
}

open class MetalFileCompiler
{
    var files: [URL] = []
    var watchers: [FileWatcher] = []
    public var onUpdate: (() -> ())?
    
    public init() {}
    
    public func touch()
    {
        onUpdate?()
    }
    
    public func parse(_ fileURL: URL) throws -> String
    {
        files = []
        watchers = []
        return try _parse(fileURL)
    }
    
    func _parse(_ fileURL: URL) throws -> String
    {
        var fileURLResolved = fileURL.resolvingSymlinksInPath()
        if !files.contains(fileURLResolved)
        {
            let baseURL = fileURL.deletingLastPathComponent()
            var content = ""
            do
            {
                content = try String(contentsOf: fileURLResolved, encoding: .utf8)
            }
            catch
            {
                if fileURLResolved.path.contains("Satin"), let satinFileURL = getPipelinesSatinUrl(fileURLResolved.lastPathComponent)
                {
                    content = try String(contentsOf: satinFileURL, encoding: .utf8)
                    fileURLResolved = satinFileURL
                }
                else if fileURLResolved.path.contains("Library"), let libraryFileURL = getPipelinesLibraryUrl(fileURLResolved.lastPathComponent)
                {
                    content = try String(contentsOf: libraryFileURL, encoding: .utf8)
                    fileURLResolved = libraryFileURL
                }
                else
                {
                    throw MetalFileCompilerError.invalidFile(fileURLResolved)
                }
            }
            
            let watcher = FileWatcher(filePath: fileURLResolved.path, timeInterval: 0.25)
            watcher.onUpdate = { [weak self] in
                guard let self = self else { return }
                self.onUpdate?()
            }
            watchers.append(watcher)
            files.append(fileURLResolved)
            
            let pattern = #"^#include\s+\"(.*)\"\n"#
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
            var matches = regex.matches(in: content, options: [], range: nsrange)
            while !matches.isEmpty
            {
                let match = matches[0]
                if match.numberOfRanges == 2, let r0 = Range(match.range(at: 0), in: content), let r1 = Range(match.range(at: 1), in: content)
                {
                    let includeURL = URL(fileURLWithPath: String(content[r1]), relativeTo: baseURL)
                    do
                    {
                        let includeContent = try _parse(includeURL)
                        content.replaceSubrange(r0, with: includeContent + "\n")
                    }
                    catch
                    {
                        throw MetalFileCompilerError.invalidFile(includeURL)
                    }
                }
                let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
                matches = regex.matches(in: content, options: [], range: nsrange)
            }
            
            return content
        }
        
        return ""
    }
    
    deinit
    {
        onUpdate = nil
        files = []
        watchers = []
    }
}
