import WidgetKit
import SwiftUI
import UIKit

// "Vers des Tages" home-screen widget.
//
// * Loads today's verse itself (Supabase REST, public read access) in the
//   app language – also when the app is not opened.
// * Background: the plain nature photo of the day (the one behind the
//   shareable verse image). Without a photo the layout's own decoration is
//   used.
// * Six layouts; the layout changes every day (same rule as on Android).
// * Refreshes every 2 hours and right after midnight.

// MARK: - Model

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: String
    let reference: String
    let label: String
    let background: UIImage?
    let template: Int
    let isRTL: Bool
}

enum WidgetStrings {
    static let labels: [String: String] = [
        "de": "VERS DES TAGES",
        "en": "VERSE OF THE DAY",
        "ru": "СТИХ ДНЯ",
        "es": "VERSÍCULO DEL DÍA",
        "pl": "WERSET DNIA",
        "tr": "GÜNÜN AYETİ",
        "he": "פסוק היום",
    ]
    static let empty: [String: String] = [
        "de": "Öffne die App, um den Vers des Tages zu laden.",
        "en": "Open the app to load the verse of the day.",
        "ru": "Открой приложение, чтобы загрузить стих дня.",
        "es": "Abre la app para cargar el versículo del día.",
        "pl": "Otwórz aplikację, aby wczytać werset dnia.",
        "tr": "Günün ayetini yüklemek için uygulamayı aç.",
        "he": "פתח את האפליקציה כדי לטעון את פסוק היום.",
    ]
    static func label(_ lang: String) -> String { labels[lang] ?? labels["de"]! }

    /// Verse in the quotation marks of the language.
    static func quote(_ verse: String, lang: String) -> String {
        switch lang {
        case "de": return "„\(verse)“"
        case "pl": return "„\(verse)”"
        case "ru": return "«\(verse)»"
        case "he": return verse
        default: return "“\(verse)”"
        }
    }
}

// MARK: - Loading

struct VerseLoader {
    static let appGroupId = "group.io.stephanus.jugendkompass"
    static let templateCount = 6

    let defaults = UserDefaults(suiteName: VerseLoader.appGroupId)

    var language: String { defaults?.string(forKey: "app_language") ?? "de" }

    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Same on iOS and Android: days since 2000-01-01 modulo 6.
    static func template(for iso: String) -> Int {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return 0 }
        var c = DateComponents()
        c.year = parts[0]; c.month = parts[1]; c.day = parts[2]; c.hour = 12
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let d = cal.date(from: c) else { return 0 }
        let days = Int(floor(d.timeIntervalSince1970 / 86400)) - 10957
        return ((days % templateCount) + templateCount) % templateCount
    }

    func load(now: Date = Date()) async -> VerseEntry {
        let lang = language
        let today = VerseLoader.isoDate(now)
        var verse = defaults?.string(forKey: "verse_text") ?? ""
        var reference = defaults?.string(forKey: "verse_reference") ?? ""
        var background: UIImage? = cachedImage(for: today)

        if let fetched = await fetchVerse(date: today, lang: lang) {
            verse = fetched.verse
            reference = fetched.reference
            // Cache as offline fallback.
            defaults?.set(verse, forKey: "verse_text")
            defaults?.set(reference, forKey: "verse_reference")
            defaults?.set(today, forKey: "verse_date")
            if background == nil, let url = fetched.background {
                background = await downloadImage(url, date: today)
            }
        }
        if verse.isEmpty {
            verse = WidgetStrings.empty[lang] ?? WidgetStrings.empty["de"]!
        }
        return VerseEntry(
            date: now,
            verse: WidgetStrings.quote(verse, lang: lang),
            reference: reference,
            label: WidgetStrings.label(lang),
            background: background,
            template: VerseLoader.template(for: today),
            isRTL: lang == "he"
        )
    }

    // MARK: Network

    private struct Fetched {
        let verse: String
        let reference: String
        let background: URL?
    }

    private func get(_ path: String) async -> Any? {
        guard let base = defaults?.string(forKey: "supabase_url"), !base.isEmpty,
              let key = defaults?.string(forKey: "supabase_anon_key"), !key.isEmpty,
              let url = URL(string: base + path) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(key, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private func fetchVerse(date: String, lang: String) async -> Fetched? {
        guard let rows = await get(
            "/rest/v1/verse_of_the_day?select=content_id,verse,reference,background_image_url&date=eq.\(date)&limit=1"
        ) as? [[String: Any]], let row = rows.first else { return nil }

        var verse = Self.clean(row["verse"] as? String ?? "")
        var reference = Self.clean(row["reference"] as? String ?? "")
        if lang != "de", let contentId = row["content_id"] as? String,
           let tr = await get(
               "/rest/v1/content_translations?select=field_name,value&content_id=eq.\(contentId)&language=eq.\(lang)"
           ) as? [[String: Any]] {
            for t in tr {
                let value = Self.clean(t["value"] as? String ?? "")
                guard !value.isEmpty else { continue }
                if t["field_name"] as? String == "verse" { verse = value }
                if t["field_name"] as? String == "reference" { reference = value }
            }
        }
        let bg = (row["background_image_url"] as? String).flatMap(URL.init(string:))
        return verse.isEmpty ? nil : Fetched(verse: verse, reference: reference, background: bg)
    }

    static func clean(_ s: String) -> String {
        s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Image cache (one photo per day, downscaled for the widget)

    private func cacheURL(for date: String) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: VerseLoader.appGroupId)?
            .appendingPathComponent("widget_bg_\(date).jpg")
    }

    private func cachedImage(for date: String) -> UIImage? {
        guard let url = cacheURL(for: date), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func downloadImage(_ url: URL, date: String) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        let scaled = Self.downscale(image, maxSide: 900)
        if let target = cacheURL(for: date), let jpeg = scaled.jpegData(compressionQuality: 0.85) {
            // Keep only today's photo.
            if let dir = cacheURL(for: date)?.deletingLastPathComponent(),
               let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
                for f in files where f.hasPrefix("widget_bg_") {
                    try? FileManager.default.removeItem(at: dir.appendingPathComponent(f))
                }
            }
            try? jpeg.write(to: target)
        }
        return scaled
    }

    static func downscale(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        guard scale < 1 else { return image }
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Timeline

struct VerseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(
            date: Date(),
            verse: WidgetStrings.quote("Denn ich weiß, welche Pläne ich für euch habe – Pläne des Friedens und nicht des Unheils.", lang: "de"),
            reference: "Jeremia 29,11",
            label: WidgetStrings.label("de"),
            background: nil,
            template: VerseLoader.template(for: VerseLoader.isoDate(Date())),
            isRTL: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { completion(await VerseLoader().load()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        Task {
            let entry = await VerseLoader().load()
            let cal = Calendar.current
            let twoHours = cal.date(byAdding: .hour, value: 2, to: Date())!
            let midnight = cal.date(byAdding: .minute, value: 2,
                                    to: cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date())!))!
            completion(Timeline(entries: [entry], policy: .after(min(twoHours, midnight))))
        }
    }
}

// MARK: - Shared pieces

private extension Font {
    static func verse(_ family: WidgetFamily, serif: Bool = false) -> Font {
        let size: CGFloat
        switch family {
        case .systemSmall: size = 13
        case .systemLarge: size = 22
        default: size = 16
        }
        return .system(size: size, weight: .medium, design: serif ? .serif : .default)
    }
}

private struct TrackedLabel: View {
    let text: String
    var color: Color = .white.opacity(0.8)
    var size: CGFloat = 10
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .tracking(2.2)
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// Photo or soft gradient as background.
private struct PhotoBackground: View {
    let image: UIImage?
    var dim: Double = 0.35
    var blur: CGFloat = 0
    var body: some View {
        ZStack {
            if let image {
                GeometryReader { geo in
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: blur)
                }
            } else {
                LinearGradient(colors: [Color(red: 0.40, green: 0.48, blue: 0.62),
                                        Color(red: 0.78, green: 0.72, blue: 0.66)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            Color.black.opacity(dim)
        }
    }
}

// MARK: - Templates (based on the provided examples)

/// 0 – Glass: cross + spaced label, book icon, large verse, spaced reference.
private struct GlassTemplate: View {
    let entry: VerseEntry
    let family: WidgetFamily
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
            HStack(spacing: 10) {
                Image(systemName: "cross").font(.system(size: family == .systemSmall ? 14 : 20, weight: .light))
                if family != .systemSmall { TrackedLabel(text: entry.label) }
                Spacer()
                if family != .systemSmall {
                    Image(systemName: "book").font(.system(size: 18, weight: .light)).opacity(0.85)
                }
            }
            .foregroundColor(.white.opacity(0.9))
            Spacer(minLength: 0)
            Text(entry.verse)
                .font(.verse(family))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
            Spacer(minLength: 0)
            HStack {
                TrackedLabel(text: entry.reference, color: .white.opacity(0.8), size: family == .systemSmall ? 9 : 11)
                Spacer()
                if family != .systemSmall {
                    Capsule().fill(.white.opacity(0.6)).frame(width: 40, height: 2)
                }
            }
        }
        .padding(family == .systemSmall ? 14 : 18)
    }
}

/// 1 – Tile: light tile with cross and reference, divider, label + verse.
private struct TileTemplate: View {
    let entry: VerseEntry
    let family: WidgetFamily
    var body: some View {
        if family == .systemSmall {
            GlassTemplate(entry: entry, family: family)
        } else {
            HStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: "cross").font(.system(size: 30, weight: .regular))
                    Text(entry.reference.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                }
                .foregroundColor(Color(white: 0.15))
                .padding(10)
                .frame(width: family == .systemLarge ? 120 : 96, height: family == .systemLarge ? 140 : 104)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(white: 0.93).opacity(0.92)))

                Rectangle().fill(.white.opacity(0.35)).frame(width: 1)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 8) {
                    TrackedLabel(text: entry.label, color: .white.opacity(0.75))
                    Text(entry.verse)
                        .font(.verse(family))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}

/// 2 – Paper: light card, big quote mark, dark verse, line + reference,
/// the photo fades in on the right (instead of the leaf).
private struct PaperTemplate: View {
    let entry: VerseEntry
    let family: WidgetFamily
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8) {
            Text("“").font(.system(size: family == .systemSmall ? 34 : 48, weight: .bold, design: .serif))
                .foregroundColor(Color(white: 0.6))
                .frame(height: family == .systemSmall ? 24 : 34, alignment: .top)
            Text(entry.verse)
                .font(.verse(family))
                .foregroundColor(Color(white: 0.1))
                .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                Rectangle().fill(Color(white: 0.25)).frame(width: 24, height: 1)
                Text(entry.reference)
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .medium))
                    .tracking(0.6)
                    .foregroundColor(Color(white: 0.3))
                    .lineLimit(1)
            }
        }
        .padding(family == .systemSmall ? 14 : 18)
        .padding(.trailing, family == .systemSmall ? 0 : 40)
    }

    static func background(_ image: UIImage?) -> some View {
        ZStack(alignment: .trailing) {
            Color(white: 0.94)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(LinearGradient(colors: [.clear, .clear, .black.opacity(0.85)],
                                         startPoint: .leading, endPoint: .trailing))
                    .opacity(0.9)
            } else {
                Image(systemName: "leaf")
                    .font(.system(size: 90, weight: .ultraLight))
                    .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.42).opacity(0.55))
                    .rotationEffect(.degrees(-25))
                    .offset(x: 20, y: 20)
            }
        }
    }
}

/// 3 – Split: photo on the left fading into dark, text on the right.
private struct SplitTemplate: View {
    let entry: VerseEntry
    let family: WidgetFamily
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: family == .systemSmall ? 0 : (family == .systemLarge ? 110 : 120))
            VStack(alignment: .leading, spacing: 8) {
                if family != .systemSmall { TrackedLabel(text: entry.label, color: .white.opacity(0.7)) }
                Spacer(minLength: 0)
                Text(entry.verse)
                    .font(.verse(family))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                Text(entry.reference)
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(family == .systemSmall ? 14 : 18)
        }
    }

    static func background(_ image: UIImage?) -> some View {
        ZStack {
            Color(red: 0.12, green: 0.13, blue: 0.16)
            GeometryReader { geo in
                PhotoBackground(image: image, dim: 0.05)
                    .frame(width: geo.size.width * 0.6, height: geo.size.height)
                    .clipped()
                    .mask(LinearGradient(colors: [.black, .black, .clear],
                                         startPoint: .leading, endPoint: .trailing))
            }
            if image == nil {
                HStack {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 54, weight: .regular))
                        .foregroundColor(.black.opacity(0.75))
                        .padding(.leading, 36)
                    Spacer()
                }
            }
        }
    }
}

/// 4 – Bottom: full photo, dark gradient from below, verse at the bottom.
private struct BottomTemplate: View {
    let entry: VerseEntry
    let family: WidgetFamily
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.22)))
                .opacity(family == .systemSmall ? 0 : 1)
            Spacer(minLength: 0)
            Text(entry.verse)
                .font(.verse(family))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
            Text(entry.reference)
                .font(.system(size: family == .systemSmall ? 10 : 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(family == .systemSmall ? 14 : 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    static func background(_ image: UIImage?) -> some View {
        ZStack {
            PhotoBackground(image: image, dim: 0)
            LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.0), .black.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

/// 5 – Center: calm, centered serif verse with a small cross.
private struct CenterTemplate: View {
    let entry: VerseEntry
    let family: WidgetFamily
    var body: some View {
        VStack(spacing: family == .systemSmall ? 6 : 10) {
            Image(systemName: "cross").font(.system(size: family == .systemSmall ? 12 : 16, weight: .light))
                .foregroundColor(.white.opacity(0.85))
            Spacer(minLength: 0)
            Text(entry.verse)
                .font(.verse(family, serif: true))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
            TrackedLabel(text: entry.reference.uppercased(), color: .white.opacity(0.8), size: family == .systemSmall ? 9 : 10)
        }
        .padding(family == .systemSmall ? 14 : 20)
    }
}

// MARK: - Entry view

struct VerseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VerseEntry

    var body: some View {
        content
            .environment(\.layoutDirection, entry.isRTL ? .rightToLeft : .leftToRight)
            .widgetURL(URL(string: "jugendkompass://verse"))
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder private var content: some View {
        switch entry.template {
        case 1: TileTemplate(entry: entry, family: family)
        case 2: PaperTemplate(entry: entry, family: family)
        case 3: SplitTemplate(entry: entry, family: family)
        case 4: BottomTemplate(entry: entry, family: family)
        case 5: CenterTemplate(entry: entry, family: family)
        default: GlassTemplate(entry: entry, family: family)
        }
    }

    @ViewBuilder private var background: some View {
        switch entry.template {
        case 1: PhotoBackground(image: entry.background, dim: 0.42)
        case 2: PaperTemplate.background(entry.background)
        case 3: SplitTemplate.background(entry.background)
        case 4: BottomTemplate.background(entry.background)
        case 5: PhotoBackground(image: entry.background, dim: 0.48, blur: 1.5)
        default: PhotoBackground(image: entry.background, dim: 0.28)
        }
    }
}

// MARK: - Widget

@main
struct VerseWidget: Widget {
    let kind: String = "VerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseTimelineProvider()) { entry in
            VerseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vers des Tages")
        .description("Der tägliche Bibelvers – mit dem Naturbild des Tages.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
