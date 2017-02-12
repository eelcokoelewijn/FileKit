import Foundation

public enum FileKitError: Error {
    case failedToSave(path: URL)
    case failedToLoad(path: URL)
    case failedToDelete(path: URL)
    case failedToCreate(path: URL)
}

public class FileKit {
    public init() { }
    
    public func save(file: File, withAttributes attr: [String: Any]? = nil) throws {
        if !FileManager.default.fileExists(atPath: file.folder.path.path) {
            try create(folder: file.folder, withAttributes: attr)
        }
        guard FileManager
            .default
            .createFile(atPath: file.path.path,
                        contents: file.data,
                        attributes: attr) == true else {
                            throw(FileKitError.failedToSave(path: file.path))
        }
    }
    
    public func create(folder: Folder, withAttributes attr: [String: Any]? = nil) throws {
        do {
            try FileManager.default.createDirectory(at: folder.path, withIntermediateDirectories: true, attributes: attr)
        } catch {
            throw FileKitError.failedToCreate(path: folder.path)
        }
    }
    
    public func load(file: File) throws -> File {
        guard let data = FileManager
            .default
            .contents(atPath: file.path.path) else {
                throw(FileKitError.failedToLoad(path: file.path))
        }
        
        return File(name: file.name, folder: file.folder, data: data)
    }
    
    public func load(folder: Folder) throws -> Folder {
        let fileURLs: [URL]
        do {
            fileURLs = try FileManager
            .default
            .contentsOfDirectory(at: folder.path, includingPropertiesForKeys: nil)
        } catch {
            throw FileKitError.failedToLoad(path: folder.path)
        }
        return Folder(path: folder.path, filePaths: fileURLs)
    }
    
    public func delete(file: File) throws {
        do {
            try FileManager.default.removeItem(at: file.path)
        } catch {
            throw(FileKitError.failedToDelete(path: file.path))
        }
    }
    
    public func delete(folder: Folder) throws {
        do {
            try FileManager.default.removeItem(at: folder.path)
        } catch {
            throw(FileKitError.failedToDelete(path: folder.path))
        }
    }
}

public extension FileKit {
    public static func pathToCachesFolder() -> URL {
        let urls = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory,
                                            in: FileManager.SearchPathDomainMask.userDomainMask)
        guard let url = urls.first else {
            fatalError("Path to caches folder not found")
        }
        return url
    }

    public static func cachesFolder() -> Folder {
        return Folder(path: pathToCachesFolder())
    }
    
    public static func fileInCachesFolder(withName name: String, data: Data? = nil) -> File {
        return File(name: name, folder: cachesFolder(), data: data)
    }
    
    public static func pathToDocumentsFolder() -> URL {
        let urls = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                            in: FileManager.SearchPathDomainMask.userDomainMask)
        guard let url = urls.first else {
            fatalError("Path to document folder not found")
        }
        return url
    }
    
    public static func documentsFolder() -> Folder {
        return Folder(path: pathToDocumentsFolder())
    }
    
    public static func fileInDocumentsFolder(withName name: String, data: Data? = nil) -> File {
        return File(name: name, folder: documentsFolder(), data: data)
    }
    
    public static func path(forResource resource: String,
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
        return File(name: "\(resource).\(ext)", folder: Folder(path: path))
    }
}
