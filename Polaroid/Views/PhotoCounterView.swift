import SwiftUI

struct PhotoCounterView: View {
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            // Film strip dots
            HStack(spacing: 5) {
                ForEach(0..<8, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < count ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 10, height: 14)
                }
            }

            Text("\(count) left")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(count == 0 ? .red : .white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        PhotoCounterView(count: 8)
        PhotoCounterView(count: 3)
        PhotoCounterView(count: 0)
    }
    .padding()
    .background(Color.black)
}
