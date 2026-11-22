import SwiftUI

extension View {
    /// The Move to another Source dialog, presented while `model` is non-nil. A move that
    /// succeeds clears `model` and opens the target Source's page, where a Toast says what moved.
    func sourceMoveDialog(_ model: Binding<SourceMoveModel?>) -> some View {
        modifier(SourceMoveDialogModifier(model: model))
    }
}

private struct SourceMoveDialogModifier: ViewModifier {
    @Environment(WorkspaceNavigation.self) private var navigation
    @Binding var model: SourceMoveModel?

    func body(content: Content) -> some View {
        content.pvFormDialog(
            item: $model,
            copy: PVFormDialogCopy(
                title: L10n.Sources.moveDialogTitle,
                verbatimSubtitle: model.map { "\($0.seedTitle) · \($0.seedRef)" },
                confirm: L10n.Sources.moveConfirm,
                cancel: L10n.Sources.cancelAction
            ),
            width: 520,
            isRunning: model?.isMoving ?? false,
            confirmDisabled: !(model?.canMove ?? false),
            accessibilityIdentifierPrefix: "sources.move",
            scrollsBody: true,
            onConfirm: { current in
                await current.move(leavingPage: { target in
                    navigation.go(to: SourcesListNavigation.pageLocation(for: target))
                })
            },
            form: { SourceMoveForm(model: $0) }
        )
    }
}

/// The dialog body: the failure, the target field, what moves together, then the notes the
/// move earns.
private struct SourceMoveForm: View {
    @Bindable var model: SourceMoveModel

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if let moveError = model.moveError {
                PVCallout(
                    tone: .danger,
                    title: L10n.Sources.moveFailedTitle,
                    message: L10n.Sources.moveFailedMessage(moveError),
                    announces: true
                )
                .accessibilityIdentifier("sources.move.error")
            }
            targetField
            PVFormLoadArea(
                state: model.readState,
                loadingText: L10n.Sources.moveLoading,
                errorTitle: L10n.Sources.moveLoadErrorTitle,
                errorMessage: L10n.Sources.moveLoadErrorMessage,
                onReadAgain: { model.readAgain() },
                accessibilityIdentifierPrefix: "sources.move.bundle"
            ) {
                SourceMoveBundle(model: model)
            }
            if let note = model.credibilityNote {
                PVCallout(tone: .warning, title: note.title, message: note.message, compact: true)
                    .accessibilityIdentifier("sources.move.credibility")
            }
            if let note = model.leavesEmptyNote {
                PVCallout(tone: .neutral, message: note, compact: true)
                    .accessibilityIdentifier("sources.move.leavesEmpty")
            }
            if let note = model.leavesNoGraphNote {
                PVCallout(tone: .neutral, message: note, compact: true)
                    .accessibilityIdentifier("sources.move.leavesNoGraph")
            }
        }
    }

    /// While the Sources list is unread there is neither the field nor the note.
    @ViewBuilder
    private var targetField: some View {
        if let targets = model.targets {
            if targets.isEmpty {
                PVCallout(tone: .neutral, message: L10n.string(L10n.Sources.moveNowhere), compact: true)
                    .accessibilityIdentifier("sources.move.nowhere")
            } else {
                PVField(label: L10n.Sources.moveTargetLabel) {
                    PVComboBox(
                        selection: Binding(
                            get: { model.targetID ?? "" },
                            set: { model.pick(targetID: $0) }
                        ),
                        options: targets.map { PVComboBoxOption(value: $0.id, label: $0.title, subtext: $0.ref) },
                        placeholder: L10n.Sources.moveTargetPlaceholder,
                        emptyLabel: L10n.Sources.moveTargetNoMatch,
                        label: L10n.Sources.moveTargetLabel,
                        accessibilityIdentifierPrefix: "sources.move.target"
                    )
                }
            }
        }
    }
}

/// "Moves together": the Artifacts, then the graphs, one row each. The seed is first in its
/// group and carries no mark.
private struct SourceMoveBundle: View {
    let model: SourceMoveModel

    var body: some View {
        let artifacts = model.bundleArtifacts
        let graphs = model.bundleGraphs
        PVSubsectionHeader(title: L10n.Sources.moveTogether) {
            VStack(alignment: .leading, spacing: PVSpacing.space3) {
                if model.showsWhy {
                    Text(L10n.Sources.moveTogetherWhy)
                        .font(PVFont.body(size: PVTypeScale.bodySmall))
                        .foregroundStyle(PVColor.textSecondary)
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(artifacts, id: \.id) { art in
                        SourceMoveRow(
                            title: art.displayTitle,
                            ref: art.ref,
                            identifier: "sources.move.bundle.artifact.\(art.ref)"
                        ) {
                            CachedThumbnail(
                                projectDir: model.projectDir,
                                relPath: art.thumbnailRelPath,
                                mediaType: art.file?.mediaType ?? "",
                                originalFilename: art.file?.originalFilename ?? "",
                                typeIconKey: art.thumbnailTypeIconKey(sourceTypeIconKey: model.sourceTypeIconKey),
                                size: 32
                            )
                        } detail: {
                            EmptyView()
                        }
                    }
                    if !artifacts.isEmpty, !graphs.isEmpty {
                        PVDivider()
                    }
                    ForEach(graphs, id: \.graph.id) { row in
                        SourceMoveRow(
                            title: row.graph.name,
                            ref: row.graph.ref,
                            identifier: "sources.move.bundle.graph.\(row.graph.ref)"
                        ) {
                            PVIcon(.gitBranch, size: 16)
                                .foregroundStyle(PVColor.textMuted)
                                .frame(width: 32, height: 32)
                        } detail: {
                            if let progress = row.progress {
                                SourcesGraphCountLine(
                                    counts: SourcesGraphCounts(
                                        progress: progress, countsLoading: false, countsError: nil
                                    ),
                                    style: .card
                                )
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("sources.move.bundle")
    }
}

/// One bundle row: a 32pt lead, the title with its ref beside it, and an optional line under both.
private struct SourceMoveRow<Lead: View, Detail: View>: View {
    let title: String
    let ref: String
    let identifier: String
    @ViewBuilder let lead: () -> Lead
    @ViewBuilder let detail: () -> Detail

    var body: some View {
        HStack(alignment: .center, spacing: PVSpacing.space5) {
            lead()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: PVSpacing.space1) {
                HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space4) {
                    Text(verbatim: title)
                        .font(PVFont.body(size: PVTypeScale.bodySmall))
                        .foregroundStyle(PVColor.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(verbatim: ref)
                        .font(PVFont.mono(size: PVTypeScale.micro))
                        .foregroundStyle(PVColor.textMuted)
                        .fixedSize()
                }
                detail()
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 40, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
