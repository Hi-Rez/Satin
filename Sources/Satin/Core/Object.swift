//
//  Object.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Foundation
import simd

open class Object: Codable, ObservableObject {
    @Published open var id: String = UUID().uuidString
    
    @Published open var label: String = "Object"
    
    @Published open var visible: Bool = true
    
    open weak var context: Context? = nil {
        didSet {
            if context != nil, context != oldValue {
                setup()
                for child in children {
                    child.context = context
                }
            }
        }
    }
    
    @Published open var position = simd_make_float3(0, 0, 0) {
        didSet {
            updateMatrix = true
        }
    }
    
    @Published open var orientation = simd_quatf(matrix_identity_float4x4) {
        didSet {
            updateMatrix = true
            _rotationMatrix.clear()
            _orientationMatrix.clear()
        }
    }
    
    @Published open var scale = simd_make_float3(1, 1, 1) {
        didSet {
            updateMatrix = true
        }
    }
    
    var _localBounds = ValueCache<Bounds>()
    public var localBounds: Bounds { _localBounds.get(computeLocalBounds) }

    var _worldBounds = ValueCache<Bounds>()
    public var worldBounds: Bounds { _worldBounds.get(computeWorldBounds) }
    
    public var translationMatrix: matrix_float4x4 { translationMatrix3f(position) }
    
    public var scaleMatrix: matrix_float4x4 { scaleMatrix3f(scale) }
    
    var _rotationMatrix = ValueCache<matrix_float4x4>()
    public var rotationMatrix: matrix_float4x4 {
        _rotationMatrix.get { matrix_float4x4(orientation) }
    }

    var _orientationMatrix = ValueCache<matrix_float3x3>()
    public var orientationMatrix: matrix_float3x3 {
        _orientationMatrix.get { matrix_float3x3(orientation) }
    }
    
    public var forwardDirection: simd_float3 {
        return simd_normalize(orientation.act(Satin.worldForwardDirection))
    }
    
    public var upDirection: simd_float3 {
        return simd_normalize(orientation.act(Satin.worldUpDirection))
    }
    
    public var rightDirection: simd_float3 {
        return simd_normalize(orientation.act(Satin.worldRightDirection))
    }
    
    public var worldForwardDirection: simd_float3 {
        return simd_normalize(worldOrientation.act(Satin.worldForwardDirection))
    }
    
    public var worldUpDirection: simd_float3 {
        return simd_normalize(worldOrientation.act(Satin.worldUpDirection))
    }
    
    public var worldRightDirection: simd_float3 {
        return simd_normalize(worldOrientation.act(Satin.worldRightDirection))
    }
    
    open weak var parent: Object? {
        didSet {
            updateMatrix = true
        }
    }
    
    @Published open var children: [Object] = [] {
        didSet {
            _worldBounds.clear()
        }
    }
    
    public var onUpdate: (() -> ())?
    
    var updateMatrix: Bool = true {
        didSet {
            if updateMatrix {
                _localMatrix.clear()
                _localBounds.clear()
                _worldBounds.clear()
                _normalMatrix.clear()
                _worldMatrix.clear()
                _worldOrientation.clear()
                transformPublisher.send(self)
                updateMatrix = false
                for child in children {
                    child.updateMatrix = true
                }
            }
        }
    }
    
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

    public var worldPosition: simd_float3 {
        get {
            let wp = worldMatrix.columns.3
            return simd_make_float3(wp.x, wp.y, wp.z)
        }
        set {
            if let parent = parent {
                position = simd_make_float3(parent.worldMatrix.inverse * simd_make_float4(newValue, 1.0))
            }
            else {
                position = newValue
            }
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
            }
            else {
                scale = newValue
            }
        }
    }
    
    var _worldOrientation = ValueCache<simd_quatf>()
    public var worldOrientation: simd_quatf {
        get {
            _worldOrientation.get {
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
        }
        set {
            if let parent = parent {
                orientation = parent.worldOrientation.inverse * newValue
            }
            else {
                orientation = newValue
            }
        }
    }
    
    var _worldMatrix = ValueCache<matrix_float4x4>()
    public var worldMatrix: matrix_float4x4 {
        get {
            _worldMatrix.get {
                if let parent = parent {
                    return simd_mul(parent.worldMatrix, localMatrix)
                }
                else {
                    return localMatrix
                }
            }
        }
        set {
            if let parent = parent {
                localMatrix = parent.worldMatrix.inverse * newValue
            }
            else {
                localMatrix = newValue
            }
        }
    }
    
    var _normalMatrix = ValueCache<matrix_float3x3>()
    public var normalMatrix: matrix_float3x3 {
        _normalMatrix.get {
            let n = worldMatrix.inverse.transpose
            return simd_matrix(simd_make_float3(n.columns.0), simd_make_float3(n.columns.1), simd_make_float3(n.columns.2))
        }
    }
    
    public let transformPublisher = PassthroughSubject<Object, Never>()
    
    public init() {}
    
    public init(_ label: String, _ children: [Object] = []) {
        self.label = label
        for child in children {
            add(child)
        }
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
    
    open func update(camera: Camera, viewport: simd_float4) {}
    
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
        }
    }
    
    open func add(_ objects: [Object], _ setParent: Bool = true) {
        for obj in objects {
            add(obj, setParent)
        }
    }
    
    open func remove(_ child: Object) {
        for (index, object) in children.enumerated() {
            if object === child {
                if object.parent === self {
                    object.parent = nil
                }
                children.remove(at: index)
                return
            }
        }
    }
    
    open func removeFromParent() {
        parent?.remove(self)
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
    
    public func lookAt(_ center: simd_float3, _ up: simd_float3 = Satin.worldUpDirection) {
        localMatrix = lookAtMatrix3f(position, center, up)
    }
}

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
