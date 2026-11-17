package valuecompare_test

import (
	"testing"

	"github.com/mendahu/provenencia/core/datevalue"
	"github.com/mendahu/provenencia/core/datevalue/datevaluetest"
	"github.com/mendahu/provenencia/core/valuecompare"
)

func TestDatingOfTiedHiTakesLowestLo(t *testing.T) {
	point := datevaluetest.YMD(1990, 0, 0)
	rng := datevaluetest.Between(1985, 0, 0, 1990, 0, 0)
	for _, samples := range [][]datevalue.Value{{*point, *rng}, {*rng, *point}} {
		got := valuecompare.DatingOf(nil, nil, nil, samples)
		if got.Low == nil || got.Low.Kind != datevalue.KindRange {
			t.Errorf("Low = %+v, want the range in either order", got.Low)
		}
	}
}

func TestDatingOf(t *testing.T) {
	ymd := datevaluetest.YMD
	y := func(n int) *datevalue.Value { return ymd(n, 0, 0) }
	same := func(a, b *datevalue.Value) bool {
		if a == nil || b == nil {
			return a == b
		}
		fa, la, _ := valuecompare.DateEnds(*a)
		fb, lb, _ := valuecompare.DateEnds(*b)
		return fa == fb && la == lb && a.Qualifier == b.Qualifier
	}
	vals := func(ds ...*datevalue.Value) []datevalue.Value {
		var out []datevalue.Value
		for _, d := range ds {
			out = append(out, *d)
		}
		return out
	}
	reversed := func(in []datevalue.Value) []datevalue.Value {
		out := make([]datevalue.Value, len(in))
		for i, v := range in {
			out[len(in)-1-i] = v
		}
		return out
	}
	noYear := datevaluetest.Phrase("sometime")
	tooFar := y(10000)

	cases := []struct {
		name              string
		date, start, end  *datevalue.Value
		samples           []datevalue.Value
		kind              valuecompare.DatingKind
		low, high         *datevalue.Value
		openLow, openHigh bool
	}{
		{name: "date", date: ymd(1817, 5, 14), kind: valuecompare.DatingOccurrence, low: ymd(1817, 5, 14)},
		{name: "unplaced date with start", date: noYear, start: y(1860), kind: valuecompare.DatingOccurrence, low: noYear},
		{name: "start and end", start: y(1985), end: y(2015), kind: valuecompare.DatingSpan, low: y(1985), high: y(2015)},
		{name: "start equals end", start: y(1985), end: y(1985), kind: valuecompare.DatingSpan, low: y(1985), high: y(1985)},
		{name: "start only", start: y(1985), kind: valuecompare.DatingSpan, low: y(1985), openHigh: true},
		{name: "end only", end: y(2015), kind: valuecompare.DatingSpan, high: y(2015), openLow: true},
		{name: "nothing", kind: valuecompare.DatingNone},
		{name: "two as-ofs", samples: vals(ymd(1990, 1, 10), ymd(2015, 2, 10)), kind: valuecompare.DatingAsOf,
			low: ymd(1990, 1, 10), high: ymd(2015, 2, 10), openLow: true, openHigh: true},
		{name: "one as-of", samples: vals(ymd(1990, 1, 10)), kind: valuecompare.DatingAsOf,
			low: ymd(1990, 1, 10), openLow: true, openHigh: true},
		{name: "start and as-ofs", start: y(1985), samples: vals(ymd(1990, 1, 10), ymd(2015, 2, 10)),
			kind: valuecompare.DatingAsOf, low: y(1985), high: ymd(2015, 2, 10), openHigh: true},
		{name: "as-of and end", end: y(2015), samples: vals(y(1990)),
			kind: valuecompare.DatingAsOf, low: y(1990), high: y(2015), openLow: true},
		{name: "as-of before start", start: y(1995), samples: vals(y(1990)),
			kind: valuecompare.DatingAsOf, low: y(1990), openLow: true, openHigh: true},
		{name: "as-of after end", end: y(2015), samples: vals(y(2020)),
			kind: valuecompare.DatingAsOf, low: y(2020), openLow: true, openHigh: true},
		{name: "as-of before end-only", end: y(2015), samples: vals(y(1980)),
			kind: valuecompare.DatingAsOf, low: y(1980), high: y(2015), openLow: true},
		{name: "abt and bef", samples: vals(datevaluetest.About(1990, 0, 0), datevaluetest.Before(2015, 0, 0)),
			kind: valuecompare.DatingAsOf, low: datevaluetest.About(1990, 0, 0), high: datevaluetest.Before(2015, 0, 0),
			openLow: true, openHigh: true},
		{name: "range beside point inside", samples: vals(datevaluetest.Between(1985, 0, 0, 1995, 0, 0), y(1990)),
			kind: valuecompare.DatingAsOf, low: datevaluetest.Between(1985, 0, 0, 1995, 0, 0), openLow: true, openHigh: true},
		{name: "as-ofs inside start and end", start: y(1980), end: y(2020), samples: vals(y(1990), y(2015)),
			kind: valuecompare.DatingSpan, low: y(1980), high: y(2020)},
		{name: "unplaceable sample skipped", samples: vals(tooFar, y(1990)),
			kind: valuecompare.DatingAsOf, low: y(1990), openLow: true, openHigh: true},
		{name: "only unplaceable sample", start: y(1985), samples: vals(tooFar),
			kind: valuecompare.DatingSpan, low: y(1985), openHigh: true},
	}
	for _, tc := range cases {
		for _, order := range []string{"as given", "reversed"} {
			t.Run(tc.name+"/"+order, func(t *testing.T) {
				samples := tc.samples
				if order == "reversed" {
					samples = reversed(samples)
				}
				got := valuecompare.DatingOf(tc.date, tc.start, tc.end, samples)
				if got.Kind != tc.kind || got.OpenLow != tc.openLow || got.OpenHigh != tc.openHigh ||
					!same(got.Low, tc.low) || !same(got.High, tc.high) {
					t.Errorf("DatingOf = %+v, want kind %v low %v high %v open %v/%v", got, tc.kind, tc.low, tc.high, tc.openLow, tc.openHigh)
				}
			})
		}
	}
}

func TestDatingOfOrderFreeWhenOnlyOneSideTies(t *testing.T) {
	y := func(n int) datevalue.Value { return *datevaluetest.YMD(n, 0, 0) }
	between := func(a, b int) datevalue.Value { return *datevaluetest.Between(a, 0, 0, b, 0, 0) }
	ends := func(d *datevalue.Value) [2]valuecompare.DateEnd {
		if d == nil {
			return [2]valuecompare.DateEnd{}
		}
		f, l, _ := valuecompare.DateEnds(*d)
		return [2]valuecompare.DateEnd{f, l}
	}
	for _, samples := range [][]datevalue.Value{
		{between(1990, 1991), y(1991)},
		{between(1990, 1995), y(1990)},
	} {
		fwd := valuecompare.DatingOf(nil, nil, nil, samples)
		rev := valuecompare.DatingOf(nil, nil, nil, []datevalue.Value{samples[1], samples[0]})
		if (fwd.High == nil) != (rev.High == nil) || ends(fwd.Low) != ends(rev.Low) || ends(fwd.High) != ends(rev.High) {
			t.Errorf("order changes the dating: %+v vs reversed %+v", fwd, rev)
		}
	}
}
