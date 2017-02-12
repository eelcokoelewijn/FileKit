import Foundation

public struct Folder {
    public let path: URL
    public let filePaths: [URL]
    
    public init(path: URL, filePaths: [URL] = []) {
        self.path = path
        self.filePaths = filePaths
    }
}

extension Folder: Equatable {}

public func ==(lhs: Folder, rhs: Folder) -> Bool {
    return lhs.path == rhs.path && lhs.filePaths == rhs.filePaths
}
