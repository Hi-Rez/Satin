//
//  TextGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

import CoreText

open class TextGeometry: Geometry {
    public enum VerticalAlignment {
        case top
        case center
        case bottom
    }
    
    public var verticalAlignment: VerticalAlignment = .center {
        didSet {
            if verticalAlignment != oldValue {
                needsSetup = true
            }
        }
    }
    
    public var textAlignment: CTTextAlignment = .natural {
        didSet {
            if textAlignment != oldValue {
                needsSetup = true
            }
        }
    }
    
    public var text: String = "" {
        didSet {
            if text != oldValue {
                needsSetup = true
            }
        }
    }
    
    public var pivot: simd_float2 = simd_float2(repeating: 0.0) {
        didSet {
            if pivot != oldValue {
                needsSetup = true
            }
        }
    }
    
    public var bounds: CGSize = CGSize(width: -1, height: -1) {
        didSet {
            if bounds != oldValue {
                needsSetup = true
            }
        }
    }
    
    public var kern: Float = 0.0 {
        didSet {
            if oldValue != kern {
                needsSetup = true
            }
        }
    }
    
    public var lineSpacing: Float = 0.0 {
        didSet {
            if oldValue != kern {
                needsSetup = true
            }
        }
    }
    
    public var fontName: String = "Helvetica" {
        didSet {
            if fontName != oldValue {
                ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
                clearGeometryCache()
                needsSetup = true
            }
        }
    }
    
    public var fontSize: Float = 1 {
        didSet {
            if fontSize != oldValue {
                ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
                clearGeometryCache()
                needsSetup = true
            }
        }
    }
    
    public var lineHeight: Float {
        ascent + descent + leading
    }
    
    public var ascent: Float {
        Float(CTFontGetAscent(ctFont))
    }
    
    public var descent: Float {
        Float(CTFontGetDescent(ctFont))
    }
    
    public var leading: Float {
        Float(CTFontGetLeading(ctFont))
    }
    
    public var unitsPerEm: Float {
        Float(CTFontGetUnitsPerEm(ctFont))
    }
    
    public var glyphCount: Float {
        Float(CTFontGetGlyphCount(ctFont))
    }
    
    public var underlinePosition: Float {
        Float(CTFontGetUnderlinePosition(ctFont))
    }
    
    public var underlineThickness: Float {
        Float(CTFontGetUnderlineThickness(ctFont))
    }
    
    public var slantAngle: Float {
        Float(CTFontGetSlantAngle(ctFont))
    }
    
    public var capHeight: Float {
        Float(CTFontGetCapHeight(ctFont))
    }
    
    public var xHeight: Float {
        Float(CTFontGetXHeight(ctFont))
    }
    
    public var suggestFrameSize: CGSize? {
        guard let attributedText = attributedText else { return nil }
        var bnds = bounds
        if bnds.width < 0 {
            bnds.width = CGFloat.greatestFiniteMagnitude
        }
        if bnds.height < 0 {
            bnds.height = CGFloat.greatestFiniteMagnitude
        }
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, text.count), nil, bnds, nil)
    }
    
    var attributedText: CFAttributedString? {
        // Text Attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: ctFont,
            .kern: NSNumber(value: kern)
        ]
        
        let attributedText = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0)
        CFAttributedStringReplaceString(attributedText, CFRangeMake(0, 0), text as CFString)
        CFAttributedStringSetAttributes(attributedText, CFRangeMake(0, text.count), attributes as CFDictionary, false)
        
        // Paragraph Attributes
        let alignment = UnsafeMutablePointer<CTTextAlignment>.allocate(capacity: 1)
        alignment.pointee = textAlignment
        
        let lineSpace = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        lineSpace.pointee = lineSpacing
        
        let settings = [
            CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: alignment),
            CTParagraphStyleSetting(spec: .lineSpacingAdjustment, valueSize: MemoryLayout<Float>.size, value: lineSpace)
        ]
        
        let style = CTParagraphStyleCreate(settings, settings.count)
        CFAttributedStringSetAttribute(attributedText, CFRangeMake(0, text.count), kCTParagraphStyleAttributeName, style)
        
        alignment.deallocate()
        lineSpace.deallocate()
        
        return attributedText
    }
    
    var ctFont: CTFont
    var needsSetup: Bool = true
    var geometryCache: [CGGlyph: GeometryData] = [:]
    
    public init(text: String, fontName: String, fontSize: Float, bounds: CGSize = CGSize(width: -1, height: -1), pivot: simd_float2, textAlignment: CTTextAlignment = .natural, verticalAlignment: VerticalAlignment = .center, kern: Float = 0.0, lineSpacing: Float = 0.0) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.bounds = bounds
        self.pivot = pivot
        self.textAlignment = textAlignment
        self.verticalAlignment = verticalAlignment
        self.kern = kern
        self.lineSpacing = lineSpacing
        self.ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
        super.init()
    }
    
    override func update() {
        if needsSetup {
            setupData()
            needsSetup = false
        }
    }
    
    func setupData() {
        let maxStraightDistance = Float(fontSize / 10.0)
        var gData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        if let attributedString = self.attributedText {
            // Calculate Suggested Bounds
            var bnds = bounds
            if bnds.width < 0 {
                bnds.width = CGFloat.greatestFiniteMagnitude
            }
            if bnds.height < 0 {
                bnds.height = CGFloat.greatestFiniteMagnitude
            }
            
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, text.count), nil, bnds, nil)
            
            bnds.width = suggestedSize.width
            bnds.height = suggestedSize.height
            
            let framePath = CGMutablePath()
            let constraints = CGRect(x: 0.0, y: 0.0, width: bounds.width >= 0.0 ? bounds.width : bnds.width, height: bounds.height >= 0.0 ? bounds.height : bnds.height)
            framePath.addRect(constraints)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.count), framePath, nil)
            let lines = CTFrameGetLines(frame) as! [CTLine]
            
            var origins: [CGPoint] = Array(repeating: CGPoint(), count: lines.count)
            CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
            
            let pvt = pivot * 0.5 + 0.5
            let pivotOffsetX: CGFloat = (bounds.width >= 0 ? bounds.width : bnds.width) * CGFloat(pvt.x)
            let pivotOffsetY: CGFloat = (bounds.height >= 0 ? bounds.height : bnds.height) * CGFloat(pvt.y)
            
            var verticalOffset: CGFloat
            switch verticalAlignment {
            case .top:
                verticalOffset = 0
            case .center:
                verticalOffset = ((bounds.height >= 0 ? bounds.height : bnds.height) - suggestedSize.height) * 0.5
            case .bottom:
                verticalOffset = (bounds.height >= 0 ? bounds.height : bnds.height) - suggestedSize.height
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
                        
                        var cData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
                        
                        if let cacheData = geometryCache[glyph] {
                            cData = cacheData
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
                            
                            if triangulate(&paths, &lengths, Int32(lengths.count), &cData) != 0 {
                                let char = text[text.index(text.startIndex, offsetBy: Int(glyphIndex))]
                                print("Triangulation for \(char) FAILED!")
                            }
                            
                            geometryCache[glyph] = cData
                        }
                        
                        let glyphPosition = glyphPositions[glyphIndex]
                        combineAndOffsetGeometryData(&gData, &cData, simd_make_float3(
                            Float(glyphPosition.x + origin.x - pivotOffsetX),
                            Float(glyphPosition.y + origin.y - pivotOffsetY - verticalOffset),
                            0.0
                        ))
                    }
                    
                    glyphPositions.deallocate()
                    glyphs.deallocate()
                }
            }
            
            let vertexCount = Int(gData.vertexCount)
            if vertexCount > 0, let data = gData.vertexData {
                data.withMemoryRebound(to: Vertex.self, capacity: vertexCount) { ptr in
                    vertexData = Array(UnsafeBufferPointer(start: ptr, count: vertexCount))
                }
            }
            
            let indexCount = Int(gData.indexCount) * 3
            if indexCount > 0, let data = gData.indexData {
                data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                    indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
                }
            }
            
            freeGeometryData(&gData)
        }
    }
    
    func clearGeometryCache() {
        for var (_, data) in geometryCache {
            freeGeometryData(&data)
        }
        geometryCache = [:]
    }
    
    deinit {
        clearGeometryCache()
    }
}
