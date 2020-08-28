# Satin - A 3D Graphics Framework built on Apple's Metal

## About

Satin is a 3D graphics framework (inspired by threejs) that helps designers and developers work with Apple's Metal API. Satin provides helpful classes for creating meshes, materials, buffers, uniforms, geometries, pipelines (shaders), compute kernels, etc and render them on screen or to textures. The api is a constant work in progress, so proceed with caution. There is no documentation, but there are tons of examples that show how to use the APIs.

## Examples

![2D Example](./Images/2DExample.png)
![2D Example](./Images/3DExample.png)
![2D Example](./Images/Cubemap.png)
![2D Example](./Images/CustomGeometry.png)
![2D Example](./Images/DepthMaterial.png)
![2D Example](./Images/ExtrudedTextGeometry.png)
![2D Example](./Images/MatcapMaterial.png)
![2D Example](./Images/ModelLoading.png)
![2D Example](./Images/ParticleSystem.png)
![2D Example](./Images/PhysicallyBasedShading.png)
![2D Example](./Images/TextGeometry.png)


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
