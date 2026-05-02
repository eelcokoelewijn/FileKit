import Foundation

/// Represents a folder with a location and optional contents.
public struct Folder: Equatable {
    /// The URL location of the folder.
    public let location: URL
    /// URLs of items within this folder.
    public let filePaths: [URL]
    /// File objects representing the contents of this folder.
    public let files: [File]

    public init(location: URL, filePaths: [URL] = [], files: [File] = []) {
        self.location = location
        self.filePaths = filePaths
        self.files = files
    }
}
