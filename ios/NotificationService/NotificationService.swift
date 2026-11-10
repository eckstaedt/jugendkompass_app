import UserNotifications

/// Attaches the image of a push notification (FCM `fcm_options.image`)
/// so it is shown on iOS. Without this extension iOS only shows text.
class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttempt: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttempt = request.content.mutableCopy() as? UNMutableNotificationContent

        guard let content = bestAttempt,
              let urlString = Self.imageURL(from: request.content.userInfo),
              let url = URL(string: urlString) else {
            contentHandler(request.content)
            return
        }

        URLSession.shared.downloadTask(with: url) { location, response, _ in
            defer { contentHandler(content) }
            guard let location = location else { return }
            let ext = Self.fileExtension(for: response, url: url)
            let target = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            do {
                try FileManager.default.moveItem(at: location, to: target)
                let attachment = try UNNotificationAttachment(identifier: "image", url: target)
                content.attachments = [attachment]
            } catch {
                // Show the notification without image.
            }
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        if let handler = contentHandler, let content = bestAttempt {
            handler(content)
        }
    }

    private static func imageURL(from userInfo: [AnyHashable: Any]) -> String? {
        if let options = userInfo["fcm_options"] as? [String: Any],
           let image = options["image"] as? String {
            return image
        }
        return userInfo["image"] as? String
    }

    private static func fileExtension(for response: URLResponse?, url: URL) -> String {
        switch response?.mimeType {
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "image/webp": return "webp"
        case "image/jpeg", "image/jpg": return "jpg"
        default:
            let ext = url.pathExtension.lowercased()
            return ext.isEmpty ? "jpg" : ext
        }
    }
}
