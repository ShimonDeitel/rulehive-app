import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("rulehive.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var restoreMessage: String?

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Rulehive \(v)"
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                howItWorksSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .tint(RulehiveColor.gold)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Erase All Rulehive Data?", isPresented: $showDeleteConfirm) {
                Button("Erase", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes every indexed game and page. Rulehive keeps no data anywhere else.")
            }
        }
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if store.isPro {
                HStack {
                    Label("Rulehive Pro", systemImage: "books.vertical.fill")
                    Spacer()
                    Text("Active").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Haptics.tap(); showPaywall = true
                } label: {
                    HStack {
                        Label("Get Rulehive Pro", systemImage: "books.vertical.fill")
                        Spacer()
                        Text("\(store.displayPrice)/mo").foregroundStyle(.secondary)
                    }
                }
                Button("Restore Purchase") {
                    Task {
                        await store.restore()
                        restoreMessage = store.isPro ? "Restored." : "No previous purchase found."
                    }
                }
                if let restoreMessage {
                    Text(restoreMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !store.isPro {
                Text("Free indexes up to \(AppModel.freeGameLimit) games. Pro unlocks unlimited games and search across all of them.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeRaw) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var howItWorksSection: some View {
        Section {
            DisclosureGroup("How Rulehive indexes a rulebook") {
                Text("Each page photo is sent to the shared AI proxy's vision route, which transcribes the visible text. Rulehive stores that transcription with the page number you're on, then searches across all indexed pages client-side using simple keyword matching — no photo-perfect rendering, just the extracted text and which page it came from.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataSection: some View {
        Section {
            Button("Erase All Data", role: .destructive) { showDeleteConfirm = true }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Indexed games (\(appModel.games().count)) live only in this app on this device. Rulebook page photos are sent to the AI proxy only while a page is being transcribed and are not stored on the server.")
        }
    }

    private var aboutSection: some View {
        Section {
            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/rulehive-app/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://shimondeitel.github.io/rulehive-app/terms.html")!)
        } footer: {
            Text(version).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
        }
    }
}
