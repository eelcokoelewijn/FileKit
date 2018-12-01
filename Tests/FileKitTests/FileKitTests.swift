import XCTest
import Foundation
@testable import FileKit

class FileKitTests: XCTestCase {
    var folderURL: URL!
    var filename: String!
    var filename1: String!
    var pathToCache: URL!
    var invalidPath: URL!

    override func setUp() {
        pathToCache = FileKit.pathToFolder(forSearchPath: .cachesDirectory)
        folderURL = URL(string: "filekit", relativeTo: pathToCache)
        filename = "file.txt"
        filename1 = "file1.txt"
        invalidPath = URL(string: "file://invalid")
    }

    override func tearDown() {
        do {
            print("Tear-down: deleting folder: \(folderURL.path)")
            try FileManager.default.removeItem(atPath: folderURL.path)
        } catch {
            print("failed to remove dir")
        }
    }

    func testSavingLoadingOfFile() {
        let subject = FileKit()
        let data = "Hello World".data(using: String.Encoding.utf8)
        let folder = Folder(location: folderURL)
        let file = File(name: filename, folder: folder, data: data)
        let expectation = XCTestExpectation(description: "Wait for folder & file to be created")
        do {
            _ = try subject.create(folder: file.folder)
            _ = try subject.save(file: file)
            guard let loadedFile = try? subject.load(file: file) else {
                XCTFail("Failed to load file")
                return
            }
            XCTAssertEqual(file, loadedFile)
            expectation.fulfill()
        } catch {
            XCTFail("Failed to create folder")
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLoadingOfFolder() {
        let subject = FileKit()
        let data = "Hello World".data(using: String.Encoding.utf8)
        let folder = Folder(location: folderURL)
        let file = File(name: filename, folder: folder, data: data)
        let file1 = File(name: filename1, folder: folder, data: data)

        let expectation = XCTestExpectation(description: "Wait folder & files to be created")
        do {
            _ = try subject.create(folder: folder)
            _ = try subject.save(file: file)
            _ = try subject.save(file: file1)
            guard let sut = try? subject.load(folder: folder) else { XCTFail("Failed to load folder"); return }
            XCTAssert(sut.files.count == 2, "Folder file count is not 2")
            expectation.fulfill()
        } catch {
            XCTFail("Failed to read files")
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testIfCreatingOfDirectoryWorks() {
        let subject = FileKit()
        let folder = Folder(location: folderURL)

        let expectation = XCTestExpectation(description: "Wait for folder to be created")
        do {
            _ = try subject.create(folder: folder)
            XCTAssertTrue(self.isAccessable(path: folder.location))
            expectation.fulfill()
        } catch {
            XCTFail("Failed to read files")
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testIfFilePathIsSetToCachesFolder() {
        let cachesPath = FileKit.pathToFolder(forSearchPath: .cachesDirectory)
        let file = File(name: "file.txt", folder: Folder(location: cachesPath))
        XCTAssertEqual(file.folder.location, cachesPath, "\(file.folder.location) should be equal to \(cachesPath)")
    }

    func testIfFilePathIsSetToDocumentsFolder() {
        let documentsPath = FileKit.pathToFolder(forSearchPath: .cachesDirectory)
        let file = File(name: "file.txt", folder: Folder(location: documentsPath))
        XCTAssertEqual(file.folder.location,
                       documentsPath,
                       "\(file.folder.location) should be equal to \(documentsPath)")
    }

    func testIfCreatingFolderWithWrongPathFails() {
        let subject = FileKit()
        let folder = Folder(location: invalidPath)
        let expectation = XCTestExpectation(description: "Wait for folder to be created")
        do {
            _ = try subject.create(folder: folder)
            XCTFail("Creating folder with invalid path should return error")
        } catch {
            guard case let FileKitError.failedToCreate(urlOfFolder) = error else {
                XCTFail("Failed to read error")
                return
            }
            XCTAssertEqual(urlOfFolder, folder.location)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testIfFilesAreEqual() {
        let folderA = FileKit.folder(forSearchPath: .cachesDirectory)
        let fileA = File(name: "A.png", folder: folderA)
        let folderB = FileKit.folder(forSearchPath: .cachesDirectory)
        let fileB = File(name: "B.png", folder: folderB)

        XCTAssertNotEqual(fileA, fileB)
        XCTAssertEqual(fileA, fileA)
        XCTAssertNotEqual(fileA.location, fileB.location)
    }

    func testIfFoldersAreEqual() {
        let folderPathA = FileKit.folder(forSearchPath: .cachesDirectory).location.appendingPathComponent("document")
        let folderA = Folder(location: folderPathA)
        let folderPathB = FileKit.folder(forSearchPath: .cachesDirectory).location.appendingPathComponent("images")
        let folderB = Folder(location: folderPathB)

        XCTAssertNotEqual(folderA, folderB)
        XCTAssertEqual(folderA, folderA)
        XCTAssertNotEqual(folderA.location, folderB.location)
    }

    private func isAccessable(path: URL) -> Bool {
        return FileManager.default.fileExists(atPath: path.path)
    }

    static var allTests: [(String, (FileKitTests) -> () throws -> Void)] {
        return [
            ("testIfFilePathIsSetToCachesFolder", testIfFilePathIsSetToCachesFolder),
            ("testSavingOfFile", testSavingLoadingOfFile),
            ("testLoadingOfFolder", testLoadingOfFolder),
            ("testIfCreatingOfDirectoryWorks", testIfCreatingOfDirectoryWorks),
            ("testIfFilePathIsSetToDocumentsFolder", testIfFilePathIsSetToDocumentsFolder),
            ("testIfFilesAreEqual", testIfFilesAreEqual),
            ("testIfFoldersAreEqual", testIfFoldersAreEqual)
        ]
    }
}
