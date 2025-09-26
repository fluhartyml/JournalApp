// JournalApp
import SwiftUI

@main
struct JournalApp: App {
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
        VStack {
            Text("Journal App")
                .font(.largeTitle)
            Text("This platform is not yet supported")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Fallback implementations if the platform-specific views aren't available
#if os(macOS) && !targetEnvironment(macCatalyst)
// If ContentView_macOS isn't found, provide a fallback
extension ContentView_Fallback {
    static func fallbackMacOS() -> some View {
        ContentView_Fallback()
    }
}
#endif

#if os(iOS) || targetEnvironment(macCatalyst)
// If ContentView_iOS isn't found, provide a fallback
extension ContentView_Fallback {
    static func fallbackiOS() -> some View {
        ContentView_Fallback()
    }
}
#endif
