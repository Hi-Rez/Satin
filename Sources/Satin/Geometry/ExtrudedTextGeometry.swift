//
//  ExtrudedTextGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/19/20.
//

import CoreGraphics
import CoreText
import simd

open class ExtrudedTextGeometry: TextGeometry {
    public var distance: Float {
        didSet {
            if oldValue != distance {
                needsSetup = true
            }
        }
    }
    
    var geometryExtrudeCache: [CGGlyph: GeometryData] = [:]
    var geometryReverseCache: [CGGlyph: GeometryData] = [:]
    
    public init(text: String, fontName: String, fontSize: Float, distance: Float = 1.0, bounds: CGSize = CGSize(width: -1, height: -1), pivot: simd_float2, textAlignment: CTTextAlignment = .natural, verticalAlignment: VerticalAlignment = .center, kern: Float = 0.0, lineSpacing: Float = 0) {
        self.distance = distance
        super.init(text: text, fontName: fontName, fontSize: fontSize, bounds: bounds, pivot: pivot, textAlignment: textAlignment, verticalAlignment: verticalAlignment, kern: kern, lineSpacing: lineSpacing)
    }
    
    override func setupData() {
        let maxStraightDistance = Float(fontSize / 10.0)
        var gData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        if let attributedString = self.attributedText {
            // Calculate Suggested Bounds
            var bnds = textBounds
            if bnds.width <= 0 {
                bnds.width = CGFloat.greatestFiniteMagnitude
            }
            if bnds.height <= 0 {
                bnds.height = CGFloat.greatestFiniteMagnitude
            }
            print(bnds)
            
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, text.count), nil, bnds, nil)
            
            bnds.width = suggestedSize.width
            bnds.height = suggestedSize.height
            
            let framePath = CGMutablePath()
            let constraints = CGRect(x: 0.0, y: 0.0, width: textBounds.width >= 0.0 ? textBounds.width : bnds.width, height: textBounds.height >= 0.0 ? textBounds.height : bnds.height)
            framePath.addRect(constraints)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.count), framePath, nil)
            let lines = CTFrameGetLines(frame) as! [CTLine]
            
            var origins: [CGPoint] = Array(repeating: CGPoint(), count: lines.count)
            CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
            
            let pvt = pivot * 0.5 + 0.5
            let pivotOffsetX: CGFloat = (textBounds.width >= 0 ? textBounds.width : bnds.width) * CGFloat(pvt.x)
            let pivotOffsetY: CGFloat = (textBounds.height >= 0 ? textBounds.height : bnds.height) * CGFloat(pvt.y)
            
            var verticalOffset: CGFloat
            switch verticalAlignment {
            case .top:
                verticalOffset = 0
            case .center:
                verticalOffset = ((textBounds.height >= 0 ? textBounds.height : bnds.height) - suggestedSize.height) * 0.5
            case .bottom:
                verticalOffset = (textBounds.height >= 0 ? textBounds.height : bnds.height) - suggestedSize.height
            }
            
            for (lineIndex, line) in lines.enumerated() {
                let origin = origins[lineIndex]
                let runs: [CTRun] = CTLineGetGlyphRuns(line) as! [CTRun]
                
                for run in runs {
                    let glyphCount = CTRunGetGlyphCount(run)
                    
                    let glyphPositions = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
                    CTRunGetPositions(run, CFRangeMake(0, 0), glyphPositions)
                    
                    let glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphCount)
                    CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs)
                    
                    for glyphIndex in 0..<glyphCount {
                        let glyph = glyphs[glyphIndex]
                        
                        // front face character data
                        var cData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
                        
                        // back face character data
                        var bData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
                        
                        // side faces character data
                        var sData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
                        
                        if let cacheData = geometryCache[glyph], let cacheReverseData = geometryReverseCache[glyph],
                            let cacheExtrudeData = geometryExtrudeCache[glyph] {
                            cData = cacheData
                            bData = cacheReverseData
                            sData = cacheExtrudeData
                        } else {
                            guard let path = CTFontCreatePathForGlyph(ctFont, glyph, nil) else { continue }
                            
                            var allPaths: [[simd_float2]] = []
                            var currentPath: [simd_float2] = []
                            path.applyWithBlock { (elementPtr: UnsafePointer<CGPathElement>) in
                                let element = elementPtr.pointee
                                var pointsPtr = element.points
                                let pt = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                
                                switch element.type {
                                case .moveToPoint:
                                    currentPath.append(pt)
                                case .addLineToPoint:
                                    let a = currentPath[currentPath.count - 1]
                                    adaptiveLinear(a, pt, &currentPath, maxStraightDistance)
                                case .addQuadCurveToPoint:
                                    let a = currentPath[currentPath.count - 1]
                                    let b = pt
                                    pointsPtr += 1
                                    let c = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                    adaptiveQuadratic(a, b, c, &currentPath, 0)
                                    currentPath.append(c)
                                case .addCurveToPoint:
                                    let a = currentPath[currentPath.count - 1]
                                    let b = pt
                                    pointsPtr += 1
                                    let c = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                    pointsPtr += 1
                                    let d = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                    adaptiveCubic(a, b, c, d, &currentPath, 0)
                                    currentPath.append(d)
                                case .closeSubpath:
                                    // remove repeated last point
                                    var a = currentPath[currentPath.count - 1]
                                    let b = currentPath[0]
                                    if isEqual2(a, b) {
                                        currentPath.remove(at: currentPath.count - 1)
                                    }
                                    a = currentPath[currentPath.count - 1]
                                    // sample start and end
                                    adaptiveLinear(a, b, &currentPath, maxStraightDistance, 1, false)
                                    allPaths.append(currentPath)
                                    currentPath = []
                                default:
                                    break
                                }
                            }
                            
                            var paths: [UnsafeMutablePointer<simd_float2>?] = []
                            var lengths: [Int32] = []
                            for i in 0..<allPaths.count {
                                allPaths[i].withUnsafeMutableBufferPointer { ptr in
                                    paths.append(ptr.baseAddress!)
                                }
                                lengths.append(Int32(allPaths[i].count))
                            }
                            
                            let char = text[text.index(text.startIndex, offsetBy: Int(glyphIndex))]
                            
                            let counts = Int32(lengths.count)
                            if triangulate(&paths, &lengths, counts, &cData) != 0 {
                                print("Triangulation for \(char) FAILED!")
                            }
                            geometryCache[glyph] = cData
                            
                            copyGeometryData(&bData, &cData)
                            reverseFacesOfGeometryData(&bData)
                            geometryReverseCache[glyph] = bData
                            
                            if extrudePaths(&paths, &lengths, counts, &sData) != 0 {
                                print("Path Extrusion for \(char) FAILED!")
                            }
                            
                            computeNormalsOfGeometryData(&sData)
                            geometryExtrudeCache[glyph] = sData
                        }
                        
                        let glyphPosition = glyphPositions[glyphIndex]
                        
                        combineAndOffsetGeometryData(&gData, &cData, simd_make_float3(
                            Float(glyphPosition.x + origin.x - pivotOffsetX),
                            Float(glyphPosition.y + origin.y - pivotOffsetY - verticalOffset),
                            distance * 0.5
                        ))
                        
                        combineAndOffsetGeometryData(&gData, &bData, simd_make_float3(
                            Float(glyphPosition.x + origin.x - pivotOffsetX),
                            Float(glyphPosition.y + origin.y - pivotOffsetY - verticalOffset),
                            -distance * 0.5
                        ))
                        
                        combineAndScaleAndOffsetGeometryData(&gData, &sData,
                                                             simd_make_float3(1.0, 1.0, distance * 0.5),
                                                             simd_make_float3(
                                                                 Float(glyphPosition.x + origin.x - pivotOffsetX),
                                                                 Float(glyphPosition.y + origin.y - pivotOffsetY - verticalOffset),
                                                                 0
                                                             ))
                    }
                    
                    glyphPositions.deallocate()
                    glyphs.deallocate()
                }
            }
            
            setFrom(&gData)
            freeGeometryData(&gData)
        }
    }
    
    override func clearGeometryCache() {
        super.clearGeometryCache()
        
        for var (_, data) in geometryReverseCache {
            freeGeometryData(&data)
        }
        geometryReverseCache = [:]
        
        for var (_, data) in geometryExtrudeCache {
            freeGeometryData(&data)
        }
        geometryExtrudeCache = [:]
    }
}
