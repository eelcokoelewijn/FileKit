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

    func testLoadingOfFolder() {
        let subject = FileKit()
        let data = "Hello World".data(using: String.Encoding.utf8)
        let folder = Folder(location: folderURL)
        let file = File(name: filename, folder: folder, data: data)
        let file1 = File(name: filename1, folder: folder, data: data)

        let expectation = XCTestExpectation(description: "Wait folder & files to be created")
        subject.create(folder: folder) { result in
            guard case .success(_) = result else { XCTFail("Failed to create folder"); return }
            subject.save(file: file) { result in
                guard case .success(_) = result else { XCTFail("Failed to create file"); return }
                subject.save(file: file1) { result in
                    guard case .success(_) = result else { XCTFail("Failed to create file1"); return }
                    subject.load(folder: folder) { (result) in
                        guard case let .success(folder) = result else { XCTFail("Failed to load folder"); return }
                        XCTAssert(folder.files.count == 2, "Folder file count is not 2")
                        expectation.fulfill()
                    }
                }
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
            ("testIfCreatingOfDirectoryWorks", testIfCreatingOfDirectoryWorks),
            ("testIfFilePathIsSetToDocumentsFolder", testIfFilePathIsSetToDocumentsFolder),
            ("testIfFilesAreEqual", testIfFilesAreEqual),
            ("testIfFoldersAreEqual", testIfFoldersAreEqual)
        ]
    }
}
