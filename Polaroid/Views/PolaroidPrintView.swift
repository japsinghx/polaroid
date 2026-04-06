import SwiftUI

struct PolaroidPrintView: View {
    let image: UIImage
    let date: Date
    var developOpacity: Double = 0.0
    var location: String? = nil

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo with developing overlay
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipped()

                // "Developing" chemical overlay
                Rectangle()
                    .fill(Color(white: 0.95))
                    .opacity(developOpacity)
            }
            .frame(width: 280, height: 280)
            .padding(.top, 16)
            .padding(.horizontal, 16)

            // Bottom border — light, personal handwritten feel
            HStack(alignment: .bottom) {
                if let location {
                    Text(location)
                        .font(.custom("PermanentMarker-Regular", size: 15))
                        .foregroundStyle(Color(white: 0.2).opacity(0.55))
                }

                Spacer()

                Text(dateString)
                    .font(.custom("PermanentMarker-Regular", size: 15))
                    .foregroundStyle(Color(white: 0.2).opacity(0.55))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .frame(width: 312)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

#Preview {
    PolaroidPrintView(
        image: UIImage(systemName: "photo.fill")!,
        date: .now,
        developOpacity: 0.0,
        location: "New York"
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
