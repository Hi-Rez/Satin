//
//  MTLSamplerDescriptor.swift
//  Satin
//
//  Created by Reza Ali on 4/4/23.
//

import Metal

extension MTLSamplerDescriptor {
    func shaderInjection(index: PBRTextureIndex) -> String {
        var minfilter = ""
        switch self.minFilter {
            case .nearest:
                minfilter = "min_filter::nearest"
            case .linear:
                minfilter = "min_filter::linear"
            @unknown default:
                break
        }

        var magfilter = ""
        switch self.magFilter {
            case .nearest:
                magfilter = "mag_filter::nearest"
            case .linear:
                magfilter = "mag_filter::linear"
            @unknown default:
                break
        }

        var mipfilter = ""
        switch self.mipFilter {
            case .notMipmapped:
                break
            case .nearest:
                mipfilter = "mip_filter::nearest"
            case .linear:
                mipfilter = "mip_filter::linear"
            @unknown default:
                break
        }

        var coord = ""
        switch self.normalizedCoordinates {
            case true:
                coord = "coord::normalized"
            case false:
                coord = "coord::pixel"
        }

        var border_color = ""
        if #available(iOS 14.0, *) {
            switch self.borderColor {
                case .transparentBlack:
                    border_color = "border_color::transparent_black"
                case .opaqueBlack:
                    border_color = "border_color::opaque_black"
                case .opaqueWhite:
                    border_color = "border_color::opaque_white"
                @unknown default:
                    break
            }
        } else {
            // Fallback on earlier versions
        }

        var s_address = ""
        switch self.sAddressMode {
            case .clampToEdge:
                s_address = "s_address::clamp_to_edge"
            case .mirrorClampToEdge:
                s_address = "s_address::mirrored_clamp"
            case .repeat:
                s_address = "s_address::repeat"
            case .mirrorRepeat:
                s_address = "s_address::mirrored_repeat"
            case .clampToZero:
                s_address = "s_address::clamp_to_zero"
            case .clampToBorderColor:
                s_address = "s_address::clamp_to_border"
            @unknown default:
                break
        }

        var r_address = ""
        switch self.rAddressMode {
            case .clampToEdge:
                r_address = "r_address::clamp_to_edge"
            case .mirrorClampToEdge:
                r_address = "r_address::mirrored_clamp"
            case .repeat:
                r_address = "r_address::repeat"
            case .mirrorRepeat:
                r_address = "r_address::mirrored_repeat"
            case .clampToZero:
                r_address = "r_address::clamp_to_zero"
            case .clampToBorderColor:
                r_address = "r_address::clamp_to_border"
            @unknown default:
                break
        }

        var t_address = ""
        switch self.tAddressMode {
            case .clampToEdge:
                t_address = "t_address::clamp_to_edge"
            case .mirrorClampToEdge:
                t_address = "t_address::mirrored_clamp"
            case .repeat:
                t_address = "t_address::repeat"
            case .mirrorRepeat:
                t_address = "t_address::mirrored_repeat"
            case .clampToZero:
                t_address = "t_address::clamp_to_zero"
            case .clampToBorderColor:
                t_address = "t_address::clamp_to_border"
            @unknown default:
                break
        }

        var injection = "constexpr sampler " + index.samplerName + "("
        injection += minfilter.isEmpty ? "" : minfilter
        injection += magfilter.isEmpty ? "" : ", " + magfilter
        injection += mipfilter.isEmpty ? "" : ", " + mipfilter
        injection += coord.isEmpty ? "" : ", " + coord
        injection += s_address.isEmpty ? "" : ", " + s_address
        injection += r_address.isEmpty ? "" : ", " + r_address
        injection += t_address.isEmpty ? "" : ", " + t_address
        injection += border_color.isEmpty ? "" : ", " + border_color
        injection += ");"
        return injection
    }
}
