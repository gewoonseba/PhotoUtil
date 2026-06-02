import AppKit
import Combine
import Foundation
import PhotoUtilCore

@MainActor
final class ImportViewModel: ObservableObject {
    @Published var sourceURL: URL?
    @Published var destinationURL: URL?
    @Published var mountedSources: [URL] = []
    @Published var options = ImportOptions()
    @Published var candidates: [ImportCandidate] = []
    @Published var summary: ImportSummary?
    @Published var isScanning = false
    @Published var isImporting = false
    @Published var completedCount = 0
    @Published var errorMessage: String?

    private let service: PhotoUtilService

    init(service: PhotoUtilService = PhotoUtilService()) {
        self.service = service
        refreshMountedSources()
    }

    var readyCount: Int {
        candidates.filter { $0.duplicateState == .none }.count
    }

    var duplicateCount: Int {
        candidates.count - readyCount
    }

    var importProgress: Double {
        guard !candidates.isEmpty else { return 0 }
        return Double(completedCount) / Double(candidates.count)
    }

    func refreshMountedSources() {
        mountedSources = service.mountedImportSources()
    }

    func chooseSourceFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose import source"
        panel.message = "Select an SD card, connected camera volume, or folder to scan."
        panel.prompt = "Choose Source"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)

        if panel.runModal() == .OK {
            sourceURL = panel.url
            resetResults()
        }
    }

    func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose destination"
        panel.message = "Select the folder where imported photos should be organized."
        panel.prompt = "Choose Destination"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            destinationURL = panel.url
            resetResults()
        }
    }

    func scan() {
        guard let sourceURL, let destinationURL else { return }
        isScanning = true
        errorMessage = nil
        summary = nil

        let currentOptions = options
        Task.detached { [service] in
            do {
                let candidates = try service.makeCandidates(
                    from: sourceURL,
                    to: destinationURL,
                    options: currentOptions
                )
                await MainActor.run {
                    self.candidates = candidates
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isScanning = false
                }
            }
        }
    }

    func startImport() {
        guard !candidates.isEmpty else { return }
        completedCount = 0
        isImporting = true
        errorMessage = nil

        let importCandidates = candidates
        let currentOptions = options
        Task.detached { [service] in
            let summary = service.importCandidates(importCandidates, options: currentOptions) { done, _ in
                Task { @MainActor in
                    self.completedCount = done
                }
            }

            await MainActor.run {
                self.summary = summary
                self.isImporting = false
            }
        }
    }

    func resetResults() {
        candidates = []
        summary = nil
        completedCount = 0
        errorMessage = nil
    }
}
