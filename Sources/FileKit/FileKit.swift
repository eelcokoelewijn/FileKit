import Foundation

public enum FileKitError: Error {
    case failedToSave(path: URL)
    case failedToLoad(path: URL)
    case failedToDelete(path: URL)
    case failedToCreate(path: URL)
    case folderDoesntExist(path: URL)
}

public class FileKit {
    public init() { }

    public func save(file: File, withAttributes attr: [FileAttributeKey: Any]? = nil) throws -> URL {
        if !FileManager.default.fileExists(atPath: file.folder.location.path) {
            throw(FileKitError.folderDoesntExist(path: file.folder.location))
        }
        guard FileManager
            .default
            .createFile(atPath: file.location.path, contents: file.data, attributes: attr) == true else {
                throw(FileKitError.failedToSave(path: file.location))
        }
        return file.location
    }

    public func create(folder: Folder, withAttributes attr: [FileAttributeKey: Any]? = nil) throws -> URL {
        do {
            try FileManager.default.createDirectory(at: folder.location,
                                                    withIntermediateDirectories: true,
                                                    attributes: attr)
        } catch {
            throw(FileKitError.failedToCreate(path: folder.location))
        }
        return folder.location
    }

    public func load(file: File) throws -> File {
        guard let data = FileManager
            .default
            .contents(atPath: file.location.path) else {
                throw(FileKitError.failedToLoad(path: file.location))
        }
        return File(name: file.name, folder: file.folder, data: data)
    }

    public func load(folder: Folder) throws -> Folder {
        let fileURLs: [URL]
        do {
            fileURLs = try FileManager
                .default
                .contentsOfDirectory(at: folder.location, includingPropertiesForKeys: nil)
        } catch {
            throw (FileKitError.failedToLoad(path: folder.location))
        }
        let files: [File] = fileURLs.map { (url: URL) -> File in
            File(name: url.lastPathComponent,
                 folder: Folder(location: folder.location))
        }
        return Folder(location: folder.location,
                               filePaths: fileURLs,
                               files: files)
    }

    public func delete(file: File) throws -> URL {
        do {
            try FileManager.default.removeItem(at: file.location)
        } catch {
            throw(FileKitError.failedToDelete(path: file.location))
        }
        return file.location
    }

    public func delete(folder: Folder) throws -> URL {
        do {
            try FileManager.default.removeItem(at: folder.location)
        } catch {
            throw(FileKitError.failedToDelete(path: folder.location))
        }
        return folder.location
    }
}

public extension FileKit {
    static func pathToFolder(forSearchPath searchPath: FileManager.SearchPathDirectory) -> URL {
        let urls = FileManager.default.urls(for: searchPath,
                                            in: FileManager.SearchPathDomainMask.userDomainMask)
        guard let url = urls.first else {
            fatalError("Path to \(searchPath) folder not found")
        }
        return url
    }

    static func folder(forSearchPath searchPath: FileManager.SearchPathDirectory) -> Folder {
        return Folder(location: pathToFolder(forSearchPath: searchPath))
    }

    static func fileInCachesFolder(withName name: String, data: Data? = nil) -> File {
        return File(name: name, folder: folder(forSearchPath: .cachesDirectory), data: data)
    }

    static func fileInDocumentsFolder(withName name: String, data: Data? = nil) -> File {
        return File(name: name, folder: folder(forSearchPath: .documentDirectory), data: data)
    }

    static func path(forResource resource: String,
                            withExtension ext: String,
                            inBundle bundle: Bundle,
                            subdirectory subdir: String? = nil) throws -> File {
        guard let url = bundle.url(forResource: resource, withExtension: ext, subdirectory: subdir) else {
            throw(FileKitError.failedToLoad(path: URL(string: resource)!))
        }

        var path: URL = URL(fileURLWithPath: url.pathComponents.first!)
        url.pathComponents.dropFirst().dropLast().forEach { component in
            path.appendPathComponent(component)
        }
        return File(name: "\(resource).\(ext)", folder: Folder(location: path))
    }

    static func currentWorkingFolder() -> Folder? {
        guard let currentWorkingURL = URL(string: FileManager.default.currentDirectoryPath) else {
            return nil
        }
        return Folder(location: currentWorkingURL)
    }
}
