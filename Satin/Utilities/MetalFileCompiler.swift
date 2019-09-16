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
    
    public func parse(_ fileURL: URL) throws -> String
    {
        files = []
        watchers = []
        return try _parse(fileURL)
    }
    
    func _parse(_ fileURL: URL) throws -> String
    {
        let fileURLResolved = fileURL.resolvingSymlinksInPath()
        if !files.contains(fileURLResolved)
        {
            let watcher = FileWatcher(filePath: fileURLResolved.path, timeInterval: 0.25)
            watcher.onUpdate = { [unowned self] in
                self.onUpdate?()
            }
            watchers.append(watcher)
            files.append(fileURLResolved)
            
            
            let baseURL = fileURL.deletingLastPathComponent()
            var content = ""
            do
            {
                content = try String(contentsOf: fileURLResolved, encoding: .utf8)
            }
            catch
            {
                throw MetalFileCompilerError.invalidFile(fileURLResolved)
            }
            
            let pattern = #"#include +\"(.*)\"\n"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
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
    
    deinit {
        files = []
        watchers = [] 
    }
}
