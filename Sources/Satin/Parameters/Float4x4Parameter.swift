//
//  Float4x4Parameter.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import simd

public class Float4x4Parameter: GenericParameter<simd_float4x4> {
    override public var type: ParameterType { .float4x4 }
    override public var string: String { "float4x4" }
    override public var count: Int { 4 }

    override public subscript<simd_float4>(index: Int) -> simd_float4 {
        get {
            return value[index % count] as! simd_float4
        }
        set {
            switch index % count {
            case 0:
                value.columns.0 = newValue as! SIMD4<Float>
            case 1:
                value.columns.1 = newValue as! SIMD4<Float>
            case 2:
                value.columns.2 = newValue as! SIMD4<Float>
            case 3:
                value.columns.3 = newValue as! SIMD4<Float>
            default:
                break
            }
        }
    }
}
