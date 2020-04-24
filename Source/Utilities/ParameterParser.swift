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

func _parseStruct(source: String, key: String) -> String? {
    do {
        let patterns = [
            "\\{((?:(.|\\n)(?!\\{))+)\\} \(key)",
            key+"\\W*\\{\\W(?:((.*|\\n)+))\\W\\}"
        ]
        for pattern in patterns {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(source.startIndex..<source.endIndex, in: source)
            let matches = regex.matches(in: source, options: [], range: range)

            for match in matches {
                if let r1 = Range(match.range(at: 1), in: source) {
                    return String(source[r1])+"\n"
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
                if type == "bool" {
                    params.append(BoolParameter(name))
                }
                else if type == "int" {
                    params.append(IntParameter(name))
                }
                else if type == "int2" {
                    params.append(Int2Parameter(name))
                }
                else if type == "int3" {
                    params.append(Int3Parameter(name))
                }
                else if type == "int4" {
                    params.append(Int4Parameter(name))
                }
                else if type == "float" {
                    params.append(FloatParameter(name))
                }
                else if type == "float2" {
                    params.append(Float2Parameter(name))
                }
                else if type == "float3" {
                    params.append(Float3Parameter(name))
                }
                else if type == "float4" {
                    params.append(Float4Parameter(name))
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

func parseParameters(source: String) -> ParameterGroup? {
    do {
        let params = ParameterGroup("")
        let pattern = #"^\s*(?!\/\/)(\w+\_?\w+)\s+(\w+)\s*;\s*\/\/\s*((\w+),?:?(.*))?$"#
        let options: NSRegularExpression.Options = [.anchorsMatchLines]
        let regex = try NSRegularExpression(pattern: pattern, options:options)
        let nsrange = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: nsrange)

        for match in matches {
            var vType: String?
            var vName: String?
            var uiType: String?
            var uiDetails: String?

            if let r1 = Range(match.range(at: 1), in: source) {
                vType = String(source[r1])
            }
            if let r2 = Range(match.range(at: 2), in: source) {
                vName = String(source[r2])
            }
            if let r3 = Range(match.range(at: 4), in: source) {
                uiType = String(source[r3])
            }
            if let r4 = Range(match.range(at: 5), in: source) {
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
                                    parameter = FloatParameter(label, fValue, fMin, fMax)
                                }
                                else if vType == "int" {
                                    parameter = IntParameter(label, Int(fValue), Int(fMin), Int(fMax))
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
                                        parameter = FloatParameter(label.titleCase, fValue, fMin, fMax)
                                    }
                                    else if vType == "int" {
                                        parameter = IntParameter(label.titleCase, Int(fValue), Int(fMin), Int(fMax))
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
                            parameter = FloatParameter(label.titleCase, 0.5, 0.0, 1.0)
                        }
                        else if vType == "int" {
                            parameter = IntParameter(label.titleCase, 50, 0, 100)
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
                                else if vType == "int" {
                                    parameter = IntParameter(label, Int(fValue), .inputfield)
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
                                else if vType == "int" {
                                    parameter = IntParameter(label.titleCase, Int(fValue), .inputfield)
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
                            parameter = FloatParameter(label.titleCase, 0.0, .inputfield)
                        }
                        else if vType == "int" {
                            parameter = IntParameter(label.titleCase, 0, .inputfield)
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
                    var subRegex: NSRegularExpression = NSRegularExpression()
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
                    var subRegex: NSRegularExpression = NSRegularExpression()

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
            }
        }
        return params
    }
    catch {
        print(error)
        return nil
    }
}
