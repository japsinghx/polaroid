import SwiftUI
import SwiftData

struct CameraBodyView: View {
    @State private var cameraService = CameraService()
    @State private var printViewModel = PrintViewModel()
    @State private var soundManager = SoundManager()
    @State private var locationManager = LocationManager()
    @State private var showGallery = false
    @State private var showFlash = false
    @State private var flipRotation: Double = 0
    @State private var lastPhotoImage: UIImage? = nil
    @AppStorage("remainingShots") private var remainingShots = 8

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PolaroidPhoto.captureDate, order: .reverse)
    private var photos: [PolaroidPhoto]

    private var filmFull: Bool { photos.count >= 8 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Camera preview area
                ZStack {
                    CameraPreviewView(session: cameraService.session)
                        .opacity(cameraService.isRunning ? 1 : 0)

                    // Top bar overlay
                    VStack {
                        HStack {
                            Spacer()
                            PhotoCounterView(count: max(0, 8 - photos.count))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Spacer()

                        // Film full banner
                        if filmFull {
                            Text("Film full — save photos and clear to shoot more")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.bottom, 12)
                        }
                    }
                }

                // White Polaroid-style bottom strip
                BottomBarView(
                    onCapture: capturePhoto,
                    onGallery: { showGallery = true },
                    onFlip: {
                        flipRotation += 180
                        cameraService.switchCamera()
                    },
                    lastPhoto: lastPhotoImage,
                    filmFull: filmFull,
                    flipRotation: flipRotation
                )
            }

            // Print ejection overlay
            PrintEjectionOverlay(viewModel: printViewModel)

            // Flash effect
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            cameraService.requestPermissionAndStart()
            soundManager.prepare()
            locationManager.requestPermission()
        }
        .onChange(of: photos.first?.id) { _, _ in
            guard let path = photos.first?.imagePath else {
                lastPhotoImage = nil
                return
            }
            Task.detached(priority: .userInitiated) {
                let img = PhotoStorageManager.shared.loadPhoto(path: path)
                await MainActor.run { lastPhotoImage = img }
            }
        }
        .onChange(of: printViewModel.showPrint) { oldValue, newValue in
            if oldValue && !newValue, let image = printViewModel.lastCompletedImage {
                let date = printViewModel.lastCompletedDate
                let location = printViewModel.currentLocation
                let path = PhotoStorageManager.shared.savePhoto(image)
                if let path {
                    let photo = PolaroidPhoto(captureDate: date, imagePath: path, location: location)
                    modelContext.insert(photo)
                }
                printViewModel.lastCompletedImage = nil
            }
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .sheet(isPresented: $showGallery) {
            GalleryView()
        }
        .onChange(of: cameraService.capturedImage) { _, newImage in
            guard let image = newImage else { return }
            cameraService.capturedImage = nil
            soundManager.playPrintEject()
            let location = locationManager.cityName
            Task.detached(priority: .userInitiated) {
                let cropped = image.squareCropped()
                await MainActor.run {
                    printViewModel.eject(image: cropped, location: location)
                }
            }
        }
    }

    private func capturePhoto() {
        guard !printViewModel.isAnimating, !filmFull else { return }

        // Flash
        showFlash = true
        withAnimation(.easeOut(duration: 0.15)) {
            showFlash = false
        }

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        soundManager.playShutter()
        cameraService.capturePhoto()
    }
}

#Preview {
    CameraBodyView()
        .modelContainer(for: PolaroidPhoto.self, inMemory: true)
}
