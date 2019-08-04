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
    var result = matrix_identity_float4x4;
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

public func scale(_ v: simd_double3 ) -> matrix_double4x4
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

public func scale(_ v: simd_float3 ) -> matrix_float4x4
{
    var result = matrix_identity_float4x4
    result[0].x = v.x
    result[1].y = v.y
    result[2].z = v.z
    return result
}

// MARK: - Rotate (Double)

public func rotate(_ angle: Float, _ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4
{
    let result = matrix_identity_float4x4;
    
    let a = angle * 1.0 / 180.0;
    let c = 0.0
    let s = 0.0

    
    return result;
}

// MARK: - Rotate (Float)




+ (matrix_float4x4)rotate:(float)angle axis:(simd_float3)axis {
    float a = RZARadiansOverPi(angle);
    float c = 0.0f;
    float s = 0.0f;
    
    // Computes the sine and cosine of pi times angle (measured in radians)
    // faster and gives exact results for angle = 90, 180, 270, etc.
    __sincospif(a, &s, &c);
    
    float k = 1.0f - c;
    simd_float3 u = simd_normalize(axis);
    simd_float3 v = s * u;
    simd_float3 w = k * u;
    
    simd_float4 P;
    simd_float4 Q;
    simd_float4 R;
    simd_float4 S;
    
    P.x = w.x * u.x + c;
    P.y = w.x * u.y + v.z;
    P.z = w.x * u.z - v.y;
    P.w = 0.0f;
    
    Q.x = w.x * u.y - v.z;
    Q.y = w.y * u.y + c;
    Q.z = w.y * u.z + v.x;
    Q.w = 0.0f;
    
    R.x = w.x * u.z + v.y;
    R.y = w.y * u.z - v.x;
    R.z = w.z * u.z + c;
    R.w = 0.0f;
    
    S.x = 0.0f;
    S.y = 0.0f;
    S.z = 0.0f;
    S.w = 1.0f;
    
    matrix_float4x4 result = { P, Q, R, S };
    return result;
}
