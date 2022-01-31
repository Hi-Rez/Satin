//
//  Context.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class Context {
    public var device: MTLDevice
    public var sampleCount: Int
    public var colorPixelFormat: MTLPixelFormat
    public var depthPixelFormat: MTLPixelFormat
    public var stencilPixelFormat: MTLPixelFormat

    public init(_ device: MTLDevice,
                _ sampleCount: Int,
                _ colorPixelFormat: MTLPixelFormat,
                _ depthPixelFormat: MTLPixelFormat = .invalid,
                _ stencilPixelFormat: MTLPixelFormat = .invalid)
    {
        self.device = device
        self.sampleCount = sampleCount
        self.colorPixelFormat = colorPixelFormat
        self.depthPixelFormat = depthPixelFormat
        self.stencilPixelFormat = stencilPixelFormat
    }
}

extension Context: Equatable {
    public static func == (lhs: Context, rhs: Context) -> Bool {
        return (lhs.device.name == rhs.device.name && lhs.sampleCount == rhs.sampleCount && lhs.colorPixelFormat == rhs.colorPixelFormat && lhs.depthPixelFormat == rhs.depthPixelFormat && lhs.stencilPixelFormat == rhs.stencilPixelFormat)
    }
}
