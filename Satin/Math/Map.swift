//
//  Map.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

public func map(_ input: Float, _ inMin: Float, _ inMax: Float, _ outMin: Float, _ outMax: Float) -> Float {
    return ((input - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}

