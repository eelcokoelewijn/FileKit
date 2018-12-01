import Foundation

public struct Folder {
    public let location: URL
    public let filePaths: [URL]
    public let files: [File]

    public init(location: URL, filePaths: [URL] = [], files: [File] = []) {
        self.location = location
        self.filePaths = filePaths
        self.files = files
    }
}

extension Folder: Equatable { }
