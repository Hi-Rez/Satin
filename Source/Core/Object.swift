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
    
    open var id: String = UUID().uuidString
    open var label: String = "Object"
    open var visible: Bool = true
    
    open var context: Context? = nil {
        didSet {
            if context != nil {
                setup()
                for child in children {
                    child.context = context
                }
            }
        }
    }
    
    public var position = simd_make_float3(0, 0, 0) {
        didSet {
            updateMatrix = true
        }
    }
    
    public var orientation = simd_quatf(matrix_identity_float4x4) {
        didSet {
            updateMatrix = true
        }
    }
    
    public var scale = simd_make_float3(1, 1, 1) {
        didSet {
            updateMatrix = true
        }
    }
    
    var _updateBounds: Bool = true
    var _bounds: Bounds = Bounds(min: simd_float3(repeating: 0.0), max: simd_float3(repeating: 0.0))
    
    public var bounds: Bounds {
        if _updateBounds {
            _bounds = computeBounds()
            _updateBounds = false
        }
        return _bounds
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
        return simd_normalize(simd_matrix3x3(orientation) * Satin.worldForwardDirection)
    }
    
    public var upDirection: simd_float3 {
        return simd_normalize(simd_matrix3x3(orientation) * Satin.worldUpDirection)
    }
    
    public var rightDirection: simd_float3 {
        return simd_normalize(simd_matrix3x3(orientation) * Satin.worldRightDirection)
    }
    
    public var worldForwardDirection: simd_float3 {
        return simd_normalize(simd_matrix3x3(worldOrientation) * Satin.worldForwardDirection)
    }
    
    public var worldUpDirection: simd_float3 {
        return simd_normalize(simd_matrix3x3(worldOrientation) * Satin.worldUpDirection)
    }
    
    public var worldRightDirection: simd_float3 {
        return simd_normalize(simd_matrix3x3(worldOrientation) * Satin.worldRightDirection)
    }
    
    public weak var parent: Object? {
        didSet {
            updateMatrix = true
        }
    }
    
    public var children: [Object] = [] {
        didSet {
            _updateBounds = true
        }
    }
    
    public var onUpdate: (() -> ())?
    
    var updateMatrix: Bool = true {
        didSet {
            if updateMatrix {
                _updateLocalMatrix = true
                _updateWorldMatrix = true
                _updateWorldPosition = true
                _updateWorldScale = true
                _updateWorldOrientation = true
                _updateBounds = true
                updateMatrix = false
                for child in children {
                    child.updateMatrix = true
                }
            }
        }
    }
    
    var _updateLocalMatrix: Bool = true
    var _localMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    public var localMatrix: matrix_float4x4 {
        get {
            if _updateLocalMatrix {
                _localMatrix = simd_mul(simd_mul(translationMatrix, rotationMatrix), scaleMatrix)
                _updateLocalMatrix = false
            }
            return _localMatrix
        }
        set {
            position = simd_make_float3(newValue.columns.3)
            let sx = newValue.columns.0
            let sy = newValue.columns.1
            let sz = newValue.columns.2
            scale = simd_make_float3(length(sx), length(sy), length(sz))
            let rx = simd_make_float3(sx.x, sx.y, sx.z) / scale.x
            let ry = simd_make_float3(sy.x, sy.y, sy.z) / scale.y
            let rz = simd_make_float3(sz.x, sz.y, sz.z) / scale.z
            orientation = simd_quatf(simd_float3x3(columns: (rx, ry, rz)))
        }
    }
    
    var _updateWorldPosition: Bool = true
    var _worldPosition = simd_make_float3(0, 0, 0)
    
    public var worldPosition: simd_float3 {
        if _updateWorldPosition {
            let wp = worldMatrix.columns.3
            _worldPosition = simd_make_float3(wp.x, wp.y, wp.z)
            _updateWorldPosition = false
        }
        return _worldPosition
    }
    
    var _updateWorldScale: Bool = true
    var _worldScale = simd_make_float3(0, 0, 0)
    
    public var worldScale: simd_float3 {
        if _updateWorldScale {
            let wm = worldMatrix
            let sx = wm.columns.0
            let sy = wm.columns.1
            let sz = wm.columns.2
            _worldScale = simd_make_float3(length(sx), length(sy), length(sz))
            _updateWorldScale = false
        }
        return _worldScale
    }
    
    var _updateWorldOrientation: Bool = true
    var _worldOrientation = simd_quaternion(0, simd_make_float3(0, 0, 1))
    
    public var worldOrientation: simd_quatf {
        if _updateWorldOrientation {
            let ws = worldScale
            let wm = worldMatrix
            let c0 = wm.columns.0
            let c1 = wm.columns.1
            let c2 = wm.columns.2
            let x = simd_make_float3(c0.x, c0.y, c0.z) / ws.x
            let y = simd_make_float3(c1.x, c1.y, c1.z) / ws.y
            let z = simd_make_float3(c2.x, c2.y, c2.z) / ws.z
            _worldOrientation = simd_quatf(simd_float3x3(columns: (x, y, z)))
            _updateWorldOrientation = false
        }
        return _worldOrientation
    }
    
    var _updateWorldMatrix: Bool = true
    var _worldMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    public var worldMatrix: matrix_float4x4 {
        if _updateWorldMatrix {
            if let parent = self.parent {
                _worldMatrix = simd_mul(parent.worldMatrix, localMatrix)
            }
            else {
                _worldMatrix = localMatrix
            }
            _updateWorldMatrix = false
        }
        return _worldMatrix
    }
    
    public init() {}
    
    open func setup() {}
    
    open func computeBounds() -> Bounds
    {
        var result = Bounds(min: worldPosition, max: worldPosition)
        for child in children {
            let childBounds = child.bounds
            result = mergeBounds(result, childBounds)
        }
        return result
    }
    
    open func update() {
        onUpdate?()
        for child in children {
            child.update()
        }
    }
    
    open func add(_ child: Object) {
        if !children.contains(child) {
            child.parent = self
            child.context = context
            children.append(child)
        }
    }
    
    open func remove(_ child: Object) {
        for (index, object) in children.enumerated() {
            if object == child {
                if object.parent == self {
                    object.parent = nil
                }
                children.remove(at: index)
                return
            }
        }
    }
    
    open func removeAll() {
        children = []
    }
    
    public func apply(_ fn: (_ object: Object) -> (), _ recursive: Bool = true) {
        fn(self)
        if recursive {
            for child in children {
                child.apply(fn, recursive)
            }
        }
    }
    
    public func getChildren(_ recursive: Bool = true) -> [Object] {
        var results: [Object] = []
        for child in children {
            results.append(child)
            if recursive {
                results.append(contentsOf: child.getChildren(recursive))
            }
        }
        return results
    }
    
    public func getChild(_ name: String, _ recursive: Bool = true) -> Object? {
        for child in children {
            if child.label == name {
                return child
            }
            else if recursive, let found = child.getChild(name, recursive) {
                return found
            }
        }
        return nil
    }
    
    public func isVisible() -> Bool {
        if let parent = self.parent {
            return (parent.isVisible() && visible)
        }
        else {
            return visible
        }
    }
}

extension Object: Equatable {
    public static func == (lhs: Object, rhs: Object) -> Bool {
        return lhs === rhs
    }
}

extension Object: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
