//
//  Object.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class Object {
    public var id: String = UUID().uuidString

    public var position = simd_make_float3(0, 0, 0) {
        didSet {
            updateMatrix = true
        }
    }

    public var orientation = simd_quaternion(0, simd_make_float3(0, 0, 1)) {
        didSet {
            updateMatrix = true
        }
    }

    public var scale = simd_make_float3(1, 1, 1) {
        didSet {
            updateMatrix = true
        }
    }

    public var translationMatrix: matrix_float4x4 {
        return Satin.translate(position)
    }

    public var scaleMatrix: matrix_float4x4 {
        return Satin.scale(scale)
    }

    public var rotationMatrix: matrix_float4x4 {
        return matrix_float4x4(orientation)
    }

    public var forwardDirection: simd_float3 {
        return simd_matrix3x3(orientation) * worldForwardDirection
    }

    public var upDirection: simd_float3 {
        return simd_matrix3x3(orientation) * worldUpDirection
    }

    public var rightDirection: simd_float3 {
        return simd_matrix3x3(orientation) * worldRightDirection
    }

    public weak var parent: Object? {
        didSet {
            updateMatrix = true
        }
    }

    public var children: [Object] = []

    public var onUpdate: (() -> ())?

    private var updateMatrix: Bool = true

    private var _localMatrix: matrix_float4x4 = matrix_identity_float4x4

    public var localMatrix: matrix_float4x4 {
        if updateMatrix {
            _localMatrix = translationMatrix * rotationMatrix * scaleMatrix
            updateMatrix = false
        }
        return _localMatrix
    }

    private var _worldMatrix: matrix_float4x4 = matrix_identity_float4x4

    public var worldMatrix: matrix_float4x4 {
        if updateMatrix {
            if let parent = self.parent {
                _worldMatrix = parent.worldMatrix * localMatrix
            } else {
                _worldMatrix = localMatrix
            }
            for child in children {
                child.updateMatrix = true
            }
            updateMatrix = false
        }
        return _worldMatrix
    }

    public init() {}

    public func update() {
        onUpdate?()

        for child in children {
            child.update()
        }
    }

    public func addChild(_ child: Object) {
        if !children.contains(child) {
            child.parent = self
            children.append(child)
        }
    }

    public func removeChild(_ child: Object) {
        for (index, object) in children.enumerated() {
            if object == child {
                children.remove(at: index)
                return
            }
        }
    }
}

extension Object: Equatable {
    public static func == (lhs: Object, rhs: Object) -> Bool {
        return lhs.id == rhs.id
    }
}
