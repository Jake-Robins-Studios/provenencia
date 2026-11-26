import Foundation

/// The one fold rule of a folded list: the first `limit` of a list behind a
/// "Show N more" row, then `pageSize` more at a time. A fold that would leave fewer than
/// `minimumHidden` items hidden shows them all. Each content declares its folds once.
struct PagedFold: Hashable {
    /// How many items one "Show more" reveals.
    static let pageSize = 50

    let limit: Int
    let minimumHidden: Int

    /// How many items show after `pages` pages: all of them when the rest would be
    /// fewer than `minimumHidden`.
    func shownCount(count: Int, pages: Int) -> Int {
        let target = limit + max(pages, 0) * Self.pageSize
        return count - target < minimumHidden ? count : target
    }

    /// The first items of `list` at `pages` pages; `hidden` is how many the fold leaves out.
    func shown<T>(_ list: [T], pages: Int) -> (shown: [T], hidden: Int) {
        let count = shownCount(count: list.count, pages: pages)
        return (Array(list.prefix(count)), list.count - count)
    }

    /// How many items the next "Show more" adds: a whole page, or what is left when
    /// folding the rest would hide fewer than `minimumHidden`.
    func nextPageCount(hidden: Int) -> Int {
        hidden - Self.pageSize < minimumHidden ? hidden : Self.pageSize
    }

    /// The first item the next page adds, or nil when the fold hides nothing.
    func firstRevealed<T>(_ list: [T], pages: Int) -> T? {
        let count = shownCount(count: list.count, pages: pages)
        return count < list.count ? list[count] : nil
    }

    /// The fewest pages p >= 0 that show `list[index]` of a list of `count`.
    func pages(toShow index: Int, count: Int) -> Int {
        var pages = 0
        while index >= shownCount(count: count, pages: pages) && shownCount(count: count, pages: pages) < count {
            pages += 1
        }
        return pages
    }
}

/// How many pages of each fold a section has revealed. Reset when the page is another
/// entity. `Hashable` so a derived value can key on it.
struct PagedFoldState<Fold: Hashable>: Hashable {
    private var revealed: [Fold: Int] = [:]

    /// Pages revealed; 0 when never.
    func pages(_ fold: Fold) -> Int { revealed[fold] ?? 0 }

    mutating func revealPage(_ fold: Fold) { revealed[fold, default: 0] += 1 }

    /// Reveals through `pages`, keeping the larger of that and what is revealed.
    mutating func reveal(_ fold: Fold, pages: Int) {
        guard pages > self.pages(fold) else { return }
        revealed[fold] = pages
    }
}
