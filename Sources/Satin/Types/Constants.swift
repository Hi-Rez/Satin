//
//  Defines.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

public let maxBuffersInFlight: Int = 3

public let worldForwardDirection = simd_make_float3(0, 0, 1)
public let worldUpDirection = simd_make_float3(0, 1, 0)
public let worldRightDirection = simd_make_float3(1, 0, 0)

public enum Blending: Codable {
    case disabled
    case alpha
    case additive
    case subtract
    case custom
}

public enum VertexAttribute: Int {
    case Position = 0
    case Normal = 1
    case Texcoord = 2
    case Custom0 = 3
    case Custom1 = 4
    case Custom2 = 5
    case Custom3 = 6
    case Custom4 = 7
    case Custom5 = 8
    case Custom6 = 9
    case Custom7 = 10
    case Custom8 = 11
    case Custom9 = 12
    case Custom10 = 13

    public var description: String {
        return String(describing: self)
    }

    public var name: String {
        switch self {
        case .Position:
            return "position"
        case .Normal:
            return "normal"
        case .Texcoord:
            return "uv"
        case .Custom0:
            return "custom0"
        case .Custom1:
            return "custom1"
        case .Custom2:
            return "custom2"
        case .Custom3:
            return "custom3"
        case .Custom4:
            return "custom4"
        case .Custom5:
            return "custom5"
        case .Custom6:
            return "custom6"
        case .Custom7:
            return "custom7"
        case .Custom8:
            return "custom8"
        case .Custom9:
            return "custom9"
        case .Custom10:
            return "custom10"
        }
    }
}

public enum VertexBufferIndex: Int {
    case Vertices = 0
    case VertexUniforms = 1
    case InstanceMatrixUniforms = 2
    case MaterialUniforms = 3
    case Custom0 = 4
    case Custom1 = 5
    case Custom2 = 6
    case Custom3 = 7
    case Custom4 = 8
    case Custom5 = 9
    case Custom6 = 10
    case Custom7 = 11
    case Custom8 = 12
    case Custom9 = 13
    case Custom10 = 14
}

public enum VertexTextureIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
}

public enum FragmentBufferIndex: Int {
    case MaterialUniforms = 0
    case Custom0 = 1
    case Custom1 = 2
    case Custom2 = 3
    case Custom3 = 4
    case Custom4 = 5
    case Custom5 = 6
    case Custom6 = 7
    case Custom7 = 8
    case Custom8 = 9
    case Custom9 = 10
    case Custom10 = 11
}

public enum FragmentTextureIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
}

public enum FragmentSamplerIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
}

public enum ComputeBufferIndex: Int {
    case Uniforms = 0
    case Custom0 = 1
    case Custom1 = 2
    case Custom2 = 3
    case Custom3 = 4
    case Custom4 = 5
    case Custom5 = 6
    case Custom6 = 7
    case Custom7 = 8
    case Custom8 = 9
    case Custom9 = 10
    case Custom10 = 11
}

public enum ComputeTextureIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
}
