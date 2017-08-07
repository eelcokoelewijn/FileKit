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

    override func tearDown() {
        do {
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
        subject.create(folder: file.folder) { result in
            if case .success(_) = result {
                subject.save(file: file) { result in
                    if case .success(_) = result {
                        subject.load(file: file) { result in
                            if case let .success(loadedfile) = result {
                                XCTAssertEqual(file, loadedfile)
                                expectation.fulfill()
                            } else {
                                XCTFail("Failed to load file")
                            }
                        }
                    }
                }
            } else {
                XCTFail("Failed to create folder")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testIfCreatingOfDirectoryWorks() {
        let subject = FileKit()
        let folder = Folder(location: folderURL)

        let expectation = XCTestExpectation(description: "Wait for folder to be created")
        subject.create(folder: folder) { _ in
            XCTAssertTrue(self.isAccessable(path: folder.location))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testIfFilePathIsSetToCachesFolder() {
        let cachesPath = FileKit.pathToCachesFolder()
        let file = File(name: "file.txt", folder: Folder(location: cachesPath))
        XCTAssertEqual(file.folder.location, cachesPath, "\(file.folder.location) should be equal to \(cachesPath)")
    }

    func testIfFilePathIsSetToDocumentsFolder() {
        let documentsPath = FileKit.pathToDocumentsFolder()
        let file = File(name: "file.txt", folder: Folder(location: documentsPath))
        XCTAssertEqual(file.folder.location,
                       documentsPath,
                       "\(file.folder.location) should be equal to \(documentsPath)")
    }

    func testIfCreatingFolderWithWrongPathFails() {
        let subject = FileKit()
        let folder = Folder(location: invalidPath)
        let expectation = XCTestExpectation(description: "Wait for folder to be created")
        subject.create(folder: folder) { result in
            if case let .failedToCreate(urlOfFolder) = result {
                XCTAssertEqual(urlOfFolder, folder.location)
                expectation.fulfill()
            } else {
                XCTFail("Creating folder with invalid path should return error")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testIfFilesAreEqual() {
        let folderA = FileKit.cachesFolder()
        let fileA = File(name: "A.png", folder: folderA)
        let folderB = FileKit.cachesFolder()
        let fileB = File(name: "B.png", folder: folderB)

        XCTAssertNotEqual(fileA, fileB)
        XCTAssertEqual(fileA, fileA)
        XCTAssertNotEqual(fileA.location, fileB.location)
    }

    func testIfFoldersAreEqual() {
        let folderPathA = FileKit.cachesFolder().location.appendingPathComponent("document")
        let folderA = Folder(location: folderPathA)
        let folderPathB = FileKit.cachesFolder().location.appendingPathComponent("images")
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
            ("testIfCreatingOfDirectoryWorks", testIfCreatingOfDirectoryWorks),
            ("testIfFilePathIsSetToDocumentsFolder", testIfFilePathIsSetToDocumentsFolder),
            ("testIfFilesAreEqual", testIfFilesAreEqual),
            ("testIfFoldersAreEqual", testIfFoldersAreEqual)
        ]
    }
}
