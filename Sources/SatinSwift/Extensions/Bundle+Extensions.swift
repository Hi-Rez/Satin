//
//  Bundle+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 4/23/20.
//

import Foundation

public extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
