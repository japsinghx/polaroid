import Foundation
import SwiftData

@Model
final class PolaroidPhoto {
    var id: UUID
    var captureDate: Date
    var imagePath: String
    var isFavorite: Bool
    var location: String?
    var customMessage: String?

    init(captureDate: Date = .now, imagePath: String, location: String? = nil) {
        self.id = UUID()
        self.captureDate = captureDate
        self.imagePath = imagePath
        self.isFavorite = false
        self.location = location
    }
}
