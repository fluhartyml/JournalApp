import SwiftUI

@main
struct Journal_AppApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(macOS) && !targetEnvironment(macCatalyst)
                ContentView_MacOS()  // Pure macOS app (not Catalyst)
            #elseif os(iOS) || targetEnvironment(macCatalyst)
                ContentView_iOS()    // iOS and Mac Catalyst
            #else
                ContentView_Fallback()  // Fallback for other platforms
            #endif
        }
    }
}

// Fallback view for unsupported platforms
struct ContentView_Fallback: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "book")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                Text("Journal App")
                    .font(.title)
                    .bold()
                Text("This platform is not yet supported")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Journal")
        }
    }
}

#Preview("Fallback") {
    ContentView_Fallback()
}