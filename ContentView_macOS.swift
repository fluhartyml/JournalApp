//ContentView_MacOS 0830
#if os(macOS) && !targetEnvironment(macCatalyst)

import SwiftUI
import Foundation

struct MacJournalEntry: Identifiable, Codable {
    let id: String
    var title: String
    var content: String
    var date: Date
    var mood: String
    
    init(title: String, content: String, date: Date, mood: String) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.date = date
        self.mood = mood
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

class MacJournalManager: ObservableObject {
    @Published var entries: [MacJournalEntry] = []

    private let fileName = "journal_entries_mac.json"
    private let migrationFlagKey = "didMigrateLocalToICloudJournal_mac"

    private var ubiquityContainerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }

    private var iCloudDocumentsURL: URL? {
        ubiquityContainerURL?.appendingPathComponent("Documents")
    }

    private var localDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var currentStoreURL: URL {
        if let iCloudURL = iCloudDocumentsURL {
            return iCloudURL.appendingPathComponent(fileName)
        } else {
            return localDocumentsURL.appendingPathComponent(fileName)
        }
    }

    init() {
        if let iCloudDocs = iCloudDocumentsURL {
            try? FileManager.default.createDirectory(at: iCloudDocs, withIntermediateDirectories: true)
        }
        migrateLocalFileToICloudIfNeeded()
        startMetadataQuery()
        loadEntries()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addEntry(_ entry: MacJournalEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }

    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
    }

    func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            try ensureCurrentDirectoryExists()
            try data.write(to: currentStoreURL, options: [.atomic])
        } catch {
            print("Failed to save entries: \(error)")
        }
    }

    func loadEntries() {
        do {
            let data = try Data(contentsOf: currentStoreURL)
            entries = try JSONDecoder().decode([MacJournalEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    // MARK: - Helpers

    private func ensureCurrentDirectoryExists() throws {
        let dir = currentStoreURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func migrateLocalFileToICloudIfNeeded() {
        guard UserDefaults.standard.bool(forKey: migrationFlagKey) == false else { return }
        guard let iCloudDocs = iCloudDocumentsURL else { return }

        let localURL = localDocumentsURL.appendingPathComponent(fileName)
        let iCloudURL = iCloudDocs.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            UserDefaults.standard.set(true, forKey: migrationFlagKey)
            return
        }

        do {
            try FileManager.default.createDirectory(at: iCloudDocs, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: iCloudURL.path) == false {
                try FileManager.default.copyItem(at: localURL, to: iCloudURL)
                print("Migrated macOS journal to iCloud Drive")
            }
            UserDefaults.standard.set(true, forKey: migrationFlagKey)
        } catch {
            print("Migration to iCloud failed: \(error)")
        }
    }

    // MARK: - Metadata query for iCloud file updates

    private var metadataQuery: NSMetadataQuery?

    private func startMetadataQuery() {
        guard metadataQuery == nil else { return }
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, fileName)

        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { [weak self] _ in
            query.disableUpdates()
            self?.processMetadataResults(query)
            query.enableUpdates()
        }
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidUpdate, object: query, queue: .main) { [weak self] _ in
            self?.processMetadataResults(query)
        }
        metadataQuery = query
        query.start()
    }

    private func processMetadataResults(_ query: NSMetadataQuery) {
        loadEntries()
    }
}

struct ContentView_MacOS: View {
    @StateObject private var journalManager = MacJournalManager()
    @State private var showingNewEntry = false
    @State private var selectedEntry: MacJournalEntry?
    
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
                        
                        Text("Click the + button to create your first entry")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(journalManager.entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.mood)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Text(entry.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(entry.title)
                                    .font(.headline)
                                
                                Text(entry.content)
                                    .font(.body)
                                    .lineLimit(3)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
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
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                MacNewEntryView(journalManager: journalManager)
            }
            .sheet(item: $selectedEntry) { entry in
                MacEntryDetailView(entry: entry)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct MacNewEntryView: View {
    @ObservedObject var journalManager: MacJournalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var mood = "Happy"
    
    let moods = ["Happy", "Sad", "Excited", "Calm", "Grateful", "Neutral"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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
                    .pickerStyle(MenuPickerStyle())
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = MacJournalEntry(
                            title: title.isEmpty ? "Untitled Entry" : title,
                            content: content,
                            date: Date(),
                            mood: mood
                        )
                        journalManager.addEntry(entry)
                        dismiss()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}

struct MacEntryDetailView: View {
    let entry: MacJournalEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(entry.mood)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        Text(entry.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(entry.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(entry.content)
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("Journal Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    ContentView_MacOS()
}

#endif // os(macOS) && !targetEnvironment(macCatalyst)
