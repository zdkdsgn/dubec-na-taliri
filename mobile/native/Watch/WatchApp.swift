import SwiftUI

@main
struct SkolaNaTaliriWatchApp: App {
    init() { WatchSync.shared.activate() }
    var body: some Scene {
        WindowGroup { WatchContentView() }
    }
}
