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
	date   datevalue.Value
	key    DateKey
	lo, hi DateEnd // earliest closed end, latest closed end
}

// DatingOf is the dating of a period. A date wins outright. Otherwise a
// start, an end and the as-of samples that can be placed are read together:
// the low side is the earlier of a placed start and the sample that ends
// first, the high side the later of a placed end and the sample that starts
// last (ties go to the start and the end). A side no recorded start or end
// closes is open. The picks rank samples by their four closed-end bounds
// before their place in the slice (see pickSamples), so only samples equal in
// all four, and on the same side of their day, are told apart by order, and
// then not by anything DateEnds shows.
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
	for _, s := range samples {
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
		out = append(out, datingSample{date: s, key: key, lo: lo, hi: hi})
	}
	return out
}

// pickSamples is the index of the sample that ends first and the one that
// starts last, picked by SampleExtremes over each sample's earliest and latest
// closed ends as DateEnds shows them. Every tie reads the dates before the
// place in the slice, so the picks never depend on order. Ends first: the
// lowest latest bound of its earliest closed end, then that end's lowest
// earliest bound, then the same two of its latest closed end. Starts last: the
// highest earliest bound of its latest closed end, then that end's highest
// latest bound, then the sample that ends first when it is tied on its ranks,
// then the highest two of its earliest closed end. Each ranking ends on the
// sample's side of its day (BEF, plain, AFT), so a BEF and an AFT of one day
// are told apart; only samples equal in all of these fall to the lower index
// (D-3). subjectcompare's samplesAgainst reads the ends as the comparer does
// and breaks its tie on the Same key instead.
func pickSamples(placed []datingSample) (low, high int) {
	his := make([]DateEnd, len(placed))
	los := make([]DateEnd, len(placed))
	for i, s := range placed {
		his[i], los[i] = s.hi, s.lo
	}
	endsTie := func(i, j int) int { return endsCompare(placed[i], placed[j]) }
	startsTie := func(i, j, ender int) int {
		a, b := placed[i], placed[j]
		if d := b.hi.Hi - a.hi.Hi; d != 0 {
			return d
		}
		aEnds, bEnds := endsCompare(a, placed[ender]) == 0, endsCompare(b, placed[ender]) == 0
		if aEnds != bEnds {
			if aEnds {
				return -1
			}
			return 1
		}
		for _, d := range [...]int{b.lo.Hi - a.lo.Hi, b.lo.Lo - a.lo.Lo, b.key.Side - a.key.Side} {
			if d != 0 {
				return d
			}
		}
		return 0
	}
	return SampleExtremes(his, los, endsTie, startsTie)
}

// endsCompare orders a and b by when they end: negative when a ends first.
func endsCompare(a, b datingSample) int {
	for _, d := range [...]int{a.lo.Hi - b.lo.Hi, a.lo.Lo - b.lo.Lo, a.hi.Lo - b.hi.Lo, a.hi.Hi - b.hi.Hi, a.key.Side - b.key.Side} {
		if d != 0 {
			return d
		}
	}
	return 0
}
