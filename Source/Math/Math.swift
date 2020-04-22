//
//  Math.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

// MARK: - Degrees To Radians (Double)

public func degToRad(_ degrees: Double) -> Double
{
    return degrees * Double.pi / 180.0
}

// MARK: - Degrees To Radians (Float)

public func degToRad(_ degrees: Float) -> Float
{
    return degrees * Float.pi / 180.0
}

// MARK: - Translate (Double)

public func translate(_ x: Double, _ y: Double, _ z: Double) -> matrix_double4x4
{
    var result = matrix_identity_double4x4
    result[3].x = x
    result[3].y = y
    result[3].z = z
    return result
}

public func translate(_ v: simd_double3) -> matrix_double4x4
{
    var result = matrix_identity_double4x4
    result[3].x = v.x
    result[3].y = v.y
    result[3].z = v.z
    return result
}

// MARK: - Translate (Float)

public func translate(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4
{
    var result = matrix_identity_float4x4
    result[3].x = x
    result[3].y = y
    result[3].z = z
    return result
}

public func translate(_ v: simd_float3) -> matrix_float4x4
{
    var result = matrix_identity_float4x4
    result[3].x = v.x
    result[3].y = v.y
    result[3].z = v.z
    return result
}

// MARK: - Scale (Double)

public func scale(_ x: Double, _ y: Double, _ z: Double) -> matrix_double4x4
{
    var result = matrix_identity_double4x4
    result[0].x = x
    result[1].y = y
    result[2].z = z
    return result
}

public func scale(_ v: simd_double3) -> matrix_double4x4
{
    var result = matrix_identity_double4x4
    result[0].x = v.x
    result[1].y = v.y
    result[2].z = v.z
    return result
}

// MARK: - Scale (Float)

public func scale(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4
{
    var result = matrix_identity_float4x4
    result[0].x = x
    result[1].y = y
    result[2].z = z
    return result
}

public func scale(_ v: simd_float3) -> matrix_float4x4
{
    var result = matrix_identity_float4x4
    result[0].x = v.x
    result[1].y = v.y
    result[2].z = v.z
    return result
}

// MARK: - Frustum (Float)

public func frustum(_ horizontalFov: Float, _ verticalFov: Float, _ near: Float, _ far: Float) -> matrix_float4x4
{
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

public func frustum(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) -> matrix_float4x4
{
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

public func lookAt(_ eye: simd_float3, _ center: simd_float3, _ up: simd_float3) -> matrix_float4x4
{
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

public func perspective(width: Float, height: Float, near: Float, far: Float) -> matrix_float4x4
{
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

public func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4
{
    let angle = degToRad(0.5 * fov)

    let sy = 1.0 / tanf(angle)
    let sx = sy / aspect
    let rz = far - near
    let sz = -(far + near) / rz
    let sw = -far * near / rz

    var result = matrix_identity_float4x4

    result[0].x = sx
    result[1].y = sy
    result[2].z = sz
    result[2].w = -1.0
    result[3].z = sw
    result[3].w = 0.0

    return result
}

// MARK: - Orthographic (Float)

public func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> matrix_float4x4
{
    let length = 1.0 / (right - left)
    let height = 1.0 / (top - bottom)
    let depth = 1.0 / (far - near)

    var result = matrix_identity_float4x4

    result[0].x = 2.0 * length
    result[1].y = 2.0 * height
    result[2].z = depth
    result[3].z = -near * depth

    return result
}
