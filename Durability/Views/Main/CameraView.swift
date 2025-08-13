import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onVideoSaved: (URL) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // Prefer camera when available; fall back to library on simulator or devices without camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
            if cameraTypes.contains("public.movie") {
                picker.sourceType = .camera
                picker.mediaTypes = ["public.movie"]
                picker.cameraCaptureMode = .video
            } else {
                // Camera doesn't support video; fallback to picking a video from library if possible
                picker.sourceType = .photoLibrary
                let libraryTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
                picker.mediaTypes = libraryTypes.contains("public.movie") ? ["public.movie"] : libraryTypes
            }
        } else {
            picker.sourceType = .photoLibrary
            if let types = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                picker.mediaTypes = types
            }
        }
        picker.videoQuality = .typeHigh
        picker.videoExportPreset = AVAssetExportPresetHighestQuality
        picker.videoMaximumDuration = Config.maxAssessmentDuration
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoSaved(videoURL)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

