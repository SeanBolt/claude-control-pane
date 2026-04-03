import SwiftUI

struct HooksView: View {
    @Bindable var manager: SettingsFileManager

    private var hasSoundHook: Bool {
        guard let groups = manager.settings.hooks["Stop"] else { return false }
        return groups.contains { group in
            group.hooks.contains { $0.command.contains("afplay") }
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Play sound when Claude finishes", isOn: Binding(
                    get: { hasSoundHook },
                    set: { enabled in
                        manager.updateSettings { settings in
                            if enabled {
                                let hook = Hook(type: "command", command: "afplay /System/Library/Sounds/Funk.aiff")
                                let group = HookGroup(hooks: [hook])
                                if settings.hooks["Stop"] != nil {
                                    settings.hooks["Stop"]!.append(group)
                                } else {
                                    settings.hooks["Stop"] = [group]
                                }
                            } else {
                                settings.hooks["Stop"]?.removeAll { group in
                                    group.hooks.contains { $0.command.contains("afplay") }
                                }
                                if settings.hooks["Stop"]?.isEmpty == true {
                                    settings.hooks.removeValue(forKey: "Stop")
                                }
                            }
                        }
                    }
                ))
            } header: {
                Text("Quick Settings")
            }

            ForEach(ClaudeSettings.knownHookEvents, id: \.self) { event in
                Section {
                    let groups = manager.settings.hooks[event] ?? []
                    if groups.isEmpty {
                        Text("No hooks configured")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(Array(groups.enumerated()), id: \.element.id) { groupIndex, group in
                            ForEach(Array(group.hooks.enumerated()), id: \.element.id) { hookIndex, hook in
                                HookRowView(
                                    command: hook.command,
                                    onUpdate: { newCommand in
                                        manager.updateSettings { settings in
                                            settings.hooks[event]?[groupIndex].hooks[hookIndex].command = newCommand
                                        }
                                    },
                                    onDelete: {
                                        manager.updateSettings { settings in
                                            settings.hooks[event]?[groupIndex].hooks.remove(at: hookIndex)
                                            if settings.hooks[event]?[groupIndex].hooks.isEmpty == true {
                                                settings.hooks[event]?.remove(at: groupIndex)
                                            }
                                            if settings.hooks[event]?.isEmpty == true {
                                                settings.hooks.removeValue(forKey: event)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }

                    Button("Add Hook") {
                        manager.updateSettings { settings in
                            let hook = Hook(type: "command", command: "")
                            let group = HookGroup(hooks: [hook])
                            if settings.hooks[event] != nil {
                                settings.hooks[event]!.append(group)
                            } else {
                                settings.hooks[event] = [group]
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                } header: {
                    Text(event)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct HookRowView: View {
    @State var command: String
    var onUpdate: (String) -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            TextField("Command", text: $command)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    onUpdate(command)
                }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
