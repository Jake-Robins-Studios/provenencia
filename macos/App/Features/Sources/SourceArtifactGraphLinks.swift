import SwiftUI

/// The Evidence graphs an Artifact belongs to, as a bordered checklist: one
/// kit checkbox per graph with its name and ref. State is the unchecked set
/// (`excluded`), so a graph made later starts checked. A `locked` graph (its
/// id mapped to its hint) is checked, shows the lock mark and cannot be
/// cleared. Used by the Artifact sheet, in edit and add mode.
/// `accessibilityIdentifierPrefix` roots the ids: `<prefix>`, `.<graph id>`.
struct SourceArtifactGraphLinks: View {
    let graphs: [CatalogEvidenceGraph]
    @Binding var excluded: Set<String>
    var locked: [String: String] = [:]
    var isDisabled = false
    let accessibilityIdentifierPrefix: String

    var body: some View {
        PVChecklistFrame(items: graphs, id: \.id, row: row)
            .accessibilityIdentifier(accessibilityIdentifierPrefix)
    }

    private func row(_ graph: CatalogEvidenceGraph) -> some View {
        PVChecklistCheckbox(
            id: graph.id,
            title: graph.name,
            ref: graph.ref,
            description: graph.ref,
            lockReason: locked[graph.id],
            excluded: $excluded,
            isDisabled: isDisabled
        )
        .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(graph.id)")
        .padding(.vertical, PVSpacing.space2)
        .padding(.horizontal, PVSpacing.space5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension CatalogEvidenceGraphUnlinkBlock {
    /// The hint under a locked row: how many Citations the engine says are
    /// using the Artifact, else the engine's own reason. One wording for the
    /// Artifact sheet and the graph form; no reason is decided here.
    var lockHint: String {
        citationCount > 0
            ? PVDeleteImpactCopy.heading(via: reason.wire, kind: "citation", total: citationCount)
            : L10n.Errors.message(code: reason.wire)
    }
}

extension Sequence where Element == CatalogEvidenceGraphUnlinkBlock {
    /// Key (a graph or Artifact id) to the hint under its locked row: one lock
    /// per key, from the first block that names it. Every block the engine
    /// reports locks; Swift decides no lock.
    func lockHints(by key: KeyPath<Element, String>) -> [String: String] {
        var hints: [String: String] = [:]
        for block in self where hints[block[keyPath: key]] == nil {
            hints[block[keyPath: key]] = block.lockHint
        }
        return hints
    }
}

/// The muted line under a graph group with no box checked.
struct SourceArtifactNoGraphLine: View {
    let accessibilityIdentifier: String

    var body: some View {
        Text(L10n.Sources.artifactGraphsNone)
            .font(PVFont.body(size: PVTypeScale.caption, italic: true))
            .foregroundStyle(PVColor.textMuted)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}
