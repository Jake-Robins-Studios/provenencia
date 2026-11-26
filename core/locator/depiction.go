package locator

import (
	"math"
	"strings"
)

// ValidateDepictionRegion checks the region locator of a depiction value
// against the locator of the Citation that holds it.
//
// Both documents must parse (Validate without its retired-key and file-page
// checks). The region has exactly one region selector, at most one page
// selector, an optional leading artifact selector, and no other selector. The
// region's page selector names a file page. The Citation locator has at most
// one page selector; one with no file page is no page. The file pages must
// agree: both absent, or both present with the same artifact_page. The region
// need not lie inside a region of the Citation's own locator.
func ValidateDepictionRegion(regionJSON, citationLocatorJSON string) error {
	regionPages, err := regionDocPages(regionJSON)
	if err != nil {
		return err
	}
	citation, err := parse(citationLocatorJSON)
	if err != nil {
		return err
	}
	page := citationPage(citation)
	hasPage := page > 0
	if hasPage != (len(regionPages) == 1) {
		return ErrInvalid
	}
	if hasPage && regionPages[0] != page {
		return ErrInvalid
	}
	return nil
}

// ArtifactPage returns the file page of a Citation locator's page selector. It
// returns 0 when the document is empty, invalid, longer than MaxDocumentBytes,
// has no page selector, or the selector holds no file page.
func ArtifactPage(locatorJSON string) int {
	doc, err := parse(locatorJSON)
	if err != nil {
		return 0
	}
	return citationPage(doc)
}

// citationPage reads the file page of a validated document's page selector,
// which it has at most one of. It is 0 for no selector, a selector with no file
// page, or a page above math.MaxInt32, so no caller narrows it.
func citationPage(doc document) int {
	sel, ok := pageSelector(doc)
	if !ok {
		return 0
	}
	page, ok := sel.filePage()
	if !ok || page > math.MaxInt32 {
		return 0
	}
	return page
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
			page, ok := sel.filePage()
			if !ok {
				return nil, ErrInvalid
			}
			pages = append(pages, page)
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
