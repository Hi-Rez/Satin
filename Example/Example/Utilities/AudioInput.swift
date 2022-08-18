//
//  AudioInout.swift
//  AudioInput
//
//  Created by Reza Ali on 8/4/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Accelerate
import AVFoundation

import Foundation
import Combine

import Satin
import Spectra

protocol AudioInputDelegate: AnyObject {
    func updatedSpectrum(microphone: AudioInput, spectrum: [Float], channel: Int)
}

class AudioInput: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    public weak var delegate: AudioInputDelegate?
    
    var cancellables = Set<AnyCancellable>()
    
    public weak var context: Satin.Context?
    public var texture: MTLTexture?
    
    public var windowTypes: [String] = ["Hanning-N", "Hanning-D", "Hamming", "Blackman", "None"]
    public var rmsTextureTypes: [String] = ["RMS", "RMS-Smoothed", "Normalized-Level", "Separate-Channel"]
    
    public lazy var inputs: [String] = getInputDeviceNames()
    public lazy var input = StringParameter("Input", inputs.first!, inputs, .dropdown)
    public lazy var rmsTextureType = StringParameter("RMS Texture", "rms-smoothed", rmsTextureTypes, .dropdown)
    public lazy var window = StringParameter("Spectrum Filter", "Blackman", windowTypes, .dropdown)
    public lazy var fftSmoothing = FloatParameter("Spectrum Smoothing", 0.975, .slider)
    
    public var max: Float = -Float.infinity
    public var min = Float.infinity
    
    private enum CodingKeys: String, CodingKey {
        case input, window
    }
    
    var numberOfSamples: Int = 0 {
        didSet {
            resizeTexture = true
        }
    }
    
    var numberOfChannels: Int = 0 {
        didSet {
            resizeTexture = true
        }
    }
    
    var bytesPerSample: Int = 4
    
    var resizeTexture: Bool = false
    
    var numberOfSamplesHalf: Int {
        return numberOfSamples / 2
    }
    
    private var audioBuffers: [UnsafeMutablePointer<Float>] = []
    private var rmsBuffers: [UnsafeMutablePointer<Float>] = []
    
    var ffts: [FFT] = []
    
    // MARK: AVFoundation
    
    var captureSession = AVCaptureSession()
    var captureInput: AVCaptureDeviceInput?
    var captureSessionQueue: DispatchQueue!
    lazy var outputData: AVCaptureAudioDataOutput = {
        AVCaptureAudioDataOutput()
    }()
    
    public init(context: Satin.Context) {
        self.context = context
        super.init()
        setup()
    }
    
    public func setup() {
        setupInputList()
        setupPermissions()
        setWindowType()
        setSmoothing()
        setupObservers()
    }
    
    func setupObservers()
    {
        input.$value.sink { [weak self] value in
            guard let self = self else { return }
            if self.input.value != value {
                self.setupCapture()
            }
        }.store(in: &cancellables)
        
        fftSmoothing.$value.sink { [weak self] value in
            self?.setSmoothing()
        }.store(in: &cancellables)
        
        window.$value.sink { [weak self] value in
            self?.setWindowType()
        }.store(in: &cancellables)
    }
    
    func setWindowType() {
        let windowType = getWindowType()
        for fft in ffts {
            fft.windowSequence = windowType
        }
    }
    
    func getWindowType() -> FFT.WindowSequence {
        let type = window.value
        if type == "Hanning-N" {
            return .hanningNormalized
        }
        else if type == "Hanning-D" {
            return .hanningDenormalized
        }
        else if type == "Hamming" {
            return .hamming
        }
        else if type == "Blackman" {
            return .blackman
        }
        return .none
    }
    
    func setSmoothing() {
        for fft in ffts {
            fft.smoothing = fftSmoothing.value
        }
    }
    
    func isPowerOfTwo(_ input: Int) -> Bool {
        if remainderf(Float(input), powf(2.0, logbf(Float(input)))) != 0 {
            return false
        }
        return true
    }
    
    func setupFFT() {
        let lg2 = logbf(Float(numberOfSamples))
        if remainderf(Float(numberOfSamples), powf(2.0, lg2)) != 0 {
            print("Number of samples is not a power of two: \(numberOfSamples)")
        }
        else {
            ffts = []
            for _ in 0..<numberOfChannels {
                if let fft = FFT(samples: numberOfSamples, windowSequence: getWindowType(), smoothing: fftSmoothing.value) {
                    ffts.append(fft)
                }
            }
        }
    }
    
    func setupInputList() {
        inputs = getInputDeviceNames()
    }
    
    func setupPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            setupCapture()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [unowned self] granted in
                if granted {
                    self.setupCapture()
                }
            }
        case .denied:
            AVCaptureDevice.requestAccess(for: .audio) { [unowned self] granted in
                if granted {
                    self.setupCapture()
                }
            }
            return
        case .restricted: // The user can't grant access due to restrictions.
            return
        default:
            return
        }
    }
    
    func stopCapture()
    {
        if captureSession.isRunning, let captureInput = self.captureInput {
            if captureSession.inputs.contains(captureInput) {
                captureSession.beginConfiguration()
                captureSession.removeInput(captureInput)
                captureSession.commitConfiguration()
            }
            captureSession.stopRunning()
        }
    }
    
    func setupCapture() {
        guard let inputDevice = getInputDevice(input.value) else { return }
        
        var newInputCaptureDevice: AVCaptureDeviceInput? = nil
        do {
            newInputCaptureDevice = try AVCaptureDeviceInput(device: inputDevice)
        }
        catch {
            print("Failed to initialized AVCaptureDeviceInput device: \(inputDevice.localizedName)")
        }
                
        guard let newCaptureInput = newInputCaptureDevice else { return }
        
        if let captureInput = self.captureInput, captureSession.inputs.contains(captureInput) {
            captureSession.removeInput(captureInput)
        }
    
        guard captureSession.canAddInput(newCaptureInput) else {
            print("AVCaptureSession unable to add: \(inputDevice.localizedName) as input")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        captureSession.addInput(newCaptureInput)
        captureInput = newCaptureInput
        if captureSession.isRunning {
            captureSession.commitConfiguration()
        }
        else {
            captureSessionQueue = DispatchQueue(label: "AudioSessionQueue", attributes: [])
            outputData.setSampleBufferDelegate(self, queue: captureSessionQueue)
            guard captureSession.canAddOutput(outputData) else { return }
            captureSession.addOutput(outputData)
            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    @objc public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.audioChannels.count > 0 {
            guard let description = CMSampleBufferGetFormatDescription(sampleBuffer), let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(description) else {
                return
            }
            
            let info = asbd.pointee
            
            let channels = Int(info.mChannelsPerFrame)
            if numberOfChannels != channels {
                numberOfChannels = channels
            }
            
            let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
            if isPowerOfTwo(numSamples) {
                if numberOfSamples != numSamples {
                    numberOfSamples = numSamples
                }
            }
            else {
                print("Number of samples is not a power of two: \(numSamples)")
            }
            
            
            
            guard numberOfSamples > 0 else { return }
            if resizeTexture {
                resize()
            }
            
            let bufferlistSize = AudioBufferList.sizeInBytes(maximumBuffers: channels)
            let abl = AudioBufferList.allocate(maximumBuffers: channels)
            
            var block: CMBlockBuffer?
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                bufferListSizeNeededOut: nil,
                bufferListOut: abl.unsafeMutablePointer,
                bufferListSize: bufferlistSize,
                blockBufferAllocator: nil,
                blockBufferMemoryAllocator: nil,
                flags: 0,
                blockBufferOut: &block
            )
            
            let bps = Int(abl[0].mDataByteSize) / numberOfSamples
            if bps != bytesPerSample {
                bytesPerSample = bps
            }
            
            for i in 0..<channels {
                guard let dataPtr = abl[i].mData else {
                    return
                }
                updateTexturePCM(dataPtr, i)
                if ffts.count > i {
                    let fft = ffts[i]
                    fft.forward(audioBuffers[i])
                    updateTextureFFT(fft.getSpectrum(), i)
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for (index, fft) in self.ffts.enumerated() {
                    self.delegate?.updatedSpectrum(microphone: self, spectrum: fft.getSpectrum(), channel: index)
                }
            }
        }
    }
    
    func resize() {
        if numberOfSamples > 0, numberOfChannels > 0 {
            setupBuffers()
            createAudioTexture()
            setupFFT()
        }
        resizeTexture = false
    }
    
    func getInputDevices() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .builtInWideAngleCamera], mediaType: .audio, position: .unspecified)
        return discoverySession.devices
    }
    
    func getInputDeviceNames() -> [String] {
        var results: [String] = []
        let devices = getInputDevices()
        for device in devices {
            results.append(device.localizedName)
        }
        return results
    }
    
    func getInputDevice(_ name: String) -> AVCaptureDevice? {
        let devices = getInputDevices()
        if devices.count == 0 { return nil }
        for device in devices {
            if device.localizedName == input.value {
                return device
            }
        }
        return nil
    }
    
    func setupBuffers() {
        audioBuffers = []
        for _ in 0..<numberOfChannels {
            audioBuffers.append(UnsafeMutablePointer<Float>.allocate(capacity: numberOfSamples))
            rmsBuffers.append(UnsafeMutablePointer<Float>.allocate(capacity: numberOfSamples))
        }
    }
    
    func createAudioTexture() {
        guard let context = self.context else { return }
        
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .r32Float
        descriptor.width = numberOfSamples
        descriptor.height = numberOfChannels * 2
        descriptor.depth = 1
        descriptor.usage = .shaderRead
        
        #if os(macOS)
        descriptor.resourceOptions = .storageModeManaged
        #else
        descriptor.resourceOptions = .storageModeShared
        #endif
        
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        
        guard let tmp = context.device.makeTexture(descriptor: descriptor) else {
            print("Failed to create Audio Texture")
            return
        }
        tmp.label = "Audio Texture"
        
        let width = numberOfSamples
        let height = numberOfChannels * 2
        let bytesPerRow = MemoryLayout<Float>.size * width
        let size = width * height
        var data = [Float](repeating: 0.0, count: size)
        tmp.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: &data, bytesPerRow: bytesPerRow)
        
        texture = tmp
    }

    deinit {
        audioBuffers = []
        outputData.setSampleBufferDelegate(nil, queue: nil)
        stopCapture()
    }
    
    func updateTexturePCM(_ amplitudes: UnsafeRawPointer, _ channel: Int) {
        guard let texture = self.texture else {
            return
        }
        
        let buffer = audioBuffers[channel]
        
        if bytesPerSample == 4 {
            buffer.assign(from: amplitudes.assumingMemoryBound(to: Float.self), count: numberOfSamples)
        }
        else if bytesPerSample == 2 {
            var factor = Float(Int16.max)
            vDSP_vflt16(amplitudes.assumingMemoryBound(to: Int16.self), 1, buffer, 1, vDSP_Length(numberOfSamples))
            vDSP_vsdiv(buffer, 1, &factor, buffer, 1, vDSP_Length(numberOfSamples))
        }
        else {
            print("Unable to convert data")
            return
        }
        
        let region = MTLRegionMake2D(0, channel, numberOfSamples, 1)
        let floatSize = MemoryLayout<Float>.size
        let bytesPerRow = 1 * floatSize * numberOfSamples
        texture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: bytesPerRow)
    }
    
    func updateTextureFFT(_ spectrum: [Float], _ channel: Int) {
        if let texture = self.texture {
            spectrum.withUnsafeBytes { spectrumPtr in
                let region = MTLRegionMake2D(0, numberOfChannels + channel, numberOfSamplesHalf, 1)
                let floatSize = MemoryLayout<Float>.size
                let bytesPerRow = 1 * floatSize * numberOfSamplesHalf
                texture.replace(region: region, mipmapLevel: 0, withBytes: spectrumPtr.baseAddress!, bytesPerRow: bytesPerRow)
            }
        }
    }
}
