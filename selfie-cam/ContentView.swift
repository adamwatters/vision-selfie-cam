
import SwiftUI
import RealityKit
import AVFoundation
import CoreImage

struct FrameView: View {
    var image: CGImage?
    var texture: MaterialParameters.Texture?
    private let label = Text("frame")
    
    var body: some View {
        RealityView { content, attachments in
            let material = PhysicallyBasedMaterial()
            let videoSphereMesh = MeshResource.generateSphere(radius: 0.2)
            var videoSphere = ModelEntity(mesh: videoSphereMesh, materials: [material])
            videoSphere.name = "video_sphere"
            videoSphere.orientation = simd_quatf(angle: 1.5708, axis: simd_float3(0,1,0))
            content.add(videoSphere)
//            if let video = attachments.entity(for: "video") {
//                content.add(video)
//            }
        } update: { content, attachments in
            let sphere = content.entities.first(where: { entity in
                return entity.name == "video_sphere"
            }) as! ModelEntity
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(texture: texture)
            sphere.model?.materials = [material]
        } attachments: {
            Attachment(id: "video") {
                if let image = image {
                    Image(image, scale: 1.0, orientation: .up, label: label)
                } else {
                    Color.black
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var model = FrameHandler()
    var body: some View {
        VStack {
            FrameView(image: model.frame, texture: model.texture)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
