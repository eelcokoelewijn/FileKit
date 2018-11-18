import Foundation

public struct File {
    public let name: String
    public let folder: Folder
    public let data: Data?

    public init(name: String, folder: Folder, data: Data? = nil) {
        self.name = name
        self.folder = folder
        self.data = data
    }
}

extension File: Equatable { }

extension File {
    public var location: URL {
        return folder.location.appendingPathComponent(name)
    }
}
