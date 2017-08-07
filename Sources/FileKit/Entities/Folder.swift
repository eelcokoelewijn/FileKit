import Foundation

public struct Folder {
    public let location: URL
    public let filePaths: [URL]

    public init(location: URL, filePaths: [URL] = []) {
        self.location = location
        self.filePaths = filePaths
    }
}

extension Folder: Equatable {}

public func == (lhs: Folder, rhs: Folder) -> Bool {
    return lhs.location == rhs.location && lhs.filePaths == rhs.filePaths
}
