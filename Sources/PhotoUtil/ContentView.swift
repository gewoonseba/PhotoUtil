import PhotoUtilCore
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ImportViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { viewModel.sourceURL },
                set: { selectedURL in
                    viewModel.sourceURL = selectedURL
                    viewModel.resetResults()
                }
            )) {
                Section("Connected sources") {
                    if viewModel.mountedSources.isEmpty {
                        Text("No removable volumes found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.mountedSources, id: \.self) { source in
                            Label(source.lastPathComponent, systemImage: "sdcard")
                                .tag(Optional(source))
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        viewModel.refreshMountedSources()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        viewModel.chooseSourceFolder()
                    } label: {
                        Label("Choose Source", systemImage: "folder")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        } detail: {
            VStack(alignment: .leading, spacing: 18) {
                header
                selectionPanel
                optionsPanel
                previewPanel
                footer
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PhotoUtil")
                .font(.largeTitle.weight(.semibold))
            Text("Import from an SD card or camera volume and organize files by capture date.")
                .foregroundStyle(.secondary)
        }
    }

    private var selectionPanel: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                Text("Source")
                    .foregroundStyle(.secondary)
                pathText(viewModel.sourceURL, placeholder: "Select a source volume or folder")
                Button {
                    viewModel.chooseSourceFolder()
                } label: {
                    Image(systemName: "folder")
                }
                .help("Choose source")
            }

            GridRow {
                Text("Destination")
                    .foregroundStyle(.secondary)
                pathText(viewModel.destinationURL, placeholder: "Select destination directory")
                Button {
                    viewModel.chooseDestinationFolder()
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Choose destination")
            }
        }
    }

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Organization")
                .font(.headline)

            Toggle("Create year and month folders", isOn: $viewModel.options.organizeByCaptureDate)
            Toggle("Prefix filenames with capture date", isOn: $viewModel.options.prefixFilenameWithCaptureDate)

            Picker("Duplicates", selection: $viewModel.options.duplicatePolicy) {
                ForEach(DuplicatePolicy.allCases) { policy in
                    Text(policy.title).tag(policy)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 420)

            Text("Example: 2026/06/2026-06-02-original_name.dng")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: viewModel.options) {
            viewModel.resetResults()
        }
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Import Preview")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.scan()
                } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .disabled(viewModel.sourceURL == nil || viewModel.destinationURL == nil || viewModel.isScanning)
            }

            if viewModel.isScanning {
                ProgressView("Scanning source")
            } else if viewModel.candidates.isEmpty {
                emptyPreview
            } else {
                summaryStrip
                Table(viewModel.candidates) {
                    TableColumn("File") { candidate in
                        Text(candidate.fileName)
                            .lineLimit(1)
                    }
                    TableColumn("Destination") { candidate in
                        Text(candidate.destinationURL.deletingLastPathComponent().path)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    TableColumn("Status") { candidate in
                        statusLabel(candidate.duplicateState)
                    }
                }
                .frame(minHeight: 220)
            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    private var emptyPreview: some View {
        ContentUnavailableView {
            Label("No scan yet", systemImage: "photo.stack")
        } description: {
            Text("Choose a source and destination, then scan to preview the import.")
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var summaryStrip: some View {
        HStack(spacing: 16) {
            metric("Files", viewModel.candidates.count)
            metric("Ready", viewModel.readyCount)
            metric("Duplicates", viewModel.duplicateCount)
            Spacer()
        }
        .font(.callout)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if viewModel.isImporting {
                ProgressView(value: viewModel.importProgress)
                    .frame(maxWidth: 260)
                Text("\(viewModel.completedCount) of \(viewModel.candidates.count)")
                    .foregroundStyle(.secondary)
            }

            if let summary = viewModel.summary {
                Text("Imported \(summary.imported), overwritten \(summary.overwritten), skipped \(summary.skipped), failed \(summary.failed).")
                    .foregroundStyle(summary.failed == 0 ? Color.secondary : Color.red)
            }

            Spacer()

            Button {
                viewModel.startImport()
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.candidates.isEmpty || viewModel.isImporting)
        }
    }

    private func pathText(_ url: URL?, placeholder: String) -> some View {
        Text(url?.path ?? placeholder)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(url == nil ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value.formatted())
                .fontWeight(.semibold)
        }
    }

    private func statusLabel(_ state: DuplicateState) -> some View {
        Label(state.title, systemImage: iconName(for: state))
            .foregroundStyle(color(for: state))
    }

    private func iconName(for state: DuplicateState) -> String {
        switch state {
        case .none:
            "checkmark.circle"
        case .existingDestination:
            "exclamationmark.triangle"
        case .duplicateInBatch:
            "doc.on.doc"
        }
    }

    private func color(for state: DuplicateState) -> Color {
        switch state {
        case .none:
            .green
        case .existingDestination:
            .orange
        case .duplicateInBatch:
            .yellow
        }
    }
}
