import Foundation

struct RecentPhoto: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let filename: String
}

struct RecentPhotoStore {
    private static let indexFilename = "recent-photos.json"

    private let directory: URL
    private let maximumCount: Int
    private let fileManager: FileManager
    private(set) var items: [RecentPhoto]

    init(
        directory: URL = Self.defaultDirectory,
        maximumCount: Int = 8,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.maximumCount = max(1, maximumCount)
        self.fileManager = fileManager
        self.items = Self.loadItems(from: directory, fileManager: fileManager)
    }

    @discardableResult
    mutating func store(data: Data) throws -> RecentPhoto {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let photo = RecentPhoto(id: UUID(), createdAt: Date(), filename: "\(UUID().uuidString).jpg")
        try data.write(to: fileURL(for: photo), options: .atomic)
        items.insert(photo, at: 0)

        let overflow = Array(items.dropFirst(maximumCount))
        items = Array(items.prefix(maximumCount))
        overflow.forEach { try? fileManager.removeItem(at: fileURL(for: $0)) }
        try persistIndex()
        return photo
    }

    func data(for photo: RecentPhoto) throws -> Data {
        try Data(contentsOf: fileURL(for: photo))
    }

    private func persistIndex() throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: directory.appendingPathComponent(Self.indexFilename), options: .atomic)
    }

    private func fileURL(for photo: RecentPhoto) -> URL {
        directory.appendingPathComponent(photo.filename)
    }

    private static func loadItems(from directory: URL, fileManager: FileManager) -> [RecentPhoto] {
        let indexURL = directory.appendingPathComponent(indexFilename)
        guard
            fileManager.fileExists(atPath: indexURL.path),
            let data = try? Data(contentsOf: indexURL),
            let items = try? JSONDecoder().decode([RecentPhoto].self, from: data)
        else {
            return []
        }
        return items.filter { fileManager.fileExists(atPath: directory.appendingPathComponent($0.filename).path) }
    }

    private static var defaultDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("CuteStickerCamera/RecentPhotos", isDirectory: true)
    }
}
