//
//  Tonemapping.swift
//  
//
//  Created by Reza Ali on 4/10/23.
//

import Foundation

public enum Tonemapping: Codable {
    case none
    case aces
    case filmic
    case lottes
    case reinhard
    case reinhard2
    case uchimura
    case uncharted2
    case unreal

    public var description: String {
        return String(describing: self)
    }

    public var shaderDefine: String {
        return "TONEMAPPING_" + description.uppercased()
    }
}
