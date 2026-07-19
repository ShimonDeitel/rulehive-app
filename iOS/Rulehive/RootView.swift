import SwiftUI

struct RootView: View {
    @AppStorage("rulehive.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            LibraryView()
                .navigationTitle("Rulehive")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { settingsToolbar }
        }
        .tint(RulehiveColor.gold)
        .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Haptics.tap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }
}
