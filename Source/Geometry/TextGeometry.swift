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
    
    var verticalAlignment: VerticalAlignment = .center {
        didSet {
            if verticalAlignment != oldValue {
                needsLayout = true
            }
        }
    }
    
    var textAlignment: CTTextAlignment = .natural {
        didSet {
            if textAlignment != oldValue {
                needsLayout = true
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
                needsLayout = true
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
    
    public var fontName: String = "Helvetica" {
        didSet {
            if fontName != oldValue {
                ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
                needsSetup = true
            }
        }
    }
    
    public var fontSize: Float = 1 {
        didSet {
            if fontSize != oldValue {
                ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
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
    
    private var attributedText: CFAttributedString? {
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
        let settings = [CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: alignment)]
        let style = CTParagraphStyleCreate(settings, 1)
        CFAttributedStringSetAttribute(attributedText, CFRangeMake(0, text.count), kCTParagraphStyleAttributeName, style)
        alignment.deallocate()
        
        return attributedText
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
    
    private var ctFont: CTFont
    private var needsSetup: Bool = true
    private var needsLayout: Bool = false
    
    private var geometryCache: [String: GeometryData] = [:]
    
    public init(text: String, fontName: String, fontSize: Float, bounds: CGSize = CGSize(width: -1, height: -1), pivot: simd_float2, textAlignment: CTTextAlignment = .natural, verticalAlignment: VerticalAlignment = .center, kern: Float = 0.0) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.bounds = bounds
        self.pivot = pivot
        self.textAlignment = textAlignment
        self.verticalAlignment = verticalAlignment
        self.kern = kern
        self.ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
        super.init()
    }
    
    override func update() {
        if needsSetup {
            setupData()
            needsSetup = false
        }
        if needsLayout {
            setupLayout()
            needsLayout = false
        }
    }
    
    func setupData() {
        var gData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        let maxStraightDistance = Float(fontSize / 10.0)
        
        if let attributedString = self.attributedText {
            var bnds = bounds
            if bnds.width < 0 {
                bnds.width = CGFloat.greatestFiniteMagnitude
            }
            if bnds.height < 0 {
                bnds.height = CGFloat.greatestFiniteMagnitude
            }
            
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, text.count), nil, bnds, nil)
            print("suggestedSize: \(suggestedSize)")
            
            bnds.width = suggestedSize.width
            bnds.height = suggestedSize.height
            
            let framePath = CGMutablePath()
            let constraints = CGRect(x: 0.0, y: 0.0, width: bounds.width >= 0.0 ? bounds.width : bnds.width, height: bounds.height >= 0.0 ? bounds.height : bnds.height)
            framePath.addRect(constraints)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.count), framePath, nil)
            let lines = CTFrameGetLines(frame) as! [CTLine]
            
            var origins: [CGPoint] = Array(repeating: CGPoint(), count: lines.count)
            CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
            
            let lineSpacing: CGFloat = origins.count > 1 ? abs(origins[1].y - origins[0].y) : CGFloat(lineHeight)
            print("Line Spacing: \(lineSpacing)")
            
            let pvt = pivot * 0.5 + 0.5
            let pivotOffsetX: CGFloat = (bounds.width >= 0 ? bounds.width : bnds.width) * CGFloat(pvt.x)
            let pivotOffsetY: CGFloat = (bounds.height >= 0 ? bounds.height : bnds.height) * CGFloat(pvt.y)
            
            for (lineIndex, line) in lines.enumerated() {
                let origin = origins[lineIndex]
                
                let rect = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
                print("Rect: \(rect)")
                print("Origin: \(origin)")
//                print("Line: \(line)")
                
                let imageBounds = CTLineGetImageBounds(line, nil)
                print("ImageBounds: \(imageBounds)")
                
                var ascent: CGFloat = 0
                var decent: CGFloat = 0
                var leading: CGFloat = 0
                let typographicBounds = CTLineGetTypographicBounds(line, &ascent, &decent, &leading)
                print("TypographicBounds: \(typographicBounds)")
                print("ascent: \(ascent)")
                print("decent: \(decent)")
                print("leading: \(leading)")
                
                let whitespaceWidth = CTLineGetTrailingWhitespaceWidth(line)
                print("whitespaceWidth: \(whitespaceWidth)")
                
                let runs: [CTRun] = CTLineGetGlyphRuns(line) as! [CTRun]
                for (runIndex, run) in runs.enumerated() {
                    print("run: \(run), index: \(runIndex)")
                    
                    let glyphCount = CTRunGetGlyphCount(run)
                    print("glyphCount: \(glyphCount)")
                    
                    let glyphPositions = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
                    CTRunGetPositions(run, CFRangeMake(0, 0), glyphPositions)
                    
                    let glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphCount)
                    CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs)
                    
                    for glyphIndex in 0..<glyphCount {
                        print("glyphIndex: \(glyphIndex)")
                        let glyphPosition = glyphPositions[glyphIndex]
                        print("glyphPosition: \(glyphPosition)")
                        
                        var verticalOffset: CGFloat
                        switch verticalAlignment {
                        case .top:
                            verticalOffset = 0
                        case .center:
                            verticalOffset = ((bounds.height >= 0 ? bounds.height : bnds.height) - suggestedSize.height) * 0.5
                        case .bottom:
                            verticalOffset = (bounds.height >= 0 ? bounds.height : bnds.height) - suggestedSize.height
                        }
                        
                        var transform = CGAffineTransform(
                            translationX: glyphPosition.x + origin.x - pivotOffsetX,
                            y: glyphPosition.y + origin.y - pivotOffsetY - verticalOffset
                        )
                        
//                        var transform = CGAffineTransform(
//                            translationX: 0,
//                            y: 0
//                        )
                        print("transform: \(transform)")
                        
                        let glyph = glyphs[glyphIndex]
                        guard let path = CTFontCreatePathForGlyph(ctFont, glyph, &transform) else { continue }
                        
                        var allPaths: [[simd_float2]] = []
                        var currentPath: [simd_float2] = []
                        path.applyWithBlock { (elementPtr: UnsafePointer<CGPathElement>) in
                            let element = elementPtr.pointee
                            var pointsPtr = element.points
                            let pt = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                            
                            switch element.type {
                            case .moveToPoint:
                                print("moveToPoint:\(pt)")
                                currentPath.append(pt)
                                
                            case .addLineToPoint:
                                print("addLineToPoint:\(pt)")
                                let a = currentPath[currentPath.count - 1]
                                adaptiveLinear(a, pt, &currentPath, maxStraightDistance)
                                
                            case .addQuadCurveToPoint:
                                let a = currentPath[currentPath.count - 1]
                                let b = pt
                                pointsPtr += 1
                                let c = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                print("addQuadCurveToPoint: \(a), \(b), \(c)")
                                
                                adaptiveQuadratic(a, b, c, &currentPath, 0)
                                currentPath.append(c)
                                
                            case .addCurveToPoint:
                                let a = currentPath[currentPath.count - 1]
                                let b = pt
                                pointsPtr += 1
                                let c = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                pointsPtr += 1
                                let d = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                                print("addCurveToPoint: \(a), \(b), \(c), \(d)")
                                
                                adaptiveCubic(a, b, c, d, &currentPath, 0)
                                currentPath.append(d)
                                
                            case .closeSubpath:
                                print("closeSubpath")
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
                        if triangulate(&paths, &lengths, Int32(lengths.count), &gData) == 0 {
                            print("Triangulation for \(char) SUCCEEDED!")
                        } else {
                            print("Triangulation for \(char) FAILED!")
                        }
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
            
            freeGeometryData(gData)
        }
    }
    
    func setupLayout() {
        print("layout geometry here")
    }
}
