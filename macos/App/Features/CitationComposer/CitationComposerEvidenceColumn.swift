import SwiftUI

enum CitationComposerColumnLayout {
    /// Citation form in its own column beside the file.
    case side
    /// Citation form stacked above the file.
    case panel

    /// Wide puts the form beside the file; Regular stacks it above.
    init(_ widthClass: PVWidthClass) {
        self = widthClass == .wide ? .side : .panel
    }
}

/// The Citation form's fields that Tab moves between.
enum CitationFormFocus: Hashable {
    case label, printedPage, transcription

    /// Tab order of the form in `layout`: the printed page follows Label, and
    /// is left out when the Artifact does not offer it.
    static func order(
        _ layout: CitationComposerColumnLayout,
        printedPageOffered: Bool
    ) -> [CitationFormFocus] {
        let order: [CitationFormFocus]
        switch layout {
        case .side: order = [.label, .printedPage, .transcription]
        case .panel: order = [.transcription, .label, .printedPage]
        }
        return printedPageOffered ? order : order.filter { $0 != .printedPage }
    }
}

/// Citation column: artifact and citation menus, then the reading.
struct CitationComposerEvidenceColumn: View {
    @Bindable var model: CitationComposerModel
    var layout: CitationComposerColumnLayout
    /// Held by the composer, above the layout switch, so focus survives the column being rebuilt.
    var formFocus: FocusState<CitationFormFocus?>.Binding

    var body: some View {
        switch layout {
        case .side:
            VStack(alignment: .leading, spacing: 0) {
                PVSectionHeader(
                    title: L10n.CitationComposer.citationEyebrow,
                    meta: "\(model.listedCitations.count)"
                )
                .padding(.horizontal, PVSpacing.space7)
                .padding(.top, 14)
                .padding(.bottom, PVSpacing.space4)
                ScrollView {
                    sideForm
                        .padding(.horizontal, PVSpacing.space7)
                        .padding(.top, PVSpacing.space2)
                        .padding(.bottom, PVSpacing.space7)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(PVColor.surfaceCard)
        case .panel:
            ScrollView {
                panelForm
                    .padding(.horizontal, PVSpacing.space6)
                    .padding(.top, PVSpacing.space5)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(PVColor.surfaceCard)
            .overlay(alignment: .bottom) {
                PVDivider(axis: .horizontal, color: PVColor.borderSubtle)
            }
        }
    }

    @ViewBuilder
    private var sideForm: some View {
        let order = CitationFormFocus.order(.side, printedPageOffered: printedPageOffered)
        VStack(alignment: .leading, spacing: PVSpacing.space7) {
            VStack(alignment: .leading, spacing: PVSpacing.space5) {
                artifactStepper
                citationStepper
                citationLoadErrorLine
            }
            PVDivider(axis: .horizontal, color: PVColor.borderSubtle)
            labelAndPrintedPage(
                label: PVFieldFocus(formFocus, equals: .label, in: order),
                printedPage: PVFieldFocus(formFocus, equals: .printedPage, in: order)
            )
            transcriptionColumn(
                rows: 8...40,
                focus: PVFieldFocus(formFocus, equals: .transcription, in: order)
            )
            footer
        }
    }

    @ViewBuilder
    private var panelForm: some View {
        let order = CitationFormFocus.order(.panel, printedPageOffered: printedPageOffered)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: PVSpacing.space5) {
                artifactStepper
                    .frame(maxWidth: 300)
                citationStepper
                    .frame(maxWidth: .infinity)
            }
            citationLoadErrorLine
            PVWeightedColumns(weights: [1.5, 1], spacing: PVSpacing.space6, alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    transcriptionColumn(
                        rows: 6...40,
                        focus: PVFieldFocus(formFocus, equals: .transcription, in: order)
                    )
                    footer
                }
                labelAndPrintedPage(
                    label: PVFieldFocus(formFocus, equals: .label, in: order),
                    printedPage: PVFieldFocus(formFocus, equals: .printedPage, in: order)
                )
            }
        }
    }

    /// Why the last Citation load failed, naming the Citation, under the picker.
    @ViewBuilder
    private var citationLoadErrorLine: some View {
        if let error = model.citationLoadError {
            PVErrorText(error, announces: true)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("citationComposer.citationLoadError")
        }
    }

    private var artifactStepper: some View {
        // Read once: each read of `model.artifacts` scans the project's graph list.
        let artifacts = model.artifacts
        return PVSubsectionHeader(
            title: L10n.CitationComposer.artifactEyebrow,
            meta: artifactPosition(in: artifacts)
        ) {
            artifactSelect(artifacts)
        }
    }

    private var citationStepper: some View {
        let ordered = model.orderedCitations
        return PVSubsectionHeader(
            title: L10n.CitationComposer.citationEyebrow,
            meta: citationPosition(in: ordered)
        ) {
            citationSelect(ordered)
        }
    }

    private func citationSelect(_ ordered: [CatalogListedCitation]) -> some View {
        CitationStepMenu(
            model: model,
            ordered: ordered,
            selection: citationSelection,
            size: .md,
            menuWidth: 480,
            maxVisibleRows: 6,
            rowHeight: 84,
            isDisabled: model.isTranscribing || model.isDrawingDepiction,
            accessibilityIdentifier: "citationComposer.citationSelect"
        )
    }

    private func artifactSelect(_ artifacts: [CatalogArtifact]) -> some View {
        PVSelect(
            selection: artifactSelection,
            options: artifactOptions(artifacts),
            size: .md,
            menuWidth: 360,
            maxVisibleRows: 6,
            rowHeight: 64,
            isDisabled: model.isTranscribing || model.isDrawingDepiction || artifacts.isEmpty,
            accessibilityLabel: L10n.CitationComposer.artifactEyebrow,
            accessibilityIdentifier: "citationComposer.artifactSelect"
        ) { option in
            if let artifact = artifacts.first(where: { $0.id == option.id }) {
                artifactMenuRow(artifact)
            } else {
                Text(verbatim: option.label)
            }
        }
    }

    private var citationSelection: Binding<String> {
        Binding(
            get: { model.activeCitationID ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    if model.activeCitationID != nil { model.selectCitation(nil) }
                    return
                }
                guard newValue != model.activeCitationID else { return }
                model.selectCitation(newValue)
            }
        )
    }

    private var artifactSelection: Binding<String> {
        Binding(
            get: { model.selectedArtifactID ?? "" },
            set: { newValue in
                guard !newValue.isEmpty, newValue != model.selectedArtifactID else { return }
                model.requestSelectArtifact(newValue)
            }
        )
    }

    private func artifactOptions(_ artifacts: [CatalogArtifact]) -> [PVSelectOption] {
        artifacts.map { artifact in
            PVSelectOption(value: artifact.id, label: artifactTitle(artifact))
        }
    }

    private func citationPosition(in ordered: [CatalogListedCitation]) -> String {
        guard let id = model.activeCitationID,
              let index = ordered.firstIndex(where: { $0.citation.id == id })
        else {
            return L10n.string(L10n.CitationComposer.newPosition)
        }
        return L10n.DesignSystem.selectOptionPosition(
            current: index + 1,
            count: ordered.count
        )
    }

    private func artifactPosition(in artifacts: [CatalogArtifact]) -> String {
        guard let id = model.selectedArtifactID,
              let index = artifacts.firstIndex(where: { $0.id == id })
        else { return "" }
        return L10n.DesignSystem.selectOptionPosition(current: index + 1, count: artifacts.count)
    }

    private func artifactMenuRow(_ artifact: CatalogArtifact) -> some View {
        HStack(alignment: .center, spacing: 10) {
            artifactThumbnail(artifact)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: artifactTitle(artifact))
                    .font(PVFont.body(size: PVTypeScale.caption))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
                Text(verbatim: artifactMeta(artifact))
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(1)
                Text(verbatim: L10n.CitationComposer.artifactCitationCount(count: model.listedCount(for: artifact.id)))
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, PVSpacing.space2)
    }

    private func artifactThumbnail(_ artifact: CatalogArtifact) -> some View {
        let content: PVThumbnail.Content
        if artifact.id == model.selectedArtifactID,
           let image = model.artifactViewer.displayImage,
           model.artifactViewer.kind == .image
        {
            content = PVThumbnail.Content(image: Image(nsImage: image))
        } else {
            content = PVThumbnail.Content(glyph: artifactMark(artifact).map(PVGlyph.mark))
        }
        return PVThumbnail(content, size: 48)
    }

    private var printedPageOffered: Bool {
        model.locatorCapabilities.supportsPrintedPage
    }

    /// Label with Printed page: one row when the form's column fits both, else
    /// Printed page directly under Label. An Artifact with no printed page shows Label alone.
    @ViewBuilder
    private func labelAndPrintedPage(label: PVFieldFocus?, printedPage: PVFieldFocus?) -> some View {
        if printedPageOffered {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PVSpacing.space5) {
                    labelField(focus: label)
                        .frame(minWidth: 180)
                    printedPageField(focus: printedPage)
                        .frame(width: 140)
                }
                VStack(alignment: .leading, spacing: PVSpacing.space5) {
                    labelField(focus: label)
                    printedPageField(focus: printedPage)
                }
            }
        } else {
            labelField(focus: label)
        }
    }

    private func printedPageField(focus: PVFieldFocus?) -> some View {
        let help = L10n.string(L10n.CitationComposer.printedPageHelp)
        return PVField(label: L10n.CitationComposer.printedPageLabel) {
            PVInput(
                text: $model.pageLabel,
                size: .sm,
                prompt: L10n.CitationComposer.printedPagePrompt,
                focus: focus
            )
            .help(help)
            .accessibilityHint(Text(verbatim: help))
            .accessibilityIdentifier("citationComposer.printedPage")
        }
    }

    private func labelField(focus: PVFieldFocus?) -> some View {
        PVField(label: L10n.CitationComposer.descriptionLabel) {
            PVInput(
                text: $model.citationDescription,
                size: .sm,
                prompt: L10n.CitationComposer.descriptionPrompt,
                focus: focus
            )
            .accessibilityIdentifier("citationComposer.label")
        }
    }

    private func transcriptionColumn(rows: ClosedRange<Int>, focus: PVFieldFocus?) -> some View {
        VStack(alignment: .leading, spacing: PVSpacing.space4) {
            PVField(label: L10n.CitationComposer.transcriptionLabel, error: model.fields.error) {
                PVTextArea(
                    text: $model.transcription,
                    lineLimit: rows,
                    prompt: L10n.CitationComposer.transcriptionPrompt,
                    focus: focus
                )
                .accessibilityIdentifier("citationComposer.transcription")
            }
            .overlay(alignment: .topTrailing) {
                readingAction
                    .offset(y: -5)
            }
            PVCheckbox(
                L10n.CitationComposer.uncertainLabel,
                isChecked: $model.transcriptionUncertain
            )
            if let message = model.transcriptionOCRMessage, !message.isEmpty {
                PVCallout(tone: .warning, message: message)
            }
        }
    }

    @ViewBuilder
    private var readingAction: some View {
        if model.artifactViewer.kind == .pdf {
            PVButton(
                L10n.CitationComposer.pasteTranscription,
                variant: .ghost,
                size: .sm,
                icon: .clipboardPaste
            ) {
                model.requestPasteTranscription()
            }
            .disabled(!model.canPasteTranscription || model.isTranscribing || model.isDrawingDepiction)
        } else if model.artifactViewer.kind == .image {
            PVButton(
                L10n.CitationComposer.autoTranscribe,
                variant: .primary,
                size: .sm,
                icon: .scanText,
                loading: model.isTranscribing
            ) {
                model.requestAutoTranscribe()
            }
            .disabled(!model.canAutoTranscribe || model.isTranscribing || model.isDrawingDepiction)
        }
    }

    private var footer: some View {
        HStack(spacing: PVSpacing.space4) {
            Spacer(minLength: 0)
            if model.activeCitationID != nil {
                PVButton(
                    L10n.CitationComposer.deleteReading,
                    variant: .ghost,
                    size: .sm,
                    icon: .trash
                ) {
                    Task { await model.askDeleteCitation() }
                }
                .disabled(model.isTranscribing || model.isDrawingDepiction)
                .accessibilityLabel(Text(verbatim: L10n.CitationComposer.deleteCitationAccessibility(ref: model.activeCitationRef)))
            }
            PVButton(
                L10n.CitationComposer.save,
                variant: .secondary,
                size: .sm,
                loading: model.fields.isSaving
            ) {
                Task { await model.fields.saveCitation() }
            }
            .disabled(!model.canSaveCitation)
            .accessibilityIdentifier("citationComposer.saveCitation")
        }
    }

    private func artifactTitle(_ artifact: CatalogArtifact) -> String {
        let label = artifact.label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !label.isEmpty { return label }
        return artifact.file?.originalFilename ?? ""
    }

    private func artifactMeta(_ artifact: CatalogArtifact) -> String {
        L10n.CitationComposer.artifactKindDetail(
            kind: artifactKindLabel(artifact),
            detail: artifactDetail(artifact)
        )
    }

    private func artifactKindLabel(_ artifact: CatalogArtifact) -> String {
        let media = artifact.file?.mediaType ?? ""
        if media == "application/pdf" {
            return L10n.string(L10n.CitationComposer.artifactKindPDF)
        }
        if media.hasPrefix("image/") {
            return L10n.string(L10n.CitationComposer.artifactKindImage)
        }
        return L10n.string(L10n.CitationComposer.artifactKindUnknown)
    }

    private func artifactDetail(_ artifact: CatalogArtifact) -> String {
        if artifact.id == model.selectedArtifactID {
            if model.artifactViewer.kind == .pdf, model.artifactViewer.pageCount > 0 {
                return L10n.CitationComposer.pageCount(count: model.artifactViewer.pageCount)
            }
            if model.artifactViewer.kind == .image, let size = model.artifactViewer.imagePixelSize {
                return L10n.CitationComposer.imagePixels(width: size.width, height: size.height)
            }
        }
        return ByteCountFormatter.string(fromByteCount: artifact.file?.byteSize ?? 0, countStyle: .file)
    }

    private func artifactMark(_ artifact: CatalogArtifact) -> PVMarkKey? {
        PVFileTypeGlyph.key(
            mediaType: artifact.file?.mediaType,
            originalFilename: artifact.file?.originalFilename
        )
    }

}

/// The Citation menu of the step picker and the observation dialog: a "New
/// citation" row, then one row per listed Citation.
struct CitationStepMenu: View {
    let model: CitationComposerModel
    let ordered: [CatalogListedCitation]
    let selection: Binding<String>
    let size: PVControlSize
    let menuWidth: CGFloat
    let maxVisibleRows: Int
    let rowHeight: CGFloat
    let isDisabled: Bool
    let accessibilityIdentifier: String

    var body: some View {
        let listedByID = Dictionary(ordered.map { ($0.citation.id, $0) }, uniquingKeysWith: { first, _ in first })
        PVSelect(
            selection: selection,
            options: options,
            size: size,
            displayLabel: model.citationStepLabel(for: selection.wrappedValue),
            menuWidth: menuWidth,
            maxVisibleRows: maxVisibleRows,
            rowHeight: rowHeight,
            isDisabled: isDisabled,
            accessibilityLabel: L10n.CitationComposer.citationEyebrow,
            accessibilityIdentifier: accessibilityIdentifier
        ) { option in
            if option.id.isEmpty {
                HStack(spacing: PVSpacing.space4) {
                    PVIcon(.plus, size: 14)
                    Text(L10n.CitationComposer.newCitation)
                        .font(PVFont.body(size: PVTypeScale.caption))
                    Text(L10n.CitationComposer.onThisArtifact)
                        .font(PVFont.body(size: 12, italic: true))
                        .foregroundStyle(PVColor.textMuted)
                }
            } else if let listed = listedByID[option.id] {
                CitationStepMenuRow(listed: listed)
            } else {
                Text(verbatim: option.label)
            }
        }
    }

    private var options: [PVSelectOption] {
        [PVSelectOption(value: "", label: L10n.string(L10n.CitationComposer.newCitation))]
            + ordered.map {
                PVSelectOption(value: $0.citation.id, label: $0.citation.ref)
            }
    }
}

/// Citation menu row for the step picker and the observation dialog.
struct CitationStepMenuRow: View {
    let listed: CatalogListedCitation

    /// The row's locator words: the printed page, the file page and the region,
    /// each when present, as "p. 23 · image 37 · region".
    static func locatorText(_ locator: CitationLocatorDraft) -> String {
        var parts: [String] = []
        if !locator.pageLabel.isEmpty {
            parts.append(CitationLineDisplay.printedPage(locator.pageLabel))
        }
        if let page = locator.page {
            parts.append(CitationLineDisplay.filePage(page))
        }
        if locator.region != nil {
            parts.append(L10n.string(L10n.CitationComposer.menuRegion))
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        let citation = listed.citation
        let locator = Self.locatorText(CitationLocatorDraft.decode(citation.locatorJSON))
        let label = citation.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let transcription = citation.transcription
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " — ")
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space4) {
                Text(verbatim: citation.ref)
                    .font(PVFont.mono(size: 12, weight: PVFontWeight.semibold))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
                Text(verbatim: L10n.CitationComposer.citationStepperCount(count: listed.observationCount))
                    .font(PVFont.mono(size: 11))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(1)
                Spacer(minLength: PVSpacing.space4)
                if !locator.isEmpty {
                    Text(verbatim: locator)
                        .font(PVFont.mono(size: 11))
                        .foregroundStyle(PVColor.textFaint)
                        .lineLimit(1)
                }
            }
            if !label.isEmpty {
                Text(verbatim: label)
                    .font(PVFont.body(size: 13))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
            }
            if transcription.isEmpty {
                Text(L10n.CitationComposer.noTranscriptionLine)
                    .font(PVFont.body(size: 12, italic: true))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(2)
            } else {
                Text(verbatim: transcription)
                    .font(PVFont.body(size: 12))
                    .foregroundStyle(PVColor.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, PVSpacing.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
