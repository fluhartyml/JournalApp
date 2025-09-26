import SwiftUI

@main
struct Journal_AppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "book")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                Text("Journal App")
                    .font(.title)
                    .bold()
                Text("Welcome! This is a placeholder root view. Replace with your actual content when ready.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview("RootView") {
    RootView()
}
