//
//  Light.swift
//  
//
//  Created by Reza Ali on 11/2/22.
//

import Foundation
import Combine
import simd

public protocol Light {
    var type: LightType { get }

    var data: LightData { get }
        
    var color: simd_float3 { get set } // color
    var intensity: Float { get set }
    
    var publisher: PassthroughSubject<Light, Never> { get }
}
