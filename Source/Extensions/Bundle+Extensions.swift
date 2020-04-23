//
//  Bundle+Extensions.swift
//  Satin-iOS
//
//  Created by Reza Ali on 4/23/20.
//

import Foundation

extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
