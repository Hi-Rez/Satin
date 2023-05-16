//
//  ObjectShadowRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Combine
import Foundation
import Metal
import MetalPerformanceShaders
import Satin

class ShadowPostProcessor: PostProcessor {
    class ShadowPostMaterial: SourceMaterial {
        public unowned var colorTexture: MTLTexture?
        public unowned var depthTexture: MTLTexture?

        public required init() {
            super.init(pipelinesURL: Bundle.main.resourceURL!
                .appendingPathComponent("Assets")
                .appendingPathComponent("Shared")
                .appendingPathComponent("Pipelines")
            )
            blending = .alpha
        }

        required init(from _: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            renderEncoder.setFragmentTexture(colorTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(depthTexture, index: FragmentTextureIndex.Custom1.rawValue)
        }
    }

    public unowned var colorTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? ShadowPostMaterial {
                material.colorTexture = colorTexture
            }
        }
    }

    public unowned var depthTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? ShadowPostMaterial {
                material.depthTexture = depthTexture
            }
        }
    }

    public init(context: Context) {
        super.init(context: context, material: ShadowPostMaterial())
        renderer.setClearColor(.zero)
        label = "Shadow Post Processor"
    }
}

class ObjectShadowRenderer {
    private var context: Context
    private var object: Object
    private var container: Object
    private var scene: Object
    private var catcher: Mesh

    var resolution: Int {
        didSet {
            if oldValue != resolution {
                _updateTexture = true
            }
        }
    }

    var padding: Float
    var blurRadius: Float {
        didSet {
            if oldValue != blurRadius {
                _updateBlur = true
            }
        }
    }

    var near: Float
    var far: Float
    var color: simd_float4

    private var camera: OrthographicCamera
    private var renderer: Satin.Renderer
    private var processor: ShadowPostProcessor

    public private(set) var texture: MTLTexture?
    public private(set) var renderTexture: MTLTexture?
    private var _updateTexture = true

    private var blurFilter: MPSImageGaussianBlur?
    private var _updateBlur = true

    var materialCache: [Object: Material] = [:]

    var material = BasicColorMaterial(.one, .disabled)

    init(context: Context,
         object: Object,
         container: Object,
         scene: Object,
         catcher: Mesh,
         resolution: Int = 512,
         padding: Float = 0.175,
         blurRadius: Float = 16.0,
         near: Float = 0.0001,
         far: Float = 5.0,
         color: simd_float4 = simd_make_float4(1.0, 1.0, 1.0, 0.875))
    {
        self.context = context
        self.object = object
        self.container = container
        self.scene = scene
        self.catcher = catcher
        self.resolution = resolution
        self.padding = padding
        self.blurRadius = blurRadius
        self.near = near
        self.far = far
        self.color = color

        renderer = Satin.Renderer(context: context)
        renderer.label = "Object Shadow Renderer"

        processor = ShadowPostProcessor(context: Context(context.device, 1, .rgba16Float))
        camera = OrthographicCamera()

        renderer.setClearColor(.zero)
        renderer.depthStoreAction = .store

        let size = (Float(resolution), Float(resolution))
        renderer.resize(size)
        processor.resize(size)

        update()
    }

    public func update(commandBuffer: MTLCommandBuffer) {
        update()

        let finalScene = Object("Shadow Scene")
        let renderables = getRenderables(object, true, false)
        materialCache.removeAll(keepingCapacity: true)

        for var renderable in renderables {
            if let object = renderable as? Object {
                materialCache[object] = renderable.material
                renderable.material = material
                finalScene.attach(object)
            }
        }

        let rpd = MTLRenderPassDescriptor()
        rpd.renderTargetWidth = resolution
        rpd.renderTargetHeight = resolution
        renderer.draw(
            renderPassDescriptor: rpd,
            commandBuffer: commandBuffer,
            scene: finalScene,
            camera: camera
        )

        if let renderTexture = renderTexture,
           var texture = texture
        {
            let srpd = MTLRenderPassDescriptor()
            srpd.renderTargetWidth = resolution
            srpd.renderTargetHeight = resolution
            srpd.colorAttachments[0].texture = renderTexture
            processor.colorTexture = renderer.colorTexture
            processor.depthTexture = renderer.depthTexture
            processor.mesh.material?.set("Near Far", [camera.near, camera.far])
            processor.mesh.material?.set("Color", color)
            processor.draw(renderPassDescriptor: srpd, commandBuffer: commandBuffer)

            if let blurFilter = blurFilter {
                blurFilter.encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: renderTexture,
                    destinationTexture: texture
                )
            }

            if let material = catcher.material as? BasicTextureMaterial {
                material.texture = texture
            }
        }

        for var renderable in renderables {
            if let object = renderable as? Object {
                renderable.material = materialCache[object]
            }
        }
    }

    private func update() {
        updateCamera()
        updateTexture()
        updateBlur()
    }

    private func updateCamera() {
        let objectBounds = object.worldBounds
        let objectSize = objectBounds.size
        let objectCenter = objectBounds.center
        let size = max(objectSize.x, objectSize.z)

        camera.position = objectCenter
        camera.position.y = container.position.y
        camera.orientation = container.orientation
        camera.orientation *= simd_quatf(angle: Float.pi * 0.5, axis: Satin.worldRightDirection)
        camera.update(
            left: -size * 0.5 - padding,
            right: size * 0.5 + padding,
            bottom: -size * 0.5 - padding,
            top: size * 0.5 + padding,
            near: near,
            far: far
        )

        catcher.worldPosition = objectCenter
        catcher.position.y = .zero
        catcher.scale = .init(repeating: size + padding * 2.0)
    }

    private func updateTexture() {
        guard _updateTexture else { return }
        texture = createTexture(
            device: context.device,
            width: resolution,
            height: resolution,
            pixelFormat: .rgba16Float
        )

        renderTexture = createTexture(
            device: context.device,
            width: resolution,
            height: resolution,
            pixelFormat: .rgba16Float
        )

        _updateTexture = false
    }

    private func updateBlur() {
        guard _updateBlur, blurRadius > 0 else { return }
        blurFilter = MPSImageGaussianBlur(device: context.device, sigma: blurRadius)
        _updateBlur = false
    }

    private func createTexture(device: MTLDevice, width: Int, height: Int, pixelFormat: MTLPixelFormat) -> MTLTexture? {
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        descriptor.resourceOptions = .storageModePrivate
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.label = "Shadow Render Target"
        return texture
    }
}
