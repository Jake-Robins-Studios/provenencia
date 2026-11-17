// Package shortlist is layer 6's first step: the keys a Subject is looked up by
// and the index that maps them to handles. Layer 1 makes every key and layer 3
// picks the values, so shortlisting reads a Subject as comparison does. It is
// pure.
package shortlist

import (
	"slices"
	"sort"
	"strconv"

	"github.com/mendahu/provenencia/core/propertycompare"
	"github.com/mendahu/provenencia/core/subjectcompare"
	"github.com/mendahu/provenencia/core/valuecompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// Rules say which leads key a Subject of each kind.
type Rules struct {
	// Words are the leads whose word keys key a Subject of the kind.
	Words map[vocabkey.SubjectType][]vocabkey.PropertyKey
	// Dated are the kinds keyed by a type term with the year buckets of a date.
	Dated map[vocabkey.SubjectType]Dated
	// YearBucket is the years per bucket.
	YearBucket int
	// MaxBuckets is the most buckets a date may key; a wider reach keys as an
	// open one, so a hostile range cannot make a million keys.
	MaxBuckets int
}

// Dated is a kind keyed by a type term and the year buckets of a date.
type Dated struct {
	// Type is the term lead keyed with each bucket.
	Type vocabkey.PropertyKey
	// Date is the date lead whose reach is bucketed; its period comes from the
	// subject section.
	Date vocabkey.PropertyKey
}

const (
	anyType    = "*" // an untyped probe meets every type
	noType     = ""  // an untyped event, met by every typed probe
	datePrefix = "t:"
)

// positive is the positive values Compare reads for lead, typed as the
// property.
func positive(kind vocabkey.SubjectType, lead vocabkey.PropertyKey, v subjectcompare.Values, metas subjectcompare.Metas, subject subjectcompare.Rules) []propertycompare.Value {
	var out []propertycompare.Value
	for _, x := range subjectcompare.Side(kind, lead, v, subject) {
		if x.Positive() {
			out = append(out, propertycompare.Typed(x, metas[lead]))
		}
	}
	return out
}

// Keys are the keys a Subject of kind is filed under (index) and looked up by
// (lookup). Two Subjects that can reach the weak band share an index key and a
// lookup key. Both lists are sorted, with no duplicates.
//
// Word leads file every index word key of every positive value and look up
// every lookup word key (valuecompare.WordKeys). A dated kind keys its type
// tokens with the year buckets its date can still be Near to (a reach wider
// than MaxBuckets counts as open): a closed reach is filed under each bucket it
// covers and looked up under each, an open one meets every closed one through
// "wide" and "any" keys. An event dated only by as-ofs is filed as one open
// reach but looks up the years its closed samples reach (open when it has
// none, or has more samples than the cap reads). An event with no type is filed under every type, and a
// probe with no type meets every event.
func Keys(kind vocabkey.SubjectType, v subjectcompare.Values, metas subjectcompare.Metas, r Rules, subject subjectcompare.Rules, value valuecompare.Rules) (index, lookup []string) {
	for _, lead := range r.Words[kind] {
		for _, x := range positive(kind, lead, v, metas, subject) {
			ik, lk := valuecompare.WordKeys(x.Value, value)
			for _, k := range ik {
				index = append(index, string(lead)+"|"+k)
			}
			for _, k := range lk {
				lookup = append(lookup, string(lead)+"|"+k)
			}
		}
	}
	if d, ok := r.Dated[kind]; ok && r.YearBucket >= 1 {
		var types []string
		for _, t := range positive(kind, d.Type, v, metas, subject) {
			if k, ok := valuecompare.Key(t.Value, valuecompare.Equivalent, value); ok {
				types = append(types, k)
			}
		}
		slices.Sort(types)
		types = slices.Compact(types)
		indexTypes := append(slices.Clone(types), anyType)
		lookupTypes := append(slices.Clone(types), noType)
		if len(types) == 0 {
			indexTypes = []string{noType, anyType}
			lookupTypes = []string{anyType}
		}
		// A reach is what an event's date can still be Near to: lo to hi, open
		// when it has no bound. It is filed (index) and looked up (lookup) on its
		// own, because an as-of-only event is filed as open but looks up by its
		// samples' years.
		type reach struct {
			lo, hi                int
			indexOpen, lookupOpen bool
		}
		var reaches []reach
		dates := positive(kind, d.Date, v, metas, subject)
		for _, date := range dates {
			if lo, hi, open, ok := valuecompare.YearReach(date.Value, value); ok {
				reaches = append(reaches, reach{lo, hi, open, open})
			}
		}
		// An event with only as-ofs began and ended at unknown days. It is filed
		// as one open reach, which a dated event looks up and meets. Its own
		// lookup is the years its samples reach, so it stops meeting every event
		// of its type; with no closed reach, or too many buckets, or more samples
		// than the cap reads, it looks up open as before.
		if period, _ := subject.Period(kind, d.Date); len(dates) == 0 && subjectcompare.CountSamples(v, period) > 0 {
			rc := reach{indexOpen: true, lookupOpen: true}
			found := false
			for _, sample := range subjectcompare.PeriodSamples(v, period) {
				if lo, hi, open, ok := valuecompare.YearReach(sample.Value, value); ok && !open {
					if !found || lo < rc.lo {
						rc.lo = lo
					}
					if !found || hi > rc.hi {
						rc.hi = hi
					}
					found = true
				}
			}
			rc.lookupOpen = !found
			reaches = append(reaches, rc)
		}
		for _, rc := range reaches {
			lo, hi := rc.lo, rc.hi
			tooWide := !rc.lookupOpen && floorDiv(hi, r.YearBucket)-floorDiv(lo, r.YearBucket)+1 > r.MaxBuckets
			indexOpen, lookupOpen := rc.indexOpen, rc.lookupOpen || tooWide
			if !rc.indexOpen && tooWide {
				indexOpen = true
			}
			for _, k := range indexTypes {
				base := datePrefix + k + "|"
				if indexOpen {
					index = append(index, base+"wide", base+"any")
					continue
				}
				index = append(index, base+"any")
				index = appendBuckets(index, base, lo, hi, r.YearBucket)
			}
			for _, k := range lookupTypes {
				base := datePrefix + k + "|"
				if lookupOpen {
					lookup = append(lookup, base+"any")
					continue
				}
				lookup = append(lookup, base+"wide")
				lookup = appendBuckets(lookup, base, lo, hi, r.YearBucket)
			}
		}
	}
	return sortedUnique(index), sortedUnique(lookup)
}

// appendBuckets adds base and each bucket from lo to hi.
func appendBuckets(keys []string, base string, lo, hi, width int) []string {
	for b := floorDiv(lo, width); b <= floorDiv(hi, width); b++ {
		keys = append(keys, base+strconv.Itoa(b))
	}
	return keys
}

func sortedUnique(keys []string) []string {
	sort.Strings(keys)
	return slices.Compact(keys)
}

// floorDiv rounds y / w toward minus infinity.
func floorDiv(y, w int) int {
	q := y / w
	if y%w != 0 && y < 0 {
		q--
	}
	return q
}
