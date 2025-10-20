import SwiftUI
import WidgetKit

@main
struct dayaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if url.scheme == "daya" && url.host == "refresh" {
                        // Force refresh widgets when tapped
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
        }
    }
}

