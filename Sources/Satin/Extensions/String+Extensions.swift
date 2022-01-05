//
//  String+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Foundation

public extension String {
    var camelCase: String {
        var parts = self.split(separator: " ")
        if let first = parts.first {
            var tmp = Substring(first.prefix(1).lowercased())
            tmp += Substring(first.dropFirst())
            parts[0] = tmp
        }
        return parts.joined()
    }

    var titleCase: String {
        return self
            .replacingOccurrences(of: "([A-Z])",
                                  with: " $1",
                                  options: .regularExpression,
                                  range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}
