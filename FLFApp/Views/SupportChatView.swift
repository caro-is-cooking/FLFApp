import SwiftUI
import UIKit

struct SupportChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var inputFocused: Bool
    
    private let service = SupportChatService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if appState.chatHistory.isEmpty {
                                welcomeBubble
                            }
                            ForEach(appState.chatHistory) { msg in
                                ChatBubbleView(message: msg)
                                    .id(msg.id)
                            }
                            if isSending {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: appState.chatHistory.count) { _ in
                        if let last = appState.chatHistory.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                inputBar()
            }
            .navigationTitle("Support Chat")
            .overlay(alignment: .topTrailing) {
                Menu {
                    Button("Add a challenge I face") {
                        inputText = "Remember this as something I find challenging: "
                        inputFocused = true
                    }
                    if !appState.userChallenges.isEmpty {
                        Section("Saved challenges") {
                            ForEach(appState.userChallenges, id: \.self) { c in
                                Text(c)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .padding(8)
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: imagePickerSource) { image in
                    showImagePicker = false
                    if image != nil { sendPlatePhoto(image) }
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private func sendPlatePhoto(_ image: UIImage?) {
        guard let image = image else { return }
        let text = "Here's my plate - can you estimate the calories and give me feedback?"
        let userMsg = ChatMessage(role: .user, content: text)
        appState.addChatMessage(userMsg)
        isSending = true
        Task {
            let base64 = compressAndEncodeImage(image)
            let response = await service.respond(to: text, appState: appState, imageBase64: base64)
            await MainActor.run {
                appState.addChatMessage(ChatMessage(role: .assistant, content: response))
                isSending = false
            }
        }
    }
    
    private func compressAndEncodeImage(_ image: UIImage) -> String? {
        let maxSide: CGFloat = 1024
        let scale = min(maxSide / image.size.width, maxSide / image.size.height, 1)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let jpeg = resized?.jpegData(compressionQuality: 0.75) else { return nil }
        return jpeg.base64EncodedString()
    }
    
    private var welcomeBubble: some View {
        Text("Hi! I'm here to support your fat loss journey. I know your goals and I'll remember what you find challenging. Share what's on your mind—wins, struggles, or questions.")
            .font(.subheadline)
            .padding(12)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func inputBar() -> some View {
        HStack(spacing: 12) {
            Menu {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        imagePickerSource = .camera
                        showImagePicker = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }
                Button {
                    imagePickerSource = .photoLibrary
                    showImagePicker = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
            } label: {
                Image(systemName: "camera.fill")
                    .font(.title2)
            }
            .disabled(isSending)
            TextField("Message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...4)
                .focused($inputFocused)
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        let userMsg = ChatMessage(role: .user, content: text)
        appState.addChatMessage(userMsg)
        inputText = ""
        isSending = true
        
        Task {
            let response = await service.respond(to: text, appState: appState)
            await MainActor.run {
                appState.addChatMessage(ChatMessage(role: .assistant, content: response))
                isSending = false
                // Save "challenge" if user said to remember
                if text.lowercased().contains("remember") && text.lowercased().contains("challeng") {
                    let challenge = text.replacingOccurrences(of: "Remember this as something I find challenging:", with: "").trimmingCharacters(in: .whitespaces)
                    if !challenge.isEmpty {
                        appState.addUserChallenge(challenge)
                    }
                }
            }
        }
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }
            Text(message.content)
                .font(.subheadline)
                .padding(12)
                .background(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundColor(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Image Picker (camera + photo library)
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onPick: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage?) -> Void
        
        init(onPick: @escaping (UIImage?) -> Void) {
            self.onPick = onPick
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onPick(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onPick(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    SupportChatView()
        .environmentObject(AppState())
}
