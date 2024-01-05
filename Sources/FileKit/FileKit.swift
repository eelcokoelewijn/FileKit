import Foundation

public enum FileKitError: Error, LocalizedError {
    case failedToSave(path: URL)
    case failedToLoad(path: URL)
    case failedToDelete(path: URL)
    case failedToCreate(path: URL)
    case folderDoesntExist(path: URL)
    case searchPathDoesntExist(path: FileManager.SearchPathDirectory)
    case invalid(path: String)

    public var errorDescription: String? {
        switch self {
        case let .failedToSave(path):
            return "Failed to save file at \(path)"
        case let .failedToLoad(path):
            return "Failed to load file at \(path)"
        case let .failedToDelete(path):
            return "Failed to delete file at \(path)"
        case let .failedToCreate(path):
            return "Failed to create file at \(path)"
        case let .folderDoesntExist(path):
            return "Folder doesn't exist at \(path)"
        case let .searchPathDoesntExist(path):
            return "Search path doesn't exist at \(path)"
        case let .invalid(path):
            return "Invalid path \(path)"
        }
    }
}

public class FileKit {
    public init(fileManager: FileManager = FileManager.default) {
        self._fileManager = fileManager
    }

    /// Saves a file to the specified location with optional attributes.
    /// - Parameters:
    ///   - file: The file to save.
    ///   - attr: Optional file attributes.
    /// - Throws: `FileKitError` if the file cannot be saved.
    /// - Returns: The URL of the saved file.
    public func save(file: File, withAttributes attr: [FileAttributeKey: Any]? = nil) throws -> URL {
        try ensureExists(path: file.folder.location)
        guard _fileManager.createFile(atPath: file.location.path, contents: file.data, attributes: attr) else {
            throw FileKitError.failedToSave(path: file.location)
        }
        return file.location
    }

    /// Creates a folder at the specified location with optional attributes.
    /// - Parameters:
    ///   - folder: The folder to create.
    ///   - attr: Optional folder attributes.
    /// - Throws: `FileKitError` if the folder cannot be created.
    /// - Returns: The URL of the created folder.
    public func create(folder: Folder, withAttributes attr: [FileAttributeKey: Any]? = nil) throws -> URL {
        do {
            try _fileManager.createDirectory(at: folder.location, withIntermediateDirectories: true, attributes: attr)
        } catch {
            throw FileKitError.failedToCreate(path: folder.location)
        }
        return folder.location
    }

    /// Loads a file from the specified location.
    /// - Parameter file: The file to load.
    /// - Throws: `FileKitError` if the file cannot be loaded.
    /// - Returns: The loaded file.
    public func load(file: File) throws -> File {
        guard
            let data = _fileManager.contents(atPath: file.location.path)
        else {
            throw FileKitError.failedToLoad(path: file.location)
        }
        return File(name: file.name, folder: file.folder, data: data)
    }

    /// Loads a folder from the specified location.
    /// - Parameter folder: The folder to load.
    /// - Throws: `FileKitError` if the folder cannot be loaded.
    /// - Returns: The loaded folder.
    public func load(folder: Folder) throws -> Folder {
        let fileURLs: [URL]
        do {
            fileURLs = try _fileManager.contentsOfDirectory(at: folder.location, includingPropertiesForKeys: nil)
        } catch {
            throw FileKitError.failedToLoad(path: folder.location)
        }
        let files: [File] = fileURLs.map { (url: URL) -> File in
            File(
                name: url.lastPathComponent,
                folder: Folder(location: folder.location)
            )
        }
        return Folder(location: folder.location, filePaths: fileURLs, files: files)
    }

    /// Deletes a file from the specified location.
    /// - Parameter file: The file to delete.
    /// - Throws: `FileKitError` if the file cannot be deleted.
    /// - Returns: The URL of the deleted file.
    public func delete(file: File) throws -> URL {
        do {
            try _fileManager.removeItem(at: file.location)
        } catch {
            throw FileKitError.failedToDelete(path: file.location)
        }
        return file.location
    }

    /// Deletes a folder from the specified location.
    /// - Parameter folder: The folder to delete.
    /// - Throws: `FileKitError` if the folder cannot be deleted.
    /// - Returns: The URL of the deleted folder.
    public func delete(folder: Folder) throws -> URL {
        do {
            try _fileManager.removeItem(at: folder.location)
        } catch {
            throw FileKitError.failedToDelete(path: folder.location)
        }
        return folder.location
    }

    private func ensureExists(path: URL) throws {
        if !_fileManager.fileExists(atPath: path.path) {
            throw FileKitError.folderDoesntExist(path: path)
        }
    }

    private let _fileManager: FileManager
}

public extension FileKit {
    /// Path to the search path directory.
    /// - Parameter searchPath: The search path directory.
    /// - Throws: `FileKitError` if the search path directory doesn't exist.
    /// - Returns: The path to the search path directory.
    static func pathToFolder(forSearchPath searchPath: FileManager.SearchPathDirectory) throws -> URL {
        let urls = FileManager.default.urls(for: searchPath, in: FileManager.SearchPathDomainMask.userDomainMask)
        guard let url = urls.first else {
            throw FileKitError.searchPathDoesntExist(path: searchPath)
        }
        return url
    }

    /// Folder for the search path directory.
    /// - Parameter searchPath: The search path directory.
    /// - Throws: `FileKitError` if the search path directory doesn't exist.
    /// - Returns: The folder for the search path directory.
    static func folder(forSearchPath searchPath: FileManager.SearchPathDirectory) throws -> Folder {
        try Folder(location: pathToFolder(forSearchPath: searchPath))
    }

    /// File in the cache directory.
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - data: Optional data to save to the file.
    /// - Throws: `FileKitError` if the file cannot be created.
    /// - Returns: The file in the cache directory.
    static func fileInCachesFolder(withName name: String, data: Data? = nil) throws -> File {
        try File(name: name, folder: folder(forSearchPath: .cachesDirectory), data: data)
    }

    /// File in the documents directory.
    /// - Parameters:
    ///  - name: The name of the file.
    ///  - data: Optional data to save to the file.
    /// - Throws: `FileKitError` if the file cannot be created.
    /// - Returns: The file in the documents directory.
    static func fileInDocumentsFolder(withName name: String, data: Data? = nil) throws -> File {
        try File(name: name, folder: folder(forSearchPath: .documentDirectory), data: data)
    }

    /// File for resource in bundle.
    /// - Parameters:
    ///  - resource: The name of the resource.
    ///  - ext: The extension of the resource.
    ///  - bundle: The bundle to search for the resource.
    ///  - subdir: Optional subdirectory to search for the resource.
    /// - Throws: `FileKitError` if the file cannot be created.
    /// - Returns: The file for the resource.
    static func path(forResource resource: String, withExtension ext: String, inBundle bundle: Bundle, subdirectory subdir: String? = nil) throws -> File {
        guard let url = bundle.url(forResource: resource, withExtension: ext, subdirectory: subdir) else {
            throw FileKitError.failedToLoad(path: URL(string: resource)!)
        }

        var path = URL(fileURLWithPath: url.pathComponents.first!)
        url.pathComponents.dropFirst().dropLast().forEach { component in
            path.appendPathComponent(component)
        }
        return File(name: "\(resource).\(ext)", folder: Folder(location: path))
    }

    /// Current working folder.
    /// - Returns: The current working folder.
    static func currentWorkingFolder() -> Folder? {
        guard let currentWorkingURL = URL(string: FileManager.default.currentDirectoryPath) else {
            return nil
        }
        return Folder(location: currentWorkingURL)
    }

    /// URL from path.
    /// - Parameters:
    ///  - path: The path to convert to a URL.
    ///  - isDirectory: Whether the path is a directory.
    /// - Returns: The URL from the path.
    static func url(fromPath path: String, isDirectory: Bool = true) -> URL {
        URL(fileURLWithPath: path, isDirectory: isDirectory)
    }

    /// Folder from path.
    /// - Parameters:
    ///  - path: The path to convert to a folder.
    ///  - isDirectory: Whether the path is a directory.
    /// - Returns: The folder from the path.
    static func folder(fromPath path: String, isDirectory: Bool = true) -> Folder {
        Folder(location: url(fromPath: path))
    }
}
