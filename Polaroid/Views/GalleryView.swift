import SwiftUI
import SwiftData

struct GalleryView: View {
    let styleSettings: StyleSettings

    @Query(sort: \PolaroidPhoto.captureDate, order: .reverse)
    private var photos: [PolaroidPhoto]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showClearAlert = false
    @State private var showDeleteSelectedAlert = false
    @State private var isSelecting = false
    @State private var selectedIDs = Set<UUID>()
    @State private var shareItems: ShareableImages? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var selectedPhotos: [PolaroidPhoto] {
        photos.filter { selectedIDs.contains($0.id) }
    }

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
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(photos, id: \.id) { photo in
                                    NavigationLink(destination: PhotoDetailView(photo: photo, styleSettings: styleSettings)) {
                                        GalleryThumbnail(photo: photo, styleSettings: styleSettings)
                                            .overlay(alignment: .topTrailing) {
                                                if isSelecting {
                                                    selectionBadge(selected: selectedIDs.contains(photo.id))
                                                        .padding(6)
                                                }
                                            }
                                            .opacity(isSelecting && !selectedIDs.isEmpty && !selectedIDs.contains(photo.id) ? 0.6 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isSelecting)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        if isSelecting { toggleSelection(photo) }
                                    })
                                }
                            }
                            .padding()

                            if !isSelecting {
                                Button(role: .destructive) {
                                    showClearAlert = true
                                } label: {
                                    Text("Clear Film Roll")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.red.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }

                            Color.clear.frame(height: isSelecting ? 80 : 0)
                        }

                        // Selection action bar
                        if isSelecting && !selectedIDs.isEmpty {
                            selectionActionBar
                        }
                    }
                }
            }
            .navigationTitle(isSelecting ? "\(selectedIDs.count) Selected" : "Film Roll (\(photos.count)/8)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelecting {
                        Button("Cancel") { exitSelection() }
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSelecting {
                        Button(selectedIDs.count == photos.count ? "Deselect All" : "Select All") {
                            if selectedIDs.count == photos.count {
                                selectedIDs.removeAll()
                            } else {
                                selectedIDs = Set(photos.map(\.id))
                            }
                        }
                    } else if !photos.isEmpty {
                        Button("Select") { isSelecting = true }
                    }
                }
            }
            .alert("Clear Film Roll?", isPresented: $showClearAlert) {
                Button("Clear All", role: .destructive) { clearAllPhotos() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Make sure you've saved your photos to your camera roll first. This cannot be undone.")
            }
            .alert("Delete \(selectedIDs.count) photo\(selectedIDs.count == 1 ? "" : "s")?", isPresented: $showDeleteSelectedAlert) {
                Button("Delete", role: .destructive) { deleteSelected() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .sheet(item: $shareItems) { shareable in
                ShareSheet(items: shareable.images)
            }
        }
    }

    private var selectionActionBar: some View {
        HStack(spacing: 0) {
            // Share
            Button {
                exportSelected()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                    Text("Share")
                        .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(selectedIDs.isEmpty)

            Divider().frame(height: 40)

            // Delete
            Button {
                showDeleteSelectedAlert = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    Text("Delete")
                        .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.red)
            }
            .disabled(selectedIDs.isEmpty)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.2), value: selectedIDs.isEmpty)
    }

    @ViewBuilder
    private func selectionBadge(selected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(selected ? Color.blue : Color.white.opacity(0.85))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(selected ? Color.blue : Color(white: 0.6), lineWidth: 1.5))
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func toggleSelection(_ photo: PolaroidPhoto) {
        if selectedIDs.contains(photo.id) {
            selectedIDs.remove(photo.id)
        } else {
            selectedIDs.insert(photo.id)
        }
    }

    private func exitSelection() {
        isSelecting = false
        selectedIDs.removeAll()
    }

    private func exportSelected() {
        // Extract all values from MainActor-bound objects before the detached task
        let showLocation = styleSettings.showLocation
        let fontStyle = styleSettings.fontStyle
        let fontColor = styleSettings.fontColor
        let exportData: [(path: String, date: Date, leftText: String?)] = selectedPhotos.map { photo in
            let leftText: String? = {
                if let msg = photo.customMessage, !msg.isEmpty { return msg }
                return showLocation ? photo.location : nil
            }()
            return (path: photo.imagePath, date: photo.captureDate, leftText: leftText)
        }
        Task.detached(priority: .userInitiated) {
            var items: [UIImage] = []
            for entry in exportData {
                guard let img = PhotoStorageManager.shared.loadPhoto(path: entry.path)?.squareCropped() else { continue }
                let framed = PolaroidFrameRenderer.render(
                    image: img,
                    date: entry.date,
                    leftText: entry.leftText,
                    fontStyle: fontStyle,
                    fontColor: fontColor
                )
                items.append(framed)
            }
            guard !items.isEmpty else { return }
            await MainActor.run {
                shareItems = ShareableImages(images: items)
            }
        }
    }

    private func deleteSelected() {
        for photo in selectedPhotos {
            PhotoStorageManager.shared.deletePhoto(path: photo.imagePath)
            modelContext.delete(photo)
        }
        exitSelection()
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

struct ShareableImages: Identifiable {
    let id = UUID()
    let images: [UIImage]
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
