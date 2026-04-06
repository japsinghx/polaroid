import SwiftUI

enum FontStyle: String {
    case handwritten, classic
}

enum FontColor: String {
    case dark, light, faded

    var swiftUIColor: Color {
        switch self {
        case .dark:   return Color.black
        case .light:  return Color.white.opacity(0.8)
        case .faded:  return Color(white: 0.2).opacity(0.55)
        }
    }

    var uiColor: UIColor {
        switch self {
        case .dark:   return UIColor.black
        case .light:  return UIColor(white: 1.0, alpha: 0.8)
        case .faded:  return UIColor(white: 0.2, alpha: 0.55)
        }
    }
}

@MainActor
@Observable
final class StyleSettings {
    var fontStyle: FontStyle {
        didSet { UserDefaults.standard.set(fontStyle.rawValue, forKey: "fontStyle") }
    }
    var fontColor: FontColor {
        didSet { UserDefaults.standard.set(fontColor.rawValue, forKey: "fontColor") }
    }
    var showLocation: Bool {
        didSet { UserDefaults.standard.set(showLocation, forKey: "showLocation") }
    }

    init() {
        fontStyle = FontStyle(rawValue: UserDefaults.standard.string(forKey: "fontStyle") ?? "") ?? .handwritten
        fontColor = FontColor(rawValue: UserDefaults.standard.string(forKey: "fontColor") ?? "") ?? .dark
        showLocation = UserDefaults.standard.object(forKey: "showLocation") as? Bool ?? true
    }
}
