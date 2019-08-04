//
//  Object.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class Object {
    public var id: String = "Object"
    
    public var position = simd_make_float3(0, 0, 0)
    {
        didSet {
            print("\(position.x), \(position.y), \(position.z)")
            updateMatrix = true
        }
    }
    
    public var localMatrix: matrix_float4x4 = matrix_identity_float4x4
    public var rotationMatrix: matrix_float4x4 = matrix_identity_float4x4
    public var translationMatrix: matrix_float4x4 = matrix_identity_float4x4
    public var scaleMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    
    public var scale: simd_float3 = simd_make_float3(1, 1, 1)
    public var orientation: simd_quatf = simd_quaternion(0, simd_make_float3(0, 0, 1))
    
    public var worldForwardDirection: simd_float3 = simd_make_float3(0, 0, 1)
    public var worldUpDirection: simd_float3 = simd_make_float3(0, 1, 0)
    public var worldRightDirection: simd_float3 = simd_make_float3(1, 0, 0)
    
    public var forwardDirection: simd_float3 = simd_make_float3(0, 0, 1)
    public var upDirection: simd_float3 = simd_make_float3(0, 1, 0)
    public var rightDirection: simd_float3 = simd_make_float3(1, 0, 0)
    
    public weak var parent: Object?
    public var children: [Object] = []
    
    public var onUpdate: ()?
    
    private var updateMatrix: Bool = true
    private var _worldMatrix: matrix_float4x4 {
        return _updateMatrix()
    }
    
    public var worldMatrix: matrix_float4x4 {
        print("returning worldMatrix aka calculated / cached _worldmatrix")
        return _worldMatrix
    }
    
    public init() {
        print("Setup Object")
    }
    
    public func update() {
//        if let updateFn = self.onUpdate {
//            updateFn()
//        }
        
        for child in children {
            child.update()
        }
    }
    
    public func _updateMatrix() -> matrix_float4x4 {
        
        var result = matrix_identity_float4x4
        
        if updateMatrix {
            print("calculating _worldmatrix")
            
            localMatrix = simd_mul(simd_mul(translationMatrix, rotationMatrix), scaleMatrix)
            
            if let parent = self.parent {
                result = simd_mul(parent.worldMatrix, localMatrix)
            } else {
                result = localMatrix
            }
            
            for child in children {
                _ = child._updateMatrix()
            }
            
            updateMatrix = false
            
            return result
        }
        
        return result
    }
    
    public func addChild(_ child: Object) {}
    
    public func removeChild(_ child: Object) {}
    
//    public func setPosition(_ position: simd_float3 ) {
//        self.position = position
//    }
//
//    public func setPosition(_ x: Float, _ y: Float, _ z: Float) {
//        self.position = simd_make_float3(x, y, z)
//    }
}
