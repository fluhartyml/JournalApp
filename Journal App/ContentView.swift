import SwiftUI
import Foundation

#if canImport(AppKit)
import AppKit
#endif

// Platform-specific image type
typealias PlatformImage = NSImage

struct JournalEntry: Identifiable, Codable {
    let id: String
    var title: String
    var content: String
    var date: Date
    var mood: String
    var createdAt: Date
    var modifiedAt: Date
    var imageData: Data?
    
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
    
    var image: PlatformImage? {
        guard let imageData = imageData else { return nil }
        return NSImage(data: imageData)
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
            print("Successfully saved \(entries.count) entries")
        } catch {
            print("Failed to save entries: \(error)")
        }
    }
    
    func loadEntries() {
        do {
            let data = try Data(contentsOf: journalFileURL)
            entries = try JSONDecoder().decode([JournalEntry].self, from: data)
            print("Successfully loaded \(entries.count) entries")
        } catch {
            print("Failed to load entries: \(error)")
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

struct ContentView: View {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showingStorageInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
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
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct EntryRowView: View {
    let entry: JournalEntry
    @ObservedObject var journalManager: JournalManager
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            if let image = entry.image {
                Image(nsImage: image)
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
            
            Button(action: { showingEditSheet = true }) {
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

struct NewEntryView: View {
    @ObservedObject var journalManager: JournalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var mood = "Happy"
    @State private var selectedImage: PlatformImage?
    @State private var showingImagePicker = false
    
    let moods = ["Happy", "Sad", "Excited", "Calm", "Grateful", "Neutral"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo")
                            .font(.headline)
                        
                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: selectedImage)
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
                            Button(action: { showingImagePicker = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    Text("Add Photo")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("Choose from Files")
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
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let imageData = selectedImage?.tiffRepresentation
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
            .sheet(isPresented: $showingImagePicker) {
                MacImagePickerView(selectedImage: $selectedImage)
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
    @State private var selectedImage: PlatformImage?
    @State private var imageChanged = false
    @State private var showingImagePicker = false
    
    let moods = ["Happy", "Sad", "Excited", "Calm", "Grateful", "Neutral"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo")
                            .font(.headline)
                        
                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: selectedImage)
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
                            Button(action: { showingImagePicker = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    Text("Add Photo")
                                        .font(.headline)
                                        .foregroundColor(.blue)
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
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let imageData = imageChanged ? selectedImage?.tiffRepresentation : nil
                        journalManager.updateEntry(entry, title: editTitle, content: editContent, mood: editMood, imageData: imageData)
                        dismiss()
                    }
                    .disabled(editTitle.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                MacImagePickerView(selectedImage: $selectedImage) {
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
}

struct EntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var journalManager: JournalManager
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = entry.image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(entry.mood)
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
                                    Text("Modified")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Text(entry.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(entry.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
                .padding()
            }
            .navigationTitle("Journal Entry")
            
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    HStack {
                        Button("Edit") {
                            isEditing = true
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditEntryView(entry: entry, journalManager: journalManager)
        }
    }
}

struct MacImagePickerView: View {
    @Binding var selectedImage: PlatformImage?
    @Environment(\.dismiss) private var dismiss
    var onImageSelected: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose an image file")
                .font(.headline)
            
            Button("Select Image") {
                let openPanel = NSOpenPanel()
                openPanel.allowedContentTypes = [.image]
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canChooseFiles = true
                
                if openPanel.runModal() == .OK {
                    if let url = openPanel.url,
                       let nsImage = NSImage(contentsOf: url) {
                        selectedImage = nsImage
                        onImageSelected?()
                    }
                }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
