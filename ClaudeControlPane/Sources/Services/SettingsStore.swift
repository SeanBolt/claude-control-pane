import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class SettingsStore {
    var globalManager: SettingsFileManager
    var projectManagers: [ProjectEntry] = []

    struct ProjectEntry: Identifiable {
        let id: String
        let name: String
        let path: String
        let manager: SettingsFileManager

        init(path: String, manager: SettingsFileManager) {
            self.id = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.path = path
            self.manager = manager
        }
    }

    private static let customProjectsKey = "customProjectPaths"

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let globalPath = "\(home)/.claude/settings.json"
        self.globalManager = SettingsFileManager(filePath: globalPath)
        loadProjects()
    }

    func loadProjects() {
        let discovered = ProjectDiscovery.discoverProjects()
        let custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        let allPaths = Set(discovered + custom).sorted()

        projectManagers = allPaths.map { path in
            let settingsPath = "\(path)/.claude/settings.json"
            let manager = SettingsFileManager(filePath: settingsPath)
            return ProjectEntry(path: path, manager: manager)
        }
    }

    func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a project directory"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let path = url.path
        guard !projectManagers.contains(where: { $0.path == path }) else { return }

        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        if !custom.contains(path) {
            custom.append(path)
            UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        }

        let settingsPath = "\(path)/.claude/settings.json"
        let manager = SettingsFileManager(filePath: settingsPath)
        let entry = ProjectEntry(path: path, manager: manager)
        projectManagers.append(entry)
        projectManagers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func removeProject(_ entry: ProjectEntry) {
        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        custom.removeAll { $0 == entry.path }
        UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        projectManagers.removeAll { $0.id == entry.id }
    }
}
