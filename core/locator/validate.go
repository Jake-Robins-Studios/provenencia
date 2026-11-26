// Package locator validates Citation locator_json documents.
//
// Version 1 locators are an ordered selector chain. Known types validated in
// Spike 7: artifact, page, region, text_quote. Unknown selector types are preserved
// losslessly (Validate does not fail solely for an unrecognized type).
//
// A page selector holds artifact_page, the page of the file, and nothing else:
// the page the original prints is the Citation's Page metadata value. Reads
// ignore the page_label, page_unknown and page_supplied keys S15-59 retired,
// and Validate refuses them. A document has at most one page selector.
package locator

import (
	"encoding/json"
	"math"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
)

var ErrInvalid = apperr.New(apperr.CodeLocatorInvalid, apperr.KindUser)

const (
	TypeArtifact  = "artifact"
	TypePage      = "page"
	TypeRegion    = "region"
	TypeTextQuote = "text_quote"
)

const (
	// MaxRegionPoints is the most region points one locator document holds,
	// counted per document across all its region selectors. The crossing test
	// grows with the square of the point count, and a stored document is checked
	// on every read, so the cap keeps one check near 0.3 ms.
	MaxRegionPoints = 256
	// MaxDocumentBytes is the longest locator document, after trimming, that
	// decode will unmarshal.
	MaxDocumentBytes = 65536
)

type document struct {
	Version   int           `json:"version"`
	Selectors []selectorRaw `json:"selectors"`
}

type selectorRaw struct {
	Type string `json:"type"`
	// page
	ArtifactPage *int `json:"artifact_page"`
	// retired by S15-59: presence only; reads never look at them
	PageLabel    json.RawMessage `json:"page_label"`
	PageUnknown  json.RawMessage `json:"page_unknown"`
	PageSupplied json.RawMessage `json:"page_supplied"`
	// region
	Points []point `json:"points"`
	Unit   string  `json:"unit"`
	// text_quote
	Exact  string `json:"exact"`
	Prefix string `json:"prefix"`
	Suffix string `json:"suffix"`
}

type point struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

// Validate is the write check: it checks locator JSON against version-1
// invariants for known selector types, and refuses a page selector with no
// file page or with a key S15-59 retired. Reads go through parse, which
// ignores those keys.
func Validate(locatorJSON string) error {
	doc, err := parse(locatorJSON)
	if err != nil {
		return err
	}
	if sel, ok := pageSelector(doc); ok {
		if _, ok := sel.filePage(); !ok || sel.PageLabel != nil || sel.PageUnknown != nil || sel.PageSupplied != nil {
			return ErrInvalid
		}
	}
	return nil
}

// filePage returns the selector's artifact_page and whether it holds one.
func (sel selectorRaw) filePage() (int, bool) {
	if sel.ArtifactPage == nil {
		return 0, false
	}
	return *sel.ArtifactPage, true
}

// pageSelector returns the page selector of a parsed document, which has at
// most one.
func pageSelector(doc document) (selectorRaw, bool) {
	for _, sel := range doc.Selectors {
		if strings.TrimSpace(sel.Type) == TypePage {
			return sel, true
		}
	}
	return selectorRaw{}, false
}

// parse decodes locator JSON and validates every selector.
func parse(locatorJSON string) (document, error) {
	doc, err := decode(locatorJSON)
	if err != nil {
		return document{}, err
	}
	if err := validateDoc(doc); err != nil {
		return document{}, err
	}
	return doc, nil
}

// decode parses locator JSON and checks the document envelope: non-empty,
// valid JSON, version 1, at least one selector.
func decode(locatorJSON string) (document, error) {
	locatorJSON = strings.TrimSpace(locatorJSON)
	if locatorJSON == "" {
		return document{}, ErrInvalid
	}
	if len(locatorJSON) > MaxDocumentBytes {
		return document{}, ErrInvalid
	}
	var doc document
	if err := json.Unmarshal([]byte(locatorJSON), &doc); err != nil {
		return document{}, ErrInvalid
	}
	if doc.Version != 1 || len(doc.Selectors) == 0 {
		return document{}, ErrInvalid
	}
	return doc, nil
}

// validateDoc checks each selector of a decoded document.
func validateDoc(doc document) error {
	regionPoints := 0
	for _, sel := range doc.Selectors {
		if strings.TrimSpace(sel.Type) == TypeRegion {
			regionPoints += len(sel.Points)
		}
	}
	if regionPoints > MaxRegionPoints {
		return ErrInvalid
	}
	pageSelectors := 0
	for i, sel := range doc.Selectors {
		switch strings.TrimSpace(sel.Type) {
		case TypeArtifact:
			if i != 0 {
				return ErrInvalid
			}
		case TypePage:
			pageSelectors++
			if pageSelectors > 1 {
				return ErrInvalid
			}
			if err := validatePage(sel); err != nil {
				return err
			}
		case TypeRegion:
			if err := validateRegion(sel); err != nil {
				return err
			}
		case TypeTextQuote:
			if err := validateTextQuote(sel); err != nil {
				return err
			}
		default:
			// Unknown types preserved; no further validation.
		}
	}
	return nil
}

// validatePage accepts a page selector with no file page, which reads as no
// page, and a file page of 1 or more. Validate refuses the selector with no
// file page on write.
func validatePage(sel selectorRaw) error {
	if page, ok := sel.filePage(); ok && page < 1 {
		return ErrInvalid
	}
	return nil
}

func validateTextQuote(sel selectorRaw) error {
	if strings.TrimSpace(sel.Exact) == "" {
		return ErrInvalid
	}
	return nil
}

func validateRegion(sel selectorRaw) error {
	if strings.TrimSpace(sel.Unit) != "normalized" {
		return ErrInvalid
	}
	pts := sel.Points
	if len(pts) < 3 {
		return ErrInvalid
	}
	// First point must not be repeated at the end.
	first, last := pts[0], pts[len(pts)-1]
	if nearlyEqual(first.X, last.X) && nearlyEqual(first.Y, last.Y) {
		return ErrInvalid
	}
	for _, p := range pts {
		if p.X < 0 || p.X > 1 || p.Y < 0 || p.Y > 1 {
			return ErrInvalid
		}
	}
	if polygonArea(pts) < 1e-12 {
		return ErrInvalid
	}
	if selfIntersects(pts) {
		return ErrInvalid
	}
	return nil
}

func nearlyEqual(a, b float64) bool {
	return math.Abs(a-b) < 1e-12
}

func polygonArea(pts []point) float64 {
	n := len(pts)
	var sum float64
	for i := 0; i < n; i++ {
		j := (i + 1) % n
		sum += pts[i].X*pts[j].Y - pts[j].X*pts[i].Y
	}
	return math.Abs(sum) / 2
}

// selfIntersects reports whether any non-adjacent edges of the closed polygon intersect.
func selfIntersects(pts []point) bool {
	n := len(pts)
	for i := 0; i < n; i++ {
		a1, a2 := pts[i], pts[(i+1)%n]
		for j := i + 1; j < n; j++ {
			// Skip adjacent edges and the closing edge pair that shares a vertex.
			if j == i || (j+1)%n == i || (i+1)%n == j {
				continue
			}
			b1, b2 := pts[j], pts[(j+1)%n]
			if segmentsIntersect(a1, a2, b1, b2) {
				return true
			}
		}
	}
	return false
}

func segmentsIntersect(a1, a2, b1, b2 point) bool {
	d1 := cross(a2.X-a1.X, a2.Y-a1.Y, b1.X-a1.X, b1.Y-a1.Y)
	d2 := cross(a2.X-a1.X, a2.Y-a1.Y, b2.X-a1.X, b2.Y-a1.Y)
	d3 := cross(b2.X-b1.X, b2.Y-b1.Y, a1.X-b1.X, a1.Y-b1.Y)
	d4 := cross(b2.X-b1.X, b2.Y-b1.Y, a2.X-b1.X, a2.Y-b1.Y)
	if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
		((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
		return true
	}
	return false
}

func cross(ax, ay, bx, by float64) float64 {
	return ax*by - ay*bx
}
