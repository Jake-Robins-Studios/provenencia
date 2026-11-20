import AppKit
import SwiftUI
import Testing

@testable import Provenencia

@MainActor
struct PVTextAreaCompletionTests {
    /// A completion that opens on a `{` and takes the word after it, offering three rows.
    private func completion(accepted: Box<[String]> = Box([])) -> PVTextAreaCompletion {
        let rows = [
            PVComboBoxOption(value: "a", label: "Alpha", subtext: "a"),
            PVComboBoxOption(value: "b", label: "Beta", subtext: "b"),
            PVComboBoxOption(value: "c", label: "Gamma", subtext: "c"),
        ]
        return PVTextAreaCompletion(
            context: { text, caret in
                let ns = text as NSString
                var start = caret
                while start > 0, ns.character(at: start - 1) != 0x7B {
                    guard ns.character(at: start - 1) != 0x20 else { return nil }
                    start -= 1
                }
                guard start > 0 else { return nil }
                return .init(range: NSRange(location: start, length: caret - start), query: ns.substring(with: NSRange(location: start, length: caret - start)))
            },
            options: { query in query.isEmpty ? rows : rows.filter { $0.label.lowercased().hasPrefix(query.lowercased()) } },
            row: { option, _ in AnyView(Text(verbatim: option.label)) },
            accept: { option, context in
                accepted.value.append(option.value)
                return (text: option.value + "}", caretAfter: context.range.location + option.value.count + 1)
            },
            emptyLabel: "No match"
        )
    }

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    private func attached(_ text: String = "") -> (NSTextView, PVTextAreaCompletionSession, PVTextAreaTabRouter, PVTextAreaCursor, Box<[String]>) {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        textView.isEditable = true
        textView.string = text
        let accepted = Box<[String]>([])
        let session = PVTextAreaCompletionSession()
        session.completion = completion(accepted: accepted)
        session.textView = textView
        let router = PVTextAreaTabRouter()
        router.completionSession = session
        router.attach(to: textView)
        let cursor = PVTextAreaCursor()
        cursor.textView = textView
        return (textView, session, router, cursor, accepted)
    }

    @Test func cursorReplaceEditsTheTextAndPlacesTheCaret() {
        let (textView, _, _, cursor, _) = attached("abc")
        cursor.replace(NSRange(location: 1, length: 1), with: "XY", caretAfter: 3)
        #expect(textView.string == "aXYc")
        #expect(textView.selectedRange() == NSRange(location: 3, length: 0))
    }

    @Test func cursorSelectSelectsTheRange() {
        let (textView, _, _, cursor, _) = attached("hello world")
        cursor.select(NSRange(location: 6, length: 5))
        #expect(textView.selectedRange() == NSRange(location: 6, length: 5))
    }

    @Test func typingACompletableCharacterOpensTheListWithAllRows() {
        let (textView, session, _, _, _) = attached()
        textView.insertText("{", replacementRange: textView.selectedRange())
        #expect(session.isOpen)
        #expect(session.options.map(\.value) == ["a", "b", "c"])
        #expect(session.activeIndex == 0)
    }

    @Test func downThenReturnTakesTheSecondRowAndWritesItIn() {
        let (textView, session, router, _, accepted) = attached()
        textView.insertText("{", replacementRange: textView.selectedRange())
        #expect(router.textView(textView, doCommandBy: #selector(NSResponder.moveDown(_:))))
        #expect(router.textView(textView, doCommandBy: #selector(NSResponder.insertNewline(_:))))
        #expect(accepted.value == ["b"])
        #expect(textView.string == "{b}")
        #expect(textView.selectedRange() == NSRange(location: 3, length: 0))
        #expect(!session.isOpen)
    }

    @Test func escapeClosesTheListAndLeavesTheText() {
        let (textView, session, router, _, _) = attached()
        textView.insertText("{a", replacementRange: textView.selectedRange())
        #expect(session.isOpen)
        #expect(router.textView(textView, doCommandBy: #selector(NSResponder.cancelOperation(_:))))
        #expect(!session.isOpen)
        #expect(textView.string == "{a")
    }

    @Test func aCaretMoveWithNoEditDoesNotOpenTheList() {
        let (textView, session, _, _, _) = attached("{a")
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        session.selectionDidChange(textView)
        #expect(!session.isOpen)
    }

    @Test func aSpaceClosesTheList() {
        let (textView, session, _, _, _) = attached()
        textView.insertText("{a", replacementRange: textView.selectedRange())
        textView.insertText(" ", replacementRange: textView.selectedRange())
        #expect(!session.isOpen)
    }

    @Test func aClosedListLeavesReturnToTheTextView() {
        let (textView, _, router, _, _) = attached("plain")
        #expect(!router.textView(textView, doCommandBy: #selector(NSResponder.insertNewline(_:))))
    }

    @Test func theListFlipsAboveTheCaretWhenTheScreenHasNoRoomBelow() {
        let visible = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let caretNearBottom = CGRect(x: 100, y: 40, width: 360, height: 16)
        let frame = PVComboBoxPlacement.popupFrame(
            anchor: caretNearBottom,
            contentHeight: PVTextAreaCompletionList.height(rows: 8),
            visibleFrame: visible
        )
        #expect(frame.minY >= caretNearBottom.maxY)
    }
}
