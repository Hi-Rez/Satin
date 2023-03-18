//
//  File.swift
//  
//
//  Created by Reza Ali on 3/17/23.
//

import Foundation

public enum VertexBufferIndex: Int {
    case Vertices = 0
    case Generics = 1
    case VertexUniforms = 2
    case InstanceMatrixUniforms = 3
    case MaterialUniforms = 4
    case ShadowMatrices = 5
    case Custom0 = 6
    case Custom1 = 7
    case Custom2 = 8
    case Custom3 = 9
    case Custom4 = 10
    case Custom5 = 11
    case Custom6 = 12
    case Custom7 = 13
    case Custom8 = 14
    case Custom9 = 15
    case Custom10 = 16
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
    case Custom11 = 11
    case Custom12 = 12
    case Custom13 = 13
    case Custom14 = 14
    case Custom15 = 15
    case Custom16 = 16
}

public enum VertexAttribute: Int, CaseIterable {
    case Position = 0
    case Normal = 1
    case Texcoord = 2
    case Tangent = 3
    case Bitangent = 4
    case Color = 5
    case Custom0 = 6
    case Custom1 = 7
    case Custom2 = 8
    case Custom3 = 9
    case Custom4 = 10
    case Custom5 = 11
    case Custom6 = 12
    case Custom7 = 13
    case Custom8 = 14
    case Custom9 = 15
    case Custom10 = 16
    case Custom11 = 17

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
            case .Tangent:
                return "tangent"
            case .Bitangent:
                return "bitangent"
            case .Color:
                return "color"
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
            case .Custom11:
                return "custom11"
        }
    }

    public var shaderDefine: String {
        switch self {
            case .Position:
                return "HAS_POSITION"
            case .Normal:
                return "HAS_NORMAL"
            case .Texcoord:
                return "HAS_UV"
            case .Tangent:
                return "HAS_TANGENT"
            case .Bitangent:
                return "HAS_BITANGENT"
            case .Color:
                return "HAS_COLOR"
            case .Custom0:
                return "HAS_CUSTOM0"
            case .Custom1:
                return "HAS_CUSTOM1"
            case .Custom2:
                return "HAS_CUSTOM2"
            case .Custom3:
                return "HAS_CUSTOM3"
            case .Custom4:
                return "HAS_CUSTOM4"
            case .Custom5:
                return "HAS_CUSTOM5"
            case .Custom6:
                return "HAS_CUSTOM6"
            case .Custom7:
                return "HAS_CUSTOM7"
            case .Custom8:
                return "HAS_CUSTOM8"
            case .Custom9:
                return "HAS_CUSTOM9"
            case .Custom10:
                return "HAS_CUSTOM10"
            case .Custom11:
                return "HAS_CUSTOM11"
        }
    }
}
