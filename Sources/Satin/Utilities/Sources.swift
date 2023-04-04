//
//  PipelineSources.swift
//  Satin
//
//  Created by Reza Ali on 3/3/23.
//

import Foundation

class PassThroughVertexPipelineSource {
    static let shared = PassThroughVertexPipelineSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard PassThroughVertexPipelineSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesCommonURL("VertexShader.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

class PassThroughShadowPipelineSource {
    static let shared = PassThroughShadowPipelineSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard PassThroughShadowPipelineSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesCommonURL("ShadowShader.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

class ShadowFunctionSource {
    static let shared = ShadowFunctionSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard ShadowFunctionSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesLibraryURL("Shadow.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

class ConstantsSource {
    static let shared = ConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard ConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("Constants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class ComputeConstantsSource {
    static let shared = ComputeConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard ComputeConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("ComputeConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class MeshConstantsSource {
    static let shared = MeshConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard MeshConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("MeshConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexConstantsSource {
    static let shared = VertexConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("VertexConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class FragmentConstantsSource {
    static let shared = FragmentConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard FragmentConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("FragmentConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class PBRConstantsSource {
    static let shared = PBRConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard PBRConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("PBRConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexSource {
    static let shared = VertexSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("Vertex.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexDataSource {
    static let shared = VertexDataSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexDataSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("VertexData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexUniformsSource {
    static let shared = VertexUniformsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("VertexUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class InstanceMatrixUniformsSource {
    static let shared = InstanceMatrixUniformsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard InstanceMatrixUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("InstanceMatrixUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class LightingSource {
    static let shared = LightingSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard LightingSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("LightData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class ShadowDataSource {
    static let shared = ShadowDataSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard ShadowDataSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("ShadowData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class InstancingArgsSource {
    static let shared = InstancingArgsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard InstancingArgsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("InstancingArgs.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}
