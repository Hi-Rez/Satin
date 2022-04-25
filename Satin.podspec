Pod::Spec.new do |spec|
  spec.name                   = "Satin"
  spec.version                = "2.1.0"
  spec.summary                = "Satin is a Swift based creative coding toolkit built on top of Metal"
  spec.description            = <<-DESC
  Satin is a swift based creative coding toolkit built on top of Metal. Satin contains classes & helpers that make create graphics with Metal fun and fast!
                   DESC
  spec.homepage               = "https://github.com/Hi-Rez/Satin"
  spec.license                = { :type => "MIT", :file => "LICENSE" }
  spec.author                 = { "Reza Ali" => "reza@hi-rez.io" }
  spec.social_media_url       = "https://twitter.com/rezaali"
  spec.source                 = { :git => "https://github.com/Hi-Rez/Satin.git", :tag => spec.version.to_s }

  spec.osx.deployment_target  = "10.15"
  spec.ios.deployment_target  = "13.0"
  spec.tvos.deployment_target = "13.0"

  spec.public_header_files    = ["Sources/SatinCore/*.h"]

  spec.source_files           = "Sources/SatinCore/*.h",
                                "Sources/SatinCore/**/*.{h,c}",
                                "Sources/Satin/**/*.swift"

  spec.exclude_files          = ["Sources/Satin/Pipelines/**/**/*.metal", "Sources/Satin/Export.swift"]
  spec.resources              = "Sources/Satin/Pipelines"
  spec.frameworks             = "Metal", "MetalKit"
  spec.module_name            = "Satin"
  spec.swift_version          = "5.1"
end
