//
//  BezierTests.swift
//  
//
//  Created by Taylor Holliday on 3/23/22.
//

import XCTest
import SatinCore

class BezierTests: XCTestCase {

    func testAdaptiveQuadraticBezierPath2Perf() {
        self.measure {
            var polyline = getAdaptiveQuadraticBezierPath2(.init(0, 0), .init(1,0), .init(0,1), 0.001)
            XCTAssertEqual(polyline.count, 513)
            freePolyline2D(&polyline)
        }
    }

}
