import SwiftUI

struct ProfileListView: View {
    @ObservedObject var store: ProfileStore
    @Binding var selectedProfileName: String?

    var body: some View {
        List(store.profiles, selection: $selectedProfileName) { profile in
            HStack(spacing: 8) {
                if profile.name == store.currentProfileName {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                Text(profile.name.capitalized)
                    .lineLimit(1)
                Spacer()
            }
            .tag(profile.name)
            .contextMenu {
                Button("Delete", role: .destructive) {
                    store.delete(name: profile.name)
                    if selectedProfileName == profile.name {
                        selectedProfileName = store.profiles.first?.name
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay(alignment: .bottom) {
            HStack {
                Spacer()
                Button {
                    let newProfile = Profile.blank(name: "new-profile")
                    store.save(newProfile)
                    selectedProfileName = newProfile.name
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .padding(8)
            }
        }
    }
}
