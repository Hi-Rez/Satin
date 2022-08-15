//
//  Mapping.swift
//  
//
//  Created by Reza Ali on 8/9/22.
//

import Foundation

public func remap(input: Float, inputMin: Float, inputMax: Float, outputMin: Float, outputMax: Float) -> Float {
    return ((input - inputMin) / (inputMax - inputMin) * (outputMax - outputMin)) + outputMin;
}
