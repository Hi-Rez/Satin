//
//  BaseRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation
import Forge
import Satin

class BaseRenderer: Forge.Renderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var dataURL: URL { rendererAssetsURL.appendingPathComponent("Data") }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { rendererAssetsURL.appendingPathComponent("Models") }
    
    deinit {
        print("deinit: \(String(describing: type(of: self)))")
    }
}
