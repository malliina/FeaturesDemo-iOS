import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let imageData: Data?
}

struct Provider: AsyncTimelineProvider {
    let log = LoggerFactory.shared.system(Provider.self)
    
    func placeholder(in context: Context) -> SimpleEntry {
        log.info("Get placeholder")
        return SimpleEntry(date: Date(), imageData: nil)
    }
    
    func snapshot(in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), imageData: await loadImageData())
    }
    
    func timeline(in context: Context) async -> Timeline<Entry> {
        let currentDate = Date()
        let data = await loadImageData()
        let entries = Array(0 ..< 5).map { hourOffset in
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            return SimpleEntry(date: entryDate, imageData: data)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    func loadImageData() async -> Data? {
        let url = ImageSource.shared.sharkUrl
        return await loadImage(from: url)
    }
    
    func loadImage(from url: URL) async -> Data? {
        do {
            log.info("Downloading \(url)...")
            let (data, _) = try await URLSession.shared.data(from: url)
            log.info("Download of \(url) complete.")
            return data
        } catch {
            log.error("Download of \(url) failed. \(error)")
            return nil
        }
    }
}

extension WidgetFamily {
    // https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension#Respond-to-user-interactions
    var supportsLink: Bool {
        [.systemMedium, .systemLarge, .systemExtraLarge].contains(self)
    }
}

struct StaticExtensionEntryView : View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var entry: Provider.Entry
    
    var body: some View {
        Group {
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                VStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    if family.supportsLink {
                        Link(destination: FeatureConstants.shared.widgetLink) {
                            Text("Text link here")
                        }
                        .padding()
                    }
                }
            }
            else {
                Text("Text this time!")
            }
        }
        .widgetURL(FeatureConstants.shared.widgetUrl)
    }
}

struct StaticExtension: Widget {
    let kind: String = "StaticExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StaticExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct StaticExtension_Previews: PreviewProvider {
    static var previews: some View {
        StaticExtensionEntryView(entry: SimpleEntry(date: Date(), imageData: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
