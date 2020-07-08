//
//  TextGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

import CoreText

open class TextGeometry: Geometry {
    public override init() {
        super.init()
        self.setupData()
    }
    
    func setupData() {
//        guard let nsfont = NSFont(name: "Times", size: 32) else { return }
//        guard let nsfont = NSFont(name: "AvenirNext-UltraLight", size: 32) else { return }
//        guard let nsfont = NSFont(name: "Helvetica", size: 32) else { return }
//        guard let nsfont = NSFont(name: "SFMono-HeavyItalic", size: 32) else { return }
        guard let nsfont = NSFont(name: "SFProRounded-Thin", size: 32) else { return }
//        guard let nsfont = NSFont(name: "SFProRounded-Bold", size: 32) else { return }
        let fontName = nsfont.fontName as CFString
        let font = CTFontCreateWithName(fontName, nsfont.pointSize, nil)
        let maxStraightDistance = Float(nsfont.pointSize / 10.0)
        
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
//        let input = "0123456789"
//        let input = "abcdefghijklmnopqrstuvwxyz"
//        let input = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        let input = "%"
//          let input = "abcdefg"
//        let input = "aebd"
        
        if let attributedString = CFAttributedStringCreate(nil, input as CFString, attributes as CFDictionary) {
            print("attributedString: \(attributedString)")
            
            let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
            print("typesetter: \(typesetter)")
            
            let line = CTTypesetterCreateLine(typesetter, CFRangeMake(0, 0))
//            print("line: \(line)")
            
            let runs: [CTRun] = CTLineGetGlyphRuns(line) as! [CTRun]
//            print("runs: \(runs)")
                        
            
            let run = runs[0]
            
            let glyphCount = CTRunGetGlyphCount(run)
//            print("glyphCount: \(glyphCount)")
            
            
            
            let glyphPositions = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
            CTRunGetPositions(run, CFRangeMake(0, 0), glyphPositions)
                        
            
            let glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphCount)
            CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs)
            
            var gData = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
            
            for index in 0..<glyphCount {
//                print("glyphIndex: \(index)")
                
                let glyphPosition = glyphPositions[index]
//                print("glyphPosition: \(glyphPosition)")
                
                var transform = CGAffineTransform(translationX: glyphPosition.x, y: glyphPosition.y)
//                print("transform: \(transform)")
                
                let glyph = glyphs[index]
                guard let path = CTFontCreatePathForGlyph(font, glyph, &transform) else { continue }
                
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
                
                let char = input[input.index(input.startIndex, offsetBy: Int(index))]
                var paths: [UnsafeMutablePointer<simd_float2>?] = []
                var lengths: [Int32] = []
                for i in 0..<allPaths.count {
                    
                    print("\(char) path \(i) has \(allPaths[i].count) pts");
                    for pt in allPaths[i] {
                        print("(\(pt.x), \(pt.y))")
                    }
                    print()
                    // this piece of code below is super important, don't cache the path, use the index look up to ensure order when sent to C
                    allPaths[i].withUnsafeMutableBufferPointer { ptr in
                        paths.append(ptr.baseAddress!)
                    }
                    lengths.append(Int32(allPaths[i].count))
                }
                
                let result = triangulate(&paths, &lengths, Int32(lengths.count), &gData)
                if(result == 0) {
                    print("Triangulation for \(char) SUCCEEDED!")
                }
                else {
                    print("Triangulation for \(char) FAILED!")
                }
            }
            
            let geo = Geometry()
            geo.primitiveType = .triangle
            
            let vertexCount = Int(gData.vertexCount)
            if vertexCount > 0, let data = gData.vertexData {
                data.withMemoryRebound(to: Vertex.self, capacity: vertexCount) { ptr in
                    vertexData = Array(UnsafeBufferPointer(start: ptr, count: vertexCount))
                }
            }
                        
            print("\(input) path final has \(vertexData.count) pts");
            for vertex in vertexData {
                print("(\(vertex.position.x), \(vertex.position.y))")
            }
            
            
            let indexCount = Int(gData.indexCount) * 3
            if indexCount > 0, let data = gData.indexData {
                data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                    indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
                }
            }
            
            freeGeometryData(gData)
            
            glyphPositions.deallocate()
            glyphs.deallocate()
        }
    }
}
