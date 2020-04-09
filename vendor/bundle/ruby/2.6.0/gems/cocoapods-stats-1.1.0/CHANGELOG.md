# CocoaPods Stats CHANGELOG

## 1.1.0 (2019-01-24)

##### Enhancements

* Networking requests are sent on a forked process.  
  [Eric Amorde](https://github.com/amorde)

##### Bug Fixes

* None.  


## 1.0.0 (2016-05-10)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.0.0.rc.1 (2016-04-30)

##### Enhancements

* None.  

##### Bug Fixes

* None.  


## 1.0.0.beta.4 (2016-04-14)

##### Bug Fixes

* Compatibility with CocoaPods 1.0.0.beta.7.  
  [Samuel Giddins](https://github.com/segiddins)


## 1.0.0.beta.3 (2016-01-16)

##### Bug Fixes

* Introduce a compatibility shim for CocoaPods 0.39.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4741](https://github.com/CocoaPods/CocoaPods/issues/4741)


## 1.0.0.beta.2 (2016-01-05)

##### Enhancements

* Speed up stats collection by not re-opening every user Xcode project.  
  [Samuel Giddins](https://github.com/segiddins)


## 1.0.0.beta.1 (2015-12-30)

This version contains no changes.  


## 0.6.2 (2015-10-05)

##### Bug Fixes

* Don't crash when a source has no URL.  
  [Samuel Giddins](https://github.com/segiddins)
  [CocoaPods#4093](https://github.com/CocoaPods/CocoaPods/issues/4093)
  [CocoaPods#4311](https://github.com/CocoaPods/CocoaPods/issues/4311)


## 0.6.1 (2015-08-28)

##### Bug Fixes

* This release fixes a file permissions error when using the RubyGem.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.6.0 (2015-08-26)

##### Enhancements

* Send stats to the API asynchronously and out of process.  
  [Samuel Giddins](https://github.com/segiddins)

* Set maximum timeout of 30 seconds for asynchronous stats sending.  
  [Boris Bügling](https://github.com/neonichu)


## 0.5.3 (2015-07-02)

##### Bug Fixes

* Don't raise an exception when there's no user project to pull targets from.  
  [Samuel Giddins](https://github.com/segiddins)


## 0.5.2 (2015-07-01)

##### Bug Fixes

* Don't raise an exception when attempting to opt out.  
  [Samuel Giddins](https://github.com/segiddins)

## 0.5.1 (2015-07-01)

##### Bug Fixes

* Skips pods that are not integrated ( and thus we can't get UUIDs )
  [Samuel Giddins](https://github.com/CocoaPods/cocoapods-stats/pull/15)


## 0.5.0 (2015-06-24)

* Initial implementation of stats uploading.  
  [Orta](https://github.com/orta)

* Refactor of Orta's initial implementation
  [Segiddins](https://github.com/segiddins)
