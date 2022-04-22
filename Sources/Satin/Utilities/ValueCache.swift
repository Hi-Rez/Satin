//
//  ValueCache.swift
//
//
//  Created by Taylor Holliday on 3/29/22.
//

struct ValueCache<T> {
    var value: T?

    mutating func get(_ compute: () -> T) -> T {
        if let v = value { return v }
        let v = compute()
        value = v
        return v
    }

    mutating func clear() {
        value = nil
    }
}
