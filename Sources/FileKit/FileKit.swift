import Foundation

public enum FileKitResult<T>: Error {
    case failedToSave(path: URL)
    case failedToLoad(path: URL)
    case failedToDelete(path: URL)
    case failedToCreate(path: URL)
    case folderDoesntExist(path: URL)
    case success(T)
}

public class FileKit {
    public init() { }

    public func save(file: File,
                     completionQueue: DispatchQueue = DispatchQueue.main,
                     withAttributes attr: [FileAttributeKey: Any]? = nil,
                     completion: ((FileKitResult<URL>) -> Void)? = nil) {
        let workerQueue = DispatchQueue.global()
        workerQueue.async {
            if !FileManager.default.fileExists(atPath: file.folder.location.path) {
                self.execute(onQueue: completionQueue,
                        withResult: .folderDoesntExist(path: file.folder.location),
                        completionHandler: completion)
                return
            }
            guard FileManager
                .default
                .createFile(atPath: file.location.path, contents: file.data, attributes: attr) == true else {
                    self.execute(onQueue: completionQueue,
                                 withResult: .failedToSave(path: file.location),
                                 completionHandler: completion)
                    return
            }
            self.execute(onQueue: completionQueue,
                         withResult: .success(file.location),
                         completionHandler: completion)
        }
    }

    public func create(folder: Folder,
                       completionQueue: DispatchQueue = DispatchQueue.main,
                       withAttributes attr: [FileAttributeKey: Any]? = nil,
                       completion: ((FileKitResult<URL>) -> Void)? = nil) {
        let workerQueue = DispatchQueue.global()
        workerQueue.async {
            do {
                try FileManager.default.createDirectory(at: folder.location,
                                                        withIntermediateDirectories: true,
                                                        attributes: attr)
            } catch {
                self.execute(onQueue: completionQueue,
                        withResult: .failedToCreate(path: folder.location),
                        completionHandler: completion)
                return
            }
            self.execute(onQueue: completionQueue,
                    withResult: .success(folder.location),
                    completionHandler: completion)
        }

    }

    public func load(file: File,
                     completionQueue: DispatchQueue = DispatchQueue.main,
                     completion: @escaping ((FileKitResult<File>) -> Void)) {
        let workerQueue = DispatchQueue.global()
        workerQueue.async {
            guard let data = FileManager
                .default
                .contents(atPath: file.location.path) else {
                    self.execute(onQueue: completionQueue,
                                 withResult: .failedToLoad(path: file.location),
                                 completionHandler: completion)
                    return
            }
            self.execute(onQueue: completionQueue,
                         withResult: .success(File(name: file.name, folder: file.folder, data: data)),
                         completionHandler: completion)
        }

    }

    public func load(folder: Folder,
                     completionQueue: DispatchQueue = DispatchQueue.main,
                     completion: @escaping ((FileKitResult<Folder>) -> Void)) {
        let workerQueue = DispatchQueue.global()
        workerQueue.async {
            let fileURLs: [URL]
            do {
                fileURLs = try FileManager
                    .default
                    .contentsOfDirectory(at: folder.location, includingPropertiesForKeys: nil)
            } catch {
                self.execute(onQueue: completionQueue,
                             withResult: .failedToLoad(path: folder.location),
                             completionHandler: completion)
                return
            }
            let files: [File] = fileURLs.map({ (url: URL) -> File in
                File(name: url.lastPathComponent,
                     folder: Folder(location: folder.location))
            })
            self.execute(onQueue: completionQueue,
                         withResult: .success(Folder(location: folder.location,
                                                     filePaths: fileURLs,
                                                     files: files)),
                         completionHandler: completion)
        }
    }

    public func delete(file: File,
                       completionQueue: DispatchQueue = DispatchQueue.main,
                       completion: ((FileKitResult<URL>) -> Void)? = nil) {
        let workerQueue = DispatchQueue.global()
        workerQueue.async {
            do {
                try FileManager.default.removeItem(at: file.location)
            } catch {
                self.execute(onQueue: completionQueue,
                             withResult: .failedToDelete(path: file.location),
                             completionHandler: completion)
                return
            }
            self.execute(onQueue: completionQueue,
                         withResult: .success(file.location),
                         completionHandler: completion)
        }
    }

    public func delete(folder: Folder,
                       completionQueue: DispatchQueue = DispatchQueue.main,
                       completion: ((FileKitResult<URL>) -> Void)? = nil) {
        let workerQueue = DispatchQueue.global()
        workerQueue.async {
            do {
                try FileManager.default.removeItem(at: folder.location)
            } catch {
                self.execute(onQueue: completionQueue,
                             withResult: .failedToDelete(path: folder.location),
                             completionHandler: completion)
                return
            }
            self.execute(onQueue: completionQueue,
                         withResult: .success(folder.location),
                         completionHandler: completion)
        }
    }

    private func execute<ResultType>(onQueue queue: DispatchQueue,
                                     withResult result: FileKitResult<ResultType>,
                                     completionHandler: ((FileKitResult<ResultType>) -> Void)? = nil) {
        if let completion = completionHandler {
            queue.async {
                completion(result)
            }
        }
    }
}

public extension FileKit {
    public static func pathToFolder(forSearchPath searchPath: FileManager.SearchPathDirectory) -> URL {
        let urls = FileManager.default.urls(for: searchPath,
                                            in: FileManager.SearchPathDomainMask.userDomainMask)
        guard let url = urls.first else {
            fatalError("Path to \(searchPath) folder not found")
        }
        return url
    }

    public static func folder(forSearchPath searchPath: FileManager.SearchPathDirectory) -> Folder {
        return Folder(location: pathToFolder(forSearchPath: searchPath))
    }

    public static func fileInCachesFolder(withName name: String, data: Data? = nil) -> File {
        return File(name: name, folder: folder(forSearchPath: .cachesDirectory), data: data)
    }

    public static func fileInDocumentsFolder(withName name: String, data: Data? = nil) -> File {
        return File(name: name, folder: folder(forSearchPath: .documentDirectory), data: data)
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
        return File(name: "\(resource).\(ext)", folder: Folder(location: path))
    }
}
