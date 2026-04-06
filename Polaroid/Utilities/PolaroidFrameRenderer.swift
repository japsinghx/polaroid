import UIKit

enum PolaroidFrameRenderer {
    static func render(
        image: UIImage,
        date: Date,
        leftText: String? = nil,
        fontStyle: FontStyle = .handwritten,
        fontColor: FontColor = .dark
    ) -> UIImage {
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
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

            image.squareCropped().draw(in: CGRect(x: borderSide, y: borderTop, width: photoSize, height: photoSize))

            let resolvedFont: UIFont
            switch fontStyle {
            case .handwritten:
                resolvedFont = UIFont(name: "PermanentMarker-Regular", size: 52) ?? UIFont.systemFont(ofSize: 52, weight: .bold)
            case .classic:
                let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif)
                resolvedFont = descriptor.map { UIFont(descriptor: $0, size: 44) } ?? UIFont.systemFont(ofSize: 44, weight: .thin)
            }

            let textColor = fontColor.uiColor
            let textY = borderTop + photoSize + 50
            let textHeight: CGFloat = 80

            if let leftText {
                let attrs: [NSAttributedString.Key: Any] = [.font: resolvedFont, .foregroundColor: textColor]
                let rect = CGRect(x: borderSide, y: textY, width: photoSize / 2, height: textHeight)
                leftText.draw(in: rect, withAttributes: attrs)
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: date)

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: resolvedFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph,
            ]
            dateString.draw(in: CGRect(x: borderSide, y: textY, width: photoSize, height: textHeight), withAttributes: dateAttrs)
        }
    }
}
