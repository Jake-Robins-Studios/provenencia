package subjectcompare_test

import (
	"reflect"
	"testing"

	"github.com/mendahu/provenencia/core/matchregistry"
	"github.com/mendahu/provenencia/core/subjectcompare"
	"github.com/mendahu/provenencia/core/subjectcompare/subjectcomparetest"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// samplesOf is as-ofs at the cap, 1970 to 1969+MaxSamples, in two orders.
func samplesOf(n int) []V {
	out := make([]V, 0, n)
	for i := range n {
		out = append(out, year(1970+i%40))
	}
	return out
}

// TestSamplesAgainstBounded checks a side with as many samples as the cap
// reads as its extremes alone, a side with more is skipped whatever the order,
// and a period the other side's own value replaces is never read.
func TestSamplesAgainstBounded(t *testing.T) {
	rules := matchregistry.Default()
	metas := subjectcomparetest.Metas()
	limit := rules.Subject.Periods[vocabkey.Event][date].MaxSamples
	period := Vals{start: {year(1985)}, end: {year(2000)}}
	against := func(asOfs []V, other Vals) int {
		return len(subjectcompare.SamplesAgainst(vocabkey.Event, date, Vals{asOf: asOfs}, other, rules.Subject, false, metas[date], rules.Value))
	}
	extremes := subjectcompare.SamplesAgainst(vocabkey.Event, date, Vals{asOf: {year(1970), year(2009)}}, period, rules.Subject, false, metas[date], rules.Value)
	atCap := subjectcompare.SamplesAgainst(vocabkey.Event, date, Vals{asOf: samplesOf(limit)}, period, rules.Subject, false, metas[date], rules.Value)
	if len(extremes) != 2 || !reflect.DeepEqual(extremes, atCap) {
		t.Fatalf("at the cap: %+v, want the extremes' %+v", atCap, extremes)
	}
	over := samplesOf(limit + 1)
	for _, order := range [][]V{over, reverse(over)} {
		if n := against(order, period); n != 0 {
			t.Errorf("over the cap read %d results, want none", n)
		}
	}
	if got := subjectcompare.Compare(vocabkey.Event, Vals{asOf: over}, period, metas, rules.Subject, rules.Value); len(got.Properties) == 0 {
		t.Errorf("over the cap: base comparison lost: %+v", got)
	}
}

func reverse(vs []V) []V {
	out := make([]V, len(vs))
	for i, v := range vs {
		out[len(vs)-1-i] = v
	}
	return out
}

// TestSamplesAgainstReadsNothingWhenOtherSpeaks checks a period the other side
// has a value for is decided before the samples are read.
func TestSamplesAgainstReadsNothingWhenOtherSpeaks(t *testing.T) {
	rules := matchregistry.Default()
	meta := subjectcomparetest.Metas()[date]
	mine := Vals{asOf: samplesOf(500)}
	other := Vals{date: {year(1990)}, start: {year(1985)}, end: {year(2000)}}
	allocs := testing.AllocsPerRun(20, func() {
		if got := subjectcompare.SamplesAgainst(vocabkey.Event, date, mine, other, rules.Subject, false, meta, rules.Value); got != nil {
			t.Fatalf("read %+v", got)
		}
	})
	if allocs != 0 {
		t.Errorf("allocated %v times, want 0", allocs)
	}
}
