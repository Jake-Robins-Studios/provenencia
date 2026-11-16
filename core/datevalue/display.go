package datevalue

import (
	"fmt"
	"strings"
)

// displayStyle is how formatSide and applyQualifier write a date: the compact
// ISO-like digits of list rows, or one of the citation styles.
type displayStyle int

const (
	styleCompact displayStyle = iota
	styleCitationLong
	styleCitationShort
	styleCitationYear
)

// CitationStyle is how CitationDisplay writes a date.
type CitationStyle int

const (
	// CitationLong spells the month out: "3 March 1830".
	CitationLong CitationStyle = iota
	// CitationShort abbreviates it, as a short note does: "3 Mar. 1830".
	CitationShort
	// CitationYear writes the year alone: "1830".
	CitationYear
)

func (s CitationStyle) display() displayStyle {
	switch s {
	case CitationShort:
		return styleCitationShort
	case CitationYear:
		return styleCitationYear
	default:
		return styleCitationLong
	}
}

var monthsLong = [...]string{"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
var monthsShort = [...]string{"Jan.", "Feb.", "Mar.", "Apr.", "May", "June", "July", "Aug.", "Sept.", "Oct.", "Nov.", "Dec."}

// qualifierWords holds the word before a qualified date, per style, with its
// trailing space.
var qualifierWords = [...]struct{ abt, bef, aft string }{
	styleCompact:       {"About ", "Before ", "After "},
	styleCitationLong:  {"ca. ", "bef. ", "aft. "},
	styleCitationShort: {"ca. ", "bef. ", "aft. "},
	styleCitationYear:  {"ca. ", "bef. ", "aft. "},
}

// CompactDisplay returns a portable, locale-independent summary for list/card
// rows when the client has not yet formatted with a locale calendar.
// Prefer client-side locale formatting (e.g. macOS DateValueDisplay) when the
// full Value is available on the wire.
func CompactDisplay(v Value) string {
	phrase := strings.TrimSpace(v.Phrase)
	switch strings.TrimSpace(v.Kind) {
	case KindPoint:
		point := formatSide(v.startSide(), styleCompact)
		if point == "" {
			return phrase
		}
		qualified := applyQualifier(v.Qualifier, point, styleCompact)
		return appendPhrase(phrase, qualified)
	case KindRange:
		start := formatSide(v.startSide(), styleCompact)
		end := formatSide(v.endSide(), styleCompact)
		if start == "" || end == "" {
			return phrase
		}
		between := fmt.Sprintf("Between %s and %s", start, end)
		return appendPhrase(phrase, between)
	default:
		return phrase
	}
}

// CitationDisplay writes v in citation terms: day-month-year with the month
// spelled out (or abbreviated, or the year alone, per s), "ca." "bef." "aft."
// for a qualifier, and an en dash between the ends of a range. The calendar and
// the clock are ignored. A date with nothing to print is its trimmed phrase.
// The words are English citation text, not localized.
func CitationDisplay(v Value, s CitationStyle) string {
	st := s.display()
	phrase := strings.TrimSpace(v.Phrase)
	switch strings.TrimSpace(v.Kind) {
	case KindPoint:
		point := formatSide(v.startSide(), st)
		if point == "" {
			return phrase
		}
		return applyQualifier(v.Qualifier, point, st)
	case KindRange:
		start := formatSide(v.startSide(), st)
		end := formatSide(v.endSide(), st)
		if start == "" || end == "" {
			return phrase
		}
		if start == end {
			return start
		}
		return start + "–" + end
	default:
		return phrase
	}
}

func appendPhrase(phrase, structured string) string {
	if phrase == "" {
		return structured
	}
	if structured == "" {
		return phrase
	}
	return structured + " · " + phrase
}

func applyQualifier(qual, point string, st displayStyle) string {
	words := qualifierWords[st]
	switch strings.TrimSpace(qual) {
	case QualifierABT:
		return words.abt + point
	case QualifierBEF:
		return words.bef + point
	case QualifierAFT:
		return words.aft + point
	default:
		return point
	}
}

// formatSide writes one end of a date. One switch decides which parts print;
// the style decides only how a day without a month is written, whether the
// clock prints, and the words.
func formatSide(s side, st displayStyle) string {
	if st != styleCompact {
		return citationSide(s, st)
	}
	year, month, day := s.year, s.month, s.day
	var date string
	switch {
	case year != nil && month != nil && day != nil:
		date = fmt.Sprintf("%d-%02d-%02d", *year, *month, *day)
	case year != nil && month != nil:
		date = fmt.Sprintf("%d-%02d", *year, *month)
	case year != nil && day != nil:
		date = fmt.Sprintf("%d--%02d", *year, *day)
	case year != nil:
		date = fmt.Sprintf("%d", *year)
	case month != nil && day != nil:
		date = fmt.Sprintf("--%02d-%02d", *month, *day)
	case month != nil:
		date = fmt.Sprintf("--%02d", *month)
	case day != nil:
		date = fmt.Sprintf("---%02d", *day)
	}

	hour, minute, second := s.hour, s.minute, s.second
	var clock string
	switch {
	case hour != nil && minute != nil && second != nil:
		clock = fmt.Sprintf("%02d:%02d:%02d", *hour, *minute, *second)
	case hour != nil && minute != nil:
		clock = fmt.Sprintf("%02d:%02d", *hour, *minute)
	case hour != nil && second != nil:
		clock = fmt.Sprintf("%02d::%02d", *hour, *second)
	case hour != nil:
		clock = fmt.Sprintf("%02d", *hour)
	case minute != nil && second != nil:
		clock = fmt.Sprintf(":%02d:%02d", *minute, *second)
	case minute != nil:
		clock = fmt.Sprintf(":%02d", *minute)
	case second != nil:
		clock = fmt.Sprintf("::%02d", *second)
	}

	switch {
	case date != "" && clock != "":
		return date + " " + clock
	case date != "":
		return date
	default:
		return clock
	}
}

// citationSide is formatSide's citation case: the clock is dropped, and so is a
// day without a month; the year style keeps the year alone.
func citationSide(s side, st displayStyle) string {
	var parts []string
	if st != styleCitationYear {
		if s.month != nil && *s.month >= 1 && *s.month <= len(monthsLong) {
			if s.day != nil {
				parts = append(parts, fmt.Sprintf("%d", *s.day))
			}
			names := monthsLong
			if st == styleCitationShort {
				names = monthsShort
			}
			parts = append(parts, names[*s.month-1])
		}
	}
	if s.year != nil {
		parts = append(parts, fmt.Sprintf("%d", *s.year))
	}
	return strings.Join(parts, " ")
}
