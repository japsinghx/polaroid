import UIKit

final class PhotoStorageManager: Sendable {
    static let shared = PhotoStorageManager()

    private var polaroidsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Polaroids", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Saves a photo to disk, returning the relative path from Documents
    func savePhoto(_ image: UIImage) -> String? {
        // Downscale to reasonable size
        let maxDimension: CGFloat = 2000
        let scaled = downscale(image, maxDimension: maxDimension)

        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }

        let filename = "\(UUID().uuidString).jpg"
        let url = polaroidsDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return "Polaroids/\(filename)"
        } catch {
            return nil
        }
    }

    /// Loads a photo from a relative path
    func loadPhoto(path: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes a photo at the given relative path
    func deletePhoto(path: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(path)
        try? FileManager.default.removeItem(at: url)
    }

    private func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension UIImage {
    /// Center-crops to a square at a capped resolution, normalizing orientation to .up.
    /// maxDimension prevents allocating massive bitmaps from full-res camera images.
    func squareCropped(maxDimension: CGFloat = 1200) -> UIImage {
        let s = size
        let minDim = min(s.width, s.height)
        let outputDim = min(minDim, maxDimension)
        let scale = outputDim / minDim
        let drawSize = CGSize(width: s.width * scale, height: s.height * scale)
        let squareSize = CGSize(width: outputDim, height: outputDim)
        let renderer = UIGraphicsImageRenderer(size: squareSize)
        return renderer.image { _ in
            draw(in: CGRect(
                x: -(drawSize.width - outputDim) / 2,
                y: -(drawSize.height - outputDim) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
        }
    }
}
