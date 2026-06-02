import SwiftUI

@main
struct PhotoUtilApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 920, minHeight: 640)
        }
        .windowStyle(.titleBar)
    }
}
