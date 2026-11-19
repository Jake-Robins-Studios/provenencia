package locator

import (
	"math"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
)

// ValidateDepictionRegion checks the region locator of a depiction value
// against the locator of the Citation that holds it.
//
// Both documents must parse (Validate without its page mark check). The region has exactly one region
// selector, at most one page selector, an optional leading artifact selector,
// and no other selector. The region's page selector names a file page. The
// Citation locator has at most one page selector, which may hold no file page
// (only a page_label, or page_unknown). The file pages must agree: both absent, or both present with the
// same artifact_page (page_label is not compared). The region need not lie
// inside a region of the Citation's own locator.
func ValidateDepictionRegion(regionJSON, citationLocatorJSON string) error {
	regionPages, err := regionDocPages(regionJSON)
	if err != nil {
		return err
	}
	citation, err := parse(citationLocatorJSON)
	if err != nil {
		return err
	}
	ref, ok := citationPage(citation)
	hasPage := ok && ref.ArtifactPage > 0
	if hasPage != (len(regionPages) == 1) {
		return ErrInvalid
	}
	if hasPage && regionPages[0] != ref.ArtifactPage {
		return ErrInvalid
	}
	return nil
}

// PageRef is the page of a Citation locator's page selector: the page of the
// file, and the page the original prints. A selector marked unknown alone gives
// no file page and no label, with Mark.Unknown set; only the zero value means no
// page selector.
type PageRef struct {
	// ArtifactPage is the page of the file; 0 when the selector holds no file
	// page.
	ArtifactPage int
	// Label is the trimmed page_label.
	Label string
	// Mark is the printed page's unknown and supplied facts, settled against
	// Label (valuemark.Settle).
	Mark valuemark.Mark
}

// Page returns the page selector of a Citation locator. It returns the zero
// PageRef when the document is empty, invalid, longer than MaxDocumentBytes,
// or has no page selector.
func Page(locatorJSON string) PageRef {
	doc, err := parse(locatorJSON)
	if err != nil {
		return PageRef{}
	}
	ref, ok := citationPage(doc)
	if !ok {
		return PageRef{}
	}
	return ref
}

// citationPage reads the page selector of a validated document, which has at
// most one; ok is false when it has none. ArtifactPage is 0 for a selector
// that holds no file page. A page above math.MaxInt32 is no page, so no caller
// narrows it. The stored mark is settled against the label, so a pair Validate
// refuses reads as a pair it accepts.
func citationPage(doc document) (PageRef, bool) {
	sel, ok := pageSelector(doc)
	if !ok {
		return PageRef{}, false
	}
	var ref PageRef
	if sel.ArtifactPage != nil {
		ref.ArtifactPage = *sel.ArtifactPage
	}
	if ref.ArtifactPage > math.MaxInt32 {
		return PageRef{}, false
	}
	if sel.PageLabel != nil {
		ref.Label = strings.TrimSpace(*sel.PageLabel)
	}
	mark, hasLabel := sel.pageMark()
	ref.Mark = valuemark.Settle(mark, hasLabel)
	return ref, true
}

// regionDocPages validates a region document and returns the artifact_page of
// its page selector, if any. A page selector must hold a file page: a region
// is drawn on one.
func regionDocPages(regionJSON string) ([]int, error) {
	region, err := parse(regionJSON)
	if err != nil {
		return nil, err
	}
	regions := 0
	var pages []int
	for _, sel := range region.Selectors {
		switch strings.TrimSpace(sel.Type) {
		case TypeArtifact:
		case TypePage:
			if sel.ArtifactPage == nil {
				return nil, ErrInvalid
			}
			pages = append(pages, *sel.ArtifactPage)
		case TypeRegion:
			regions++
		default:
			return nil, ErrInvalid
		}
	}
	if regions != 1 {
		return nil, ErrInvalid
	}
	return pages, nil
}
