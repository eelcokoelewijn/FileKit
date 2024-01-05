import Foundation

public struct File: Equatable {
    public let name: String
    public let folder: Folder
    public let data: Data?

    public var location: URL {
        folder.location.appendingPathComponent(name)
    }

    public init(name: String, folder: Folder, data: Data? = nil) {
        self.name = name
        self.folder = folder
        self.data = data
    }
}
