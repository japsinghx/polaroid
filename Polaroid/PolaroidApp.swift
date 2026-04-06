import SwiftUI
import SwiftData
import CoreText

@main
struct PolaroidApp: App {
    init() {
        registerFonts()
    }

    private func registerFonts() {
        guard let url = Bundle.main.url(forResource: "PermanentMarker-Regular", withExtension: "ttf") else {
            print("❌ Font file not found in bundle")
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        print("✅ Registered font from: \(url)")
    }

    var body: some Scene {
        WindowGroup {
            CameraBodyView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: PolaroidPhoto.self)
    }
}
