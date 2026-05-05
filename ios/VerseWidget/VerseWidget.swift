import WidgetKit
import SwiftUI

// MARK: - Data Model

struct VerseEntry: TimelineEntry {
    let date: Date
    let verseText: String
    let verseReference: String
}

// MARK: - Timeline Provider

struct VerseTimelineProvider: TimelineProvider {
    
    private let appGroupId = "group.io.stephanus.jugendkompass"
    
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(
            date: Date(),
            verseText: "Denn Gott hat die Welt so sehr geliebt, dass er seinen einzigen Sohn hingab...",
            verseReference: "Johannes 3,16"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let entry = loadVerseEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let entry = loadVerseEntry()
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadVerseEntry() -> VerseEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        
        let verseText = userDefaults?.string(forKey: "verse_text") ?? "Kein Vers verfügbar"
        let verseReference = userDefaults?.string(forKey: "verse_reference") ?? ""
        
        return VerseEntry(
            date: Date(),
            verseText: verseText,
            verseReference: verseReference
        )
    }
}

// MARK: - Widget Views

struct VerseWidgetSmallView: View {
    let entry: VerseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                Text("VERS DES TAGES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
            }
            
            Spacer()
            
            // Verse text
            Text("\"\(entry.verseText)\"")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .minimumScaleFactor(0.4)
                .lineSpacing(2)
            
            Spacer()
            
            // Reference
            Text("— \(entry.verseReference)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct VerseWidgetMediumView: View {
    let entry: VerseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                Text("VERS DES TAGES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                Spacer()
            }
            
            Spacer()
            
            // Verse text
            Text(entry.verseText)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .minimumScaleFactor(0.4)
                .lineSpacing(2)
            
            Spacer()
            
            // Reference
            Text("— \(entry.verseReference)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct VerseWidgetLargeView: View {
    let entry: VerseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                Text("VERS DES TAGES")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                Spacer()
            }
            
            Spacer()
            
            // Verse text - full display
            Text(entry.verseText)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .lineSpacing(4)
                .minimumScaleFactor(0.4)
            
            Spacer()
            
            // Reference
            HStack {
                Spacer()
                Text("— \(entry.verseReference)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Widget Configuration

struct VerseWidget: Widget {
    let kind: String = "VerseWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                VerseWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                VerseWidgetEntryView(entry: entry)
                    .background(Color(UIColor.systemBackground))
            }
        }
        .configurationDisplayName("Vers des Tages")
        .description("Zeigt den aktuellen Vers des Tages an.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct VerseWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: VerseEntry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            VerseWidgetSmallView(entry: entry)
        case .systemMedium:
            VerseWidgetMediumView(entry: entry)
        case .systemLarge:
            VerseWidgetLargeView(entry: entry)
        default:
            VerseWidgetMediumView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct VerseWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseWidget()
    }
}

// MARK: - Preview

#if DEBUG
struct VerseWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VerseWidgetEntryView(entry: VerseEntry(
                date: Date(),
                verseText: "Denn Gott hat die Welt so sehr geliebt, dass er seinen einzigen Sohn hingab, damit jeder, der an ihn glaubt, nicht verloren geht, sondern das ewige Leben hat.",
                verseReference: "Johannes 3,16"
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")
            
            VerseWidgetEntryView(entry: VerseEntry(
                date: Date(),
                verseText: "Denn Gott hat die Welt so sehr geliebt, dass er seinen einzigen Sohn hingab, damit jeder, der an ihn glaubt, nicht verloren geht, sondern das ewige Leben hat.",
                verseReference: "Johannes 3,16"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
            
            VerseWidgetEntryView(entry: VerseEntry(
                date: Date(),
                verseText: "Denn Gott hat die Welt so sehr geliebt, dass er seinen einzigen Sohn hingab, damit jeder, der an ihn glaubt, nicht verloren geht, sondern das ewige Leben hat.",
                verseReference: "Johannes 3,16"
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
        }
    }
}
#endif
