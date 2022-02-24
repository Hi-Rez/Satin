//
//  Object.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation
import simd
import SwiftUI

@objc public protocol ObjectDelegate: AnyObject {
    @objc optional func updatedPosition(_ object: Object)
    @objc optional func updatedScale(_ object: Object)
    @objc optional func updatedOrientation(_ object: Object)
    @objc optional func updatedLabel(_ object: Object)
    @objc optional func updatedVisibility(_ object: Object)
    @objc optional func updatedParent(_ object: Object)
    @objc optional func updatedChildren(_ object: Object)
}

class MulticastObserver<T> {
    private let observers: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    public func add(_ observer: T) {
        observers.add(observer as AnyObject)
    }

    public func remove(_ observerToRemove: T) {
        for observer in observers.allObjects.reversed() {
            if observer === observerToRemove as AnyObject {
                observers.remove(observer)
                return
            }
        }
    }

    func invoke(_ invocation: (T) -> ()) {
        for observer in observers.allObjects.reversed() {
            invocation(observer as! T)
        }
    }
}

@objc open class Object: NSObject, Codable {
    public required init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        label = try values.decode(String.self, forKey: .label)
        position = try values.decode(simd_float3.self, forKey: .position)
        scale = try values.decode(simd_float3.self, forKey: .scale)
        orientation = try values.decode(simd_quatf.self, forKey: .orientation)
        visible = try values.decode(Bool.self, forKey: .visible)
        children = try values.decode([Object].self, forKey: .children)
        for child in children {
            child.parent = self
            child.context = context
        }
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encode(position, forKey: .position)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(scale, forKey: .scale)
        try container.encode(visible, forKey: .visible)
        try container.encode(children, forKey: .children)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case position
        case orientation
        case scale
        case visible
        case children
    }
    
    open var id: String = UUID().uuidString
    
    open var label: String = "Object" {
        didSet {
            observers.invoke { $0.updatedLabel?(self) }
        }
    }
    
    open var visible: Bool = true {
        didSet {
            observers.invoke { $0.updatedVisibility?(self) }
        }
    }
    
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
    
    open var position = simd_make_float3(0, 0, 0) {
        didSet {
            updateMatrix = true
            observers.invoke { $0.updatedPosition?(self) }
        }
    }
    
    open var orientation = simd_quatf(matrix_identity_float4x4) {
        didSet {
            updateMatrix = true
            observers.invoke { $0.updatedOrientation?(self) }
        }
    }
    
    open var scale = simd_make_float3(1, 1, 1) {
        didSet {
            updateMatrix = true
            observers.invoke { $0.updatedScale?(self) }
        }
    }
    
    var _updateLocalBounds: Bool = true {
        didSet {
            _updateBounds = true
        }
    }
    
    var _localbounds = Bounds(min: simd_float3(repeating: 0.0), max: simd_float3(repeating: 0.0))
    
    public var localBounds: Bounds {
        if _updateLocalBounds {
            _localbounds = computeLocalBounds()
            _updateLocalBounds = false
        }
        return _localbounds
    }
    
    var _updateBounds: Bool = true
    var _worldBounds = Bounds(min: simd_float3(repeating: 0.0), max: simd_float3(repeating: 0.0))
    
    public var worldBounds: Bounds {
        if _updateBounds {
            _worldBounds = computeWorldBounds()
            _updateBounds = false
        }
        return _worldBounds
    }
    
    public var translationMatrix: matrix_float4x4 {
        return translationMatrix3f(position)
    }
    
    public var scaleMatrix: matrix_float4x4 {
        return scaleMatrix3f(scale)
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
    
    open weak var parent: Object? {
        didSet {
            updateMatrix = true
            observers.invoke { $0.updatedParent?(self) }
        }
    }
    
    open var children: [Object] = [] {
        didSet {
            _updateBounds = true
            observers.invoke { $0.updatedChildren?(self) }
        }
    }
    
    public var onUpdate: (() -> ())?
    
    var updateMatrix: Bool = true {
        didSet {
            if updateMatrix {
                _updateLocalMatrix = true
                _updateLocalBounds = true
                _updateWorldMatrix = true
                _updateWorldPosition = true
                _updateWorldScale = true
                _updateWorldOrientation = true
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
            if let parent = parent {
                _worldMatrix = simd_mul(parent.worldMatrix, localMatrix)
            }
            else {
                _worldMatrix = localMatrix
            }
            _updateWorldMatrix = false
        }
        return _worldMatrix
    }
    
    // MARK: - Observers
    
    var observers = MulticastObserver<ObjectDelegate>()
    
    public func addObserver(_ observer: ObjectDelegate) {
        observers.add(observer)
    }
    
    public func removeObserver(_ observer: ObjectDelegate) {
        observers.remove(observer)
    }
    
    override public init() {}
    
    public init(_ label: String, _ children: [Object] = []) {
        super.init()
        self.label = label
        for child in children {
            add(child)
        }
    }
    
    open func setup() {}
    
    open func computeLocalBounds() -> Bounds {
        return Bounds(min: position, max: position)
    }
    
    open func computeWorldBounds() -> Bounds {
        var result = Bounds(min: worldPosition, max: worldPosition)
        for child in children {
            result = mergeBounds(result, child.worldBounds)
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
    
    open func add(_ objects: [Object]) {
        for obj in objects {
            add(obj)
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
    
    public func getChildById(_ id: String, _ recursive: Bool = true) -> Object? {
        for child in children {
            if child.id == id {
                return child
            }
            else if recursive, let found = child.getChildById(id, recursive) {
                return found
            }
        }
        return nil
    }
    
    public func getChildrenByName(_ name: String, _ recursive: Bool = true) -> [Object] {
        var results = [Object]()
        getChildrenByName(name, recursive, &results)
        return results
    }
    
    func getChildrenByName(_ name: String, _ recursive: Bool = true, _ results: inout [Object]) {
        for child in children {
            if child.label == name {
                results.append(child)
            }
            else if recursive {
                child.getChildrenByName(name, recursive, &results)
            }
        }
    }
    
    public func isVisible() -> Bool {
        if let parent = parent {
            return (parent.isVisible() && visible)
        }
        else {
            return visible
        }
    }
    
    public func setFrom(_ object: Object) {
        position = object.position
        orientation = object.orientation
        scale = object.scale
    }
}

// extension Object: Equatable {
//    public static func == (lhs: Object, rhs: Object) -> Bool {
//        return lhs === rhs
//    }
// }
//
// extension Object: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(ObjectIdentifier(self).hashValue)
//    }
// }
