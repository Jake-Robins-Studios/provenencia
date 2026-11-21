import AppKit
import SwiftUI

/// What a copy writes: the plain text, and a styled copy where italics are kept
/// (emphasis marked `.emphasized`, as `PVTitleText.italicizingEmphasis` reads it).
struct PVClipboardPayload: Equatable {
    var plain: String
    var rich: AttributedString?
}

/// What a copy does and how long it shows as done, kept apart from the view so a
/// test can prove the pasteboard write and the timing without the real pasteboard
/// or a real wait.
@MainActor
@Observable
final class PVClipboardCopyState {
    /// How long the check shows before the copy glyph returns.
    static let copiedInterval: Duration = .milliseconds(1600)

    private(set) var copied = false

    @ObservationIgnored private let write: (PVClipboardPayload) -> Void
    @ObservationIgnored private let sleep: @MainActor (Duration) async -> Void
    @ObservationIgnored private var reset: Task<Void, Never>?

    init(
        write: @escaping (PVClipboardPayload) -> Void = PVClipboardCopyState.writeToGeneralPasteboard,
        sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.write = write
        self.sleep = sleep
    }

    /// Writes `text`, shows the check, and restarts the timer that clears it.
    func copy(_ text: String, rich: AttributedString? = nil) {
        write(PVClipboardPayload(plain: text, rich: rich))
        copied = true
        reset?.cancel()
        reset = Task { [sleep] in
            await sleep(Self.copiedInterval)
            guard !Task.isCancelled else { return }
            copied = false
        }
    }

    /// Stops the timer when the button goes away.
    func cancel() {
        reset?.cancel()
        reset = nil
        copied = false
    }

    nonisolated static func writeToGeneralPasteboard(_ payload: PVClipboardPayload) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let rich = payload.rich, let rtf = rtfData(rich) {
            pasteboard.setData(rtf, forType: .rtf)
        }
        pasteboard.setString(payload.plain, forType: .string)
    }

    /// `rich` as RTF in the system font, each `.emphasized` run in its italic face.
    nonisolated static func rtfData(_ rich: AttributedString) -> Data? {
        let base = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let out = NSMutableAttributedString(string: String(rich.characters), attributes: [.font: base])
        let italic = NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)
        for run in rich.runs where run[AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.self]?.contains(.emphasized) == true {
            out.addAttribute(.font, value: italic, range: NSRange(run.range, in: rich))
        }
        return try? out.data(
            from: NSRange(location: 0, length: out.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}

/// Provenencia copy-to-clipboard icon button: a `PVIconButton` showing the copy
/// glyph that writes `text` to the pasteboard, turns to a green check for 1.6
/// seconds, and tells VoiceOver `copiedAnnouncement` politely. A click during the
/// check copies again and restarts the timer. The tooltip does not change (the
/// check and the announcement say it was copied).
///
/// `rich` adds an RTF copy with the italics kept. `word` swaps the icon button for a
/// ghost `PVButton` that shows the word beside the glyph (two copy buttons that
/// would otherwise look alike); `label` stays its tooltip and spoken label.
///
/// `label` names what is copied ("Copy citation"); it is the tooltip and the
/// spoken label. Named for the pasteboard because ``PVCopy`` already means a
/// component's text.
struct PVClipboardButton: View {
    private let text: String
    private let rich: AttributedString?
    private let word: (any PVCopy)?
    private let label: any PVCopy
    private let copiedAnnouncement: String
    private let size: PVControlSize

    @State private var state: PVClipboardCopyState

    init(
        text: String,
        rich: AttributedString? = nil,
        word: (any PVCopy)? = nil,
        label: some PVCopy,
        copiedAnnouncement: String,
        size: PVControlSize = .sm
    ) {
        self.text = text
        self.rich = rich
        self.word = word
        self.label = label
        self.copiedAnnouncement = copiedAnnouncement
        self.size = size
        _state = State(initialValue: PVClipboardCopyState())
    }

    var body: some View {
        control
            .onDisappear { state.cancel() }
    }

    @ViewBuilder
    private var control: some View {
        if let word {
            PVButton(
                word,
                variant: .ghost,
                size: size,
                icon: state.copied ? .check : .copy,
                iconTint: state.copied ? PVColor.success : nil,
                action: copy
            )
            .accessibilityLabel(label.pvText)
            .help(label.pvText)
        } else {
            PVIconButton(
                state.copied ? .check : .copy,
                label: label,
                size: size,
                tone: state.copied ? .success : .neutral,
                action: copy
            )
        }
    }

    private func copy() {
        state.copy(text, rich: rich)
        AccessibilityAnnouncement.post(copiedAnnouncement, priority: .low)
    }
}

#Preview {
    HStack(spacing: PVSpacing.space5) {
        PVClipboardButton(text: "Parish register, p. 12", label: "Copy citation", copiedAnnouncement: "Citation copied")
        PVClipboardButton(text: "Parish register, p. 12", label: "Copy citation", copiedAnnouncement: "Citation copied", size: .md)
    }
    .padding(PVSpacing.space9)
    .background(PVColor.surfacePage)
}
