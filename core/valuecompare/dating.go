package valuecompare

import "github.com/mendahu/provenencia/core/datevalue"

// The one dating: when an event, or any period, was under way, read from its
// recorded date, start, end and as-of samples. Pure; the caller places it
// (sort key, Timeline span) and formats it.

// DatingKind says what a Dating is.
type DatingKind int

const (
	// DatingNone: nothing dates it.
	DatingNone DatingKind = iota
	// DatingOccurrence: one recorded date; Low is it.
	DatingOccurrence
	// DatingSpan: a start, an end, or both, as recorded.
	DatingSpan
	// DatingAsOf: at least one side is an as-of sample.
	DatingAsOf
)

// Dating is a period known from what was recorded. High is nil when the
// dating is one date (an occurrence, an as-of with one date, a start alone,
// or an end alone where Low is nil). OpenLow and OpenHigh say the period
// continues before Low or after High beyond what is known.
type Dating struct {
	Kind              DatingKind
	Low, High         *datevalue.Value
	OpenLow, OpenHigh bool
}

// datingSample is one placed as-of: its date, sort key, and the earliest and
// latest closed ends the dating reads it by.
type datingSample struct {
	date     datevalue.Value
	key      DateKey
	lo, hi   DateEnd // earliest closed end, latest closed end
	original int
}

// DatingOf is the dating of a period. A date wins outright. Otherwise a
// start, an end and the as-of samples that can be placed are read together:
// the low side is the earlier of a placed start and the sample that ends
// first, the high side the later of a placed end and the sample that starts
// last (ties go to the start and the end). A side no recorded start or end
// closes is open. Picks depend on the dates, never on the order of samples.
func DatingOf(date, start, end *datevalue.Value, samples []datevalue.Value) Dating {
	if date != nil {
		return Dating{Kind: DatingOccurrence, Low: date}
	}
	placed := placeSamples(samples)
	if len(placed) == 0 {
		if start == nil && end == nil {
			return Dating{}
		}
		return Dating{Kind: DatingSpan, Low: start, High: end, OpenLow: start == nil, OpenHigh: end == nil}
	}
	lowPick, highPick := pickSamples(placed)
	low, high := &placed[lowPick].date, &placed[highPick].date
	lowKey, highKey := placed[lowPick].key, placed[highPick].key
	d := Dating{Kind: DatingAsOf, OpenLow: true, OpenHigh: true}
	startKey, startOK := placedKey(start)
	if startOK && startKey.Compare(lowKey) <= 0 {
		low, d.OpenLow = start, false
		lowPick = -1
	}
	endKey, endOK := placedKey(end)
	if endOK && endKey.Compare(highKey) >= 0 {
		high, d.OpenHigh = end, false
		highPick = -1
	}
	d.Low = low
	if lowPick >= 0 && lowPick == highPick {
		return d
	}
	d.High = high
	if !d.OpenLow && !d.OpenHigh {
		d.Kind = DatingSpan
	}
	return d
}

func placedKey(d *datevalue.Value) (DateKey, bool) {
	if d == nil {
		return DateKey{}, false
	}
	key, _, _, ok := DateKeyOf(*d)
	return key, ok
}

// placeSamples keeps the samples DateKeyOf accepts, each read once.
func placeSamples(samples []datevalue.Value) []datingSample {
	var out []datingSample
	for i, s := range samples {
		key, first, last, ok := DateKeyOf(s)
		if !ok {
			continue
		}
		lo, hi := first, last
		if lo.Open {
			lo = last
		}
		if hi.Open {
			hi = first
		}
		out = append(out, datingSample{date: s, key: key, lo: lo, hi: hi, original: i})
	}
	return out
}

// pickSamples is the index of the sample that ends first (its earliest closed
// end finishes soonest) and the one that starts last (its latest closed end
// starts latest). A tie on the picked end goes to the other end of the same
// sample, then to the lower index.
func pickSamples(placed []datingSample) (low, high int) {
	his := make([]DateEnd, len(placed)) // each sample's latest closed end
	los := make([]DateEnd, len(placed)) // each sample's earliest closed end
	for i, s := range placed {
		his[i], los[i] = s.hi, s.lo
	}
	low, high = SampleExtremes(his, los)
	for i, s := range placed {
		if s.lo.Hi == placed[low].lo.Hi && s.lo.Lo < placed[low].lo.Lo {
			low = i
		}
		if s.hi.Lo == placed[high].hi.Lo && s.hi.Hi > placed[high].hi.Hi {
			high = i
		}
	}
	return low, high
}
