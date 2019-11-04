//
//  ParameterParser.swift
//  Satin
//
//  Created by Reza Ali on 11/3/19.
//

import Foundation

public func parseParameters(source: String, key: String) -> ParameterGroup? {
    if let structSource = parseStruct(source: source, key: key) {
        return parseParameters(source: structSource)
    }
    return nil
}

func parseStruct(source: String, key: String) -> String? {
    do {
        let pattern = "\\{((?:(.|\\n)(?!\\{))+)\\} \(key)"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: range)

        for match in matches {
            if let r1 = Range(match.range(at: 1), in: source) {
                return String(source[r1])
            }
        }
        return nil
    }
    catch {
        print(error)
    }
    return nil
}

func parseParameters(source: String) -> ParameterGroup? {
    do {
        let params = ParameterGroup("")
        let pattern = #"(\w+\_?\w+) +(\w+); *\/\/ *(\w+) *: *(.*?)\n"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: nsrange)

        for match in matches {
            var vType: String?
            var uiType: String?
            var uiDetails: String?

            if let r1 = Range(match.range(at: 1), in: source) {
                vType = String(source[r1])
            }
            if let r3 = Range(match.range(at: 3), in: source) {
                uiType = String(source[r3])
            }
            if let r4 = Range(match.range(at: 4), in: source) {
                uiDetails = String(source[r4])
            }

            if let vType = vType, let uiType = uiType, let uiDetails = uiDetails {
                if uiType == "slider" {
                    do {
                        let subPattern = #" *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *?(-?\d*?\.?\d*?) *?, *(.*)"#
                        let subRegex = try NSRegularExpression(pattern: subPattern, options: [])
                        let subRange = NSRange(uiDetails.startIndex..<uiDetails.endIndex, in: uiDetails)
                        let subMatches = subRegex.matches(in: uiDetails, options: [], range: subRange)

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
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        print(error)
                        return nil
                    }
                }
                else if uiType == "toggle" {
                    do {
                        let subPattern = #" *?(\w*) *?, *(.*)"#
                        let subRegex = try NSRegularExpression(pattern: subPattern, options: [])
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
                                let parameter = BoolParameter(label, value == "true" ? true : false)
                                params.append(parameter)
                            }
                        }
                    }
                    catch {
                        print(error)
                        return nil
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
