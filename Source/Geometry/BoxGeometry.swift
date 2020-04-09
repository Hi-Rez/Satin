//
//  BoxGeometry.swift
//  Satin
//
//  Created by Reza Ali on 8/28/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class BoxGeometry: Geometry {
    public override init() {
        super.init()
        self.setup(width: 2, height: 2, depth: 2, resX: 1, resY: 1, resZ: 1)
    }

    public convenience init(size: Float) {
        self.init(size: (size, size, size))
    }

    public convenience init(size: Float, res: Int) {
        self.init(size: (size, size, size), res: res)
    }

    public convenience init(size: (width: Float, height: Float, depth: Float)) {
        self.init(size: size, res: 1)
    }

    public convenience init(size: (width: Float, height: Float, depth: Float), res: Int) {
        self.init(size: size, res: (res, res, res))
    }


    public init(size: (width: Float, height: Float, depth: Float), res: (x: Int, y: Int, z: Int)) {
        super.init()
        self.setup(width: size.width, height: size.height, depth: size.depth, resX: res.x, resY: res.y, resZ: res.z)
    }

    func setup(width: Float, height: Float, depth: Float, resX: Int, resY: Int, resZ: Int) {
        let rx = max(resX, 1)
        let ry = max(resY, 1)
        let rz = max(resZ, 1)

        let bx = Float(rx)
        let by = Float(ry)
        let bz = Float(rz)

        let hw = width * 0.5
        let hh = height * 0.5
        let hd = depth * 0.5

        let dx = width / bx
        let dy = height / by
        let dz = depth / bz
        
        //XYZ+ Front Face
        var indexOffset = 0
        for y in 0...ry {
            for x in 0...rx {
                let fx = Float(x)
                let fy = Float(y)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(-hw + fx * dx, -hh + fy * dy, hd, 1.0),
                        SIMD2<Float>(fx / bx, fy / by),
                        SIMD3<Float>(0.0, 0.0, 1.0)
                    )
                )

                let perRow = rx + 1
                let index = x + y * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1

                if x != rx, y != ry {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(tl))
                }
            }
        }
        
        indexOffset = vertexData.count
        //XYZ- Back Face
        for y in 0...ry {
            for x in 0...rx {
                let fx = Float(x)
                let fy = Float(y)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(hw - fx * dx, -hh + fy * dy, -hd, 1.0),
                        SIMD2<Float>(fx / bx, fy / by),
                        SIMD3<Float>(0.0, 0.0, -1.0)
                    )
                )
                
                let perRow = rx + 1
                let index = indexOffset + x + y * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1

                if x != rx, y != ry {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                                        
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(tl))
                }
            }
        }
        
        indexOffset = vertexData.count
        //XY+Z Top Face
        for z in 0...rz {
            for x in 0...rx {
                let fx = Float(x)
                let fz = Float(z)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(-hw + fx * dx, hh, hd - fz * dz, 1.0),
                        SIMD2<Float>(fx / bx, fz / bz),
                        SIMD3<Float>(0.0, 1.0, 0.0)
                    )
                )

                let perRow = rx + 1
                let index = indexOffset + x + z * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1

                if x != rx, z != rz {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(tl))
                }
            }
        }

        indexOffset = vertexData.count
        //XY-Z Bottom Face
        for z in 0...rz {
            for x in 0...rx {
                let fx = Float(x)
                let fz = Float(z)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(-hw + fx * dx, -hh, -hd + fz * dz, 1.0),
                        SIMD2<Float>(fx / bx, fz / bz),
                        SIMD3<Float>(0.0, -1.0, 0.0)
                    )
                )

                let perRow = rx + 1
                let index = indexOffset + x + z * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1

                if x != rx, z != rz {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(tl))
                }
            }
        }

        indexOffset = vertexData.count
        //X+YZ Right Face
        for z in 0...rz {
            for y in 0...ry {
                let fy = Float(y)
                let fz = Float(z)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(hw, -hh + fy * dy, hd - fz * dz, 1.0),
                        SIMD2<Float>(fz / bz, fy / by),
                        SIMD3<Float>(1.0, 0.0, 0.0)
                    )
                )

                let perRow = ry + 1
                let index = indexOffset + y + z * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1

                if y != ry, z != rz {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(tr))
                }
            }
        }

        indexOffset = vertexData.count
        //X+YZ Left Face
        for z in 0...rz {
            for y in 0...ry {
                let fy = Float(y)
                let fz = Float(z)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(-hw, -hh + fy * dy, -hd + fz * dz, 1.0),
                        SIMD2<Float>(fz / bz, fy / by),
                        SIMD3<Float>(-1.0, 0.0, 0.0)
                    )
                )

                let perRow = ry + 1
                let index = indexOffset + y + z * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1

                if y != ry, z != rz {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(tr))
                }
            }
        }
    }
}
