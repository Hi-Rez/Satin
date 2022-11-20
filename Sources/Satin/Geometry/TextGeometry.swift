//
//  TextGeometry.swift
//  Satin
//
//  Created by Reza Ali on 1/10/22.
//

import CoreText
import Foundation
import simd

extension CTTextAlignment: Codable {}

open class TextGeometry: Geometry {
    public enum VerticalAlignment: Int, Codable {
        case top = 0
        case center = 1
        case bottom = 2
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
    
    public var pivot = simd_float2(repeating: 0.0) {
        didSet {
            if pivot != oldValue {
                needsSetup = true
            }
        }
    }
    
    public var textBounds = CGSize(width: -1, height: -1) {
        didSet {
            if textBounds != oldValue {
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
                needsClear = true
                needsSetup = true
            }
        }
    }
    
    public var fontSize: Float = 1 {
        didSet {
            if fontSize != oldValue {
                ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
                needsClear = true
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
        if needsSuggestFrameSizeSetup {
            _suggestFrameSize = getSuggestFrameSize()
            needsSuggestFrameSizeSetup = false
        }
        return _suggestFrameSize
    }
    
    var _suggestFrameSize: CGSize?
    
    var verticalOffset: CGFloat? {
        if needsVerticalOffsetSetup {
            _verticalOffset = getVerticalOffset()
            needsVerticalOffsetSetup = false
        }
        return _verticalOffset
    }
    
    var _verticalOffset: CGFloat?
    
    var framePivot: CGPoint? {
        if needsFramePivotSetup {
            _framePivot = getFramePivot()
            needsFramePivotSetup = false
        }
        return _framePivot
    }
    
    var _framePivot: CGPoint?
    
    var frameSetter: CTFramesetter? {
        if needsFrameSetterSetup {
            _frameSetter = getFrameSetter()
            needsFrameSetterSetup = false
        }
        return _frameSetter
    }

    var _frameSetter: CTFramesetter?
    
    var frame: CTFrame? {
        if needsFrameSetup {
            _frame = getFrame()
            needsFrameSetup = false
        }
        return _frame
    }

    var _frame: CTFrame?
    
    var lines: [CTLine] {
        if needsLinesSetup {
            _lines = getLines()
            needsLinesSetup = false
        }
        return _lines
    }
    
    var _lines: [CTLine] = []
    
    var origins: [CGPoint] {
        if needsOriginsSetup {
            _origins = getOrigins()
            needsOriginsSetup = false
        }
        return _origins
    }
    
    var _origins: [CGPoint] = []
    
    var attributedText: CFAttributedString? {
        if needsTextSetup {
            _attributedText = getAttributedText()
            needsTextSetup = false
        }
        return _attributedText
    }

    var _attributedText: CFAttributedString?
    
    var ctFont: CTFont
    
    var needsVerticalOffsetSetup: Bool = true
    var needsFramePivotSetup: Bool = true
    
    var needsTextSetup: Bool = true {
        didSet {
            if needsTextSetup {
                needsFrameSetterSetup = true
                needsSuggestFrameSizeSetup = true
                needsVerticalOffsetSetup = true
                needsFramePivotSetup = true
            }
        }
    }
    
    var needsSuggestFrameSizeSetup: Bool = true
    
    var needsFrameSetterSetup: Bool = true {
        didSet {
            if needsFrameSetterSetup {
                needsFrameSetup = true
            }
        }
    }
    
    var needsFrameSetup: Bool = true {
        didSet {
            if needsFrameSetup {
                needsLinesSetup = true
            }
        }
    }
    
    var needsLinesSetup: Bool = true {
        didSet {
            if needsLinesSetup {
                needsOriginsSetup = true
            }
        }
    }
    
    var needsOriginsSetup: Bool = true
    
    var needsClear: Bool = false
    
    var needsSetup: Bool = true {
        didSet {
            if needsSetup {
                needsTextSetup = true
            }
        }
    }

    var geometryCache: [Character: GeometryData] = [:]
    var characterPathsCache: [Character: [Polyline2D]] = [:]
    
    public var characterPaths: [Character: [Polyline2D]] = [:]
    public var characterOffsets: [String.Index: simd_float2] = [:]
    
    public init(text: String, fontName: String = "Helvetica", fontSize: Float, bounds: CGSize = .zero, pivot: simd_float2 = .zero, textAlignment: CTTextAlignment = .natural, verticalAlignment: VerticalAlignment = .center, kern: Float = 0.0, lineSpacing: Float = 0.0) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        textBounds = bounds
        self.pivot = pivot
        self.textAlignment = textAlignment
        self.verticalAlignment = verticalAlignment
        self.kern = kern
        self.lineSpacing = lineSpacing
        ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
        super.init()
        update()
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        verticalAlignment = try values.decode(VerticalAlignment.self, forKey: .verticalAlignment)
        textAlignment = try values.decode(CTTextAlignment.self, forKey: .textAlignment)
        text = try values.decode(String.self, forKey: .text)
        pivot = try values.decode(simd_float2.self, forKey: .pivot)
        textBounds = try values.decode(CGSize.self, forKey: .textBounds)
        lineSpacing = try values.decode(Float.self, forKey: .lineSpacing)
        fontName = try values.decode(String.self, forKey: .fontName)
        fontSize = try values.decode(Float.self, forKey: .fontSize)
        ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verticalAlignment, forKey: .verticalAlignment)
        try container.encode(textAlignment, forKey: .textAlignment)
        try container.encode(text, forKey: .text)
        try container.encode(pivot, forKey: .pivot)
        try container.encode(textBounds, forKey: .textBounds)
        try container.encode(kern, forKey: .kern)
        try container.encode(lineSpacing, forKey: .lineSpacing)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(fontSize, forKey: .fontSize)
    }
    
    private enum CodingKeys: String, CodingKey {
        case verticalAlignment
        case textAlignment
        case text
        case pivot
        case textBounds
        case kern
        case lineSpacing
        case fontName
        case fontSize
    }
    
    override public func update() {
        if needsSetup {
            setupData()
            needsSetup = false
        }
        super.update()
    }
    
    var angleLimit: Float = degToRad(7.5)
    
    func setupData() {
        var gData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        
        if needsClear {
            clearCache()
            needsClear = false
        }
        
        var charOffset = 0
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
                    let glyphPosition = glyphPositions[glyphIndex]
                    addGlyphGeometryData(&gData, charOffset, glyph, glyphPosition, origin)
                    charOffset += 1
                }
                glyphPositions.deallocate()
                glyphs.deallocate()
            }
        }
            
        setFrom(&gData)
        freeGeometryData(&gData)
    }
    
    func addGlyphGeometryData(_ gData: inout GeometryData, _ charOffset: Int, _ glyph: CGGlyph, _ glyphPosition: CGPoint, _ origin: CGPoint) {
        guard let framePivot = framePivot, let verticalOffset = verticalOffset else { return }
        
        let charIndex = text.index(text.startIndex, offsetBy: Int(charOffset))
        let char = text[charIndex]
        characterPaths[char] = []
        
        var cData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        
        if let cacheData = geometryCache[char], let charPaths = characterPathsCache[char] {
            cData = cacheData
            characterPaths[char] = charPaths
        } else if let glyphPath = CTFontCreatePathForGlyph(ctFont, glyph, nil) {
            let glyphPaths = getPolylines(glyphPath, angleLimit, fontSize / 10.0)
            
            var _paths: [UnsafeMutablePointer<simd_float2>?] = []
            var _lengths: [Int32] = []
            for i in 0..<glyphPaths.count {
                let path = glyphPaths[i]
                _paths.append(path.data)
                _lengths.append(path.count)
            }
                                     
            if triangulate(&_paths, &_lengths, Int32(_lengths.count), &cData) != 0 {
                print("Triangulation for \(char) FAILED!")
            }
            
            geometryCache[char] = cData
            characterPaths[char] = glyphPaths
            characterPathsCache[char] = glyphPaths
        }
        
        let glyphOffset = simd_make_float2(Float(glyphPosition.x + origin.x - framePivot.x), Float(glyphPosition.y + origin.y - framePivot.y - verticalOffset))
        characterOffsets[charIndex] = glyphOffset
        combineAndOffsetGeometryData(&gData, &cData, simd_make_float3(glyphOffset, 0.0))
    }
    
    func getPolylines(_ glyphPath: CGPath, _ angleLimit: Float, _ distanceLimit: Float) -> [Polyline2D] {
        var glyphPaths = [Polyline2D]()
        var path = Polyline2D(count: 0, capacity: 0, data: nil)
        glyphPath.applyWithBlock { (elementPtr: UnsafePointer<CGPathElement>) in
            let element = elementPtr.pointee
            var pointsPtr = element.points
            let pt = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                
            switch element.type {
            case .moveToPoint:
                addPointToPolyline2D(pt, &path)
            case .addLineToPoint:
                let a = path.data[Int(path.count) - 1]
                var line = getAdaptiveLinearPath2(a, pt, distanceLimit)
                removeFirstPointInPolyline2D(&line)
                appendPolyline2D(&path, &line)
                freePolyline2D(&line)
            case .addQuadCurveToPoint:
                let a = path.data[Int(path.count) - 1]
                let b = pt
                pointsPtr += 1
                let c = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                var curve = getAdaptiveQuadraticBezierPath2(a, b, c, angleLimit)
                removeFirstPointInPolyline2D(&curve)
                appendPolyline2D(&path, &curve)
                freePolyline2D(&curve)
            case .addCurveToPoint:
                let a = path.data[Int(path.count) - 1]
                let b = pt
                pointsPtr += 1
                let c = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                pointsPtr += 1
                let d = simd_make_float2(Float(pointsPtr.pointee.x), Float(pointsPtr.pointee.y))
                var curve = getAdaptiveCubicBezierPath2(a, b, c, d, angleLimit)
                removeFirstPointInPolyline2D(&curve)
                appendPolyline2D(&path, &curve)
                freePolyline2D(&curve)
            case .closeSubpath:
                if isEqual2(path.data[0], path.data[Int(path.count - 1)]) {
                    removeLastPointInPolyline2D(&path)
                }
                let first = path.data[0]
                let last = path.data[Int(path.count) - 1]
                var line = getAdaptiveLinearPath2(last, first, distanceLimit)
                removeLastPointInPolyline2D(&line)
                removeFirstPointInPolyline2D(&line)
                appendPolyline2D(&path, &line)
                freePolyline2D(&line)
                glyphPaths.append(path)
                path = Polyline2D(count: 0, capacity: 0, data: nil)
            default:
                break
            }
        }
        return glyphPaths
    }
    
    func getVerticalOffset() -> CGFloat? {
        guard let suggestFrameSize = suggestFrameSize else { return nil }
        var verticalOffset: CGFloat
        switch verticalAlignment {
        case .top:
            verticalOffset = 0
        case .center:
            verticalOffset = ((textBounds.height <= 0 ? suggestFrameSize.height : textBounds.height) - suggestFrameSize.height) * 0.5
        case .bottom:
            verticalOffset = (textBounds.height <= 0 ? suggestFrameSize.height : textBounds.height) - suggestFrameSize.height
        }
        return verticalOffset
    }
    
    func getFramePivot() -> CGPoint? {
        guard let suggestFrameSize = suggestFrameSize else { return nil }
        let pt = pivot * 0.5 + 0.5
        let px: CGFloat = (textBounds.width <= 0 ? suggestFrameSize.width : textBounds.width) * CGFloat(pt.x)
        let py: CGFloat = (textBounds.height <= 0 ? suggestFrameSize.height : textBounds.height) * CGFloat(pt.y)
        return CGPoint(x: px, y: py)
    }
    
    func getAttributedText() -> CFAttributedString? {
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
    
    func getFrameSetter() -> CTFramesetter? {
        guard let attributedText = attributedText else { return nil }
        return CTFramesetterCreateWithAttributedString(attributedText)
    }
    
    func getSuggestFrameSize() -> CGSize? {
        guard let frameSetter = frameSetter else { return nil }
        var bnds = textBounds
        if bnds.width <= 0 {
            bnds.width = CGFloat.greatestFiniteMagnitude
        }
        if bnds.height <= 0 {
            bnds.height = CGFloat.greatestFiniteMagnitude
        }
        return CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, text.count), nil, bnds, nil)
    }
    
    func getFrame() -> CTFrame? {
        guard let suggestFrameSize = suggestFrameSize, let frameSetter = frameSetter else { return nil }
        
        let framePath = CGMutablePath()
        let constraints = CGRect(x: 0.0, y: 0.0, width: textBounds.width <= 0.0 ? suggestFrameSize.width : textBounds.width, height: textBounds.height <= 0.0 ? suggestFrameSize.height : textBounds.height)
        framePath.addRect(constraints)
        
        return CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, text.count), framePath, nil)
    }
    
    func getLines() -> [CTLine] {
        guard let frame = frame else { return [] }
        return CTFrameGetLines(frame) as! [CTLine]
    }
    
    func getOrigins() -> [CGPoint] {
        guard lines.count > 0, let frame = frame else { return [] }
        var origins: [CGPoint] = Array(repeating: CGPoint(), count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
        return origins
    }
    
    func clearGeometryCache() {
        for var (_, data) in geometryCache {
            freeGeometryData(&data)
        }
        geometryCache = [:]
    }
    
    func clearCharacterPaths() {
        characterPaths = [:]
        for (_, paths) in characterPathsCache {
            for var path in paths {
                freePolyline2D(&path)
            }
        }
        characterPathsCache = [:]
    }
    
    func clearCache() {
        clearGeometryCache()
        clearCharacterPaths()
    }
    
    deinit {
        clearCache()
    }
}
