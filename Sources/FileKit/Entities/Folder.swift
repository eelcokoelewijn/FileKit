import Foundation

public struct Folder {
    public let location: URL
    public let filePaths: [URL]

    public init(location: URL, filePaths: [URL] = []) {
        self.location = location
        self.filePaths = filePaths
    }
}

extension Folder: Equatable { }
