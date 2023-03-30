# ``Satin``

Here is a summary of what Satin has to offer!

## Overview

Here is a longer description of what Satin provides. 

## Topics

### Core

- ``Camera``
- ``Context``
- ``Geometry``
- ``Renderer``
- ``Material``
- ``Object``
- ``Shader``

### Objects

- ``Scene``
- ``InstancedMesh``
- ``Mesh``
- ``Submesh``

### Buffers

- ``InstanceMatrixUniformBuffer``
- ``StructBuffer``
- ``UniformBuffer``
- ``VertexUniformBuffer``

### Camera Controllers

- ``CameraControllerState``
- ``CameraController``
- ``PerspectiveCameraController``
- ``OrthographicCameraController``

### Cameras

- ``Camera``
- ``PerspectiveCamera``
- ``OrthographicCamera``

### Compute

- ``BufferComputeSystemDelegate``
- ``BufferComputeSystem``
- ``LiveBufferComputeSystem``
- ``TextureComputeSystemDelegate``
- ``TextureComputeSystem``
- ``LiveTextureComputeSystem``

### Constants

- ``PBRTextureIndex``
- ``PBRSamplerIndex``

- ``VertexAttribute``
- ``VertexBufferIndex``
- ``VertexTextureIndex``

- ``FragmentConstantIndex``
- ``FragmentBufferIndex``
- ``FragmentTextureIndex``
- ``FragmentSamplerIndex``

- ``ComputeBufferIndex``
- ``ComputeTextureIndex``

- ``ObjectBufferIndex``
- ``MeshBufferIndex``

### Generators

- ``BrdfGenerator``
- ``CubemapGenerator``
- ``DiffuseIBLGenerator``
- ``SpecularIBLGenerator``
- ``RandomNoiseGenerator``

### Geometries

- ``ArcGeometry``
- ``BoxGeometry``
- ``CapsuleGeometry``
- ``CircleGeometry``
- ``ConeGeometry``
- ``CylinderGeometry``
- ``ExtrudedRoundedRectGeometry``
- ``ExtrudedTextGeometry``
- ``IcoSphereGeometry``
- ``OctaSphereGeometry``
- ``ParametricGeometry``
- ``PlaneGeometry``
- ``PointGeometry``
- ``QuadGeometry``
- ``RoundedBoxGeometry``
- ``RoundedRectGeometry``
- ``SkyboxGeometry``
- ``SphereGeometry``
- ``SquircleGeometry``
- ``TextGeometry``
- ``TorusGeometry``
- ``TriangleGeometry``
- ``TubeGeometry``

### Lights

- ``Light``
- ``LightType``
- ``LightData``

- ``DirectionalLight``
- ``PointLight``
- ``SpotLight``

### Shadows

- ``Shadow``
- ``ShadowData``
- ``DirectionalLightShadow``

### Shaders

- ``LiveShader``
- ``SourceShader``
- ``PBRShader``
- ``PhysicalShader``
- ``StandardShader``

### Materials

- ``Blending``
- ``DepthBias``

- ``MaterialType``
- ``AnyMaterial``
- ``MaterialDelegate``

- ``BasicColorMaterial``
- ``BasicDiffuseMaterial``
- ``BasicPointMaterial``
- ``BasicTextureMaterial``
- ``DepthMaterial``
- ``LiveMaterial``
- ``MatCapMaterial``
- ``NormalColorMaterial``
- ``PhysicalMaterial``
- ``ShadowMaterial``
- ``SkyboxMaterial``
- ``SourceMaterial``
- ``StandardMaterial``
- ``UvColorMaterial``

### Parameters

- ``ControlType``
- ``ParameterType``
- ``Parameter``
- ``ParameterDelegate``
- ``AnyParameter``
- ``ValueParameter``
- ``ValueParameterWithMinMax``
- ``ParameterGroup``
- ``ParameterGroupDelegate``
- ``GenericParameter``
- ``GenericParameterWithMinMax``
- ``BoolParameter``
- ``UInt32Parameter``
- ``IntParameter``
- ``Int2Parameter``
- ``Int3Parameter``
- ``Int4Parameter``
- ``FloatParameter``
- ``Float2Parameter``
- ``Float3Parameter``
- ``Float4Parameter``
- ``DoubleParameter``
- ``PackedFloat3Parameter``
- ``Float2x2Parameter``
- ``Float3x3Parameter``
- ``Float4x4Parameter``
- ``StringParameter``

### Protocols

- ``Renderable``

### Uniforms

- ``InstanceMatrixUniforms``
- ``VertexUniforms``

### Globals

- ``SatinModelIOVertexDescriptor``
- ``SatinVertexDescriptor``
- ``maxBuffersInFlight``
- ``worldForwardDirection``
- ``worldUpDirection``
- ``worldRightDirection``

### Raycasting

- ``Ray``
- ``IntersectionResult``
- ``RaycastResult``
- ``raycast(ray:object:recursive:invisible:)``
- ``raycast(ray:objects:recursive:invisible:)``
- ``raycast(camera:coordinate:object:recursive:invisible:)``
- ``raycast(camera:coordinate:objects:recursive:invisible:)``
- ``raycast(origin:direction:object:recursive:invisible:)``
- ``raycast(origin:direction:objects:recursive:invisible:)``

### Utilities

- ``PostProcessor``

### File Watcher

- ``FileWatcherDelegate``
- ``FileWatcher``

### Metal File Compiler

- ``MetalFileCompilerError``
- ``MetalFileCompiler``

### Parsers

- ``parseStruct(source:key:)``
- ``parseParameters(source:key:)``
- ``parseParameters(bufferStruct:)``

### Paths

- ``getResourceURL()``
- ``getResourceURL(_:)``
- ``getPipelinesURL()``
- ``getPipelinesURL(_:)``
- ``getPipelinesLibraryURL()``
- ``getPipelinesLibraryURL(_:)``
- ``getPipelinesChunksURL()``
- ``getPipelinesChunksURL(_:)``
- ``getPipelinesSatinURL()``
- ``getPipelinesSatinURL(_:)``
- ``getPipelinesCommonURL()``
- ``getPipelinesCommonURL(_:)``
- ``getPipelinesMaterialsURL()``
- ``getPipelinesMaterialsURL(_:)``
- ``getPipelinesComputeURL()``

### Image & Texture Loaders

- ``loadImage(url:)``
- ``loadHDR(_:_:)``
- ``loadCubemap(_:_:_:_:)``

### Bounding Volume Hierarchy

- ``BVH``
- ``BVHNode``
- ``createBVH(_:_:)``
- ``freeBVH(_:)``

### Computational Geometry

- ``Rectangle``
- ``rectangleCorner(_:_:)``

- ``createRectangle()``
- ``expandRectangle(_:_:)``
- ``expandRectangleInPlace(_:_:)``

- ``mergeRectangle(_:_:)``
- ``mergeRectangleInPlace(_:_:)``

- ``rectangleContainsPoint(_:_:)``
- ``rectangleContainsRectangle(_:_:)``
- ``rectangleIntersectsRectangle(_:_:)``

- ``Bounds``
- ``boundsCorner(_:_:)``
- ``computeBoundsFromVertices(_:_:)``
- ``computeBoundsFromVerticesAndTransform(_:_:_:)``

- ``createBounds()``
- ``expandBounds(_:_:)``
- ``expandBoundsInPlace(_:_:)``

- ``mergeBounds(_:_:)``
- ``mergeBoundsInPlace(_:_:)``

- ``projectBoundsToRectangle(_:_:)``
- ``transformBounds(_:_:)``

### Curves

- ``Polyline2D``
- ``Polyline3D``

- ``freePolyline2D(_:)``
- ``addPointToPolyline2D(_:_:)``
- ``removeFirstPointInPolyline2D(_:)``
- ``removeLastPointInPolyline2D(_:)``
- ``appendPolyline2D(_:_:)``
- ``getLinearPath2(_:_:_:)``
- ``getAdaptiveLinearPath2(_:_:_:)``
- ``quadraticBezier2(_:_:_:_:)``
- ``quadraticBezierVelocity2(_:_:_:_:)``
- ``quadraticBezierAcceleration2(_:_:_:_:)``
- ``quadraticBezierCurvature2(_:_:_:_:)``
- ``getQuadraticBezierPath2(_:_:_:_:)``
- ``getAdaptiveQuadraticBezierPath2(_:_:_:_:)``
- ``cubicBezier1(_:_:_:_:_:)``
- ``cubicBezier2(_:_:_:_:_:)``
- ``cubicBezierVelocity2(_:_:_:_:_:)``
- ``cubicBezierAcceleration2(_:_:_:_:_:)``
- ``cubicBezierCurvature2(_:_:_:_:_:)``
- ``getCubicBezierPath2(_:_:_:_:_:)``
- ``getAdaptiveCubicBezierPath2(_:_:_:_:_:)``
- ``quadraticBezier3(_:_:_:_:)``
- ``cubicBezier3(_:_:_:_:_:)``
- ``freePolyline3D(_:)``
- ``convertPolyline2DToPolyline3D(_:)``

### Scene Graph Functions 

- ``getMeshes(_:_:_:)``
- ``getRenderables(_:_:_:)``
- ``getLights(_:_:_:)``

### Intersection Functions

- ``rayBoundsIntersect(_:_:)``
- ``rayBoundsIntersection(_:_:_:_:)``
- ``rayPlaneIntersection(_:_:_:_:_:)``
- ``rayPlaneIntersectionTime(_:_:_:_:_:)``
- ``rayRayIntersection2(_:_:_:_:_:)``
- ``raySphereIntersection(_:_:_:_:_:)``

- ``rayTriangleIntersect(_:_:_:_:_:_:_:_:_:)``
- ``rayTriangleIntersection(_:_:_:_:_:_:_:_:)``
- ``rayTriangleIntersectionTime(_:_:_:_:_:)``

### Matrix Functions

- ``scaleMatrix3f(_:)``
- ``scaleMatrixf(_:_:_:)``
- ``translationMatrix3f(_:)``
- ``translationMatrixf(_:_:_:)``

### Camera Projections

- ``lookAtMatrix3f(_:_:_:)``
- ``frustrumMatrixf(_:_:_:_:_:_:)``
- ``orthographicMatrixf(_:_:_:_:_:_:)``
- ``perspectiveMatrixf(_:_:_:_:)``

### Conversion Functions

- ``radToDeg(_:)``
- ``degToRad(_:)``
- ``remap(_:_:_:_:_:)``

### Computational Geometry Functions 

- ``greaterThanZero(_:)``
- ``isZero(_:)``
- ``area2(_:_:_:)``
- ``cross2(_:_:)``
- ``isLeft(_:_:_:)``
- ``isLeftOn(_:_:_:)``
- ``inCone(_:_:_:_:)``
- ``isEqual(_:_:)``
- ``isEqual2(_:_:)``
- ``isDiagonalie(_:_:_:_:)``
- ``isDiagonal(_:_:_:_:)``
- ``isClockwise(_:_:)``
- ``isColinear2(_:_:_:)``
- ``isColinear3(_:_:_:)``
- ``isBetween(_:_:_:)``
- ``intersectsProper(_:_:_:_:)``
- ``intersects(_:_:_:_:)``
- ``projectPointOnPlane(_:_:_:)``
- ``projectedPointOnLine2(_:_:_:)``
- ``pointLineDistance2(_:_:_:)``
- ``pointLineDistance3(_:_:_:)``
- ``angle2(_:)``
- ``angle(_:_:)``
- ``getBarycentricCoordinates(_:_:_:_:)``

### Extrude & Triangulation Functions

- ``extrudePaths(_:_:_:_:)``
- ``triangulate(_:_:_:_:)``
- ``triangulateMesh(_:_:_:_:_:_:_:)``

### Geometry Generation Functions

- ``generateBoxGeometryData(_:_:_:_:_:_:_:_:_:)``
- ``generateCapsuleGeometryData(_:_:_:_:_:_:)``
- ``generateConeGeometryData(_:_:_:_:_:)``
- ``generateCylinderGeometryData(_:_:_:_:_:)``
- ``generatePlaneGeometryData(_:_:_:_:_:_:)``
- ``generateArcGeometryData(_:_:_:_:_:_:)``
- ``generateTorusGeometryData(_:_:_:_:)``
- ``generateSkyboxGeometryData(_:)``
- ``generateCircleGeometryData(_:_:_:)``
- ``generateTriangleGeometryData(_:)``
- ``generateQuadGeometryData(_:)``
- ``generateSphereGeometryData(_:_:_:)``
- ``generateIcoSphereGeometryData(_:_:)``
- ``generateOctaSphereGeometryData(_:_:)``
- ``generateSquircleGeometryData(_:_:_:_:)``
- ``generateRoundedRectGeometryData(_:_:_:_:_:_:_:)``
- ``generateExtrudedRoundedRectGeometryData(_:_:_:_:_:_:_:_:_:)``
- ``generateTubeGeometryData(_:_:_:_:_:_:)``
- ``generateRoundedBoxGeometryData(_:_:_:_:_:)``

### Geometry Data

- ``Vertex``
- ``GeometryData``
- ``createGeometryData()``
- ``freeGeometryData(_:)``

- ``TriangleIndices``

- ``TriangleFaceMap``
- ``createTriangleFaceMap()``
- ``freeTriangleFaceMap(_:)``

- ``copyGeometryVertexData(_:_:_:_:)``
- ``copyGeometryIndexData(_:_:_:_:)``
- ``copyGeometryData(_:_:)``
- ``addTrianglesToGeometryData(_:_:_:)``
- ``combineGeometryData(_:_:)``
- ``combineAndOffsetGeometryData(_:_:_:)``
- ``combineAndScaleGeometryData(_:_:_:)``
- ``combineAndScaleAndOffsetGeometryData(_:_:_:_:)``
- ``combineAndTransformGeometryData(_:_:_:)``
- ``computeNormalsOfGeometryData(_:)``
- ``reverseFacesOfGeometryData(_:)``
- ``transformVertices(_:_:_:)``
- ``transformGeometryData(_:_:)``
- ``deindexGeometryData(_:_:)``
- ``unrollGeometryData(_:_:)``
- ``combineGeometryDataAndTriangleFaceMap(_:_:_:_:_:)``
