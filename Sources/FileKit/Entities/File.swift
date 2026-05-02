import Foundation

/// Represents a file with a name, location, and optional data content.
public struct File: Equatable {
    /// The name of the file including extension.
    public let name: String
    /// The folder containing this file.
    public let folder: Folder
    /// The file's data contents, if any.
    public let data: Data?

    /// The full URL location of the file.
    public var location: URL {
        folder.location.appendingPathComponent(name)
    }

    public init(name: String, folder: Folder, data: Data? = nil) {
        self.name = name
        self.folder = folder
        self.data = data
    }
}
