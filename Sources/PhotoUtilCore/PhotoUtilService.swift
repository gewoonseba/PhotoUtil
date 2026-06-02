import CryptoKit
import Foundation
import ImageIO

public struct PhotoUtilService: @unchecked Sendable {
    public static let defaultRawExtensions: Set<String> = [
        "3fr", "ari", "arw", "bay", "braw", "cr2", "cr3", "crw", "dcr",
        "dng", "erf", "fff", "gpr", "iiq", "k25", "kdc", "mef", "mos",
        "mrw", "nef", "nrw", "orf", "pef", "raf", "raw", "rwl", "rw2",
        "sr2", "srf", "srw", "x3f"
    ]

    private let fileManager: FileManager
    private let calendar: Calendar

    public init(fileManager: FileManager = .default, calendar: Calendar = .current) {
        self.fileManager = fileManager
        self.calendar = calendar
    }

    public func mountedImportSources() -> [URL] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
        let volumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []

        return volumes
            .filter { url in
                guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return false }
                return values.volumeIsRemovable == true || values.volumeIsEjectable == true
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    public func makeCandidates(
        from sourceURL: URL,
        to destinationURL: URL,
        options: ImportOptions
    ) throws -> [ImportCandidate] {
        let sourceFiles = try photoFiles(in: sourceURL, allowedExtensions: options.allowedExtensions)
        var destinationCounts: [String: Int] = [:]
        let provisional = sourceFiles.map { sourceFile in
            let captureDate = captureDate(for: sourceFile)
            let destination = destinationURLForPhoto(
                sourceURL: sourceFile,
                destinationRoot: destinationURL,
                captureDate: captureDate,
                options: options
            )
            destinationCounts[destination.standardizedFileURL.path, default: 0] += 1
            return (sourceFile: sourceFile, captureDate: captureDate, destination: destination)
        }

        return provisional.map { item in
            let path = item.destination.standardizedFileURL.path
            let state: DuplicateState
            if fileManager.fileExists(atPath: path) {
                state = .existingDestination
            } else if destinationCounts[path, default: 0] > 1 {
                state = .duplicateInBatch
            } else {
                state = .none
            }

            return ImportCandidate(
                sourceURL: item.sourceFile,
                destinationURL: item.destination,
                captureDate: item.captureDate,
                duplicateState: state
            )
        }
    }

    public func importCandidates(
        _ candidates: [ImportCandidate],
        options: ImportOptions,
        progress: @Sendable (Int, Int) -> Void = { _, _ in }
    ) -> ImportSummary {
        var summary = ImportSummary(scanned: candidates.count)

        for (index, candidate) in candidates.enumerated() {
            do {
                let destinationDirectory = candidate.destinationURL.deletingLastPathComponent()
                try fileManager.createDirectory(
                    at: destinationDirectory,
                    withIntermediateDirectories: true
                )

                let destinationPath = candidate.destinationURL.path
                if fileManager.fileExists(atPath: destinationPath) {
                    switch options.duplicatePolicy {
                    case .skip:
                        summary.skipped += 1
                        progress(index + 1, candidates.count)
                        continue
                    case .overwrite:
                        try fileManager.removeItem(at: candidate.destinationURL)
                        try fileManager.copyItem(at: candidate.sourceURL, to: candidate.destinationURL)
                        summary.overwritten += 1
                    }
                } else {
                    try fileManager.copyItem(at: candidate.sourceURL, to: candidate.destinationURL)
                    summary.imported += 1
                }
            } catch {
                summary.failures.append(
                    ImportFailure(sourceURL: candidate.sourceURL, message: error.localizedDescription)
                )
            }

            progress(index + 1, candidates.count)
        }

        return summary
    }

    public func contentFingerprint(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1024 * 1024)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func photoFiles(in sourceURL: URL, allowedExtensions: Set<String>) throws -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
            guard values.isRegularFile == true, values.isHidden != true else { continue }

            let ext = fileURL.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else { continue }
            files.append(fileURL)
        }

        return files.sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    private func destinationURLForPhoto(
        sourceURL: URL,
        destinationRoot: URL,
        captureDate: Date,
        options: ImportOptions
    ) -> URL {
        var directory = destinationRoot

        if options.organizeByCaptureDate {
            let year = Self.folderFormatter("yyyy", calendar: calendar).string(from: captureDate)
            let month = Self.folderFormatter("MM", calendar: calendar).string(from: captureDate)
            directory.appendPathComponent(year, isDirectory: true)
            directory.appendPathComponent(month, isDirectory: true)
        }

        var fileName = sourceURL.lastPathComponent
        if options.prefixFilenameWithCaptureDate {
            let prefix = Self.folderFormatter("yyyy-MM-dd", calendar: calendar).string(from: captureDate)
            fileName = "\(prefix)-\(fileName)"
        }

        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    private func captureDate(for fileURL: URL) -> Date {
        if let imageDate = imageMetadataDate(for: fileURL) {
            return imageDate
        }

        if let values = try? fileURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]) {
            return values.creationDate ?? values.contentModificationDate ?? Date()
        }

        return Date()
    }

    private func imageMetadataDate(for fileURL: URL) -> Date? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return nil
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

        let rawValues: [Any?] = [
            exif?[kCGImagePropertyExifDateTimeOriginal],
            exif?[kCGImagePropertyExifDateTimeDigitized],
            tiff?[kCGImagePropertyTIFFDateTime]
        ]

        for value in rawValues {
            guard let dateString = value as? String else { continue }
            if let date = Self.exifDateFormatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    private static func folderFormatter(_ format: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()
}
