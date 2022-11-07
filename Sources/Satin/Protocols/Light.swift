//
//  Light.swift
//  
//
//  Created by Reza Ali on 11/2/22.
//

import Foundation
import simd

public protocol Light {
    var type: LightType { get }
    var color: simd_float4 { get set } // color
    var intensity: Float { get set }
    
    func getLightData() -> LightData
}
