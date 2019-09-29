//
//  Context.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class Context {
    var device: MTLDevice
    var sampleCount: Int
    var colorPixelFormat: MTLPixelFormat
    var depthPixelFormat: MTLPixelFormat
    var stencilPixelFormat: MTLPixelFormat

    public init(_ device: MTLDevice,
                _ sampleCount: Int,
                _ colorPixelFormat: MTLPixelFormat,
                _ depthPixelFormat: MTLPixelFormat,
                _ stencilPixelFormat: MTLPixelFormat) {
        self.device = device
        self.sampleCount = sampleCount
        self.colorPixelFormat = colorPixelFormat
        self.depthPixelFormat = depthPixelFormat
        self.stencilPixelFormat = stencilPixelFormat
    }
}
