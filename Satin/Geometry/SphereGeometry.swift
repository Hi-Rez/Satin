//
//  SphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/1/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class SphereGeometry: Geometry {
    public override init() {
        super.init()
        self.setup(radius: 1, res:(phi: 60, theta: 60))
    }
    
    public convenience init(radius: Float) {
        self.init(radius:radius, res:(60,60))
    }
    
    public convenience init(radius: Float, res:Int) {
        self.init(radius: radius, res:(res, res))
    }
        
    public init(radius: Float, res: (phi: Int, theta: Int)) {
        super.init()
        self.setup(radius: radius, res: res)
    }
    
    func setup(radius: Float, res:(phi: Int, theta: Int)) {
        
    }
}
