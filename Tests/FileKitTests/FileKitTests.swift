import XCTest
import Foundation
@testable import FileKit

class FileKitTests: XCTestCase {
    var folderURL: URL!
    var filename: String!
    var pathToCache: URL!
    var invalidPath: URL!
    
    override func setUp() {
        pathToCache = FileKit.pathToCachesFolder()
        folderURL = URL(string: "filekit", relativeTo: pathToCache)
        filename = "file.txt"
        invalidPath = URL(string: "file://invalid")
    }
    
    func testSavingLoadingandDeletingOfFile() {
        let subject = FileKit()
        let data = "Hello World".data(using: String.Encoding.utf8)
        let folder = Folder(path: folderURL)
        let file = File(name: filename, folder: folder, data: data)
        
        do {
            try subject.save(file: file)
            do {
                let loadedfile = try subject.load(file: file)
                XCTAssertEqual(file, loadedfile)
            } catch {
                XCTFail("Loading of \(file.path) failed")
            }
            try subject.delete(folder: folder)
        } catch {
            XCTFail("Saving and deleting of \(file.path) failed")
        }
    }
    
    func testIfCreatingOfDirectoryWorks() {
        let subject = FileKit()
        let folder = Folder(path: folderURL)
        
        try! subject.create(folder: folder)
        XCTAssertTrue(isAccessable(path: folder.path))
        try! subject.delete(folder: folder)
        XCTAssertFalse(isAccessable(path: folder.path))
    }
    
    func testIfFilePathIsSetToCachesFolder() {
        let cachesPath = FileKit.pathToCachesFolder()
        let file = File(name: "file.txt", folder: Folder(path: cachesPath))
        XCTAssertEqual(file.folder.path, cachesPath, "\(file.folder.path) should be equal to \(cachesPath)")
    }

    func testIfFilePathIsSetToDocumentsFolder() {
        let documentsPath = FileKit.pathToDocumentsFolder()
        let file = File(name: "file.txt", folder: Folder(path: documentsPath))
        XCTAssertEqual(file.folder.path, documentsPath, "\(file.folder.path) should be equal to \(documentsPath)")
    }
    
    func testIfCreatingFolderWithWrongPathThrows() {
        let subject = FileKit()
        let folder = Folder(path: invalidPath)
        do {
            try subject.create(folder: folder)
        } catch FileKitError.failedToCreate(let path) {
            XCTAssertEqual(path, folder.path)
        } catch {
            XCTFail("Creating folder with invalid path should throw")
        }
    }
    
    private func isAccessable(path: URL) -> Bool {
        return FileManager.default.fileExists(atPath: path.path)
    }
    
    static var allTests : [(String, (FileKitTests) -> () throws -> Void)] {
        return [
            ("testIfFilePathIsSetToCachesFolder", testIfFilePathIsSetToCachesFolder),
            ("testSavingOfFile",testSavingLoadingandDeletingOfFile),
            ("testIfCreatingOfDirectoryWorks", testIfCreatingOfDirectoryWorks),
            ("testIfFilePathIsSetToDocumentsFolder", testIfFilePathIsSetToDocumentsFolder)
        ]
    }
}
