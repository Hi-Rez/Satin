//
//  Object.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Metal
import Combine
import Foundation
import simd

open class Object: Codable, ObservableObject {
    @Published open var id: String = UUID().uuidString
    @Published open var label = "Object"
    @Published open var visible = true

    open var context: Context? = nil {
        didSet {
            if context != nil, context !== oldValue {
                setup()
            }
        }
    }

    // MARK: - Position

    @Published open var position: simd_float3 = .zero {
        didSet {
            _translationMatrix.clear()
            updateLocalMatrix = true
        }
    }

    public var worldPosition: simd_float3 {
        get {
            simd_make_float3(worldMatrix.columns.3)
        }
        set {
            if let parent = parent {
                position = simd_make_float3(parent.worldMatrix.inverse * simd_make_float4(newValue, 1.0))
            } else {
                position = newValue
            }
        }
    }

    var _translationMatrix = ValueCache<matrix_float4x4>()
    public var translationMatrix: matrix_float4x4 {
        _translationMatrix.get { translationMatrix3f(position) }
    }

    // MARK: - Orientation

    @Published open var orientation = simd_quatf(matrix_identity_float4x4) {
        didSet {
            _rotationMatrix.clear()
            updateLocalMatrix = true
        }
    }

    public var worldOrientation: simd_quatf {
        get {
            let ws = worldScale
            let wm = worldMatrix
            let c0 = wm.columns.0
            let c1 = wm.columns.1
            let c2 = wm.columns.2
            let x = simd_make_float3(c0.x, c0.y, c0.z) / ws.x
            let y = simd_make_float3(c1.x, c1.y, c1.z) / ws.y
            let z = simd_make_float3(c2.x, c2.y, c2.z) / ws.z
            return simd_quatf(simd_float3x3(columns: (x, y, z)))
        }
        set {
            if let parent = parent {
                orientation = parent.worldOrientation.inverse * newValue
            } else {
                orientation = newValue
            }
        }
    }

    var _rotationMatrix = ValueCache<matrix_float4x4>()
    public var rotationMatrix: matrix_float4x4 {
        _rotationMatrix.get { matrix_float4x4(orientation) }
    }

    // MARK: - Scale

    @Published open var scale: simd_float3 = .one {
        didSet {
            _scaleMatrix.clear()
            updateLocalMatrix = true
        }
    }

    public var worldScale: simd_float3 {
        get {
            let wm = worldMatrix
            let sx = wm.columns.0
            let sy = wm.columns.1
            let sz = wm.columns.2
            return simd_make_float3(length(sx), length(sy), length(sz))
        }
        set {
            if let parent = parent {
                scale = newValue / parent.worldScale
            } else {
                scale = newValue
            }
        }
    }

    var _scaleMatrix = ValueCache<matrix_float4x4>()
    public var scaleMatrix: matrix_float4x4 {
        _scaleMatrix.get { scaleMatrix3f(scale) }
    }

    // MARK: - Local Matrix

    var _localMatrix = ValueCache<matrix_float4x4>()
    public var localMatrix: matrix_float4x4 {
        get {
            _localMatrix.get {
                simd_mul(simd_mul(translationMatrix, rotationMatrix), scaleMatrix)
            }
        }
        set {
            position = simd_make_float3(newValue.columns.3)
            let sx = newValue.columns.0
            let sy = newValue.columns.1
            let sz = newValue.columns.2
            scale = simd_make_float3(simd_length(sx), simd_length(sy), simd_length(sz))
            let rx = simd_make_float3(sx) / scale.x
            let ry = simd_make_float3(sy) / scale.y
            let rz = simd_make_float3(sz) / scale.z
            orientation = simd_quatf(simd_float3x3(rx, ry, rz))
        }
    }

    var updateLocalMatrix = true {
        didSet {
            if updateLocalMatrix {
                _updateLocalBounds = true

                _normalMatrix.clear()
                _worldMatrix.clear()
                _localMatrix.clear()

                transformPublisher.send(self)

                updateLocalMatrix = false

                for child in children {
                    child.updateWorldMatrix = true
                }
            }
        }
    }

    // MARK: - World Matrix

    var _worldMatrix = ValueCache<matrix_float4x4>()
    public var worldMatrix: matrix_float4x4 {
        get {
            _worldMatrix.get {
                if let parent = parent {
                    return simd_mul(parent.worldMatrix, localMatrix)
                } else {
                    return localMatrix
                }
            }
        }
        set {
            if let parent = parent {
                localMatrix = parent.worldMatrix.inverse * newValue
            } else {
                localMatrix = newValue
            }
        }
    }

    var updateWorldMatrix = true {
        didSet {
            if updateWorldMatrix {
                _updateWorldBounds = true

                _normalMatrix.clear()
                _worldMatrix.clear()

                transformPublisher.send(self)

                updateWorldMatrix = false

                for child in children {
                    child.updateWorldMatrix = true
                }
            }
        }
    }

    // MARK: - Normal Bounds

    var _normalMatrix = ValueCache<matrix_float3x3>()
    public var normalMatrix: matrix_float3x3 {
        _normalMatrix.get {
            let n = worldMatrix.inverse.transpose
            return simd_matrix(simd_make_float3(n.columns.0), simd_make_float3(n.columns.1), simd_make_float3(n.columns.2))
        }
    }

    // MARK: - Local Bounds

    public var updateLocalBounds = true {
        didSet {
            if updateLocalBounds {
                _updateLocalBounds = true
                updateLocalBounds = false
            }
        }
    }

    var _updateLocalBounds = true {
        didSet {
            if _updateLocalBounds {
                _updateWorldBounds = true
            }
        }
    }

    var _localBounds = createBounds()
    public var localBounds: Bounds {
        if _updateLocalBounds {
            _localBounds = computeLocalBounds()
            _updateLocalBounds = false
        }
        return _localBounds
    }

    // MARK: - World Bounds

    public var updateWorldBounds = true {
        didSet {
            if updateWorldBounds {
                _updateWorldBounds = true
                updateWorldBounds = false
            }
        }
    }

    var _updateWorldBounds = true {
        didSet {
            if _updateWorldBounds {
                parent?._updateWorldBounds = true
            }
        }
    }

    var _worldBounds = createBounds()
    public var worldBounds: Bounds {
        if _updateWorldBounds {
            _worldBounds = computeWorldBounds()
            _updateWorldBounds = false
        }
        return _worldBounds
    }

    // MARK: - Directions

    public var forwardDirection: simd_float3 { simd_normalize(orientation.act(Satin.worldForwardDirection)) }
    public var upDirection: simd_float3 { simd_normalize(orientation.act(Satin.worldUpDirection)) }
    public var rightDirection: simd_float3 { simd_normalize(orientation.act(Satin.worldRightDirection)) }

    // MARK: - World Directions

    public var worldForwardDirection: simd_float3 { simd_normalize(worldOrientation.act(Satin.worldForwardDirection)) }
    public var worldUpDirection: simd_float3 { simd_normalize(worldOrientation.act(Satin.worldUpDirection)) }
    public var worldRightDirection: simd_float3 { simd_normalize(worldOrientation.act(Satin.worldRightDirection)) }

    // MARK: - Parent & Children

    open weak var parent: Object? {
        didSet {
            updateWorldMatrix = true
        }
    }

    @Published open var children: [Object] = [] {
        didSet {
            _updateWorldBounds = true
        }
    }

    // MARK: - OnUpdate Hook

    public var onUpdate: (() -> Void)?

    // MARK: - Publishers

    public let transformPublisher = PassthroughSubject<Object, Never>()
    public let childAddedPublisher = PassthroughSubject<Object, Never>()
    public let childRemovedPublisher = PassthroughSubject<Object, Never>()

    var childAddedSubscriptions: [Object: AnyCancellable] = [:]
    var childRemovedSubscriptions: [Object: AnyCancellable] = [:]

    // MARK: - Init

    public init() {}

    public init(_ label: String, _ children: [Object] = []) {
        self.label = label
        for child in children {
            add(child)
        }
    }

    // MARK: - Deinit

    deinit {
        removeAll()
    }

    // MARK: - CodingKeys

    public enum CodingKeys: String, CodingKey {
        case id
        case label
        case position
        case orientation
        case scale
        case visible
        case children
    }

    // MARK: - Decode

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        label = try values.decode(String.self, forKey: .label)
        position = try values.decode(simd_float3.self, forKey: .position)
        scale = try values.decode(simd_float3.self, forKey: .scale)
        orientation = try values.decode(simd_quatf.self, forKey: .orientation)
        visible = try values.decode(Bool.self, forKey: .visible)
        try decodeChildren(from: decoder)
    }

    open func decodeChildren(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        children = try values.decode([Object].self, forKey: .children)
        for child in children {
            child.parent = self
            child.context = context
        }
    }

    // MARK: - Encode

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encode(position, forKey: .position)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(scale, forKey: .scale)
        try container.encode(visible, forKey: .visible)
        try encodeChildren(to: encoder)
    }

    open func encodeChildren(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(children, forKey: .children)
    }

    // MARK: - Setup

    open func setup() {}

    // MARK: - Compute Bounds

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

    open func update(_ commandBuffer: MTLCommandBuffer) {
        onUpdate?()
    }

    open func update(camera: Camera, viewport: simd_float4) {}

    // MARK: - Inserting, Adding, Attaching & Removing

    open func insert(_ child: Object, at: Int, setParent: Bool = true) {
        if !children.contains(where: { $0 === child }) {
            if setParent {
                child.parent = self
            }
            child.context = context
            children.insert(child, at: at)
        }
    }

    open func add(_ child: Object, _ setParent: Bool = true) {
        if !children.contains(where: { $0 === child }) {
            if setParent {
                child.parent = self
            }
            child.context = context
            children.append(child)
            childAddedPublisher.send(child)

            childAddedSubscriptions[child] = child.childAddedPublisher.sink { [weak self] subchild in
                self?.childAddedPublisher.send(subchild)
            }

            childRemovedSubscriptions[child] = child.childRemovedPublisher.sink { [weak self] subchild in
                self?.childRemovedPublisher.send(subchild)
            }
        }
    }

    open func attach(_ child: Object) {
        add(child, false)
    }

    open func add(_ objects: [Object], _ setParent: Bool = true) {
        for obj in objects {
            add(obj, setParent)
        }
    }

    open func remove(_ child: Object) {
        if let index = children.firstIndex(of: child) {
            childRemovedPublisher.send(child)
            if child.parent === self {
                child.parent = nil
            }
            children.remove(at: index)
            childAddedSubscriptions.removeValue(forKey: child)
            childRemovedSubscriptions.removeValue(forKey: child)
        }
    }

    open func removeFromParent() {
        parent?.remove(self)
    }

    open func removeAll(keepingCapacity: Bool = false) {
        children.removeAll(keepingCapacity: keepingCapacity)
    }

    // MARK: - Recursive Scene Graph Functions

    public func apply(_ fn: (_ object: Object) -> Void, _ recursive: Bool = true) {
        fn(self)
        if recursive {
            for child in children {
                child.apply(fn, recursive)
            }
        }
    }

    public func traverse(_ fn: (_ object: Object) -> Void) {
        for child in children {
            fn(child)
            child.traverse(fn)
        }
    }

    public func traverseVisible(_ fn: (_ object: Object) -> Void) {
        for child in children where child.visible {
            fn(child)
            child.traverse(fn)
        }
    }

    public func traverseAncestors(_ fn: (_ object: Object) -> Void) {
        if let parent = parent {
            fn(parent)
            parent.traverseAncestors(fn)
        }
    }

    // MARK: - Children

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
            } else if recursive, let found = child.getChild(name, recursive) {
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
        }
        if recursive {
            for child in children {
                if let found = child.getChildById(id, recursive) {
                    return found
                }
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
            } else if recursive {
                child.getChildrenByName(name, recursive, &results)
            }
        }
    }

    // MARK: - isVisible

    public func isVisible() -> Bool {
        if let parent = parent {
            return (parent.isVisible() && visible)
        } else {
            return visible
        }
    }

    // MARK: - isLight

    public func isLight() -> Bool {
        if let parent = parent {
            return (parent.isLight() || (self is Light))
        } else {
            return (self is Light)
        }
    }

    public func setFrom(_ object: Object) {
        position = object.position
        orientation = object.orientation
        scale = object.scale
    }

    // MARK: - Look At

    public func lookAt(target: simd_float3, up: simd_float3 = Satin.worldUpDirection, local: Bool = true) {
        if local {
            localMatrix = lookAtMatrix3f(position, target, up)
        }
        else {
            worldMatrix = lookAtMatrix3f(worldPosition, target, up)
        }
    }

    // MARK: - Intersections

    open func intersects(ray: Ray) -> Bool {
        return rayBoundsIntersect(ray, worldBounds)
    }

    open func intersect(ray: Ray, intersections: inout [RaycastResult], recursive: Bool = true, invisible: Bool = false) {
        guard visible || invisible, intersects(ray: ray), recursive else { return }
        for child in children {
            child.intersect(ray: ray, intersections: &intersections, recursive: recursive, invisible: invisible)
        }
    }
}

// MARK: - Equatable

extension Object: Equatable {
    public static func == (lhs: Object, rhs: Object) -> Bool {
        return lhs.id == rhs.id &&
            lhs.label == rhs.label &&
            lhs.position == rhs.position &&
            lhs.orientation == rhs.orientation &&
            lhs.scale == rhs.scale &&
            lhs.visible == rhs.visible &&
            lhs.children == rhs.children
    }
}

extension Object: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
