//
//  Math.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

// MARK: - Degrees To Radians (Double)

public func degToRad(_ degrees: Double) -> Double {
    return degrees * Double.pi / 180.0
}

// MARK: - Degrees To Radians (Float)

public func degToRad(_ degrees: Float) -> Float {
    return degrees * Float.pi / 180.0
}

// MARK: - Radians To Degrees (Double)

public func radToDeg(_ radians: Double) -> Double {
    return radians * 180.0 / Double.pi
}

// MARK: - Radians To Degrees (Float)

public func radToDeg(_ radians: Float) -> Float {
    return radians * 180.0 / Float.pi
}

// MARK: - Translate (Double)

public func translate(_ x: Double, _ y: Double, _ z: Double) -> matrix_double4x4 {
    var result = matrix_identity_double4x4
    result[3].x = x
    result[3].y = y
    result[3].z = z
    return result
}

public func translate(_ v: simd_double3) -> matrix_double4x4 {
    var result = matrix_identity_double4x4
    result[3].x = v.x
    result[3].y = v.y
    result[3].z = v.z
    return result
}

// MARK: - Translate (Float)

public func translate(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
    var result = matrix_identity_float4x4
    result[3].x = x
    result[3].y = y
    result[3].z = z
    return result
}

public func translate(_ v: simd_float3) -> matrix_float4x4 {
    var result = matrix_identity_float4x4
    result[3].x = v.x
    result[3].y = v.y
    result[3].z = v.z
    return result
}

// MARK: - Scale (Double)

public func scale(_ x: Double, _ y: Double, _ z: Double) -> matrix_double4x4 {
    var result = matrix_identity_double4x4
    result[0].x = x
    result[1].y = y
    result[2].z = z
    return result
}

public func scale(_ v: simd_double3) -> matrix_double4x4 {
    var result = matrix_identity_double4x4
    result[0].x = v.x
    result[1].y = v.y
    result[2].z = v.z
    return result
}

// MARK: - Scale (Float)

public func scale(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
    var result = matrix_identity_float4x4
    result[0].x = x
    result[1].y = y
    result[2].z = z
    return result
}

public func scale(_ v: simd_float3) -> matrix_float4x4 {
    var result = matrix_identity_float4x4
    result[0].x = v.x
    result[1].y = v.y
    result[2].z = v.z
    return result
}

// MARK: - Frustum (Float)

public func frustum(_ horizontalFov: Float, _ verticalFov: Float, _ near: Float, _ far: Float) -> matrix_float4x4 {
    let width = 1.0 / tan(degToRad(0.5 * horizontalFov))
    let height = 1.0 / tan(degToRad(0.5 * verticalFov))
    let depth = far / (far - near)

    var result = matrix_identity_float4x4

    result[0].x = width
    result[1].y = height
    result[3].z = depth
    result[4].z = -depth * near

    return result
}

public func frustum(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) -> matrix_float4x4 {
    let width = right - left
    let height = top - bottom
    let depth = far / (far - near)

    var result = matrix_identity_float4x4

    result[0].x = width
    result[1].y = height
    result[3].z = depth
    result[4].z = -depth * near

    return result
}

// MARK: - LookAt (Float)

public func lookAt(_ eye: simd_float3, _ center: simd_float3, _ up: simd_float3) -> matrix_float4x4 {
    let zAxis = simd_normalize(center - eye)
    let xAxis = -simd_normalize(simd_cross(up, zAxis))
    let yAxis = -simd_cross(zAxis, xAxis)

    var result = matrix_identity_float4x4

    result[0].x = xAxis.x
    result[0].y = yAxis.x
    result[0].z = zAxis.x

    result[1].x = xAxis.y
    result[1].y = yAxis.y
    result[1].z = zAxis.y

    result[2].x = xAxis.z
    result[2].y = yAxis.z
    result[2].z = zAxis.z

    result[3].x = -simd_dot(xAxis, eye)
    result[3].y = -simd_dot(yAxis, eye)
    result[3].z = -simd_dot(zAxis, eye)

    return result
}

// MARK: - Perspective (Float)

public func perspective(width: Float, height: Float, near: Float, far: Float) -> matrix_float4x4 {
    let zNear = 2.0 * near
    let zFar = far / (far - near)

    var result = matrix_identity_float4x4

    result[0].x = zNear / width
    result[1].y = zNear / height
    result[2].z = zFar
    result[2].w = 1.0
    result[3].z = -near * zFar
    result[3].w = 0.0

    return result
}

public func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
    let angle = degToRad(0.5 * fov)

    let sy = 1.0 / tanf(angle)
    let sx = sy / aspect
    let rz = far - near
    let sz = -(far + near) / rz
    let sw = -2.0 * far * near / rz

    let P = simd_make_float4(sx, 0.0, 0.0, 0.0)
    let Q = simd_make_float4(0.0, sy, 0.0, 0.0)
    let R = simd_make_float4(0.0, 0.0, sz, -1.0)
    let S = simd_make_float4(0.0, 0.0, sw, 0.0)

    return matrix_float4x4(columns: (P, Q, R, S))
}

// MARK: - Orthographic (Float)

public func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> matrix_float4x4 {
    var result = matrix_identity_float4x4

    result[0].x = 2.0 / (right - left)
    result[1].y = 2.0 / (top - bottom)
    result[2].z = -1.0 / (far - near)

    result[3].x = (left + right) / (left - right)
    result[3].y = (top + bottom) / (bottom - top)
    result[3].z = near / (near - far)

    return result
}

// MARK: - Sample Cubic Bezier

// public func adaptiveCubic(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2, _ d: simd_float2, _ pts: inout [simd_float2], _ level: Int, _ maxLevel: Int = 16)
// {
//    if level > maxLevel
//    {
//        return
//    }
//
//    let ab = (a + b) * 0.5
//    let bc = (b + c) * 0.5
//    let cd = (c + d) * 0.5
//    let abc = (ab + bc) * 0.5
//    let bcd = (bc + cd) * 0.5
//    let abcd = (abc + bcd) * 0.5
//
//    if level > 0 {
//        let adDist = length(d - a)
//        let bDist = pointLineDistance2(a, d, b)
//        let cDist = pointLineDistance2(a, d, c)
//        let m_distance_tolerance: Float = 0.01
//        if (cDist + bDist) < m_distance_tolerance * adDist
//        {
//            pts.append(abcd)
//            return
//        }
//    }
//
//    adaptiveCubic(a, ab, abc, abcd, &pts, level + 1)
//    adaptiveCubic(abcd, bcd, cd, d, &pts, level + 1)
// }

public func quadraticAngle(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2) -> Float {
    let ab = b - a
    let bc = c - b

    let phiAB = atan2(ab.y, ab.x)
    let phiBC = atan2(bc.y, bc.x)

    return abs(phiAB - phiBC)
}

public func cubicAngle(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2, _ d: simd_float2) -> Float {
    let ab = b - a
    let bc = c - b
    let cd = d - c

    let phiAB = atan2(ab.y, ab.x)
    let phiBC = atan2(bc.y, bc.x)
    let phiCD = atan2(cd.y, cd.x)

    let thetaA = phiAB - phiBC
    let thetaB = phiBC - phiCD

    return abs(thetaA) + abs(thetaB)
}

// MARK: - Sample Quadratic Bezier

// based on http://antigrain.com/research/adaptive_bezier/
// based on https://github.com/mattdesl/adaptive-bezier-curve
public func adaptiveCubic(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2, _ d: simd_float2, _ pts: inout [simd_float2], _ level: Int, _ distanceTolerance: Float = 0.0125, _ angleTolerance: Float = 0.1, _ cuspLimit: Float = 0.235, _ maxLevel: Int = 16) {
    if level > maxLevel {
        return
    }

    let ab = (a + b) * 0.5
    let bc = (b + c) * 0.5
    let cd = (c + d) * 0.5
    let abc = (ab + bc) * 0.5
    let bcd = (bc + cd) * 0.5
    let abcd = (abc + bcd) * 0.5

    if level > 0 {
        let adDist = length(d - a)
        let bDist = pointLineDistance2(a, d, b)
        let cDist = pointLineDistance2(a, d, c)
        let da1 = quadraticAngle(a, b, c)
        let da2 = quadraticAngle(b, c, d)
        let _distanceTolerance = distanceTolerance * adDist

        if bDist > .ulpOfOne, cDist > .ulpOfOne {
            if (cDist + bDist) < _distanceTolerance {
                if (da1 + da2) < angleTolerance {
                    pts.append(abcd)
                    return
                }
                if cuspLimit != 0.0 {
                    if da1 > cuspLimit {
                        pts.append(b)
                        return
                    }
                    if da2 > cuspLimit {
                        pts.append(c)
                        return
                    }
                }
            }
        }
        else {
            if bDist > .ulpOfOne {
                if bDist <= _distanceTolerance {
                    if da1 < angleTolerance {
                        pts.append(b)
                        pts.append(c)
                        return
                    }
                    if cuspLimit != 0.0 {
                        if da1 > cuspLimit {
                            pts.append(b)
                            return
                        }
                    }
                }
            }
            else if cDist > .ulpOfOne {
                if cDist <= _distanceTolerance {
                    if da2 < angleTolerance {
                        pts.append(b)
                        pts.append(c)
                        return
                    }
                    if cuspLimit != 0.0 {
                        if da2 > cuspLimit {
                            pts.append(c)
                            return
                        }
                    }
                }
            }
            else {
                let mc = abcd - (a + d) * 0.5
                if simd_length_squared(mc) <= _distanceTolerance {
                    pts.append(abcd)
                    return
                }
            }
        }
    }

    adaptiveCubic(a, ab, abc, abcd, &pts, level + 1, distanceTolerance, angleTolerance, cuspLimit, maxLevel)
    adaptiveCubic(abcd, bcd, cd, d, &pts, level + 1, distanceTolerance, angleTolerance, cuspLimit, maxLevel)
}

// MARK: - Sample Quadratic Bezier

// based on http://antigrain.com/research/adaptive_bezier/
// based on https://github.com/mattdesl/adaptive-quadratic-curve/
public func adaptiveQuadratic(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2, _ pts: inout [simd_float2], _ level: Int, _ distanceTolerance: Float = 0.05, _ angleTolerance: Float = 1.0, _ cuspLimit: Float = 0.235, _ maxLevel: Int = 16) {
    if level > maxLevel {
        return
    }

    let ab = (a + b) * 0.5
    let bc = (b + c) * 0.5
    let abc = (ab + bc) * 0.5
    
    let dist = pointLineDistance2(a, c, b)
    let acDist = length(c - a)
    let _distanceTolerance = distanceTolerance * acDist
    
    if dist > .ulpOfOne {
        if dist < _distanceTolerance {
            pts.append(abc)
            return
//            let da = quadraticAngle(a, b, c)
//            if da < angleTolerance {
//                pts.append(abc)
//                return
//            }
        }
    }
    else {
        let mc = abc - (a + c) * 0.5
        if simd_length(mc) <= _distanceTolerance {
            pts.append(abc)
            return
        }
    }

    adaptiveQuadratic(a, ab, abc, &pts, level + 1, distanceTolerance, angleTolerance, cuspLimit, maxLevel)
    adaptiveQuadratic(abc, bc, c, &pts, level + 1, distanceTolerance, angleTolerance, cuspLimit, maxLevel)
}

public func adaptiveLinear(_ a: simd_float2, _ b: simd_float2, _ pts: inout [simd_float2], _ distanceThreshold: Float, _ minSegments: Int = 3, _ addLast: Bool = true) {
    let distance = length(a - b)
    if distance > distanceThreshold {
        let segments = max(minSegments, Int(ceil(distance / distanceThreshold)))
        let by = 1.0 / Double(segments)
        let from = by
        let through = addLast ? 1.0 : 1.0 - by
        let times = stride(from: from, through: through, by: by)
        for time in times {
            pts.append(mix(a, b, t: Float(time)))
        }
    }
    else {
        let segments = minSegments
        let by = 1.0 / Double(segments)
        let from = by
        let through = addLast ? 1.0 : 1.0 - by
        let times = stride(from: from, through: through, by: by)
        for time in times {
            pts.append(mix(a, b, t: Float(time)))
        }
    }
}
