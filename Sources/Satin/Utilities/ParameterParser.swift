//
//  ParameterParser.swift
//  Satin
//
//  Created by Reza Ali on 11/3/19.
//

import Foundation
import simd

public func parseStruct(source: String, key: String) -> ParameterGroup? {
    if let structSource = _parseStruct(source: source, key: key), let params = parseStruct(source: structSource) {
        params.label = key
        return params
    }
    return nil
}

public func parseParameters(source: String, key: String) -> ParameterGroup? {
    if let structSource = _parseStruct(source: source, key: key), let params = parseParameters(source: structSource) {
        params.label = key
        return params
    }
    return nil
}

public func findStructName(_ key: String, _ source: String) -> String? {
    do {
        var pattern = #".?(constant|device) +?(\w*) +?&?\*?"#
        pattern += key
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: nsrange)
        for match in matches {
            if let r2 = Range(match.range(at: 2), in: source) {
                return String(source[r2])
            }
        }
    }
    catch {
        print(error)
    }
    return nil
}

func _parseStruct(source: String, key: String) -> String? {
    do {
        let patterns = [
            "\\{((?:(.|\\n)(?!\\{))+)\\} \(key)\\s*;",
            key + "\\W*\\{\\W(?:((.*|\\n)+))\\W\\}"
        ]
        for pattern in patterns {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(source.startIndex..<source.endIndex, in: source)
            let matches = regex.matches(in: source, options: [], range: range)

            for match in matches {
                if let r1 = Range(match.range(at: 1), in: source) {
                    return String(source[r1]) + "\n"
                }
            }
        }

        return nil
    }
    catch {
        print(error)
    }
    return nil
}

func parseStruct(source: String) -> ParameterGroup? {
    do {
        let params = ParameterGroup("")
        let pattern = #"(\w+\_?\w+) +(\w+) ?; ?\n?"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: nsrange)

        for match in matches {
            var vType: String?
            var vName: String?

            if let r1 = Range(match.range(at: 1), in: source) {
                vType = String(source[r1])
            }

            if let r2 = Range(match.range(at: 2), in: source) {
                vName = String(source[r2])
            }

            if let type = vType, let name = vName {
                addParameter(group: params, type: type, name: name)
            }
        }
        return params
    }
    catch {
        print(error)
        return nil
    }
}

func addParameter(group: ParameterGroup, type: String, name: String, control: ControlType = .none) {
    switch type {
        case "float":
            group.append(FloatParameter(name, 0.0, control))
        case "float2":
            group.append(Float2Parameter(name, .zero, control))
        case "float3":
            group.append(Float3Parameter(name, .zero, control))
        case "float4":
            group.append(Float4Parameter(name, .zero, control))
        case "int":
            group.append(IntParameter(name, .zero, control))
        case "int2":
            group.append(Int2Parameter(name, .zero, control))
        case "int3":
            group.append(Int3Parameter(name, .zero, control))
        case "int4":
            group.append(Int4Parameter(name, .zero, control))
        case "bool":
            group.append(BoolParameter(name, false, control))
        case "float2x2":
            group.append(Float2x2Parameter(name, simd_float2x2(.zero, .zero), control))
        case "float3x3":
            group.append(Float3x3Parameter(name, simd_float3x3(.zero, .zero, .zero), control))
        case "float4x4":
            group.append(Float4x4Parameter(name, simd_float4x4(.zero, .zero, .zero, .zero), control))
        default:
            break
    }
}

func parseParameters(source: String) -> ParameterGroup? {
    do {
        let params = ParameterGroup("")
        let pattern = #"^\s*(?!\/\/)(\w+\_?\w+)\s+(\w+)\s*;\s*(\s*\/\/\s*((\w+),?:?(.*))?)?$"#
        let options: NSRegularExpression.Options = [.anchorsMatchLines]
        let regex = try NSRegularExpression(pattern: pattern, options: options)
        let nsrange = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: nsrange)

        for match in matches {
            var vType: String?
            var vName: String?
            var uiType: String?
            var uiDetails: String?

            // Type: float, float2, int2, etc
            if let r1 = Range(match.range(at: 1), in: source) {
                vType = String(source[r1])
            }

            // name: position, uv, etc
            if let r2 = Range(match.range(at: 2), in: source) {
                vName = String(source[r2])
            }

            // if comment doesnt exist, just create the parameter with no UI = .none
            if let type = vType, let name = vName, Range(match.range(at: 3), in: source) == nil {
                addParameter(group: params, type: type, name: name.titleCase)
                continue
            }

            if let r3 = Range(match.range(at: 5), in: source) {
                uiType = String(source[r3])
            }
            if let r4 = Range(match.range(at: 6), in: source) {
                uiDetails = String(source[r4])
            }

            if let vType = vType, let uiType = uiType, let uiDetails = uiDetails {
                if uiType == "slider" {
                    var success = false
                    var subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *(.*)"#
                    var subRegex = NSRegularExpression()
                    do {
                        subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                    }
                    catch {
                        print(error)
                    }

                    var subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                    var subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                    if let subMatch = subMatches.first {
                        var min: String?
                        var max: String?
                        var value: String?
                        var label: String?

                        if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                            min = String(uiDetails[r1])
                        }

                        if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                            max = String(uiDetails[r2])
                        }

                        if let r3 = Range(subMatch.range(at: 3), in: uiDetails) {
                            value = String(uiDetails[r3])
                        }

                        if let r4 = Range(subMatch.range(at: 4), in: uiDetails) {
                            label = String(uiDetails[r4])
                        }

                        if let min = min, let max = max, let value = value, let label = label {
                            if let fMin = Float(min), let fMax = Float(max), let fValue = Float(value) {
                                var parameter: Parameter?
                                if vType == "float" {
                                    parameter = FloatParameter(label, fValue, fMin, fMax, .slider)
                                }
                                else if vType == "float2" {
                                    parameter = Float2Parameter(label, .init(repeating: fValue), .init(repeating: fMin), .init(repeating: fMax), .multislider)
                                }
                                else if vType == "float3" {
                                    parameter = Float3Parameter(label, .init(repeating: fValue), .init(repeating: fMin), .init(repeating: fMax), .multislider)
                                }
                                else if vType == "float4" {
                                    parameter = Float4Parameter(label, .init(repeating: fValue), .init(repeating: fMin), .init(repeating: fMax), .multislider)
                                }
                                else if vType == "int" {
                                    parameter = IntParameter(label, Int(fValue), Int(fMin), Int(fMax), .slider)
                                }

                                if let parameter = parameter {
                                    params.append(parameter)
                                    success = true
                                }
                            }
                        }
                    }

                    if !success {
                        subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?$"#
                        do {
                            subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                        }
                        catch {
                            print(error)
                        }
                        subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                        subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                        if let subMatch = subMatches.first {
                            var min: String?
                            var max: String?
                            var value: String?

                            if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                                min = String(uiDetails[r1])
                            }

                            if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                                max = String(uiDetails[r2])
                            }

                            if let r3 = Range(subMatch.range(at: 3), in: uiDetails) {
                                value = String(uiDetails[r3])
                            }

                            if let min = min, let max = max, let value = value, let label = vName {
                                if let fMin = Float(min), let fMax = Float(max), let fValue = Float(value) {
                                    var parameter: Parameter?
                                    if vType == "float" {
                                        parameter = FloatParameter(label.titleCase, fValue, fMin, fMax, .slider)
                                    }
                                    else if vType == "float2" {
                                        parameter = Float2Parameter(label.titleCase, .init(repeating: fValue), .init(repeating: fMin), .init(repeating: fMax), .multislider)
                                    }
                                    else if vType == "float3" {
                                        parameter = Float3Parameter(label.titleCase, .init(repeating: fValue), .init(repeating: fMin), .init(repeating: fMax), .multislider)
                                    }
                                    else if vType == "float4" {
                                        parameter = Float4Parameter(label.titleCase, .init(repeating: fValue), .init(repeating: fMin), .init(repeating: fMax), .multislider)
                                    }
                                    else if vType == "int" {
                                        parameter = IntParameter(label.titleCase, Int(fValue), Int(fMin), Int(fMax), .slider)
                                    }

                                    if let parameter = parameter {
                                        params.append(parameter)
                                        success = true
                                    }
                                }
                            }
                        }
                    }

                    if !success, let name = vName {
                        var label = uiDetails.count > 0 ? uiDetails : name
                        label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                        let firstChar = String(label[label.startIndex])
                        label = label.replacingCharacters(in: ...label.startIndex, with: firstChar.uppercased())

                        var parameter: Parameter?
                        if vType == "float" {
                            parameter = FloatParameter(label.titleCase, 0.5, 0.0, 1.0, .slider)
                        }
                        else if vType == "float2" {
                            parameter = Float2Parameter(label.titleCase, .init(repeating: 0.5), .zero, .one, .multislider)
                        }
                        else if vType == "float3" {
                            parameter = Float3Parameter(label.titleCase, .init(repeating: 0.5), .zero, .one, .multislider)
                        }
                        else if vType == "float4" {
                            parameter = Float4Parameter(label.titleCase, .init(repeating: 0.5), .zero, .one, .multislider)
                        }
                        else if vType == "int" {
                            parameter = IntParameter(label.titleCase, 50, 0, 100, .slider)
                        }

                        if let parameter = parameter {
                            params.append(parameter)
                            success = true
                        }
                    }
                }
                else if uiType == "input" {
                    var success = false
                    var subPattern = #" *?(-?\d*?\.?\d*?) *?, *(.*)$"#
                    var subRegex = NSRegularExpression()
                    do {
                        subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                    }
                    catch {
                        print(error)
                    }

                    var subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                    var subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                    if let subMatch = subMatches.first {
                        var value: String?
                        var label: String?

                        if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                            value = String(uiDetails[r1])
                        }

                        if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                            label = String(uiDetails[r2])
                        }

                        if let value = value, let label = label {
                            if let fValue = Float(value) {
                                var parameter: Parameter?

                                if vType == "float" {
                                    parameter = FloatParameter(label, fValue, .inputfield)
                                }
                                else if vType == "float2" {
                                    parameter = Float2Parameter(label, simd_make_float2(fValue, fValue), .inputfield)
                                }
                                else if vType == "float3" {
                                    parameter = Float3Parameter(label, simd_make_float3(fValue, fValue, fValue), .inputfield)
                                }
                                else if vType == "float4" {
                                    parameter = Float4Parameter(label, simd_make_float4(fValue, fValue, fValue, fValue), .inputfield)
                                }
                                else if vType == "int" {
                                    parameter = IntParameter(label, Int(fValue), .inputfield)
                                }
                                else if vType == "int2" {
                                    let iValue = Int32(fValue)
                                    parameter = Int2Parameter(label, simd_make_int2(iValue, iValue), .inputfield)
                                }
                                else if vType == "int3" {
                                    let iValue = Int32(fValue)
                                    parameter = Int3Parameter(label, simd_make_int3(iValue, iValue, iValue), .inputfield)
                                }
                                else if vType == "int4" {
                                    let iValue = Int32(fValue)
                                    parameter = Int4Parameter(label, simd_make_int4(iValue, iValue, iValue, iValue), .inputfield)
                                }

                                if let parameter = parameter {
                                    params.append(parameter)
                                    success = true
                                }
                            }
                        }
                    }

                    if !success, uiDetails.count > 0 {
                        print(uiDetails)
                        subPattern = #" *?(-?\d*?\.?\d*?) *?$"#
                        do {
                            subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                        }
                        catch {
                            print(error)
                        }

                        subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                        subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                        if let subMatch = subMatches.first {
                            var value: String?

                            if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                                value = String(uiDetails[r1])
                            }

                            if let value = value, value.count > 0, let fValue = Float(value), let name = vName {
                                var label = name
                                label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                                var parameter: Parameter?

                                if vType == "float" {
                                    parameter = FloatParameter(label.titleCase, fValue, .inputfield)
                                }
                                else if vType == "float2" {
                                    parameter = Float2Parameter(label.titleCase, simd_make_float2(fValue, fValue), .inputfield)
                                }
                                else if vType == "float3" {
                                    parameter = Float3Parameter(label.titleCase, simd_make_float3(fValue, fValue, fValue), .inputfield)
                                }
                                else if vType == "float4" {
                                    parameter = Float4Parameter(label.titleCase, simd_make_float4(fValue, fValue, fValue, fValue), .inputfield)
                                }
                                else if vType == "int" {
                                    parameter = IntParameter(label.titleCase, Int(fValue), .inputfield)
                                }
                                else if vType == "int2" {
                                    let iValue = Int32(fValue)
                                    parameter = Int2Parameter(label.titleCase, simd_make_int2(iValue, iValue), .inputfield)
                                }
                                else if vType == "int3" {
                                    let iValue = Int32(fValue)
                                    parameter = Int3Parameter(label.titleCase, simd_make_int3(iValue, iValue, iValue), .inputfield)
                                }
                                else if vType == "int4" {
                                    let iValue = Int32(fValue)
                                    parameter = Int4Parameter(label.titleCase, simd_make_int4(iValue, iValue, iValue, iValue), .inputfield)
                                }

                                if let parameter = parameter {
                                    params.append(parameter)
                                    success = true
                                }
                            }
                        }
                    }

                    if !success, let name = vName {
                        var label = uiDetails.count > 0 ? uiDetails : name
                        label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                        let firstChar = String(label[label.startIndex])
                        label = label.replacingCharacters(in: ...label.startIndex, with: firstChar.uppercased())

                        var parameter: Parameter?

                        if vType == "float" {
                            parameter = FloatParameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "float2" {
                            parameter = Float2Parameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "float3" {
                            parameter = Float3Parameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "float4" {
                            parameter = Float4Parameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "int" {
                            parameter = IntParameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "int2" {
                            parameter = Int2Parameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "int3" {
                            parameter = Int3Parameter(label.titleCase, .zero, .inputfield)
                        }
                        else if vType == "int4" {
                            parameter = Int4Parameter(label.titleCase, .zero, .inputfield)
                        }

                        if let parameter = parameter {
                            params.append(parameter)
                            success = true
                        }
                    }
                }
                else if uiType == "toggle", vType == "bool" {
                    var success = false
                    let subPattern = #" *?(\w*) *?, *(.*)"#
                    var subRegex = NSRegularExpression()
                    do {
                        subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                    }
                    catch {
                        print(error)
                    }
                    let subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                    let subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                    if let subMatch = subMatches.first {
                        var value: String?
                        var label: String?

                        if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                            value = String(uiDetails[r1])
                        }

                        if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                            label = String(uiDetails[r2])
                        }

                        if let value = value, let label = label {
                            params.append(BoolParameter(label, value == "true" ? true : false, .toggle))
                            success = true
                        }
                    }

                    if !success, let name = vName {
                        var label = name
                        label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)

                        if uiDetails.count > 0 {
                            let value = uiDetails
                            params.append(BoolParameter(label.titleCase, value == "true" ? true : false, .toggle))
                        }
                        else {
                            params.append(BoolParameter(label.titleCase, true, .toggle))
                        }
                        success = true
                    }
                }
                else if uiType == "color", vType == "float4" {
                    var success = false
                    var subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *(.*)"#
                    var subRegex = NSRegularExpression()

                    do {
                        subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                    }
                    catch {
                        print(error)
                    }

                    var subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                    var subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                    if let subMatch = subMatches.first {
                        var red: String?
                        var green: String?
                        var blue: String?
                        var alpha: String?
                        var label: String?

                        if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                            red = String(uiDetails[r1])
                        }

                        if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                            green = String(uiDetails[r2])
                        }

                        if let r3 = Range(subMatch.range(at: 3), in: uiDetails) {
                            blue = String(uiDetails[r3])
                        }

                        if let r4 = Range(subMatch.range(at: 4), in: uiDetails) {
                            alpha = String(uiDetails[r4])
                        }

                        if let r5 = Range(subMatch.range(at: 5), in: uiDetails) {
                            label = String(uiDetails[r5])
                        }

                        if let red = red, let green = green, let blue = blue, let alpha = alpha, let label = label {
                            if let fRed = Float(red), let fGreen = Float(green), let fBlue = Float(blue), let fAlpha = Float(alpha) {
                                params.append(Float4Parameter(label, simd_make_float4(fRed, fGreen, fBlue, fAlpha), .colorpicker))
                                success = true
                            }
                        }
                    }

                    if !success {
                        subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?)$"#
                        do {
                            subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                        }
                        catch {
                            print(error)
                        }

                        subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                        subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                        if let subMatch = subMatches.first {
                            var red: String?
                            var green: String?
                            var blue: String?
                            var alpha: String?

                            if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                                red = String(uiDetails[r1])
                            }

                            if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                                green = String(uiDetails[r2])
                            }

                            if let r3 = Range(subMatch.range(at: 3), in: uiDetails) {
                                blue = String(uiDetails[r3])
                            }

                            if let r4 = Range(subMatch.range(at: 4), in: uiDetails) {
                                alpha = String(uiDetails[r4])
                            }

                            if let red = red, let green = green, let blue = blue, let alpha = alpha, let label = vName {
                                if let fRed = Float(red), let fGreen = Float(green), let fBlue = Float(blue), let fAlpha = Float(alpha) {
                                    params.append(Float4Parameter(label.titleCase, simd_make_float4(fRed, fGreen, fBlue, fAlpha), .colorpicker))
                                    success = true
                                }
                            }
                        }
                    }

                    if !success, let name = vName {
                        var label = uiDetails.count > 0 ? uiDetails : name
                        label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                        params.append(Float4Parameter(label.titleCase, simd_make_float4(1.0, 1.0, 1.0, 1.0), .colorpicker))
                        success = true
                    }
                }
                else if uiType == "colorpalette", vType == "float4", let name = vName {
                    var label = uiDetails.count > 0 ? uiDetails : name
                    label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                    params.append(Float4Parameter(label.titleCase, simd_make_float4(1.0, 1.0, 1.0, 1.0), .colorpalette))
                }
                else if uiType == "color", vType == "float3" {
                    var success = false
                    var subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *(.*)"#
                    var subRegex = NSRegularExpression()

                    do {
                        subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                    }
                    catch {
                        print(error)
                    }

                    var subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                    var subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                    if let subMatch = subMatches.first {
                        var red: String?
                        var green: String?
                        var blue: String?
                        var label: String?

                        if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                            red = String(uiDetails[r1])
                        }

                        if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                            green = String(uiDetails[r2])
                        }

                        if let r3 = Range(subMatch.range(at: 3), in: uiDetails) {
                            blue = String(uiDetails[r3])
                        }

                        if let r5 = Range(subMatch.range(at: 4), in: uiDetails) {
                            label = String(uiDetails[r5])
                        }

                        if let red = red, let green = green, let blue = blue, let label = label {
                            if let fRed = Float(red), let fGreen = Float(green), let fBlue = Float(blue) {
                                params.append(Float3Parameter(label, simd_make_float3(fRed, fGreen, fBlue), .colorpicker))
                                success = true
                            }
                        }
                    }

                    if !success {
                        subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?)$"#
                        do {
                            subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                        }
                        catch {
                            print(error)
                        }

                        subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                        subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

                        if let subMatch = subMatches.first {
                            var red: String?
                            var green: String?
                            var blue: String?

                            if let r1 = Range(subMatch.range(at: 1), in: uiDetails) {
                                red = String(uiDetails[r1])
                            }

                            if let r2 = Range(subMatch.range(at: 2), in: uiDetails) {
                                green = String(uiDetails[r2])
                            }

                            if let r3 = Range(subMatch.range(at: 3), in: uiDetails) {
                                blue = String(uiDetails[r3])
                            }

                            if let red = red, let green = green, let blue = blue, let label = vName {
                                if let fRed = Float(red), let fGreen = Float(green), let fBlue = Float(blue) {
                                    params.append(Float3Parameter(label.titleCase, simd_make_float3(fRed, fGreen, fBlue), .colorpicker))
                                    success = true
                                }
                            }
                        }
                    }

                    if !success, let name = vName {
                        var label = uiDetails.count > 0 ? uiDetails : name
                        label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                        params.append(Float3Parameter(label.titleCase, simd_make_float3(1.0, 1.0, 1.0), .colorpicker))
                        success = true
                    }
                }
                else if uiType == "colorpalette", vType == "float3", let name = vName {
                    var label = uiDetails.count > 0 ? uiDetails : name
                    label = label.replacingOccurrences(of: ",", with: "", options: .literal, range: nil)
                    params.append(Float3Parameter(label.titleCase, simd_make_float3(1.0, 1.0, 1.0), .colorpalette))
                }
            }
        }
        return params
    }
    catch {
        print(error)
        return nil
    }
}
