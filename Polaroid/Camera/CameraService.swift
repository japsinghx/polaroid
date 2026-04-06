import AVFoundation
import UIKit

@MainActor
@Observable
final class CameraService {
    var isRunning = false
    var currentPosition: AVCaptureDevice.Position = .back
    var capturedImage: UIImage?
    var permissionGranted = false
    var error: String?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.polaroid.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var photoDelegate: PhotoCaptureDelegate?
    private var isConfigured = false

    func requestPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.permissionGranted = granted
                    if granted {
                        self.configureAndStart()
                    }
                }
            }
        default:
            permissionGranted = false
            error = "Camera access denied. Please enable in Settings."
        }
    }

    /// Configure the session and then start it, all on the session queue to avoid race conditions
    private func configureAndStart() {
        sessionQueue.async { [self] in
            session.beginConfiguration()
            session.sessionPreset = .photo

            // Remove existing inputs
            for input in session.inputs {
                session.removeInput(input)
            }

            // Add camera input
            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: currentPosition
            ) else {
                session.commitConfiguration()
                Task { @MainActor in
                    self.error = "No camera available"
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            } catch {
                session.commitConfiguration()
                Task { @MainActor in
                    self.error = "Failed to configure camera: \(error.localizedDescription)"
                }
                return
            }

            // Add photo output
            if session.outputs.isEmpty, session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            session.commitConfiguration()

            // Start running immediately after configuration
            if !session.isRunning {
                session.startRunning()
            }

            Task { @MainActor in
                self.isRunning = true
                self.isConfigured = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [self] in
            if session.isRunning {
                session.stopRunning()
                Task { @MainActor in
                    self.isRunning = false
                }
            }
        }
    }

    func switchCamera() {
        currentPosition = currentPosition == .back ? .front : .back
        configureAndStart()
    }

    func capturePhoto() {
        guard isConfigured else { return }

        // Verify there's an active video connection
        guard let connection = photoOutput.connection(with: .video), connection.isActive else {
            error = "Camera not ready"
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off

        let isFront = currentPosition == .front
        let delegate = PhotoCaptureDelegate(isFrontCamera: isFront) { [weak self] image in
            Task { @MainActor in
                self?.capturedImage = image
            }
        }
        self.photoDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let isFrontCamera: Bool
    private let completion: (UIImage?) -> Void

    init(isFrontCamera: Bool, completion: @escaping (UIImage?) -> Void) {
        self.isFrontCamera = isFrontCamera
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }

        if isFrontCamera {
            // Front camera JPEG is stored mirrored. Flip horizontally to match preview.
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let flipped = renderer.image { _ in
                let context = UIGraphicsGetCurrentContext()!
                context.translateBy(x: image.size.width, y: 0)
                context.scaleBy(x: -1, y: 1)
                image.draw(at: .zero)
            }
            completion(flipped)
        } else {
            completion(image)
        }
    }
}
