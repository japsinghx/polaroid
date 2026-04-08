import SwiftUI

enum ActiveChip: Equatable {
    case font, color
}

struct CameraChipsView: View {
    @Bindable var settings: StyleSettings
    @Binding var activeChip: ActiveChip?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Chips row
            HStack(spacing: 8) {
                // Font style chip
                ChipButton(
                    label: "Aa",
                    isActive: activeChip == .font
                ) {
                    activeChip = activeChip == .font ? nil : .font
                }

                // Color chip
                ChipButton(
                    label: nil,
                    colorDot: settings.fontColor.swiftUIColor,
                    isActive: activeChip == .color
                ) {
                    activeChip = activeChip == .color ? nil : .color
                }

                // Location toggle chip
                ChipButton(
                    label: settings.showLocation ? "Location on" : "Location off",
                    isActive: false,
                    dimmed: !settings.showLocation
                ) {
                    settings.showLocation.toggle()
                    activeChip = nil
                }
            }
            .padding(.horizontal, 12)

            // Inline picker
            if activeChip == .font {
                FontPickerRow(selected: $settings.fontStyle)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if activeChip == .color {
                ColorPickerRow(selected: $settings.fontColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeChip)
    }
}

// MARK: - Chip Button

private struct ChipButton: View {
    var label: String?
    var colorDot: Color? = nil
    var isActive: Bool
    var dimmed: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let dot = colorDot {
                    Circle()
                        .fill(dot)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                }
                if let label {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isActive ? Color.yellow : Color.white.opacity(dimmed ? 0.4 : 0.9))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.black.opacity(isActive ? 0.6 : 0.35))
                    .overlay(Capsule().stroke(isActive ? Color.yellow.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 0.5))
            )
        }
    }
}

// MARK: - Font Picker Row

private struct FontPickerRow: View {
    @Binding var selected: FontStyle

    var body: some View {
        HStack(spacing: 10) {
            ForEach([FontStyle.handwritten, .classic], id: \.rawValue) { style in
                Button {
                    selected = style
                } label: {
                    Text(style == .handwritten ? "Handwritten" : "Classic")
                        .font(style == .handwritten
                              ? .custom("PermanentMarker-Regular", size: 13)
                              : .system(size: 13, weight: .thin, design: .serif))
                        .foregroundStyle(selected == style ? Color.yellow : Color.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(selected == style ? 0.6 : 0.3))
                                .overlay(Capsule().stroke(selected == style ? Color.yellow.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 0.5))
                        )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Color Picker Row

private struct ColorPickerRow: View {
    @Binding var selected: FontColor

    private let options: [(FontColor, String)] = [(.dark, "Dark"), (.light, "Light"), (.faded, "Faded")]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.0.rawValue) { color, label in
                Button {
                    selected = color
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selected == color ? Color.yellow : Color.white.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(selected == color ? 0.6 : 0.3))
                            .overlay(Capsule().stroke(selected == color ? Color.yellow.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 0.5))
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
