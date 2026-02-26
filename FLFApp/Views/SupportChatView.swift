import SwiftUI
import UIKit

struct SupportChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var pendingImage: UIImage?
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
                    if let image = image {
                        pendingImage = image
                        inputFocused = true
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private static let defaultPhotoCaption = "Can you estimate the calories and give me feedback?"
    
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
        let canSend = !inputText.trimmingCharacters(in: .whitespaces).isEmpty || pendingImage != nil
        return HStack(alignment: .bottom, spacing: 12) {
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
            if let img = pendingImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button {
                    pendingImage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.secondary)
                }
            }
            TextField(pendingImage != nil ? "Add a caption..." : "Message...", text: $inputText, axis: .vertical)
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
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        let hasImage = pendingImage != nil
        let caption = text.isEmpty && hasImage ? Self.defaultPhotoCaption : text
        guard !caption.isEmpty else { return }

        let userMsg = ChatMessage(role: .user, content: caption)
        appState.addChatMessage(userMsg)
        let imageToSend = pendingImage
        pendingImage = nil
        inputText = ""
        isSending = true

        Task {
            let base64 = imageToSend.flatMap { compressAndEncodeImage($0) }
            let response = await service.respond(to: caption, appState: appState, imageBase64: base64)
            await MainActor.run {
                appState.addChatMessage(ChatMessage(role: .assistant, content: response))
                isSending = false
                if !caption.isEmpty && caption.lowercased().contains("remember") && caption.lowercased().contains("challeng") {
                    let challenge = caption.replacingOccurrences(of: "Remember this as something I find challenging:", with: "").trimmingCharacters(in: .whitespaces)
                    if !challenge.isEmpty {
                        appState.addUserChallenge(challenge)
                    }
                }
            }
        }
    }
}

// MARK: - Food log suggestion (from chatbot)
private struct FoodLogPayload: Decodable {
    let items: [FoodLogItem]
}
private struct FoodLogItem: Decodable {
    let name: String
    let calories: Double
    let protein: Double
    let quantity: String?

    enum CodingKeys: String, CodingKey { case name, calories, protein, quantity }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        calories = try c.decode(Double.self, forKey: .calories)
        protein = try c.decode(Double.self, forKey: .protein)
        if let s = try? c.decode(String.self, forKey: .quantity) { quantity = s }
        else if let n = try? c.decode(Int.self, forKey: .quantity) { quantity = "\(n)" }
        else { quantity = nil }
    }
}

private enum FoodLogParse {
    static let openTag = "[FOOD_LOG]"
    static let closeTag = "[/FOOD_LOG]"

    static func parse(_ content: String) -> (displayText: String, items: [FoodLogItem])? {
        guard let open = content.range(of: openTag),
              let close = content.range(of: closeTag, range: open.upperBound..<content.endIndex) else { return nil }
        let displayText = content[..<open.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonString = String(content[open.upperBound..<close.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(FoodLogPayload.self, from: data),
              !payload.items.isEmpty else { return nil }
        return (displayText, payload.items)
    }
}

struct ChatBubbleView: View {
    @EnvironmentObject var appState: AppState
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user { Spacer(minLength: 48) }
            if message.role == .assistant, let parsed = FoodLogParse.parse(message.content) {
                assistantBubbleWithFoodLog(displayText: parsed.displayText, items: parsed.items)
            } else {
                Text(message.content)
                    .font(.subheadline)
                    .padding(12)
                    .background(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }

    private func assistantBubbleWithFoodLog(displayText: String, items: [FoodLogItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !displayText.isEmpty {
                Text(displayText)
                    .font(.subheadline)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    addFoodButton(messageId: message.id.uuidString, index: index, item: item)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func addFoodButton(messageId: String, index: Int, item: FoodLogItem) -> some View {
        let applied = appState.isFoodLogSuggestionApplied(messageId: messageId, itemIndex: index)
        let buttonTitle = applied ? "Added" : "Add \(item.name) – \(Int(item.calories)) cal"
        return Button {
            guard !applied else { return }
            appState.applyFoodLogSuggestion(
                messageId: messageId,
                itemIndex: index,
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                quantity: item.quantity ?? ""
            )
        } label: {
            Text(buttonTitle)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(applied ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.15))
                .foregroundStyle(applied ? Color.green : Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(applied)
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
