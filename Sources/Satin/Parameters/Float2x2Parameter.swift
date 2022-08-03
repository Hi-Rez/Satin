//
//  Float2x2Parameter.swift
//  
//
//  Created by Reza Ali on 8/3/22.
//

import Foundation
import simd

public class Float2x2Parameter: GenericParameter<simd_float2x2> {
    override public var type: ParameterType { .float2x2 }
    override public var string: String { "float2x2" }
    override public var count: Int { 2 }
    
    override public subscript<simd_float2>(index: Int) -> simd_float2 {
        get {
            return value[index % count] as! simd_float2
        }
        set {
            switch index % count {
            case 0:
                value.columns.0 = newValue as! SIMD2<Float>
            case 1:
                value.columns.1 = newValue as! SIMD2<Float>
            default:
                break
            }
        }
    }
}
