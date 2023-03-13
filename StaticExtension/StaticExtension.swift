import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let imageData: Data?
}

struct Provider: TimelineProvider {
    let log = LoggerFactory.shared.system(Provider.self)
    
    func placeholder(in context: Context) -> SimpleEntry {
        log.info("Get placeholder")
        return SimpleEntry(date: Date(), imageData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        log.info("Get snapshot")
        Task {
            completion(await snapshot(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        log.info("Get timeline")
        Task {
            completion(await timeline(in: context))
        }
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

struct StaticExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            else {
                Text("Text this time!")
            }
        }.widgetURL(FeatureConstants.shared.widgetUrl)
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
