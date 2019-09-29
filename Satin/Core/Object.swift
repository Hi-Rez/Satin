//
//  Object.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class Object: Codable {
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        position = try values.decode(simd_float3.self, forKey: .position)
        scale = try values.decode(simd_float3.self, forKey: .scale)
        orientation = try values.decode(simd_quatf.self, forKey: .orientation)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(scale, forKey: .scale)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case position
        case orientation
        case scale
    }
    
    public var id: String = UUID().uuidString
    
    var context: Context? {
        didSet {
            setup()
            if let context = self.context {
                for child in self.children {
                    setupContext(context: context, object: child)
                }
            }
        }
    }
    
    func setupContext(context: Context, object: Object) {
        object.context = context        
    }
    
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
            _localMatrix = simd_mul(simd_mul(translationMatrix, rotationMatrix), scaleMatrix)
            updateMatrix = false
        }
        return _localMatrix
    }
    
    private var _worldMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    public var worldMatrix: matrix_float4x4 {
        if updateMatrix {
            if let parent = self.parent {
                _worldMatrix = simd_mul(parent.worldMatrix, localMatrix)
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
    
    func setup() {}
    
    public func update() {
        onUpdate?()
        
        for child in children {
            child.update()
        }
    }
    
    public func add(_ child: Object) {
        if !children.contains(child) {
            child.parent = self
            child.context = context
            children.append(child)
        }
    }
    
    public func remove(_ child: Object) {
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
