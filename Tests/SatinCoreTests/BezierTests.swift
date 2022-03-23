//
//  BezierTests.swift
//  
//
//  Created by Taylor Holliday on 3/23/22.
//

import XCTest
import SatinCore
import simd

class BezierTests: XCTestCase {

    func testAdaptiveQuadraticBezierPath2Perf() {
        self.measure {
            for _ in 0..<100 {
                var polyline = getAdaptiveQuadraticBezierPath2(.init(0, 0), .init(1,0), .init(0,1), 0.001)
                XCTAssertEqual(polyline.count, 513)
                freePolyline2D(&polyline)
            }
        }
    }

    func _adaptiveQuadBezierCurve2(_ a: SIMD2<Float>,
                                   _ b: SIMD2<Float>,
                                   _ c: SIMD2<Float>,
                                   _ aVel: SIMD2<Float>,
                                   _ bVel: SIMD2<Float>,
                                   _ cVel: SIMD2<Float>,
                                   _ angleLimit: Float,
                                   _ depth: Int,
                                   _ pts: inout [SIMD2<Float>]) {

        if depth > 8 { return }

        let startMiddleAngle = acos(simd_dot(aVel, bVel))
        let middleEndAngle = acos(simd_dot(bVel, cVel))

        if (startMiddleAngle + middleEndAngle) > angleLimit {
            // Split curve into two curves (start, end)

            let ab = (a + b) * 0.5;
            let bc = (b + c) * 0.5;
            let abc = (ab + bc) * 0.5;

            // Start Curve:  a,      ab,     abc
            // End Curve:    abc,    bc,     c

            let sVel = simd_normalize(quadraticBezierVelocity2(a, ab, abc, 0.5))

            _adaptiveQuadBezierCurve2(a, ab, abc, aVel, sVel, bVel, angleLimit,
                                                           depth + 1, &pts)
            pts.append(abc)

            let eVel = simd_normalize(quadraticBezierVelocity2(abc, bc, c, 0.5));
            _adaptiveQuadBezierCurve2(abc, bc, c, bVel, eVel, cVel, angleLimit, depth + 1, &pts)
        }

    }

    func getAdaptiveQuadBezierPath2(_ a: SIMD2<Float>,
                                    _ b: SIMD2<Float>,
                                    _ c: SIMD2<Float>,
                                    _ angleLimit: Float) -> [SIMD2<Float>] {
        let aVel = simd_normalize(quadraticBezierVelocity2(a, b, c, 0.0));
        let bVel = simd_normalize(quadraticBezierVelocity2(a, b, c, 0.5));
        let cVel = simd_normalize(quadraticBezierVelocity2(a, b, c, 1.0));

        var pts: [SIMD2<Float>] = []
        pts.reserveCapacity(513)
        pts.append(a)

        _adaptiveQuadBezierCurve2(a, b, c, aVel, bVel, cVel, angleLimit, 0, &pts);

        pts.append(c)

        return pts
    }

    func testAdaptiveQuadBezierPath2Perf() {
        self.measure {
            for _ in 0..<100 {
                let polyline = getAdaptiveQuadBezierPath2(.init(0, 0), .init(1,0), .init(0,1), 0.001)
                XCTAssertEqual(polyline.count, 513)
            }
        }
    }

}
