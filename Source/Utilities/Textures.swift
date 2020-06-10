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
    
    let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: context.colorPixelFormat, size: cubeSize, mipmapped: mipmapped)
    guard let cubeTexture = context.device.makeTexture(descriptor: desc) else { return nil }
    let mipCount = mipmapped ? cubeTexture.mipmapLevelCount : 1
    
    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    var mipSize = cubeSize
    for i in 0..<mipCount {
        let bytesPerRow = bytesPerPixel * mipSize
        let bytesPerImage = bytesPerRow * mipSize
        
        guard let cgContext = CGContext(data: nil,
                                        width: mipSize,
                                        height: mipSize,
                                        bitsPerComponent: 8,
                                        bytesPerRow: mipSize * bytesPerPixel,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo) else { return nil }
        
        let drawRect = CGRect(x: 0, y: 0, width: mipSize, height: mipSize)
        cgContext.draw(cgImage, in: drawRect)
        
        let region = MTLRegionMake2D(0, 0, mipSize, mipSize)
        cubeTexture.replace(region: region, mipmapLevel: i, slice: 0, withBytes: cgContext.data!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
        
        mipSize /= 2
    }
    
    for slice in 1..<6 {
        guard let cgImage = loadImage(url: urls[slice]) else { return nil }
        
        var mipSize = cubeSize
        for i in 0..<mipCount {
            let bytesPerRow = bytesPerPixel * mipSize
            let bytesPerImage = bytesPerRow * mipSize
            
            guard let cgContext = CGContext(data: nil,
                                            width: mipSize,
                                            height: mipSize,
                                            bitsPerComponent: 8,
                                            bytesPerRow: mipSize * bytesPerPixel,
                                            space: colorSpace,
                                            bitmapInfo: bitmapInfo) else { return nil }
            
            let drawRect = CGRect(x: 0, y: 0, width: mipSize, height: mipSize)
            cgContext.draw(cgImage, in: drawRect)
            
            let region = MTLRegionMake2D(0, 0, mipSize, mipSize)
            cgContext.draw(cgImage, in: drawRect)
            cubeTexture.replace(region: region, mipmapLevel: i, slice: slice, withBytes: cgContext.data!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
            
            mipSize /= 2
        }
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
