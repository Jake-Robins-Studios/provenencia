import SwiftUI

/// One record as a row: Read as · Citation · Outcome · Record. The citation (the
/// engine's full citation, else today's line) opens the Citation; "Source" and
/// "Observation" links sit under it, and labelled buttons beside it copy it. Place a row
/// alone (with `PVProvenanceColumns` setting its cells) or as a row of a
/// `PVProvenanceRecordTable`; the two line up when they share the columns.
///
/// Every cell but Citation has a fixed width, so a row stands alone and still
/// lines up with its neighbours (S13-36 D-7). A link calls `open` with the
/// record and the link; the caller maps it to a place.
struct PVProvenanceRecordRow: View {
    let record: PVProvenanceSheetContent.Record
    /// How the Read as cell reads; used only with Read as on.
    var face: PVProvenanceFace = .text
    var columns = PVProvenanceColumns()
    /// The prefix of the row's accessibility ids: `<prefix>.<record id>.citation`, `.copy`, `.copyFull`, `.copyShort`, `.source`, `.observation`.
    let idPrefix: String
    let open: (PVProvenanceSheetContent.Record, PVProvenanceLink) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: columns.spacing) {
            if columns.showsReadAs {
                PVProvenanceReadAs(record: record, face: face)
                    .frame(width: columns.readAsWidth, alignment: .leading)
                    // The record as one element; the citation line and the links follow as controls.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(record.spoken)
            }
            citation
                .frame(maxWidth: .infinity, alignment: .leading)
            PVProvenanceOutcome(mark: record.mark, phrase: record.phrase)
                .frame(width: columns.outcomeWidth, alignment: .leading)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PVSpacing.space1) {
                Text(verbatim: record.observationRef)
                Text(verbatim: record.subjectRef)
            }
            .font(PVFont.mono(size: PVTypeScale.caption))
            .foregroundStyle(PVColor.textMuted)
            .textSelection(.enabled)
            .frame(width: PVProvenanceColumns.recordWidth, alignment: .leading)
            .accessibilityHidden(true)
        }
        // With no Read as cell the record's one spoken line sits at the row's
        // leading edge, ahead of the citation and the links, and takes no room.
        .overlay(alignment: .topLeading) {
            if !columns.showsReadAs {
                Color.clear.frame(width: 1, height: 1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(record.spoken)
            }
        }
        .padding(.vertical, PVSpacing.space3)
    }

    /// A copy button of the row's citation: the full form, the short form, or (a row with no format)
    /// today's line.
    enum Copy: Equatable {
        case full
        case short
        case citation
    }

    /// The copy buttons a record shows, top to bottom: the full citation, the short one when
    /// it rendered, or one Copy for a row with no full format.
    nonisolated static func copies(for record: PVProvenanceSheetContent.Record) -> [Copy] {
        guard record.isFormatted, let rendered = record.rendered else { return [.citation] }
        return rendered.short.runs.isEmpty ? [.full] : [.full, .short]
    }

    private var citation: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            HStack(alignment: .citationFirstLineCenter, spacing: PVProvenanceColumns.copyTrackSpacing) {
                PVInkLink(ink: record.counted ? .primary : .secondary, action: { open(record, .citation) }) {
                    citationText
                }
                    .accessibilityLabel(Text(verbatim: record.citationText))
                    .accessibilityIdentifier("\(idPrefix).\(record.id).citation")
                    // The first line's centre sits about a third of the type size above its baseline.
                    .alignmentGuide(.citationFirstLineCenter) { $0[.firstTextBaseline] - PVTypeScale.bodySmall / 3 }
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    ForEach(Self.copies(for: record), id: \.self) { copyButton($0) }
                }
                .frame(width: PVProvenanceColumns.copyTrackWidth, alignment: .leading)
                // The first button's centre sits level with the citation's first line.
                .alignmentGuide(.citationFirstLineCenter) { $0[.top] + PVControlSize.sm.height / 2 }
            }
            HStack(spacing: PVSpacing.space5) {
                PVButton(L10n.ProvenanceSheet.sourceLink, variant: .link, size: .sm) {
                    open(record, .source)
                }
                .accessibilityLabel(L10n.ProvenanceSheet.sourceLinkSpoken(record.citation.title))
                .accessibilityIdentifier("\(idPrefix).\(record.id).source")
                PVButton(L10n.ProvenanceSheet.observationLink(record.observationRef), variant: .link, size: .sm) {
                    open(record, .observation)
                }
                .accessibilityIdentifier("\(idPrefix).\(record.id).observation")
            }
        }
    }
}

extension PVProvenanceRecordRow {
    /// The link's label: the full citation with its italics, else today's line.
    @ViewBuilder
    fileprivate var citationText: some View {
        if record.isFormatted, let rendered = record.rendered {
            Text(PVTitleText.italicizingEmphasis(rendered.full.styled, font: PVFont.body(size: PVTypeScale.bodySmall)))
        } else {
            Text(verbatim: record.citation.line)
        }
    }

    @ViewBuilder
    fileprivate func copyButton(_ copy: Copy) -> some View {
        switch copy {
        case .full:
            if let full = record.rendered?.full {
                PVClipboardButton(
                    text: full.plain,
                    rich: full.styled,
                    word: L10n.ProvenanceSheet.copyWordFull,
                    label: L10n.ProvenanceSheet.copyFullCitation,
                    copiedAnnouncement: L10n.string(L10n.ProvenanceSheet.fullCitationCopied)
                )
                .accessibilityIdentifier("\(idPrefix).\(record.id).copyFull")
            }
        case .short:
            if let short = record.rendered?.short {
                PVClipboardButton(
                    text: short.plain,
                    rich: short.styled,
                    word: L10n.ProvenanceSheet.copyWordShort,
                    label: L10n.ProvenanceSheet.copyShortCitation,
                    copiedAnnouncement: L10n.string(L10n.ProvenanceSheet.shortCitationCopied)
                )
                .accessibilityIdentifier("\(idPrefix).\(record.id).copyShort")
            }
        case .citation:
            PVClipboardButton(
                text: record.citation.line,
                word: L10n.ProvenanceSheet.copyWordCitation,
                label: L10n.ProvenanceSheet.copyCitation,
                copiedAnnouncement: L10n.string(L10n.ProvenanceSheet.citationCopied)
            )
            .accessibilityIdentifier("\(idPrefix).\(record.id).copy")
        }
    }
}

private extension VerticalAlignment {
    private enum CitationFirstLineCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context[.top] }
    }

    /// The centre of a citation line's first line, so the copy button sits level with it at any line count.
    static let citationFirstLineCenter = VerticalAlignment(CitationFirstLineCenter.self)
}
