package locator

import (
	"math"
	"strings"
)

// ValidateDepictionRegion checks the region locator of a depiction value
// against the locator of the Citation that holds it.
//
// Both documents must pass Validate. The region has exactly one region
// selector, at most one page selector, an optional leading artifact selector,
// and no other selector. The region's page selector names a file page. The
// Citation locator has at most one page selector, which may hold only a
// page_label. The file pages must agree: both absent, or both present with the
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
	page, _, ok := citationPage(citation)
	hasPage := ok && page > 0
	if hasPage != (len(regionPages) == 1) {
		return ErrInvalid
	}
	if hasPage && regionPages[0] != page {
		return ErrInvalid
	}
	return nil
}

// PageRef is the page of a Citation locator's page selector: the page of the
// file, and the page the original prints. The zero value is no page selector.
type PageRef struct {
	// ArtifactPage is the page of the file; 0 when the selector holds only a
	// printed page.
	ArtifactPage int
	// Label is the trimmed page_label.
	Label string
}

// Page returns the page selector of a Citation locator. It returns the zero
// PageRef when the document is empty, invalid, longer than MaxDocumentBytes,
// or has no page selector.
func Page(locatorJSON string) PageRef {
	doc, err := parse(locatorJSON)
	if err != nil {
		return PageRef{}
	}
	page, label, ok := citationPage(doc)
	if !ok {
		return PageRef{}
	}
	return PageRef{ArtifactPage: page, Label: label}
}

// citationPage reads the page selector of a validated document, which has at
// most one; ok is false when it has none. page is 0 for a selector that holds
// only a page_label. A page above math.MaxInt32 is no page, so no caller
// narrows it.
func citationPage(doc document) (page int, label string, ok bool) {
	for _, sel := range doc.Selectors {
		if strings.TrimSpace(sel.Type) != TypePage {
			continue
		}
		ok = true
		if sel.ArtifactPage != nil {
			page = *sel.ArtifactPage
		}
		if sel.PageLabel != nil {
			label = strings.TrimSpace(*sel.PageLabel)
		}
	}
	if page > math.MaxInt32 {
		return 0, "", false
	}
	return page, label, ok
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
