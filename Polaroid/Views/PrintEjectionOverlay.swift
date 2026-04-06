import SwiftUI

@MainActor
@Observable
final class PrintViewModel {
    var showPrint = false
    var printOffset: CGFloat = 700
    var developOpacity: Double = 1.0
    var printRotation: Double = 0
    var currentImage: UIImage?
    var captureDate: Date = .now
    var isAnimating = false

    var lastCompletedImage: UIImage?
    var lastCompletedDate: Date = .now
    var currentLocation: String? = nil

    func eject(image: UIImage, location: String? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        currentImage = image
        currentLocation = location
        captureDate = .now
        printRotation = Double.random(in: -4...4)
        printOffset = 700
        developOpacity = 1.0
        showPrint = true

        // Phase 1: Rise from bottom — delayed one frame so the view
        // is in the hierarchy at offset=700 before we animate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                printOffset = 0
            }

            // Phase 2: Develop (white overlay fades out)
            withAnimation(.easeInOut(duration: 2.5).delay(0.8)) {
                developOpacity = 0.0
            }
        }

        // Phase 3: Linger, then exit upward
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { [weak self] in
            guard let self else { return }
            lastCompletedImage = currentImage
            lastCompletedDate = captureDate

            withAnimation(.easeIn(duration: 0.4)) {
                printOffset = -900
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showPrint = false
                self?.isAnimating = false
            }
        }
    }
}

struct PrintEjectionOverlay: View {
    @Bindable var viewModel: PrintViewModel

    var body: some View {
        // Always in the hierarchy — controlled by opacity/offset, not if/else
        // This ensures SwiftUI can animate from the initial state
        ZStack {
            // Dimming backdrop
            Color.black
                .ignoresSafeArea()
                .opacity(viewModel.showPrint ? 0.45 : 0)
                .animation(.easeInOut(duration: 0.4), value: viewModel.showPrint)
                .allowsHitTesting(false)

            if let image = viewModel.currentImage {
                PolaroidPrintView(
                    image: image,
                    date: viewModel.captureDate,
                    developOpacity: viewModel.developOpacity,
                    location: viewModel.currentLocation
                )
                .rotationEffect(.degrees(viewModel.printRotation))
                .offset(y: viewModel.printOffset)
            }
        }
        .allowsHitTesting(viewModel.showPrint)
    }
}
