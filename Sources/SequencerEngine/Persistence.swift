import Foundation

public enum ProjectPersistenceError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
}

private struct ProjectPersistenceHeader: Codable {
    let schemaVersion: Int
}

private struct ProjectPersistenceEnvelope: Codable {
    let schemaVersion: Int
    let project: Project
}

extension SequencerEngine {
    public static let currentProjectSchemaVersion = 1

    public func saveProjectJSONData(prettyPrinted: Bool = false) throws -> Data {
        let envelope = ProjectPersistenceEnvelope(
            schemaVersion: Self.currentProjectSchemaVersion,
            project: project
        )
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
        return try encoder.encode(envelope)
    }

    public mutating func loadProjectJSONData(_ data: Data) throws {
        let decoder = JSONDecoder()
        let header = try decoder.decode(ProjectPersistenceHeader.self, from: data)
        guard header.schemaVersion == Self.currentProjectSchemaVersion else {
            throw ProjectPersistenceError.unsupportedSchemaVersion(header.schemaVersion)
        }

        let envelope = try decoder.decode(ProjectPersistenceEnvelope.self, from: data)
        load(project: envelope.project)
    }

    public func saveProjectJSON(to url: URL, prettyPrinted: Bool = true) throws {
        let data = try saveProjectJSONData(prettyPrinted: prettyPrinted)
        try data.write(to: url, options: .atomic)
    }

    public mutating func loadProjectJSON(from url: URL) throws {
        let data = try Data(contentsOf: url)
        try loadProjectJSONData(data)
    }
}
