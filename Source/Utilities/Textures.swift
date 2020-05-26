//
//  Textures.swift
//  Satin
//
//  Created by Reza Ali on 4/16/20.
//

import Metal
import MetalKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public func makeCubeTexture(_ context: Context, _ urls: [URL], _ mipmapped: Bool = true) -> MTLTexture? {
    assert(urls.count == 6, "Please provide 6 images to create a cube texture")
    
    guard let cgImage = loadImage(url: urls.first!) else { fatalError("Failed to create cgImage") }

    let width = cgImage.width
    let height = cgImage.height

    assert(width == height, "Cube images must have the same width & height")    

    let cubeSize = width
    let bytesPerPixel = cgImage.bitsPerPixel / 8
    let bytesPerRow = bytesPerPixel * cubeSize
    let bytesPerImage = bytesPerRow * cubeSize
    
    let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: context.colorPixelFormat, size: cubeSize, mipmapped: mipmapped)
    guard let cubeTexture = context.device.makeTexture(descriptor: desc) else { return nil }

    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue
    guard let cgContext = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: width * bytesPerPixel,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: bitmapInfo) else { return nil }
    let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
    cgContext.draw(cgImage, in: drawRect)
    
    let region = MTLRegionMake2D(0, 0, cubeSize, cubeSize)
    cubeTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: cgContext.data!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)

    for slice in 1..<6 {
        guard let cgImage = loadImage(url: urls[slice]) else { return nil }
        cgContext.draw(cgImage, in: drawRect)
        cubeTexture.replace(region: region, mipmapLevel: 0, slice: slice, withBytes: cgContext.data!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
    }

    return cubeTexture
}

public func loadImage(url: URL) -> CGImage? {
    #if os(macOS)
    guard let nsImage = NSImage(contentsOf: url), let tiffData = nsImage.tiffRepresentation else {
        fatalError("Failed to create NSImage from: \(url.path)")
    }
    guard let cgImageSource = CGImageSourceCreateWithData(tiffData as CFData, nil) else {
        fatalError("Failed to create CGImageSource")
    }
    guard let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) else {
        fatalError("Failed to create CGImage")
    }
    return cgImage
    #else
    let path = url.path
    guard let uiImage = UIImage(contentsOfFile: path) else {
        fatalError("Failed to create UIImage from: \(path)")
    }
    return uiImage.cgImage
    #endif
}
