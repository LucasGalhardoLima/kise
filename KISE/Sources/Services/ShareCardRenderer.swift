import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.kise.app", category: "ShareCard")

@MainActor
enum ShareCardRenderer {
    /// Renders ShareCardView to a UIImage at 3× scale (1170×1560px)
    static func renderImage(data: ShareCardData, theme: ThemeColors) -> UIImage? {
        let view = ShareCardView(data: data, theme: theme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    /// Presents UIActivityViewController with the rendered card image
    static func share(data: ShareCardData, theme: ThemeColors) {
        guard let image = renderImage(data: data, theme: theme) else {
            logger.error("Failed to render share card image")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        // Find the topmost presented controller
        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        // iPad requires popover configuration
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0, height: 0
            )
        }

        presenter.present(activityVC, animated: true)
    }
}
