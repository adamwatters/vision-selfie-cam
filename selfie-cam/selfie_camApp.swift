
import SwiftUI

@main
struct selfie_camApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.25, height: 0.25, depth: 0.25, in: .meters)
    }
}
