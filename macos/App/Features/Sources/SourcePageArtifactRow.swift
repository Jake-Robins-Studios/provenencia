import SwiftUI

/// One Artifact on the Source page: a list row (S15-D14). A Source page snowflake: a 64pt
/// thumbnail, the label, ref, description and graph line, the saved copy details in a column
/// of their own, then the actions. A row has no hover and nothing in it is editable in place.
struct SourcePageArtifactRow: View {
    static let thumbnailSize: CGFloat = 64

    let art: CatalogArtifact
    let model: SourcePageModel
    /// Nil while the graph list is not loaded: no graph line and no no-graph line.
    let graphLine: ArtifactGraphLine?

    private var id: String { art.id }
    private var owner: MetadataOwner { MetadataOwner(level: .artifact, id: art.id) }

    var body: some View {
        let canSetCover = model.artifacts.canUseAsThumbnail(art)
        return HStack(alignment: .top, spacing: PVSpacing.space7) {
            thumbnail
            textColumn
                .frame(maxWidth: .infinity, alignment: .leading)
            MetadataDetailsColumn(
                rows: model.metadataRows(for: owner),
                owner: owner,
                ref: art.ref,
                onMore: { model.artifacts.openSheet(artifactID: art.id, at: .copyDetails) }
            )
            actions(canSetCover: canSetCover)
        }
        .padding(.vertical, PVSpacing.space6)
        .overlay(alignment: .bottom) { PVDivider() }
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: art.displayTitle))
        .accessibilityIdentifier("sources.page.artifact.\(id)")
    }

    // MARK: Thumbnail

    private var thumbnail: some View {
        Button {
            if art.hasFile {
                Task { await model.artifacts.open(art) }
            } else {
                model.artifacts.openAttach(to: art.id)
            }
        } label: {
            CachedThumbnail(
                projectDir: model.pageProjectDir,
                relPath: art.thumbnailRelPath,
                mediaType: art.file?.mediaType ?? "",
                originalFilename: art.file?.originalFilename ?? "",
                typeIconKey: model.artifacts.thumbnailTypeIconKey(for: art),
                size: Self.thumbnailSize
            )
        }
        .buttonStyle(PVFocusRingButtonStyle(cornerRadius: PVRadius.sm))
        .help(Text(art.hasFile ? L10n.Sources.artifactOpenFileTip : L10n.Sources.artifactAddFileTip))
        .accessibilityLabel(
            art.hasFile
                ? L10n.Sources.openArtifactFile(name: art.fileDisplayName)
                : L10n.Sources.addFileToArtifact(ref: art.ref)
        )
        .accessibilityIdentifier(
            art.hasFile
                ? "sources.page.artifact.\(id).open"
                : "sources.page.artifact.\(id).addFile"
        )
    }

    // MARK: Text column

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            PVFlowLayout(spacing: PVSpacing.space4, lineSpacing: PVSpacing.space1) {
                Text(verbatim: art.displayTitle)
                    .font(PVFont.body(size: PVTypeScale.body, weight: PVFontWeight.semibold))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(2)
                Text(verbatim: art.ref)
                    .font(PVFont.mono(size: PVTypeScale.caption))
                    .foregroundStyle(PVColor.textMuted)
                    .fixedSize()
                if model.artifacts.isCover(art) {
                    PVBadge(L10n.Sources.coverBadge, tone: .accent, icon: .photo)
                        .accessibilityIdentifier("sources.page.artifact.\(id).coverBadge")
                }
            }
            .accessibilityElement(children: .combine)
            descriptionLine
            graphLineView
        }
    }

    @ViewBuilder
    private var descriptionLine: some View {
        if !art.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(verbatim: art.description)
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: PVSpacing.measureProse, alignment: .leading)
        }
    }

    @ViewBuilder
    private var graphLineView: some View {
        switch graphLine {
        case .graphs(let all, let shown, let more)?:
            HStack(spacing: PVSpacing.space3) {
                PVIcon(.gitBranch, size: 13)
                    .foregroundStyle(PVColor.textMuted)
                Text(verbatim: shown.joined(separator: " · "))
                    .font(PVFont.body(size: PVTypeScale.caption))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(1)
                if more > 0 {
                    PVBadge.moreCount(more)
                        .layoutPriority(1)
                }
            }
            .help(all.joined(separator: " · "))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.Sources.artifactGraphsSpoken(names: L10n.DesignSystem.spokenJoin(all) ?? ""))
            .accessibilityIdentifier("sources.page.artifact.\(id).graphs")
        case .none?:
            PVFlowLayout(spacing: PVSpacing.space3, lineSpacing: PVSpacing.space2) {
                PVBadge(L10n.Sources.artifactNotInGraph, tone: .neutral, icon: .link)
                    .fixedSize()
                    .accessibilityIdentifier("sources.page.artifact.\(id).noGraph")
                PVButton(L10n.Sources.artifactLinkToGraph, variant: .ghost, size: .sm) {
                    model.artifacts.openSheet(artifactID: art.id, at: .graphs)
                }
                .fixedSize()
                .accessibilityLabel(L10n.Sources.artifactLinkToGraphLabel(ref: art.ref))
                .accessibilityIdentifier("sources.page.artifact.\(id).linkToGraph")
            }
        case nil:
            EmptyView()
        }
    }

    // MARK: Actions

    private func actions(canSetCover: Bool) -> some View {
        HStack(spacing: PVSpacing.space2) {
            PVButton(L10n.Sources.useAsThumbnail, variant: .ghost, size: .sm, icon: .imageUp) {
                Task { await model.artifacts.useAsThumbnail(art) }
            }
            .opacity(canSetCover ? 1 : 0)
            .disabled(!canSetCover)
            .accessibilityHidden(!canSetCover)
            .accessibilityIdentifier("sources.page.artifact.\(id).useAsThumbnail")
            PVIconButton(
                .penLine,
                label: L10n.Sources.editArtifactLabel(ref: art.ref),
                size: .sm
            ) {
                model.artifacts.openSheet(artifactID: art.id)
            }
            .accessibilityIdentifier("sources.page.artifact.\(id).edit")
            PVIconButton(
                .folderInput,
                label: L10n.Sources.moveArtifactLabel(name: art.displayTitle),
                size: .sm
            ) {
                model.openMove(artifactID: art.id)
            }
            .accessibilityIdentifier("sources.page.artifact.\(id).move")
            PVIconButton(
                .trash,
                label: L10n.Sources.deleteArtifact,
                size: .sm,
                tone: .danger
            ) {
                Task { await model.askDeleteArtifact(id: art.id) }
            }
            .accessibilityIdentifier("sources.page.artifact.\(id).delete")
        }
        .fixedSize()
        .frame(minHeight: 28)
    }
}
