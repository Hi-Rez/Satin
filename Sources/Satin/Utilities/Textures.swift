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

import Accelerate
import CoreGraphics
import ImageIO

public func makeCubeTexture(_ device: MTLDevice, _ urls: [URL], _ mipmapped: Bool = true, _ pixelFormat: MTLPixelFormat = .rgba8Unorm) -> MTLTexture? {
    assert(urls.count == 6, "Please provide 6 images to create a cube texture")
    
    guard let cgImage = loadImage(url: urls.first!) else { fatalError("Failed to create cgImage") }
    
    let width = cgImage.width
    let height = cgImage.height
    
    assert(width == height, "Cube images must have the same width & height")
    
    let cubeSize = width
    let bytesPerPixel = cgImage.bitsPerPixel / 8
    
    let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: pixelFormat, size: cubeSize, mipmapped: mipmapped)
    guard let cubeTexture = device.makeTexture(descriptor: desc) else { return nil }
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

public func loadHDR(_ device: MTLDevice, _ url: URL) -> MTLTexture? {
    let cfURLString = url.path as CFString
    guard let cfURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfURLString, CFURLPathStyle.cfurlposixPathStyle, false) else {
        fatalError("Failed to create CFURL from: \(url.path)")
    }
    guard let cgImageSource = CGImageSourceCreateWithURL(cfURL, nil) else {
        fatalError("Failed to create CGImageSource")
    }
    guard let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) else {
        fatalError("Failed to create CGImage")
    }
    
//    print(cgImage.width)
//    print(cgImage.height)
//    print(cgImage.bitsPerComponent)
//    print(cgImage.bytesPerRow)
//    print(cgImage.byteOrderInfo)
    
    guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else { return nil }
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue | CGImageByteOrderInfo.order16Little.rawValue
    guard let bitmapContext = CGContext(data: nil,
                                        width: cgImage.width,
                                        height: cgImage.height,
                                        bitsPerComponent: cgImage.bitsPerComponent,
                                        bytesPerRow: cgImage.width * 2 * 4,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo) else { return nil }
    
    bitmapContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    
    let descriptor = MTLTextureDescriptor()
    descriptor.pixelFormat = .rgba16Float
    descriptor.width = cgImage.width
    descriptor.height = cgImage.height
    descriptor.depth = 1
    descriptor.usage = .shaderRead
    #if os(macOS)
        descriptor.resourceOptions = .storageModeManaged
    #elseif os(iOS) || os(tvOS)
        descriptor.resourceOptions = .storageModeShared
    #endif
    descriptor.sampleCount = 1
    descriptor.textureType = .type2D
    
    guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
    texture.replace(region: MTLRegionMake2D(0, 0, cgImage.width, cgImage.height), mipmapLevel: 0, withBytes: bitmapContext.data!, bytesPerRow: cgImage.width * 2 * 4)
    
    return texture
}
