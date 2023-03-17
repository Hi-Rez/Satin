//
//  Timing.swift
//  Example
//
//  Created by Reza Ali on 3/11/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation

public func getTime() -> CFAbsoluteTime {
    CFAbsoluteTimeGetCurrent()
}

var messages: [String] = []
var startTimes: [CFAbsoluteTime] = []

func start(_ message: String) {
    let count = messages.count
    messages.append(message)
    startTimes.append(getTime())
    let spacing = Array(repeating: "\t", count: count).reduce("") { $0 + $1 }
    print("\(spacing)Starting: \(message)")
}

func end() {
    if let message = messages.popLast(), let startTime = startTimes.popLast() {
        let spacing = Array(repeating: "\t", count: messages.count).reduce("") { $0 + $1 }
        print("\(spacing)Finished: \(message): \(getTime() - startTime)")
    }
}
