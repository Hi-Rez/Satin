Pod::Spec.new do |spec|
  spec.name                   = "Satin"
  spec.version                = "0.1.8"
  spec.summary                = "Satin is a Swift based creative coding toolkit built on top of Metal"
  spec.description            = <<-DESC
  Satin is a swift based creative coding toolkit built on top of Metal. Satin contains classes & helpers that make create graphics with Metal fun and fast!
                   DESC
  spec.homepage               = "https://github.com/Hi-Rez/Satin"
  spec.license                = { :type => "MIT", :file => "LICENSE" }
  spec.author                 = { "Reza Ali" => "reza@hi-rez.io" }
  spec.social_media_url       = "https://twitter.com/rezaali"
  spec.source                 = { :git => "https://github.com/Hi-Rez/Satin.git", :tag => spec.version.to_s }

  spec.osx.deployment_target  = "10.14"
  spec.ios.deployment_target  = "12.4"
  spec.tvos.deployment_target = "12.4"

  spec.source_files           = "Satin/*.h", "Satin/**/*.{h,m,swift}"
  spec.exclude_files          = "Pipelines/**/**/*.metal"
  spec.resources              = "Pipelines"
  spec.frameworks             = "Metal", "MetalKit"
  spec.module_name            = "Satin"
  spec.swift_version          = "5.1"
end
