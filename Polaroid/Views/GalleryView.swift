import SwiftUI
import SwiftData

struct GalleryView: View {
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
                                    PhotoDetailView(photo: photo)
                                } label: {
                                    GalleryThumbnail(photo: photo)
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
                Button("Clear All", role: .destructive) {
                    clearAllPhotos()
                }
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

struct GalleryThumbnail: View {
    let photo: PolaroidPhoto
    @State private var thumbnail: UIImage? = nil

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
                if let location = photo.location {
                    Text(location)
                        .font(.custom("PermanentMarker-Regular", size: 10))
                        .foregroundStyle(Color(white: 0.2).opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()
                Text(formattedDate)
                    .font(.custom("PermanentMarker-Regular", size: 10))
                    .foregroundStyle(Color(white: 0.2).opacity(0.55))
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

struct PhotoDetailView: View {
    let photo: PolaroidPhoto
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var image: UIImage? = nil

    var body: some View {
        VStack {
            Spacer()

            if let image {
                PolaroidPrintView(
                    image: image,
                    date: photo.captureDate,
                    location: photo.location
                )

                Spacer()

                HStack(spacing: 40) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .padding(.bottom, 40)
            } else {
                ProgressView()
                Spacer()
            }
        }
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
                let framedImage = PolaroidFrameRenderer.render(image: image, date: photo.captureDate, location: photo.location)
                ShareSheet(items: [framedImage])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
