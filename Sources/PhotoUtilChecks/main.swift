import Foundation
import PhotoUtilCore

@main
struct PhotoUtilChecks {
    static func main() throws {
        try dateBasedDestination()
        try skipExistingDestination()
        try overwriteExistingDestination()
        print("PhotoUtilChecks passed")
    }

    private static func dateBasedDestination() throws {
        let fixture = try ImportFixture()
        let source = fixture.source.appendingPathComponent("IMG_0001.DNG")
        try Data("raw".utf8).write(to: source)
        try fixture.setFileDate(source, year: 2026, month: 6, day: 2)

        let candidates = try fixture.service.makeCandidates(
            from: fixture.source,
            to: fixture.destination,
            options: ImportOptions()
        )

        try require(candidates.count == 1, "Expected one import candidate")
        try require(
            candidates[0].destinationURL.path.hasSuffix("/2026/06/2026-06-02-IMG_0001.DNG"),
            "Expected year/month folder and date-prefixed filename"
        )
        try require(candidates[0].duplicateState == .none, "Expected no duplicate")
    }

    private static func skipExistingDestination() throws {
        let fixture = try ImportFixture()
        let source = fixture.source.appendingPathComponent("IMG_0002.DNG")
        try Data("new".utf8).write(to: source)
        try fixture.setFileDate(source, year: 2026, month: 6, day: 2)

        let existing = try fixture.createExistingDestination(named: "2026-06-02-IMG_0002.DNG")
        try Data("old".utf8).write(to: existing)

        var options = ImportOptions()
        options.duplicatePolicy = .skip
        let candidates = try fixture.service.makeCandidates(
            from: fixture.source,
            to: fixture.destination,
            options: options
        )
        let summary = fixture.service.importCandidates(candidates, options: options)

        try require(candidates[0].duplicateState == .existingDestination, "Expected duplicate detection")
        try require(summary.imported == 0, "Expected no imported files")
        try require(summary.skipped == 1, "Expected one skipped file")
        let existingContents = try String(contentsOf: existing, encoding: .utf8)
        try require(existingContents == "old", "Expected existing file to remain unchanged")
    }

    private static func overwriteExistingDestination() throws {
        let fixture = try ImportFixture()
        let source = fixture.source.appendingPathComponent("IMG_0003.DNG")
        try Data("new".utf8).write(to: source)
        try fixture.setFileDate(source, year: 2026, month: 6, day: 2)

        let existing = try fixture.createExistingDestination(named: "2026-06-02-IMG_0003.DNG")
        try Data("old".utf8).write(to: existing)

        var options = ImportOptions()
        options.duplicatePolicy = .overwrite
        let candidates = try fixture.service.makeCandidates(
            from: fixture.source,
            to: fixture.destination,
            options: options
        )
        let summary = fixture.service.importCandidates(candidates, options: options)

        try require(summary.imported == 0, "Expected no new imported files")
        try require(summary.overwritten == 1, "Expected one overwritten file")
        let overwrittenContents = try String(contentsOf: existing, encoding: .utf8)
        try require(overwrittenContents == "new", "Expected destination to be overwritten")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() {
            throw CheckError(message)
        }
    }
}

private struct CheckError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

private struct ImportFixture {
    let root: URL
    let source: URL
    let destination: URL
    let service: PhotoUtilService

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoUtilChecks-\(UUID().uuidString)", isDirectory: true)
        source = root.appendingPathComponent("source", isDirectory: true)
        destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        service = PhotoUtilService(calendar: calendar)
    }

    func createExistingDestination(named fileName: String) throws -> URL {
        let existingDirectory = destination
            .appendingPathComponent("2026", isDirectory: true)
            .appendingPathComponent("06", isDirectory: true)
        try FileManager.default.createDirectory(at: existingDirectory, withIntermediateDirectories: true)
        return existingDirectory.appendingPathComponent(fileName)
    }

    func setFileDate(_ url: URL, year: Int, month: Int, day: Int) throws {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let date = components.date!

        try FileManager.default.setAttributes([
            .creationDate: date,
            .modificationDate: date
        ], ofItemAtPath: url.path)
    }
}
