import Foundation

public enum FileKitResult<T>: Error {
    case failedToSave(path: URL)
    case failedToLoad(path: URL)
    case failedToDelete(path: URL)
    case failedToCreate(path: URL)
    case success(T)
}

public class FileKit {
    public init() { }
    
    public func save(file: File,
                     queue: DispatchQueue = DispatchQueue.main,
                     withAttributes attr: [String: Any]? = nil,
                     completion: ((FileKitResult<URL>) -> ())? = nil) {
        queue.async {
            if !FileManager.default.fileExists(atPath: file.folder.path.path) {
                self.create(folder: file.folder, queue: queue, withAttributes: attr)
            }
            guard FileManager
                .default
                .createFile(atPath: file.path.path, contents: file.data, attributes: attr) == true else {
                    if let c = completion {
                        DispatchQueue.main.async {
                            c(FileKitResult.failedToSave(path: file.path))
                        }
                    }
                    return
            }
            if let c = completion {
                DispatchQueue.main.async {
                    c(.success(file.path))
                }
            }
        }
    }
    
    public func create(folder: Folder,
                       queue: DispatchQueue = DispatchQueue.main,
                       withAttributes attr: [String: Any]? = nil,
                       completion: ((FileKitResult<URL>) -> ())? = nil) {
        queue.async {
            do {
                try FileManager.default.createDirectory(at: folder.path, withIntermediateDirectories: true, attributes: attr)
            } catch {
                if let c = completion {
                    DispatchQueue.main.async {
                        c(.failedToCreate(path: folder.path))
                    }
                }
            }
            if let c = completion {
                DispatchQueue.main.async {
                    c(.success(folder.path))
                }
            }
        }
        
    }
    
    public func load(file: File,
                     queue: DispatchQueue = DispatchQueue.main,
                     completion: @escaping ((FileKitResult<File>) -> ())) {
        queue.async {
            guard let data = FileManager
                .default
                .contents(atPath: file.path.path) else {
                    DispatchQueue.main.async {
                        completion(.failedToLoad(path: file.path))
                    }
                    return
            }
            DispatchQueue.main.async {
                completion(.success(File(name: file.name, folder: file.folder, data: data)))
            }
        }
        
    }
    
    public func load(folder: Folder,
                     queue: DispatchQueue = DispatchQueue.main,
                     completion: @escaping ((FileKitResult<Folder>) -> ())) {
        queue.async {
            let fileURLs: [URL]
            do {
                fileURLs = try FileManager
                    .default
                    .contentsOfDirectory(at: folder.path, includingPropertiesForKeys: nil)
            } catch {
                DispatchQueue.main.async {
                    completion(.failedToLoad(path: folder.path))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(Folder(path: folder.path, filePaths: fileURLs)))
            }
        }
    }
    
    public func delete(file: File,
                       queue: DispatchQueue = DispatchQueue.main,
                       completion: ((FileKitResult<URL>) -> ())? = nil) {
        queue.async {
            do {
                try FileManager.default.removeItem(at: file.path)
            } catch {
                if let c = completion {
                    DispatchQueue.main.async {
                        c(.failedToDelete(path: file.path))
                    }
                }
            }
            if let c = completion {
                DispatchQueue.main.async {
                    c(.success(file.path))
                }
            }
        }
    }
    
    public func delete(folder: Folder,
                       queue: DispatchQueue = DispatchQueue.main,
                       completion: ((FileKitResult<URL>) -> ())? = nil) {
        queue.async {
            do {
                try FileManager.default.removeItem(at: folder.path)
            } catch {
                if let c = completion {
                    DispatchQueue.main.async {
                        c(.failedToDelete(path: folder.path))
                    }
                }
            }
            if let c = completion {
                DispatchQueue.main.async {
                    c(.success(folder.path))
                }
            }
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
            throw(FileKitResult<Any>.failedToLoad(path: URL(string: resource)!))
        }
        
        var path: URL = URL(fileURLWithPath: url.pathComponents.first!)
        url.pathComponents.dropFirst().dropLast().forEach { component in
            path.appendPathComponent(component)
        }
        return File(name: "\(resource).\(ext)", folder: Folder(path: path))
    }
}
