// ContentView_iOS - iOS/iPadOS only
#if os(iOS)
import SwiftUI
import Foundation
import UIKit
import PhotosUI
import VisionKit

struct JournalEntry: Identifiable, Codable {
    let id: String
    var title: String
    var content: String
    var date: Date
    var mood: String
    var createdAt: Date
    var modifiedAt: Date
    var imageData: Data? // Store image as Data for Codable compliance
    
    init(title: String, content: String, date: Date, mood: String, imageData: Data? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.date = date
        self.mood = mood
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.imageData = imageData
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
}

class JournalManager: ObservableObject {
    @Published var entries: [JournalEntry] = []
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private var journalFileURL: URL {
        documentsDirectory.appendingPathComponent("journal_entries.json")
    }
    
    init() {
        loadEntries()
    }
    
    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    func updateEntry(_ entry: JournalEntry, title: String, content: String, mood: String, imageData: Data? = nil) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].title = title
            entries[index].content = content
            entries[index].mood = mood
            entries[index].modifiedAt = Date()
            // Only update image if new imageData is provided
            if let newImageData = imageData {
                entries[index].imageData = newImageData
            }
            saveEntries()
        }
    }
    
    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: journalFileURL)
            print("Successfully saved \(entries.count) entries to: \(journalFileURL.path)")
        } catch {
            print("Failed to save entries: \(error.localizedDescription)")
        }
    }
    
    func loadEntries() {
        do {
            let data = try Data(contentsOf: journalFileURL)
            entries = try JSONDecoder().decode([JournalEntry].self, from: data)
            print("Successfully loaded \(entries.count) entries from storage")
        } catch {
            print("Failed to load entries: \(error.localizedDescription)")
            entries = []
        }
    }
    
    func getStorageInfo() -> String {
        let fileExists = FileManager.default.fileExists(atPath: journalFileURL.path)
        let fileSize: String
        
        if fileExists {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: journalFileURL.path)
                let size = attributes[.size] as? Int64 ?? 0
                fileSize = "\(size) bytes"
            } catch {
                fileSize = "Unknown"
            }
        } else {
            fileSize = "File doesn't exist"
        }
        
        return """
        Storage Location: \(journalFileURL.path)
        File Exists: \(fileExists)
        File Size: \(fileSize)
        Entries in Memory: \(entries.count)
        """
    }
}

struct ContentView_iOS: View {
    @StateObject private var journalManager = JournalManager()
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var showingStorageInfo = false
    
    var body: some View {
        NavigationStack {
            Group {
                if journalManager.entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("Start Your Journal")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Tap the + button to create your first entry")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Add photos to capture visual memories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(journalManager.entries) { entry in
                            EntryRowView(entry: entry, journalManager: journalManager)
                                .onTapGesture {
                                    selectedEntry = entry
                                }
                        }
                        .onDelete(perform: journalManager.deleteEntry)
                    }
                }
            }
            .navigationTitle("My Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingStorageInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(journalManager: journalManager)
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry, journalManager: journalManager)
            }
            .alert("Storage Information", isPresented: $showingStorageInfo) {
                Button("OK") { }
            } message: {
                Text(journalManager.getStorageInfo())
            }
        }
    }
}

struct EntryRowView: View {
    let entry: JournalEntry
    @ObservedObject var journalManager: JournalManager
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            // Thumbnail image if available
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.mood)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if entry.modifiedAt != entry.createdAt {
                            Text("Modified")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text(entry.title)
                    .font(.headline)
                
                Text(entry.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingEditSheet = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditSheet) {
            EditEntryView(entry: entry, journalManager: journalManager)
        }
    }
}

struct EntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var journalManager: JournalManager
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editMood = ""
    @State private var selectedImage: UIImage?
    @State private var imageChanged = false
    
    let moods = ["Happy", "Sad", "Excited", "Calm", "Grateful", "Neutral"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image if available
                    if let image = (isEditing ? selectedImage : entry.image) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(isEditing ? editMood : entry.mood)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(entry.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if entry.modifiedAt != entry.createdAt {
                                    Text("Modified \(entry.modifiedAt, style: .relative) ago")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if isEditing {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.headline)
                                
                                TextField("Enter a title...", text: $editTitle)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mood")
                                    .font(.headline)
                                
                                Picker("Mood", selection: $editMood) {
                                    ForEach(moods, id: \.self) { mood in
                                        Text(mood).tag(mood)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your thoughts")
                                    .font(.headline)
                                
                                TextEditor(text: $editContent)
                                    .frame(minHeight: 200)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        } else {
                            Text(entry.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(entry.content)
                                .font(.body)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                            resetEditFields()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                        .disabled(editTitle.isEmpty)
                    } else {
                        HStack {
                            Button("Edit") {
                                startEditing()
                            }
                            
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            resetEditFields()
        }
    }
    
    private func startEditing() {
        editTitle = entry.title
        editContent = entry.content
        editMood = entry.mood
        selectedImage = entry.image
        imageChanged = false
        isEditing = true
    }
    
    private func resetEditFields() {
        editTitle = entry.title
        editContent = entry.content
        editMood = entry.mood
        selectedImage = entry.image
        imageChanged = false
    }
    
    private func saveChanges() {
        let imageData = imageChanged ? selectedImage?.jpegData(compressionQuality: 0.8) : nil
        journalManager.updateEntry(entry, title: editTitle, content: editContent, mood: editMood, imageData: imageData)
    }
}

struct NewEntryView: View {
    @ObservedObject var journalManager: JournalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var mood = "Happy"
    @State private var selectedImage: UIImage?
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingDocumentScanner = false
    @State private var showingPhotoOptions = false
    @State private var cameraPosition: CameraPosition = .back
    
    let moods = ["Happy", "Sad", "Excited", "Calm", "Grateful", "Neutral"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo")
                            .font(.headline)
                        
                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                
                                Button(action: { self.selectedImage = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8)
                            }
                        } else {
                            Button(action: { showingPhotoOptions = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    Text("Add Photo")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("Selfie • Landscape • Document")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        
                        TextField("Enter a title...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.headline)
                        
                        Picker("Mood", selection: $mood) {
                            ForEach(moods, id: \.self) { mood in
                                Text(mood).tag(mood)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your thoughts")
                            .font(.headline)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
                        let entry = JournalEntry(
                            title: title,
                            content: content,
                            date: Date(),
                            mood: mood,
                            imageData: imageData
                        )
                        journalManager.addEntry(entry)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showingPhotoOptions) {
                Button("Take Selfie") {
                    cameraPosition = .front
                    showingCamera = true
                }
                
                Button("Take Photo") {
                    cameraPosition = .back
                    showingCamera = true
                }
                
                Button("Scan Document") {
                    showingDocumentScanner = true
                }
                
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage, cameraPosition: cameraPosition)
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPickerView(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView(selectedImage: $selectedImage)
            }
        }
    }
}

struct EditEntryView: View {
    let entry: JournalEntry
    @ObservedObject var journalManager: JournalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editMood = ""
    @State private var selectedImage: UIImage?
    @State private var imageChanged = false
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingDocumentScanner = false
    @State private var showingPhotoOptions = false
    @State private var cameraPosition: CameraPosition = .back
    
    let moods = ["Happy", "Sad", "Excited", "Calm", "Grateful", "Neutral"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo")
                            .font(.headline)
                        
                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                
                                Button(action: {
                                    self.selectedImage = nil
                                    self.imageChanged = true
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8)
                            }
                        } else {
                            Button(action: { showingPhotoOptions = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    Text("Add Photo")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("Selfie • Landscape • Document")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        
                        TextField("Enter a title...", text: $editTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.headline)
                        
                        Picker("Mood", selection: $editMood) {
                            ForEach(moods, id: \.self) { mood in
                                Text(mood).tag(mood)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your thoughts")
                            .font(.headline)
                        
                        TextEditor(text: $editContent)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(editTitle.isEmpty)
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showingPhotoOptions) {
                Button("Take Selfie") {
                    cameraPosition = .front
                    showingCamera = true
                }
                
                Button("Take Photo") {
                    cameraPosition = .back
                    showingCamera = true
                }
                
                Button("Scan Document") {
                    showingDocumentScanner = true
                }
                
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage, cameraPosition: cameraPosition) {
                    imageChanged = true
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPickerView(selectedImage: $selectedImage) {
                    imageChanged = true
                }
            }
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView(selectedImage: $selectedImage) {
                    imageChanged = true
                }
            }
        }
        .onAppear {
            editTitle = entry.title
            editContent = entry.content
            editMood = entry.mood
            selectedImage = entry.image
            imageChanged = false
        }
    }
    
    private func saveChanges() {
        let imageData = imageChanged ? selectedImage?.jpegData(compressionQuality: 0.8) : nil
        journalManager.updateEntry(entry, title: editTitle, content: editContent, mood: editMood, imageData: imageData)
    }
}

enum CameraPosition {
    case front, back
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    let cameraPosition: CameraPosition
    var onImageSelected: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = cameraPosition == .front ? .front : .rear
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.onImageSelected?()
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    var onImageSelected: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                        self.parent.onImageSelected?()
                    }
                }
            }
        }
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    var onImageSelected: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                parent.selectedImage = scan.imageOfPage(at: 0)
                parent.onImageSelected?()
            }
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView_iOS()
}

#endif // iOS only