# Satin - A 3D Graphics Framework built on Apple's Metal

## About

Satin is a 3D graphics framework (inspired by threejs) that helps designers and developers work with Apple's Metal API. Satin provides helpful classes for creating meshes, materials, buffers, uniforms, geometries, pipelines (shaders), compute kernels, etc and render them on screen or to textures. The api is a constant work in progress, so proceed with caution. There is no documentation, but there are tons of examples that show how to use the APIs.

## Examples

<img src="./Images/2DExample.png" width="25%"><img src="./Images/3DExample.png" width="25%"><img src="./Images/Cubemap.png" width="25%"><img src="./Images/CustomGeometry.png" width="25%"><img src="./Images/DepthMaterial.png" width="25%"><img src="./Images/ExtrudedTextGeometry.png" width="25%"><img src="./Images/MatcapMaterial.png" width="25%"><img src="./Images/ModelLoading.png" width="25%"><img src="./Images/ParticleSystem.png" width="25%"><img src="./Images/PhysicallyBasedShading.png" width="25%"><img src="./Images/TextGeometry.png" width="25%">

## Getting Started

Install Bundler using:

```
[sudo] gem install bundler
```

Install the Bundler dependencies specified in the Gemfile:

If not already in the Example folder
```
cd Example/
```

Config Bundler and Install

```
bundle config set path vendor/bundle
bundle install
```

Install the CocoaPod dependencies using Bundler:

```
bundle exec pod install
```

Finally, make sure to open the xcode workspace not the xcode project:

```
open Example.xcworkspace/
```
