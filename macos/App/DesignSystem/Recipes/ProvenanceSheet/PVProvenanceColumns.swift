import SwiftUI

/// The fixed columns of a provenance record row and table: Read as · Citation ·
/// Outcome · Record. The Citation column takes the rest, so
/// a row placed alone and the rows of a table line up when they share one
/// `PVProvenanceColumns`.
struct PVProvenanceColumns: Equatable {
    /// Draw the Read as cell. Off, the row drops it and the record's one spoken
    /// line moves to the row's leading edge, so the record still reads as one element.
    var showsReadAs = true
    /// At `.wide` Read as and Outcome are wider and the Citation column takes the rest.
    var widthClass: PVWidthClass = .regular

    var readAsWidth: CGFloat { widthClass == .wide ? 160 : 104 }
    var outcomeWidth: CGFloat { widthClass == .wide ? 200 : 128 }
    /// The sheet panel's width around the columns.
    var panelWidth: CGFloat { widthClass == .wide ? 1280 : 880 }

    var spacing: CGFloat { Self.spacing }

    static let spacing: CGFloat = 14
    /// Two nine-character refs in mono at caption size.
    static let recordWidth: CGFloat = 72
    /// The reserved column the Why's rows still draw (`PVProvenanceReservedCell`); the sheet no longer does.
    static let actionWidth: CGFloat = 88
    /// The labelled copy buttons' track's least width beside the citation text (a button
    /// wider than it, or the check glyph, widens the track), and the gap before it. 84 holds "Short" with its icon in Spectral 500 at `.sm` (70.7pt) with room.
    static let copyTrackWidth: CGFloat = 84
    static let copyTrackSpacing: CGFloat = 8
    /// The room the sheet's records table keeps between its Record column and the scroll bar; the headings take the same inset.
    static let scrollBarInset: CGFloat = PVSpacing.space5
}
