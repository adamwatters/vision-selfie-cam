import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import RealityKit
import CoreML
import CoreMedia
import Vision

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var texture: MaterialParameters.Texture?
    @Published var opacityTexture: MaterialParameters.Texture?
    private var permissionGranted = true
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    
    override init() {
        super.init()
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.permissionGranted = true
                
            case .notDetermined: // The user has not yet been asked for camera access.
                self.requestPermission()
                
        // Combine the two other cases into the default case
        default:
            self.permissionGranted = false
        }
    }
    
    func requestPermission() {
        // Strong reference not a problem here but might become one in the future.
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard permissionGranted else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: AVCaptureDevice.systemPreferredCamera!)
            captureSession.addInput(input)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
            captureSession.addOutput(videoOutput)
        } catch {
            print(error)
        }
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var result = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        guard var ciImage = result else { return }
        var cgImage: CGImage?
        var opactiyCgImage: CGImage?
        var maskImage = CIImage.empty()
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        if let foregroundResult = request.results?.first {
            print("here")
            if let pixelBuffer = try? foregroundResult.generateScaledMaskForImage(forInstances: foregroundResult.allInstances, from: handler) {
                maskImage = CIImage(cvPixelBuffer: pixelBuffer)
//                cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            }
        }
    
        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.maskImage = maskImage
        filter.backgroundImage = CIImage.empty()
        var filteredCIImage = filter.outputImage
        
        if let filteredCIImage {
            cgImage = context.createCGImage(filteredCIImage, from: filteredCIImage.extent)!
            opactiyCgImage = context.createCGImage(maskImage, from: maskImage.extent)
        }
        
        guard let cgImage, let opactiyCgImage else {return}
        
        do {
            let texture = try MaterialParameters.Texture.init(TextureResource.generate(from: cgImage, options: .init(semantic: .raw)))
            let opacityTexture = try MaterialParameters.Texture.init(TextureResource.generate(from: opactiyCgImage, options: .init(semantic: .raw)))
            DispatchQueue.main.async { [unowned self] in
                self.texture = texture
                self.opacityTexture = opacityTexture
            }
        } catch {
            print("error")
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return ciImage
    }
    
}
