import Foundation

struct ProjectDiscovery {
    static let scanDirectories = [
        "Documents", "code", "Developer", "Projects", "src"
    ]

    static func discoverProjects() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fm = FileManager.default
        var found: [String] = []

        for dir in scanDirectories {
            let scanPath = "\(home)/\(dir)"
            guard fm.fileExists(atPath: scanPath) else { continue }

            guard let children = try? fm.contentsOfDirectory(atPath: scanPath) else { continue }
            for child in children {
                let projectPath = "\(scanPath)/\(child)"
                let settingsPath = "\(projectPath)/.claude/settings.json"
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: projectPath, isDirectory: &isDir),
                   isDir.boolValue,
                   fm.fileExists(atPath: settingsPath) {
                    found.append(projectPath)
                }
            }
        }

        return found.sorted()
    }
}
