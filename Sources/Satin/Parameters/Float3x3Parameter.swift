//
//  File.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import simd

public class Float3x3Parameter: GenericParameter<simd_float3x3> {
    override public var type: ParameterType { .float3x3 }
    override public var string: String { "float3x3" }
    override public var count: Int { 3 }

    override public subscript<simd_float3>(index: Int) -> simd_float3 {
        get {
            return value[index % count] as! simd_float3
        }
        set {
            switch index % count {
            case 0:
                value.columns.0 = newValue as! SIMD3<Float>
            case 1:
                value.columns.1 = newValue as! SIMD3<Float>
            case 2:
                value.columns.2 = newValue as! SIMD3<Float>
            default:
                break
            }
        }
    }
}
