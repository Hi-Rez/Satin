//
//  File.swift
//
//
//  Created by Reza Ali on 9/20/22.
//

import Foundation

public enum MetalSourceCompilerError: Error
{
    case includeCompileError(_ fileURL: URL)
}

public func compileMetalSource(_ source: String) throws -> String
{
    var result = source

    let pattern = #"^#include\s+\"(.*)\"\n"#
    let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    let nsrange = NSRange(result.startIndex..<result.endIndex, in: result)
    var matches = regex.matches(in: result, options: [], range: nsrange)

    while !matches.isEmpty
    {
        let match = matches[0]
        if match.numberOfRanges == 2, let r0 = Range(match.range(at: 0), in: result), let r1 = Range(match.range(at: 1), in: result), let satinPipelinesUrl = getPipelinesUrl()
        {
            let includeURL = URL(fileURLWithPath: String(result[r1]), relativeTo: satinPipelinesUrl)
            do
            {
                let includeSource = try compileMetalSource(String(contentsOf: includeURL, encoding: .utf8))
                result.replaceSubrange(r0, with: includeSource)
            }
            catch
            {
                throw MetalSourceCompilerError.includeCompileError(includeURL)
            }
        }
        let nsrange = NSRange(result.startIndex..<result.endIndex, in: result)
        matches = regex.matches(in: result, options: [], range: nsrange)
    }

    return result
}
