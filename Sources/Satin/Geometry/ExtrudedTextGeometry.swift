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
    
    var geometryExtrudeCache: [Character: GeometryData] = [:]
    var geometryReverseCache: [Character: GeometryData] = [:]
    
    public init(text: String, fontName: String = "Helvetica", fontSize: Float, distance: Float = 1.0, bounds: CGSize = .zero, pivot: simd_float2 = .zero, textAlignment: CTTextAlignment = .natural, verticalAlignment: VerticalAlignment = .center, kern: Float = 0.0, lineSpacing: Float = 0) {
        self.distance = distance
        super.init(text: text, fontName: fontName, fontSize: fontSize, bounds: bounds, pivot: pivot, textAlignment: textAlignment, verticalAlignment: verticalAlignment, kern: kern, lineSpacing: lineSpacing)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        distance = try values.decode(Float.self, forKey: .distance)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(distance, forKey: .distance)
    }
    
    private enum CodingKeys: String, CodingKey {
        case distance
    }
    
    override func addGlyphGeometryData(_ gData: inout GeometryData, _ charOffset: Int, _ glyph: CGGlyph, _ glyphPosition: CGPoint, _ origin: CGPoint) {
        guard let framePivot = framePivot, let verticalOffset = verticalOffset else { return }
        
        let charIndex = text.index(text.startIndex, offsetBy: Int(charOffset))
        let char = text[charIndex]
        characterPaths[char] = []
        
        // front face character data
        var cData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        // back face character data
        var bData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        // side faces character data
        var sData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        
        if let cacheData = geometryCache[char], let cacheReverseData = geometryReverseCache[char],
           let cacheExtrudeData = geometryExtrudeCache[char], let charPaths = characterPathsCache[char]
        {
            cData = cacheData
            bData = cacheReverseData
            sData = cacheExtrudeData
            characterPaths[char] = charPaths
        } else if let glyphPath = CTFontCreatePathForGlyph(ctFont, glyph, nil) {
            let glyphPaths = getPolylines(glyphPath, angleLimit, fontSize / 10.0)
            
            var _paths: [UnsafeMutablePointer<simd_float2>?] = []
            var _lengths: [Int32] = []
            for i in 0 ..< glyphPaths.count {
                let path = glyphPaths[i]
                _paths.append(path.data)
                _lengths.append(path.count)
            }
                                                 
            if triangulate(&_paths, &_lengths, Int32(glyphPaths.count), &cData) != 0 {
                print("Triangulation for \(char) FAILED!")
            }
                
            copyGeometryData(&bData, &cData)
            reverseFacesOfGeometryData(&bData)
            geometryReverseCache[char] = bData
            
            if extrudePaths(&_paths, &_lengths, Int32(glyphPaths.count), &sData) != 0 {
                print("Path Extrusion for \(char) FAILED!")
            }
                
            computeNormalsOfGeometryData(&sData)
            
            geometryCache[char] = cData
            geometryExtrudeCache[char] = sData
            characterPaths[char] = glyphPaths
            characterPathsCache[char] = glyphPaths
        }
        
        let glyphOffset = simd_make_float2(Float(glyphPosition.x + origin.x - framePivot.x), Float(glyphPosition.y + origin.y - framePivot.y - verticalOffset))
        characterOffsets[charIndex] = glyphOffset

        combineAndOffsetGeometryData(&gData, &cData, simd_make_float3(glyphOffset, distance * 0.5))
        combineAndOffsetGeometryData(&gData, &bData, simd_make_float3(glyphOffset, -distance * 0.5))
        combineAndScaleAndOffsetGeometryData(&gData, &sData, simd_make_float3(1.0, 1.0, distance * 0.5), simd_make_float3(glyphOffset, 0.0))
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
