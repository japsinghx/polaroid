import SwiftUI
import SwiftData

struct GalleryView: View {
    let styleSettings: StyleSettings

    @Query(sort: \PolaroidPhoto.captureDate, order: .reverse)
    private var photos: [PolaroidPhoto]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showClearAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if photos.isEmpty {
                    ContentUnavailableView(
                        "No Polaroids Yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Take some photos to see them here")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(photos, id: \.id) { photo in
                                NavigationLink {
                                    PhotoDetailView(photo: photo, styleSettings: styleSettings)
                                } label: {
                                    GalleryThumbnail(photo: photo, styleSettings: styleSettings)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Film Roll (\(photos.count)/8)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !photos.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear Film", role: .destructive) {
                            showClearAlert = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .alert("Clear Film Roll?", isPresented: $showClearAlert) {
                Button("Clear All", role: .destructive) { clearAllPhotos() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Make sure you've saved your photos to your camera roll first. This cannot be undone.")
            }
        }
    }

    private func clearAllPhotos() {
        for photo in photos {
            PhotoStorageManager.shared.deletePhoto(path: photo.imagePath)
            modelContext.delete(photo)
        }
    }
}

// MARK: - Thumbnail

struct GalleryThumbnail: View {
    let photo: PolaroidPhoto
    let styleSettings: StyleSettings
    @State private var thumbnail: UIImage? = nil

    private var leftText: String? {
        if let msg = photo.customMessage, !msg.isEmpty { return msg }
        return styleSettings.showLocation ? photo.location : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.gray.opacity(0.15)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 8)

            HStack(alignment: .bottom) {
                if let left = leftText {
                    Text(left)
                        .font(styleSettings.fontStyle == .handwritten
                              ? .custom("PermanentMarker-Regular", size: 10)
                              : .system(size: 9, weight: .thin, design: .serif))
                        .foregroundStyle(styleSettings.fontColor.swiftUIColor)
                        .lineLimit(1)
                }
                Spacer()
                Text(formattedDate)
                    .font(styleSettings.fontStyle == .handwritten
                          ? .custom("PermanentMarker-Regular", size: 10)
                          : .system(size: 9, weight: .thin, design: .serif))
                    .foregroundStyle(styleSettings.fontColor.swiftUIColor)
            }
            .padding(.horizontal, 10)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .task {
            guard thumbnail == nil else { return }
            let path = photo.imagePath
            thumbnail = await Task.detached(priority: .userInitiated) {
                PhotoStorageManager.shared.loadPhoto(path: path)?.squareCropped()
            }.value
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: photo.captureDate)
    }
}

// MARK: - Detail View

struct PhotoDetailView: View {
    @Bindable var photo: PolaroidPhoto
    let styleSettings: StyleSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var image: UIImage? = nil
    @State private var isEditingMessage = false
    @State private var messageInput = ""

    private var leftText: String? {
        if let msg = photo.customMessage, !msg.isEmpty { return msg }
        return styleSettings.showLocation ? photo.location : nil
    }

    var body: some View {
        VStack {
            Spacer()

            if let image {
                ZStack(alignment: .bottomLeading) {
                    PolaroidPrintView(
                        image: image,
                        date: photo.captureDate,
                        leftText: leftText,
                        fontStyle: styleSettings.fontStyle,
                        fontColor: styleSettings.fontColor
                    )

                    // Tap zone over the left text area to edit custom message
                    if !isEditingMessage {
                        Color.clear
                            .frame(width: 160, height: 48)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                messageInput = photo.customMessage ?? ""
                                isEditingMessage = true
                            }
                    }
                }

                if isEditingMessage {
                    HStack {
                        TextField("Add a message...", text: $messageInput)
                            .font(.custom("PermanentMarker-Regular", size: 15))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .submitLabel(.done)
                            .onSubmit { saveMessage() }

                        Button("Save") { saveMessage() }
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Hint to tap
                    let hint = (photo.customMessage == nil || photo.customMessage!.isEmpty)
                        ? "Tap left corner to add a message"
                        : nil
                    if let hint {
                        Text(hint)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(white: 0.5))
                            .padding(.top, 6)
                    }
                }

                Spacer()

                HStack(spacing: 40) {
                    Button { showShareSheet = true } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .padding(.bottom, 40)
            } else {
                ProgressView()
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditingMessage)
        .task {
            let path = photo.imagePath
            image = await Task.detached(priority: .userInitiated) {
                PhotoStorageManager.shared.loadPhoto(path: path)?.squareCropped()
            }.value
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Polaroid?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                PhotoStorageManager.shared.deletePhoto(path: photo.imagePath)
                modelContext.delete(photo)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This photo will be permanently deleted.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let image {
                let framedImage = PolaroidFrameRenderer.render(
                    image: image,
                    date: photo.captureDate,
                    leftText: leftText,
                    fontStyle: styleSettings.fontStyle,
                    fontColor: styleSettings.fontColor
                )
                ShareSheet(items: [framedImage])
            }
        }
    }

    private func saveMessage() {
        photo.customMessage = messageInput.isEmpty ? nil : messageInput
        isEditingMessage = false
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
