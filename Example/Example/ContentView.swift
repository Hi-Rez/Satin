//
//  ContentView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Group {
                    NavigationLink(destination: Renderer2DView()) {
                        Label("2D", systemImage: "square")
                    }
                    
                    NavigationLink(destination: Renderer3DView()) {
                        Label("3D", systemImage: "cube")
                    }
                    
                    NavigationLink(destination: TextRendererView()) {
                        Label("Text", systemImage: "textformat")
                    }
                    
                    NavigationLink(destination: OctasphereRendererView()) {
                        Label("Octasphere", systemImage: "globe")
                    }
                    
                    NavigationLink(destination: ExtrudedTextRendererView()) {
                        Label("Extruded Text", systemImage: "square.3.layers.3d.down.right")
                    }
                    
                    NavigationLink(destination: ShippingShadersRendererView()) {
                        Label("Shipping Shaders", systemImage: "shippingbox")
                    }
                    
                    NavigationLink(destination: CameraControllerRendererView()) {
                        Label("Camera Controller", systemImage: "camera.aperture")
                    }
                    
                    NavigationLink(destination: DepthMaterialRendererView()) {
                        Label("Depth Material", systemImage: "rectangle.stack")
                    }
                }
                
                Group {
                    NavigationLink(destination: ExportGeometryRendererView()) {
                        Label("Export Geometry", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: CustomGeometryRendererView()) {
                        Label("Custom Geometry", systemImage: "network")
                    }
                    
                    NavigationLink(destination: BufferComputeRendererView()) {
                        Label("Buffer Compute", systemImage: "aqi.medium")
                    }
                    
                    NavigationLink(destination: FlockingRendererView()) {
                        Label("Flocking Particles", systemImage: "bird")
                    }
                    
                    NavigationLink(destination: TextureComputeRendererView()) {
                        Label("Texture Compute", systemImage: "photo.stack")
                    }
#if os(iOS)
                    NavigationLink(destination: ARRendererView()) {
                        Label("AR", systemImage: "arkit")
                    }
#endif
                    
                    NavigationLink(destination: CubemapRendererView()) {
                        Label("Cubemap", systemImage: "map")
                    }
                }
                
                Group {
                    NavigationLink(destination: MatcapRendererView()) {
                        Label("Matcap", systemImage: "graduationcap")
                    }
                    
                    NavigationLink(destination: LoadObjRendererView()) {
                        Label("Obj Loading", systemImage: "arrow.down.doc")
                    }
                    
                    NavigationLink(destination: PostProcessingRendererView()) {
                        Label("Post Processing", systemImage: "checkerboard.rectangle")
                    }
                    
                    NavigationLink(destination: RayMarchingRendererView()) {
                        Label("Ray Marching", systemImage: "camera.metering.multispot")
                    }
                    
                    NavigationLink(destination: InstancingRendererView()) {
                        Label("Instancing", systemImage: "square.grid.3x3")
                    }
                    
                    NavigationLink(destination: LiveCodeRendererView()) {
                        Label("Live Code", systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: SatinSceneKitRendererView()) {
                        Label("Satin + SceneKit", systemImage: "plus")
                    }

#if os(iOS)
                    NavigationLink(destination: SatinSceneKitARRendererView()) {
                        Label("Satin + SceneKit + AR", systemImage: "arkit")
                    }
#endif
                }

                Group {
                    NavigationLink(destination: FXAARendererView()) {
                        Label("FXAA", systemImage: "squareshape.split.2x2.dotted")
                    }
                    
                    NavigationLink(destination: PBRRendererView()) {
                        Label("Physically Based Rendering", systemImage: "eye")
                    }
                    
                    NavigationLink(destination: VertexAttributesRendererView()) {
                        Label("Custom Vertex Attributes", systemImage: "asterisk.circle")
                    }
                    
                    NavigationLink(destination: AudioInputRendererView()) {
                        Label("Audio Input", systemImage: "mic")
                    }
                }
            }
            .navigationTitle("Satin Examples")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
