@preconcurrency import AppKit
import SwiftUI

/// One row in a `PVComboBox` list. `subtext` is the secondary line the
/// default row renders under the label; it is matched by the filter too, so
/// a caller can put a machine key there and let the researcher type either.
struct PVComboBoxOption: Identifiable, Equatable {
    let value: String
    let label: String
    let subtext: String
    let isDisabled: Bool

    var id: String { value }

    init(value: String, label: String, subtext: String = "", isDisabled: Bool = false) {
        self.value = value
        self.label = label
        self.subtext = subtext
        self.isDisabled = isDisabled
    }
}

// MARK: - Pure helpers

/// Filtering and highlight rules, split out so they can be unit-tested
/// without a view — same split as `PVTableTypeSelectMatcher`.
enum PVComboBoxMatch {
    /// Contains matches, in three bands, then the caller's order inside a band:
    /// the label starts with the query, a later word starts with it, then any
    /// other contains match including subtext only. Substring, not prefix: a
    /// key like `publication-date` should be findable by typing `date`. Case,
    /// accents, punctuation and word breaks never matter (`TextMatch`).
    static func filter(_ options: [PVComboBoxOption], query: String) -> [PVComboBoxOption] {
        let q = TextMatch.Query(query)
        guard !q.isEmpty else { return options }
        return options.enumerated().compactMap { index, option -> (band: Int, index: Int, option: PVComboBoxOption)? in
            let labelKey = TextMatch.key(option.label)
            guard q.matchesKey(labelKey) || q.matches(option.subtext) else { return nil }
            return (band(for: option, labelKey: labelKey, query: q), index, option)
        }
        .sorted { lhs, rhs in
            if lhs.band != rhs.band { return lhs.band < rhs.band }
            return lhs.index < rhs.index
        }
        .map(\.option)
    }

    /// 0 label prefix, 1 a later word prefix, 2 any other contains match.
    private static func band(for option: PVComboBoxOption, labelKey: String, query: TextMatch.Query) -> Int {
        if query.isPrefix(ofKey: labelKey) { return 0 }
        if TextMatch.words(option.label).dropFirst().contains(where: { query.isPrefix(ofKey: $0) }) { return 1 }
        return 2
    }

    /// What the list draws under its rows.
    enum ListLine: Equatable {
        /// The options alone.
        case rows
        /// The searching line: remote results are loading and none are in yet.
        case loading
        /// The caller's empty line.
        case empty
    }

    /// Options already in stay on screen while a new search runs, the way the
    /// omnibar keeps its hits; the searching line shows only when there is
    /// nothing else to show.
    static func listLine(optionCount: Int, isLoading: Bool) -> ListLine {
        if optionCount > 0 { return .rows }
        return isLoading ? .loading : .empty
    }

    /// Whether the box tells its caller about a reset it made itself (a click
    /// away or Escape putting the committed label back). Only a remote caller
    /// follows the field's text; a local filter reads the box's own state.
    static func reportsRestore(isRemote: Bool, old: String, new: String) -> Bool {
        isRemote && old != new
    }

    /// What Return does in the field.
    enum ReturnAction: Equatable {
        /// Commit the highlighted row at this index.
        case commit(Int)
        /// Let the key reach the enclosing form's `.onSubmit` or a sheet's
        /// default button.
        case submit
        /// Take the key and do nothing.
        case swallow
    }

    /// Return passes on only when the field shows its pick, so a form never
    /// acts on a pick the field no longer shows.
    static func returnAction(activeIndex: Int, optionCount: Int, query: String, committedLabel: String) -> ReturnAction {
        if (0..<optionCount).contains(activeIndex) { return .commit(activeIndex) }
        return query == committedLabel ? .submit : .swallow
    }
}

/// Where the popup window sits relative to the field.
enum PVComboBoxPlacement {
    /// Air between the field and its list.
    static let gap: CGFloat = 4

    /// Screen frame for the popup window. All rects are AppKit **screen**
    /// coordinates, so y grows upward and "below the field" means a smaller
    /// y than the field's `minY`.
    ///
    /// The popup is placed strictly outside the anchor — it can never cover
    /// the text you are typing into — and always inside `visibleFrame`, so it
    /// cannot run off the display. It prefers to open downward and flips
    /// above the field only when it does not fit below *and* there is more
    /// room up there; whichever side it lands on, the height is trimmed to
    /// the space actually available, leaving the list to scroll inside it.
    static func popupFrame(
        anchor: CGRect,
        contentHeight: CGFloat,
        visibleFrame: CGRect,
        gap: CGFloat = gap
    ) -> CGRect {
        let spaceBelow = max(0, anchor.minY - visibleFrame.minY - gap)
        let spaceAbove = max(0, visibleFrame.maxY - anchor.maxY - gap)
        let opensUp = contentHeight > spaceBelow && spaceAbove > spaceBelow
        let height = min(contentHeight, opensUp ? spaceAbove : spaceBelow)
        let y = opensUp ? anchor.maxY + gap : anchor.minY - gap - height
        let width = min(anchor.width, visibleFrame.width)
        let x = min(max(anchor.minX, visibleFrame.minX), visibleFrame.maxX - width)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

/// Renders `text` with the matched span wearing the highlighter mark.
enum PVComboBoxHighlight {
    static func attributed(_ text: String, query: String) -> AttributedString {
        var full = AttributedString(text)
        // The span `TextMatch` matched, so the highlight lands where the
        // filter matched.
        guard let range = TextMatch.range(of: TextMatch.Query(query), in: text),
              let attributed = Range(range, in: full) else {
            return full
        }
        // Typed `AttributeContainer` subscripts — not `.backgroundColor` /
        // `.foregroundColor` dynamic members — avoid Swift 6 key-path
        // Sendable warnings that otherwise spam every `PVComboBox` call site.
        var mark = AttributeContainer()
        mark[AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.self] =
            PVColor.markBackground
        mark[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] =
            PVColor.markForeground
        full[attributed].mergeAttributes(mark)
        return full
    }
}

// MARK: - Default row

/// The `plain` row kind: label, and a muted second line when the option has
/// `subtext`. Both lines carry the match highlight.
struct PVComboBoxPlainRow: View {
    let option: PVComboBoxOption
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(PVComboBoxHighlight.attributed(option.label, query: query))
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.textPrimary)
                .lineLimit(1)
            if !option.subtext.isEmpty {
                Text(PVComboBoxHighlight.attributed(option.subtext, query: query))
                    .font(PVFont.body(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// How a combo box committed its selection. The form chooses the next field.
enum PVComboCommitVia: Equatable {
    case click
    case `return`
    case tab
}

// MARK: - ComboBox

/// A searchable single-select field — the design system's
/// `components/forms/ComboBox.jsx`, ported for macOS 14.
///
/// It replaces a `PVSelect` wherever the pool is long enough that scanning a
/// popup menu is worse than typing: the field filters as you type, arrow keys
/// walk the list, and Return commits.
///
/// **Interaction contract** (all of it is load-bearing — the web component
/// documents why):
/// - The field's text is seeded from the committed option's label, so *having
///   text* is not the same as *having typed*. Only typed text filters, which
///   is why re-opening the field shows the whole list rather than just the row
///   already chosen.
/// - Spotlight rule: while there is a query the top hit is pre-highlighted so
///   Return takes it. With no query nothing is highlighted — it is a browse
///   list. Return with no highlighted row reaches the form only when the
///   field shows its pick (`PVComboBoxMatch.returnAction`).
/// - Arrow keys **clamp** at the ends rather than cycling, matching `NSMenu`.
///   ⌘↑/⌘↓ and Home/End jump to the ends; Page Up/Down move by 8
///   (`PVPopupListHighlight`).
/// - Escape is two-stage: close the list, then abandon the typed text.
/// - Clicking anywhere outside the field or its list closes the list **and
///   blurs the field** — outside means done. Clicking the field itself
///   reopens a closed list.
/// - The pointer and the keyboard drive the *same* highlight, so there is no
///   separate hover state.
///
/// **The list is a child window, not an overlay.** A SwiftUI overlay is
/// clipped by any enclosing `ScrollView` and by the app window, which makes it
/// useless for a field near the bottom of a scrolling inspector. `NSMenu`,
/// `NSComboBox` and Spotlight all draw into their own borderless window for
/// exactly that reason, and so does this: `PVComboBoxPlacement` positions it
/// in screen coordinates against the field, so it clips to the *display*
/// rather than to any view, may extend past the app window's edge, and is
/// placed strictly outside the field so it can never cover what you type. The
/// window never becomes key, so the text field keeps focus and keeps handling
/// keys while the list is open.
///
/// **Content is the caller's.** The box owns the field, the list window,
/// keyboard and pointer, highlight and the row / empty-line chrome; what a row
/// and the empty line *say* comes in through `row` and `empty`. The kit ships
/// one generic row (`PVComboBoxPlainRow`: label + subtext) and a plain-text
/// empty line (`emptyLabel` inits); anything domain-shaped — a person row, a
/// type mark — is a feature view passed as `row`, and an empty line that
/// changes with the caller's state (a hint, a failure's message) is a view
/// passed as `empty` through the general init. It never grows row kinds.
///
/// **Remote results** (S9-11): set `onQueryChange` and the box stops
/// filtering — the caller runs the search and passes the results as
/// `options`, keeping the committed option among them so its label stays in
/// the field. `isLoading` is true while that search runs: with no options in
/// yet the list shows a searching line in place of the empty line, and
/// options already in stay on screen until the new ones replace them
/// (`PVComboBoxMatch.listLine`). A failed search is the caller's `empty`
/// line. When the box resets the field itself (a click away, the second
/// Escape) it reports the restored text through `onQueryChange` too, so the
/// caller's query and results follow the field (`PVComboBoxMatch.reportsRestore`).
///
/// **Not ported** (add here on demand, the way `PVSidebarNav` was): the
/// multi-select token field and the "use what you typed" create row. No call
/// site needs them yet.
struct PVComboBox<Row: View, Empty: View>: View {
    /// The committed option's `value`; empty means nothing is chosen.
    @Binding var selection: String
    let options: [PVComboBoxOption]
    var size: PVControlSize = .md
    var placeholder: (any PVCopy)?
    var isInvalid: Bool = false
    var maxListHeight: CGFloat = 288
    /// Accessibility label for the field and its list — components never
    /// invent their own (`docs/macos-client-patterns.md` §5).
    let label: any PVCopy
    var accessibilityIdentifierPrefix: String?
    /// Runs after the selection is written. A forward Tab asks the form
    /// whether to take the key. Return true to move focus inside the form.
    var onCommit: ((String, PVComboCommitVia) -> Bool)? = nil
    /// When set, the text field is bound to the host's `FocusState`.
    var focus: PVFieldFocus? = nil
    /// Remote results: called with each typed query; the caller filters and
    /// passes the results as `options`. Nil filters locally.
    var onQueryChange: ((String) -> Void)?
    /// Remote results: true while the caller's search runs. See the type's
    /// "Remote results" note.
    var isLoading: Bool = false
    /// One option's row content, given the typed query to highlight.
    @ViewBuilder var row: (PVComboBoxOption, String) -> Row
    /// The list's line when no option shows, given the typed query (empty
    /// when nothing is typed). The box sets its type and frame.
    @ViewBuilder var empty: (String) -> Empty

    @State private var query = ""
    /// Whether the current text came from the keyboard rather than from
    /// mirroring the committed label. Only typed text filters.
    @State private var isDirty = false
    @State private var isOpen = false
    /// The highlighted row. The keyboard and the pointer both drive it —
    /// there is no separate hover state.
    @State private var highlight = PVPopupListHighlight()
    /// Natural height of `rowsStack`, reported by `measuringRows`. The popup
    /// window is sized from this rather than from anything inside it.
    @State private var measuredRowsHeight: CGFloat = 0
    /// True once the open menu's rows have reported a height. The window
    /// stays down until then, so it does not appear at zero and resize.
    @State private var rowsMeasured = false
    @FocusState private var isFocused: Bool

    /// Gutter that holds the committed row's checkmark. Every row reserves it
    /// so labels stay aligned whether or not one is checked.
    private static var checkGutter: CGFloat { 22 }
    /// Air above and below the rows, inside the list's border.
    private static var listVerticalPadding: CGFloat { PVSpacing.space2 }

    /// How tall the popup wants to be: the rows plus the list's own padding.
    /// The coordinator clamps this to `maxListHeight` and to the room on
    /// screen, and the scroller takes up whatever it lands on.
    private var desiredPopupHeight: CGFloat {
        measuredRowsHeight + Self.listVerticalPadding * 2
    }

    private var selectedOption: PVComboBoxOption? {
        options.first { $0.value == selection }
    }

    private var selectedLabel: String {
        selectedOption?.label ?? ""
    }

    /// True only when the researcher typed something — see `isDirty`.
    private var hasTypedQuery: Bool {
        isDirty && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var visibleOptions: [PVComboBoxOption] {
        guard onQueryChange == nil else { return options }
        return hasTypedQuery ? PVComboBoxMatch.filter(options, query: query) : options
    }

    /// The query the rows highlight against — empty unless the user typed.
    private var highlightQuery: String {
        hasTypedQuery ? query.trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }

    var body: some View {
        field
            .background {
                if isOpen {
                    measuringRows
                }
            }
            .background(
                PVPopupList(
                    isPresented: isOpen && rowsMeasured,
                    maxHeight: maxListHeight,
                    // Only things that change the window's *size* are passed
                    // as metrics. `activeIndex` changes on every mouse move,
                    // and re-framing the window that often tore down click
                    // handling inside it.
                    contentHeight: desiredPopupHeight,
                    optionCount: visibleOptions.count,
                    onDismiss: dismissAndBlur,
                    content: openList
                )
            )
            .onChange(of: selectedLabel, initial: true) { _, newValue in
                // Mirror an externally-set value into the field, but not over
                // the top of someone mid-edit. The exception is the selection
                // being cleared or dropping out of `options` — the caller
                // does that after acting on the choice (assigning the field
                // removes it from the pool), and the field must not go on
                // showing a label that no longer names anything.
                guard !fieldIsFocused || selectedOption == nil else { return }
                query = newValue
                isDirty = false
            }
            .onChange(of: fieldIsFocused) { _, focused in
                // Losing focus closes the list and restores the field. Gaining
                // focus alone does **not** open — a sheet that lands first
                // responder on this field (Add Source) would otherwise pop the
                // list immediately. Open comes from a click, a keystroke, or
                // an arrow / Home / End / Page key. The popup's mouse monitor
                // still catches clicks on things that take no focus (a button,
                // a label, empty chrome) and resolves them via `dismissAndBlur`,
                // which resigns focus and lands back here.
                if !focused { closeAndRestore() }
            }
            .onChange(of: isOpen) { _, open in
                if open { return }
                highlight.clear()
                measuredRowsHeight = 0
                rowsMeasured = false
            }
    }

    /// Host focus when the form bound one; otherwise the field's own.
    private var fieldIsFocused: Bool { focus.isActive(own: isFocused) }

    // MARK: Field

    private var field: some View {
        fieldText
            .onKeyPress(action: handleKey)
            .modifier(PVInputChrome(
                size: size,
                isFocused: fieldIsFocused,
                isInvalid: isInvalid,
                leadingIconInset: true
            ))
            .overlay(alignment: .leading) {
                PVIcon(.search, size: PVInputChrome.iconSize)
                    .foregroundStyle(PVColor.textFaint)
                    .padding(.leading, PVInputChrome.horizontalInset)
                    .allowsHitTesting(false)
            }
            // Clicking a focused field whose list is closed (Escape closed
            // it, or a commit did) reopens it — without this the component
            // is stuck until focus leaves and comes back. Simultaneous, so
            // the text field still places the caret.
            .simultaneousGesture(TapGesture().onEnded {
                if !isOpen { open() }
            })
            .accessibilityLabel(label.pvText)
            .accessibilityIdentifier(accessibilityIdentifierPrefix ?? "")
    }

    private var fieldText: some View {
        TextField(text: typedText, prompt: placeholder?.pvText) { EmptyView() }
            .textFieldStyle(.plain)
            .modifier(PVFieldFocusModifier(host: focus, own: $isFocused))
    }

    /// The text binding the field edits. Only the *setter* marks the text as
    /// typed, which is what separates a keystroke from the code assigning
    /// `query` (mirroring a committed label, reverting on Escape, restoring
    /// on dismiss) — those assign `query` directly and leave `isDirty` alone.
    ///
    /// The same-value guard matters: `TextField` re-writes its binding when
    /// editing ends, and treating that write as typing reopened the list on
    /// blur. Only an actual change counts.
    private var typedText: Binding<String> {
        Binding(
            get: { query },
            set: { typed in
                guard typed != query else { return }
                query = typed
                isDirty = true
                isOpen = true
                resetActiveRow()
                onQueryChange?(typed)
            }
        )
    }

    // MARK: List

    /// The popup's rows. Absent while the menu is closed, so a shut field
    /// does not build an option view for every choice.
    @ViewBuilder
    private var openList: some View {
        if isOpen {
            list
        }
    }

    /// The scroller simply **fills** the popup window (inside `PVPopupListCard`):
    /// the window is the only thing that clamps its height. It deliberately does
    /// not also report an ideal height, since asking one view to both size the
    /// window and lay out inside it clips a row when the two disagree.
    private var list: some View {
        let options = visibleOptions
        return PVPopupListCard(
            rowIDs: options.map(\.id),
            activeID: highlight.current(count: options.count).map { options[$0].id },
            verticalPadding: Self.listVerticalPadding
        ) {
            rowsStack
        }
        .accessibilityLabel(label.pvText)
        .accessibilityIdentifier(identifier("list") ?? "")
    }

    /// The rows at their natural height. Shared by the scroller and by the
    /// hidden measuring copy behind the field, so the two can never disagree.
    private var rowsStack: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleOptions.enumerated()), id: \.element.id) { index, option in
                rowView(option, index: index).id(option.id)
            }
            switch PVComboBoxMatch.listLine(optionCount: visibleOptions.count, isLoading: isLoading) {
            case .rows:
                EmptyView()
            case .loading:
                PVPopupListLine(gutter: Self.checkGutter) {
                    HStack(spacing: PVSpacing.space3) {
                        ProgressView()
                            .controlSize(.small)
                        Text(L10n.DesignSystem.comboBoxSearching)
                            .font(PVFont.body(size: PVTypeScale.bodySmall))
                            .foregroundStyle(PVColor.textMuted)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(identifier("loading") ?? "")
            case .empty:
                PVPopupListLine(gutter: Self.checkGutter) {
                    empty(highlightQuery)
                        .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                        .foregroundStyle(PVColor.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityIdentifier(identifier("empty") ?? "")
            }
        }
    }

    /// A hidden, non-interactive copy of the rows, laid out behind the field
    /// at the field's width purely to measure them. Mounted only while the
    /// menu is open.
    ///
    /// The popup window has to know how tall to be *before* it is shown, and
    /// a `ScrollView` inside that window cannot tell it — nor can
    /// `NSHostingView.fittingSize`, reliably. Laying the rows out once more
    /// here is the honest way to get the number: a background never
    /// influences its parent's size, so this costs a layout pass and nothing
    /// else. The window waits for that height, then opens at it.
    private var measuringRows: some View {
        rowsStack
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.height, initial: true) { _, height in
                            guard isOpen, height > 0 else { return }
                            measuredRowsHeight = height
                            rowsMeasured = true
                        }
                }
            )
    }

    /// The row — check gutter and padding — is owned here so every row stays
    /// aligned whatever the caller draws inside it; the shell is `PVPopupListRow`.
    private func rowView(_ option: PVComboBoxOption, index: Int) -> some View {
        PVPopupListRow(
            isActive: index == highlight.index,
            isSelected: option.value == selection,
            isDisabled: option.isDisabled,
            onHighlight: {
                let options = visibleOptions
                highlight.hover(at: index, count: options.count, isDisabled: { options[$0].isDisabled })
            },
            onCommit: { _ = commit(option, via: .click) }
        ) {
            HStack(spacing: PVSpacing.space5) {
                PVIcon(.check, size: 13)
                    .foregroundStyle(PVColor.accent)
                    .opacity(option.value == selection ? 1 : 0)
                    .frame(width: Self.checkGutter)
                    .accessibilityHidden(true)
                row(option, highlightQuery)
            }
            .padding(.trailing, PVSpacing.space5)
            .padding(.vertical, PVSpacing.space3)
        }
        .accessibilityIdentifier(identifier("option.\(option.value)") ?? "")
    }

    // MARK: Behaviour

    private func open() {
        isOpen = true
        resetActiveRow()
    }

    /// Spotlight rule: a query pre-selects the top hit so Return takes it;
    /// with no query the list is a browse list and nothing is highlighted.
    private func resetActiveRow() {
        guard hasTypedQuery else {
            highlight.clear()
            return
        }
        let options = visibleOptions
        highlight.land(count: options.count, isDisabled: { options[$0].isDisabled })
    }

    /// Writes the row, then asks the form. A forward Tab is taken when the
    /// form returns true.
    private func commit(_ option: PVComboBoxOption, via: PVComboCommitVia) -> Bool {
        guard !option.isDisabled else { return false }
        selection = option.value
        query = option.label
        isDirty = false
        isOpen = false
        let claim = onCommit?(option.value, via) ?? false
        return via == .tab && claim
    }

    /// Dismissing abandons whatever was typed and puts the committed label
    /// back — the field is a picker, not free text.
    private func closeAndRestore() {
        isOpen = false
        restoreQuery()
    }

    /// Puts the committed label back in the field and tells a remote caller.
    private func restoreQuery() {
        let old = query
        query = selectedLabel
        isDirty = false
        if PVComboBoxMatch.reportsRestore(isRemote: onQueryChange != nil, old: old, new: query) {
            onQueryChange?(query)
        }
    }

    /// The popup's dismissal (click away, window resigning key). On top of
    /// closing, it resigns focus: clicking anywhere outside the field or its
    /// list means "I'm done here", and a field that kept its focus ring after
    /// that read as a bug.
    private func dismissAndBlur() {
        closeAndRestore()
        focus.resign(own: $isFocused)
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        if PVPopupListHighlight.isMovementKey(press.key) {
            // A closed list opens first (which may land on the top hit), then
            // the key moves from there.
            if !isOpen { open() }
            let options = visibleOptions
            highlight.move(
                press.key, command: press.modifiers.contains(.command),
                count: options.count, isDisabled: { options[$0].isDisabled }
            )
            return .handled
        }
        switch press.key {
        case .return:
            let options = visibleOptions
            switch PVComboBoxMatch.returnAction(
                activeIndex: highlight.index, optionCount: options.count, query: query, committedLabel: selectedLabel
            ) {
            case .commit(let index):
                _ = commit(options[index], via: .return)
                return .handled
            case .submit:
                return .ignored
            case .swallow:
                return .handled
            }
        case .escape:
            // Two-stage: close the list first, then abandon the typed text.
            // With neither left to undo, let Escape through — an enclosing
            // sheet or dialog still has to be dismissable from this field.
            if isOpen {
                isOpen = false
                return .handled
            }
            if query != selectedLabel {
                restoreQuery()
                return .handled
            }
            return .ignored
        case .tab:
            // Forward Tab commits the highlight and asks the form. The form
            // takes the key whenever another field follows this one.
            let options = visibleOptions
            if isOpen, let index = highlight.current(count: options.count) {
                if commit(options[index], via: .tab) { return .handled }
            }
            isOpen = false
            return focus?.claimTab(shift: false) ?? .ignored
        case .backTab:
            // Shift-Tab leaves the list alone unless the form has a previous
            // field to take the key.
            guard focus?.previous != nil else { return .ignored }
            isOpen = false
            return focus?.claimTab(shift: true) ?? .ignored
        default:
            return .ignored
        }
    }

    private func identifier(_ suffix: String) -> String? {
        accessibilityIdentifierPrefix.map { "\($0).\(suffix)" }
    }
}

extension PVComboBox {
    /// Caller-built rows and a caller-built empty line, given the typed query.
    init(
        selection: Binding<String>,
        options: [PVComboBoxOption],
        size: PVControlSize = .md,
        placeholder: (any PVCopy)? = nil,
        isInvalid: Bool = false,
        maxListHeight: CGFloat = 288,
        label: any PVCopy,
        accessibilityIdentifierPrefix: String? = nil,
        focus: PVFieldFocus? = nil,
        onCommit: ((String, PVComboCommitVia) -> Bool)? = nil,
        onQueryChange: ((String) -> Void)? = nil,
        isLoading: Bool = false,
        @ViewBuilder row: @escaping (PVComboBoxOption, String) -> Row,
        @ViewBuilder empty: @escaping (String) -> Empty
    ) {
        self.init(
            selection: selection,
            options: options,
            size: size,
            placeholder: placeholder,
            isInvalid: isInvalid,
            maxListHeight: maxListHeight,
            label: label,
            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
            onCommit: onCommit,
            focus: focus,
            onQueryChange: onQueryChange,
            isLoading: isLoading,
            row: row,
            empty: empty
        )
    }
}

extension PVComboBox where Empty == Text {
    /// Caller-built rows with a plain-text empty line.
    init(
        selection: Binding<String>,
        options: [PVComboBoxOption],
        size: PVControlSize = .md,
        placeholder: (any PVCopy)? = nil,
        emptyLabel: LocalizedStringResource,
        isInvalid: Bool = false,
        maxListHeight: CGFloat = 288,
        label: any PVCopy,
        accessibilityIdentifierPrefix: String? = nil,
        focus: PVFieldFocus? = nil,
        onCommit: ((String, PVComboCommitVia) -> Bool)? = nil,
        onQueryChange: ((String) -> Void)? = nil,
        isLoading: Bool = false,
        @ViewBuilder row: @escaping (PVComboBoxOption, String) -> Row
    ) {
        self.init(
            selection: selection,
            options: options,
            size: size,
            placeholder: placeholder,
            isInvalid: isInvalid,
            maxListHeight: maxListHeight,
            label: label,
            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
            focus: focus,
            onCommit: onCommit,
            onQueryChange: onQueryChange,
            isLoading: isLoading,
            row: row,
            empty: { _ in Text(emptyLabel) }
        )
    }
}

extension PVComboBox where Row == PVComboBoxPlainRow, Empty == Text {
    /// The generic row (label plus optional muted subtext) and a plain-text
    /// empty line.
    init(
        selection: Binding<String>,
        options: [PVComboBoxOption],
        size: PVControlSize = .md,
        placeholder: (any PVCopy)? = nil,
        emptyLabel: LocalizedStringResource,
        isInvalid: Bool = false,
        maxListHeight: CGFloat = 288,
        label: any PVCopy,
        accessibilityIdentifierPrefix: String? = nil,
        focus: PVFieldFocus? = nil,
        onCommit: ((String, PVComboCommitVia) -> Bool)? = nil
    ) {
        self.init(
            selection: selection,
            options: options,
            size: size,
            placeholder: placeholder,
            emptyLabel: emptyLabel,
            isInvalid: isInvalid,
            maxListHeight: maxListHeight,
            label: label,
            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
            focus: focus,
            onCommit: onCommit
        ) { option, query in
            PVComboBoxPlainRow(option: option, query: query)
        }
    }
}

private struct PVComboBoxPreview: View {
    @State private var selection = ""
    @State private var remoteSelection = ""

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space7) {
            PVComboBox(
                selection: $selection,
                options: [
                    PVComboBoxOption(value: "f1", label: "Author", subtext: "author"),
                    PVComboBoxOption(value: "f2", label: "Publication date", subtext: "publication-date"),
                    PVComboBoxOption(value: "f3", label: "Publisher", subtext: "publisher"),
                    PVComboBoxOption(value: "f4", label: "Repository", subtext: "repository"),
                ],
                placeholder: L10n.SourceTypes.assignPlaceholder,
                emptyLabel: L10n.SourceTypes.assignNoMatch,
                label: L10n.SourceTypes.level(.source).pickerLabel
            )
            // Remote results mid-search: the list shows the searching line.
            PVComboBox(
                selection: $remoteSelection,
                options: [],
                placeholder: L10n.SourceTypes.assignPlaceholder,
                emptyLabel: L10n.SourceTypes.assignNoMatch,
                label: L10n.SourceTypes.level(.source).pickerLabel,
                onQueryChange: { _ in },
                isLoading: true
            ) { option, query in
                PVComboBoxPlainRow(option: option, query: query)
            }
            Text(verbatim: selection.isEmpty ? "nothing chosen" : selection)
                .font(PVFont.mono(size: PVTypeScale.micro))
                .foregroundStyle(PVColor.textMuted)
            Spacer()
        }
        .padding(PVSpacing.space9)
        .frame(width: 380, height: 420)
        .background(PVColor.surfaceCard)
    }
}

#Preview {
    PVComboBoxPreview()
}
