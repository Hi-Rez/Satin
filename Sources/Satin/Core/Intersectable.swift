//
//  File.swift
//  
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import Metal

public protocol Intersectable {
    var vertexBuffer: MTLBuffer? { get }
    var indexBuffer: MTLBuffer? { get }
}
