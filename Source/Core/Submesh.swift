//
//  Submesh.swift
//  Satin-iOS
//
//  Created by Reza Ali on 5/25/20.
//

import Metal

open class Submesh {
    public var label: String = "Submesh"
    open var context: Context? {
        didSet {
            if context != nil {
                setup()
            }
        }
    }

    public var visible: Bool = true
    public var indexCount: Int {
        return indexData.count
    }
    public var indexType: MTLIndexType = .uint32
    public var indexBuffer: MTLBuffer?
    public var indexData: [UInt32] = [] {
        didSet {
            if context != nil {
                setup()
            }
        }
    }
    
    public init(indexData:[UInt32], indexBuffer: MTLBuffer) {
        self.indexData = indexData
        self.indexBuffer = indexBuffer
    }
    
    weak var parent: Mesh!
    
    func setup()
    {
        if indexBuffer == nil {
            setupIndexBuffer()
        }        
    }
    
    func setupIndexBuffer() {
         guard let context = self.context else { return }
         let device = context.device
         if !indexData.isEmpty {
             let indicesSize = indexData.count * MemoryLayout.size(ofValue: indexData[0])
             indexBuffer = device.makeBuffer(bytes: indexData, length: indicesSize, options: [])
             indexBuffer?.label = "Indices"
         }
         else {
             indexBuffer = nil
         }
     }
}
