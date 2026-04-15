import SwiftUI

struct ProfileFormView: View {
    @ObservedObject var store: ProfileStore
    @Binding var profile: Profile

    @State private var draft: Profile
    @State private var showDeleteConfirmation = false
    @State private var showSuccessMessage = false

    init(store: ProfileStore, profile: Binding<Profile>) {
        self.store = store
        _profile = profile
        _draft = State(initialValue: profile.wrappedValue)
    }

    private var nameChanged: Bool {
        draft.name != profile.name
    }

    private var hasChanges: Bool {
        nameChanged
            || draft.baseUrl != profile.baseUrl
            || draft.authType != profile.authType
            || draft.token != profile.token
            || draft.sonnetModel != profile.sonnetModel
            || draft.opusModel != profile.opusModel
            || draft.haikuModel != profile.haikuModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Profile Name
                GroupBox("Profile") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledField(label: "Name") {
                            TextField("profile-name", text: $draft.name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(8)
                }

                // Connection Section
                GroupBox("Connection") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledField(label: "Base URL") {
                            TextField("https://api.anthropic.com", text: $draft.baseUrl)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField(label: "Auth Type") {
                            Picker("", selection: $draft.authType) {
                                ForEach(AuthType.allCases, id: \.self) { type in
                                    Text(type.label).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        LabeledField(label: draft.authType.label) {
                            SecureField(draft.authType.placeholder, text: $draft.token)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(8)
                }

                // Model Mapping Section
                GroupBox("Model Mappings") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledField(label: "Sonnet") {
                            TextField("e.g. claude-3-5-sonnet-20241022", text: $draft.sonnetModel)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField(label: "Opus") {
                            TextField("e.g. claude-3-opus-20240229", text: $draft.opusModel)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField(label: "Haiku") {
                            TextField("e.g. claude-3-5-haiku-20241022", text: $draft.haikuModel)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(8)
                }

                // Actions
                HStack {
                    Button("Delete Profile", role: .destructive) {
                        showDeleteConfirmation = true
                    }

                    Spacer()

                    Button("Save") {
                        let oldName = profile.name
                        profile = draft
                        store.save(draft)
                        if nameChanged {
                            store.delete(name: oldName)
                        }
                        showSuccessMessage = true
                    }
                    .disabled(!hasChanges || draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .alert("Profile Saved", isPresented: $showSuccessMessage) {
            Button("OK") {}
        }
        .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.delete(name: profile.name)
            }
        } message: {
            Text("This will permanently remove the profile \"\(profile.name.capitalized)\".")
        }
        .onChange(of: profile) { newProfile in
            draft = newProfile
        }
    }
}

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
        }
    }
}
