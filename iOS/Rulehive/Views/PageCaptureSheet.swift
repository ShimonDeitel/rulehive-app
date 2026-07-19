import SwiftUI

/// A minimal full-screen camera capture sheet for photographing one rulebook page
/// or spread. One shutter button, no overlay.
struct PageCaptureSheet: View {
    let pageNumber: Int
    let onCapture: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraService()
    @State private var authDenied = false
    @State private var capturing = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if camera.isConfigured {
                CameraPreview(session: camera.session).ignoresSafeArea()
            } else if !authDenied {
                ProgressView().tint(.white)
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("PAGE \(pageNumber)")
                        .font(RulehiveFont.pageLabel(12))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                }
                .padding()

                Spacer()

                if authDenied {
                    Text("Camera access is required to photograph rulebook pages.")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Button {
                        Task { await capture() }
                    } label: {
                        ZStack {
                            Circle().stroke(Color.white, lineWidth: 3).frame(width: 72, height: 72)
                            Circle().fill(Color.white).frame(width: 58, height: 58)
                        }
                        .opacity(capturing ? 0.5 : 1)
                    }
                    .disabled(capturing)
                    .padding(.bottom, 36)
                }
            }
        }
        .task { await setUp() }
        .onDisappear { camera.stop() }
    }

    private func setUp() async {
        let granted = await CameraService.requestPermission()
        guard granted else { authDenied = true; return }
        do {
            try camera.configure()
            camera.start()
        } catch {
            authDenied = true
        }
    }

    private func capture() async {
        capturing = true
        defer { capturing = false }
        if let data = try? await camera.capturePhoto() {
            onCapture(data)
            dismiss()
        } else {
            Haptics.warning()
        }
    }
}
