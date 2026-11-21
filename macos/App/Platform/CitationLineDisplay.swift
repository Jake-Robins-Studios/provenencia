import Foundation

extension CatalogCitationRender {
    /// The runs joined, each italic run marked `.emphasized` (as `NameDisplay.styled` marks a word),
    /// for `PVTitleText.italicizingEmphasis` to draw and the clipboard to write as rich text.
    var styled: AttributedString {
        var out = AttributedString()
        for run in runs {
            var piece = AttributedString(run.text)
            if run.italic {
                piece[AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.self] = .emphasized
            }
            out += piece
        }
        return out
    }
}

/// A record's citation line: "Source, Artifact, Citation, page" (S13-11). The
/// one place to replace when the standard-citation formatter of
/// `docs/deployment-plan/spike-15/citation-formats.md` lands.
enum CitationLineDisplay {
    /// A citation line in its two caption halves (S13-14 D-3).
    struct Parts: Equatable {
        /// The Source's title; not trimmed, as the old caption was not.
        var title: String
        /// The Artifact label, Citation label and page, joined as in `line`; "" when none.
        var detail: String
        /// `title` then `detail`: the whole citation line.
        var line: String
    }

    /// The page the original prints: "p. 23". The one home of these words; the citation menus use it too.
    static func printedPage(_ label: String) -> String {
        L10n.Conclusions.citationPagePrinted(label)
    }

    /// The page of the file: "image 37".
    static func filePage(_ page: Int) -> String {
        L10n.Conclusions.citationPageImage(page)
    }

    /// A record's citation line, split into the title and the rest. The Source's title, the Artifact label, the Citation label and the page, each trimmed and dropped when empty. The page is the printed label ("p. 23") else the image number ("image 37").
    static func parts(_ outcome: CatalogReconcilerOutcome) -> Parts {
        let pageLabel = outcome.pageLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let page: String
        if !pageLabel.isEmpty {
            page = printedPage(pageLabel)
        } else if outcome.artifactPage > 0 {
            page = filePage(outcome.artifactPage)
        } else {
            page = ""
        }
        let separator = L10n.string(L10n.Conclusions.citationLineSeparator)
        func joined(_ pieces: [String]) -> String {
            pieces
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: separator)
        }
        let title = outcome.sourceTitle
        return Parts(
            title: title,
            detail: joined([outcome.artifactLabel, outcome.citationLabel, page]),
            line: joined([title, outcome.artifactLabel, outcome.citationLabel, page])
        )
    }
}
