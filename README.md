# Satin

## About

Satin is an experimental framework that helps designers and developers work with Apple's Metal API. Satin provides helpful classes for creating meshes, geometries, pipelines (shaders) and render them on screen or to textures. The api is a constant work in progress, so proceed with caution.

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
