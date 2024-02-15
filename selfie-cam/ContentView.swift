
import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation
import CoreImage

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")
    
    var body: some View {
        if let image = image {
            Image(image, scale: 1.0, orientation: .up, label: label)
        } else {
            Color.black
        }
    }
}

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    @StateObject private var model = FrameHandler()
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace


    var body: some View {
        VStack {
            FrameView(image: model.frame)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
