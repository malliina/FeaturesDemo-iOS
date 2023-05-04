import Foundation
import WidgetKit

protocol AsyncTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> Entry
    func snapshot(in context: Context) async -> Entry
    func timeline(in context: Context) async -> Timeline<Entry>
}

extension AsyncTimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
        Task {
            completion(await snapshot(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            completion(await timeline(in: context))
        }
    }
}
