import Foundation
import ActivityKit

class Activities {
    static let shared = Activities()
    let log = LoggerFactory.shared.system(Activities.self)
    
    var activeActivity: Activity<LiveActivityDemoAttributes>? = nil
    
    func start() async throws {
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let now = Date.now
            let stale = Calendar.current.date(byAdding: .second, value: 15, to: now)!
            let attrs = LiveActivityDemoAttributes(name: "Activity name")
            let initialState = LiveActivityDemoAttributes.ContentState(value: 42)
            let content = ActivityContent(state: initialState, staleDate: stale)
            let activity = try Activity.request(attributes: attrs, content: content)
            activeActivity = activity
            await observeState(activity: activity)
            log.info("Started live activity")
        } else {
            log.info("Live activities are disabled.")
        }
    }
    
    func observeState(activity: Activity<LiveActivityDemoAttributes>) async {
        for await stateUpdate in activity.activityStateUpdates {
            log.info("State update to \(stateUpdate)")
        }
    }
    
    func endAll() async {
        let endState = LiveActivityDemoAttributes.ContentState(value: 43)
        let content = ActivityContent(state: endState, staleDate: nil)
        for activity in Activity<LiveActivityDemoAttributes>.activities {
            await activity.end(content, dismissalPolicy: .immediate)
            log.info("Ended activity.")
        }
    }
}
