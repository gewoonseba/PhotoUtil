import Foundation

public enum DuplicatePolicy: String, CaseIterable, Identifiable, Sendable {
    case skip
    case overwrite

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .skip:
            "Skip duplicates"
        case .overwrite:
            "Overwrite duplicates"
        }
    }
}

public enum DuplicateState: Equatable, Sendable {
    case none
    case existingDestination
    case duplicateInBatch

    public var title: String {
        switch self {
        case .none:
            "Ready"
        case .existingDestination:
            "Already exists"
        case .duplicateInBatch:
            "Duplicate in import"
        }
    }
}

public struct ImportOptions: Equatable, Sendable {
    public var duplicatePolicy: DuplicatePolicy
    public var organizeByCaptureDate: Bool
    public var prefixFilenameWithCaptureDate: Bool
    public var allowedExtensions: Set<String>

    public init(
        duplicatePolicy: DuplicatePolicy = .skip,
        organizeByCaptureDate: Bool = true,
        prefixFilenameWithCaptureDate: Bool = true,
        allowedExtensions: Set<String> = PhotoUtilService.defaultRawExtensions
    ) {
        self.duplicatePolicy = duplicatePolicy
        self.organizeByCaptureDate = organizeByCaptureDate
        self.prefixFilenameWithCaptureDate = prefixFilenameWithCaptureDate
        self.allowedExtensions = allowedExtensions
    }
}

public struct ImportCandidate: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let sourceURL: URL
    public let destinationURL: URL
    public let captureDate: Date
    public let duplicateState: DuplicateState

    public var fileName: String {
        sourceURL.lastPathComponent
    }

    public init(sourceURL: URL, destinationURL: URL, captureDate: Date, duplicateState: DuplicateState) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.captureDate = captureDate
        self.duplicateState = duplicateState
    }
}

public struct ImportFailure: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let sourceURL: URL
    public let message: String

    public init(sourceURL: URL, message: String) {
        self.sourceURL = sourceURL
        self.message = message
    }
}

public struct ImportSummary: Equatable, Sendable {
    public var scanned: Int
    public var imported: Int
    public var skipped: Int
    public var overwritten: Int
    public var failures: [ImportFailure]

    public init(
        scanned: Int = 0,
        imported: Int = 0,
        skipped: Int = 0,
        overwritten: Int = 0,
        failures: [ImportFailure] = []
    ) {
        self.scanned = scanned
        self.imported = imported
        self.skipped = skipped
        self.overwritten = overwritten
        self.failures = failures
    }

    public var failed: Int {
        failures.count
    }
}
