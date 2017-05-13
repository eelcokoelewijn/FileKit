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

        subject.save(file: file)
        subject.load(file: file) { result in
            if case let .success(loadedfile) = result {
                XCTAssertEqual(file, loadedfile)
            }
            XCTFail("Failed to load file")
        }
    }

    func testIfCreatingOfDirectoryWorks() {
        let subject = FileKit()
        let folder = Folder(path: folderURL)

        subject.create(folder: folder) { _ in
            XCTAssertTrue(self.isAccessable(path: folder.path))
        }

        subject.delete(folder: folder) { _ in
            XCTAssertFalse(self.isAccessable(path: folder.path))
        }
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
        subject.create(folder: folder) { result in
            if case let .success(urlOfFolder) = result {
                XCTAssertEqual(urlOfFolder, folder.path)
            }
            XCTFail("Creating folder with invalid path should throw")
        }
    }

    func testIfFilesAreEqual() {
        let folderA = FileKit.cachesFolder()
        let fileA = File(name: "A.png", folder: folderA)
        let folderB = FileKit.cachesFolder()
        let fileB = File(name: "B.png", folder: folderB)

        XCTAssertNotEqual(fileA, fileB)
        XCTAssertEqual(fileA, fileA)
        XCTAssertNotEqual(fileA.path, fileB.path)
    }

    func testIfFoldersAreEqual() {
        let folderPathA = FileKit.cachesFolder().path.appendingPathComponent("document")
        let folderA = Folder(path: folderPathA)
        let folderPathB = FileKit.cachesFolder().path.appendingPathComponent("images")
        let folderB = Folder(path: folderPathB)

        XCTAssertNotEqual(folderA, folderB)
        XCTAssertEqual(folderA, folderA)
        XCTAssertNotEqual(folderA.path, folderB.path)
    }

    private func isAccessable(path: URL) -> Bool {
        return FileManager.default.fileExists(atPath: path.path)
    }

    static var allTests: [(String, (FileKitTests) -> () throws -> Void)] {
        return [
            ("testIfFilePathIsSetToCachesFolder", testIfFilePathIsSetToCachesFolder),
            ("testSavingOfFile", testSavingLoadingandDeletingOfFile),
            ("testIfCreatingOfDirectoryWorks", testIfCreatingOfDirectoryWorks),
            ("testIfFilePathIsSetToDocumentsFolder", testIfFilePathIsSetToDocumentsFolder),
            ("testIfFilesAreEqual", testIfFilesAreEqual),
            ("testIfFoldersAreEqual", testIfFoldersAreEqual)
        ]
    }
}
