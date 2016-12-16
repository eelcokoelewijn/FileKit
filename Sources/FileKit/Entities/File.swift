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

public func ==(lhs: File, rhs: File) -> Bool {
    return lhs.name == rhs.name && lhs.data == rhs.data && lhs.folder == rhs.folder
}

extension File {
    public var path: URL {
        return folder.path.appendingPathComponent(name)
    }
}
