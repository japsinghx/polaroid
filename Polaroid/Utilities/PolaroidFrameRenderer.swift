import UIKit

enum PolaroidFrameRenderer {
    static func render(image: UIImage, date: Date, location: String? = nil) -> UIImage {
        let photoSize: CGFloat = 800
        let borderSide: CGFloat = 60
        let borderBottom: CGFloat = 180
        let borderTop: CGFloat = 60

        let totalWidth = photoSize + borderSide * 2
        let totalHeight = photoSize + borderTop + borderBottom

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: totalWidth, height: totalHeight)
        )

        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

            let photoRect = CGRect(x: borderSide, y: borderTop, width: photoSize, height: photoSize)
            image.squareCropped().draw(in: photoRect)

            // Permanent Marker font for the date (matches in-app display)
            let markerFont = UIFont(name: "PermanentMarker-Regular", size: 52)
                ?? UIFont.systemFont(ofSize: 52, weight: .bold)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: date)

            let textColor = UIColor(white: 0.2, alpha: 0.55)

            // Location on left, date on right — same layout as PolaroidPrintView
            let textY = borderTop + photoSize + 50
            let textHeight: CGFloat = 80

            if let location {
                let locationAttrs: [NSAttributedString.Key: Any] = [
                    .font: markerFont,
                    .foregroundColor: textColor,
                ]
                let locationRect = CGRect(x: borderSide, y: textY, width: photoSize / 2, height: textHeight)
                location.draw(in: locationRect, withAttributes: locationAttrs)
            }

            let dateParagraph = NSMutableParagraphStyle()
            dateParagraph.alignment = .right
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: markerFont,
                .foregroundColor: textColor,
                .paragraphStyle: dateParagraph,
            ]
            let dateRect = CGRect(x: borderSide, y: textY, width: photoSize, height: textHeight)
            dateString.draw(in: dateRect, withAttributes: dateAttrs)
        }
    }
}
