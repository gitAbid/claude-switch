import SwiftUI

struct ManageView: View {
    @ObservedObject var store: ProfileStore
    @State private var selectedProfileName: String?

    private var selectedProfile: Binding<Profile?> {
        Binding(
            get: {
                guard let name = selectedProfileName else { return nil }
                return store.profiles.first { $0.name == name }
            },
            set: { newProfile in
                if let p = newProfile {
                    selectedProfileName = p.name
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            ProfileListView(
                store: store,
                selectedProfileName: $selectedProfileName
            )
            .frame(minWidth: 160)
        } detail: {
            if let profile = selectedProfile.wrappedValue {
                let binding = Binding<Profile>(
                    get: { profile },
                    set: { _ in }
                )
                ProfileFormView(store: store, profile: binding)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Select a profile")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 580, minHeight: 400)
        .onAppear {
            if selectedProfileName == nil {
                selectedProfileName = store.profiles.first?.name
            }
        }
    }
}
