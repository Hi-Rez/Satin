//
//  Tessellator.swift
//  Tesselation
//
//  Created by Reza Ali on 4/2/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import Satin

protocol Tessellator {
    var buffer: MTLBuffer? { get }
    var parameters: ParameterGroup? { get }

    var threadPerGrid: MTLSize { get }
    var threadsPerThreadgroup: MTLSize { get }

    func update(commandBuffer: MTLCommandBuffer)
}
