@testable import FileKit
import Foundation
import XCTest

class FileKitTests: XCTestCase {
    var folderURL: URL!
    var filename: String!
    var filename1: String!
    var pathToCache: URL!
    var invalidPath: URL!

    override func setUp() {
        guard let pathToCache = try? FileKit.pathToFolder(forSearchPath: .documentDirectory) else {
            XCTFail("Search path not found: .documentDirectory")
            return
        }
        folderURL = pathToCache.appendingPathComponent("filekit")
        filename = "file.txt"
        filename1 = "file1.txt"
        invalidPath = URL(fileURLWithPath: "/invalid/nonexistent/path")
    }

    override func tearDown() {
        do {
            print("Tear-down: deleting folder: \(folderURL.path)")
            try FileManager.default.removeItem(at: folderURL)
        } catch {
            print("failed to remove dir")
        }
    }

    func testSavingLoadingOfFile() throws {
        let subject = FileKit()
        let data = "Hello World".data(using: .utf8)
        let folder = Folder(location: folderURL)
        let file = File(name: filename, folder: folder, data: data)

        _ = try subject.create(folder: file.folder)
        _ = try subject.save(file: file)
        let loadedFile = try subject.load(file: file)
        XCTAssertEqual(file, loadedFile)
    }

    func testLoadingOfFolder() throws {
        let subject = FileKit()
        let data = "Hello World".data(using: .utf8)
        let folder = Folder(location: folderURL)
        let file = File(name: filename, folder: folder, data: data)
        let file1 = File(name: filename1, folder: folder, data: data)

        _ = try subject.create(folder: folder)
        _ = try subject.save(file: file)
        _ = try subject.save(file: file1)
        let sut = try subject.load(folder: folder)
        XCTAssertEqual(sut.files.count, 2, "Folder file count is not 2")
    }

    func testIfCreatingOfDirectoryWorks() throws {
        let subject = FileKit()
        let folder = Folder(location: folderURL)

        _ = try subject.create(folder: folder)
        XCTAssertTrue(isAccessable(path: folder.location))
    }

    func testIfFilePathIsSetToCachesFolder() throws {
        let cachesPath = try FileKit.pathToFolder(forSearchPath: .cachesDirectory)
        let file = File(name: "file.txt", folder: Folder(location: cachesPath))
        XCTAssertEqual(file.folder.location, cachesPath, "\(file.folder.location) should be equal to \(cachesPath)")
    }

    func testIfFilePathIsSetToDocumentsFolder() throws {
        let documentsPath = try FileKit.pathToFolder(forSearchPath: .documentDirectory)
        let file = File(name: "file.txt", folder: Folder(location: documentsPath))
        XCTAssertEqual(
            file.folder.location,
            documentsPath,
            "\(file.folder.location) should be equal to \(documentsPath)"
        )
    }

    func testIfCreatingFolderWithWrongPathFails() {
        let subject = FileKit()
        let folder = Folder(location: invalidPath)
        do {
            _ = try subject.create(folder: folder)
            XCTFail("Creating folder with invalid path should return error")
        } catch {
            guard case let FileKitError.failedToCreate(urlOfFolder) = error else {
                XCTFail("Failed to read error")
                return
            }
            XCTAssertEqual(urlOfFolder, folder.location)
        }
    }

    func testIfFilesAreEqual() throws {
        let folderA = try FileKit.folder(forSearchPath: .cachesDirectory)
        let folderB = try FileKit.folder(forSearchPath: .cachesDirectory)
        let fileA = File(name: "A.png", folder: folderA)
        let fileB = File(name: "B.png", folder: folderB)

        XCTAssertNotEqual(fileA, fileB)
        XCTAssertEqual(fileA, fileA)
        XCTAssertNotEqual(fileA.location, fileB.location)
    }

    func testIfFoldersAreEqual() throws {
        let folderPathA = try FileKit.folder(forSearchPath: .cachesDirectory).location.appendingPathComponent("document")
        let folderPathB = try FileKit.folder(forSearchPath: .cachesDirectory).location.appendingPathComponent("images")
        let folderA = Folder(location: folderPathA)
        let folderB = Folder(location: folderPathB)

        XCTAssertNotEqual(folderA, folderB)
        XCTAssertEqual(folderA, folderA)
        XCTAssertNotEqual(folderA.location, folderB.location)
    }

    func testURLFromPathString() {
        let subject = FileKit.url(fromPath: ".build/debug")
        XCTAssertEqual(subject.scheme, "file")
        XCTAssertEqual(subject.pathComponents.last, "debug")
    }

    func testFolderFromPathString() {
        let subject = FileKit.folder(fromPath: ".build/debug")
        XCTAssertEqual(subject.location.scheme, "file")
        XCTAssertEqual(subject.location.pathComponents.last, "debug")
    }

    private func isAccessable(path: URL) -> Bool {
        FileManager.default.fileExists(atPath: path.path)
    }
}
