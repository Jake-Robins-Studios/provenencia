package subjectcompare

import (
	"slices"

	"github.com/mendahu/provenencia/core/propertycompare"
	"github.com/mendahu/provenencia/core/propertymeta"
	"github.com/mendahu/provenencia/core/valuecompare"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// Side is the values Compare reads for key on one Subject: key's own, its
// pooled properties' (terms mapped into key's vocabulary by the
// pool's Terms), or, when key has a period and no positive value, the
// period built from its start and end. It copies.
func Side(kind vocabkey.SubjectType, key vocabkey.PropertyKey, values Values, rules Rules) []propertycompare.Value {
	out := slices.Clone(values[key])
	pool := rules.Pools[kind][key]
	for _, with := range pool.With {
		terms, mapped := pool.Terms[with]
		for _, v := range values[with] {
			if mapped && v.Term != "" {
				t, ok := terms[v.Term]
				if !ok {
					continue
				}
				v.Term = t
			}
			out = append(out, v)
		}
	}
	if p, ok := rules.Period(kind, key); ok && !slices.ContainsFunc(out, propertycompare.Value.Positive) {
		if v, _, ok := period(values[p.Start], values[p.End]); ok {
			out = append(out, v)
		}
	}
	return out
}

// CountSamples is how many positive values v records for p's samples property,
// counted without copying any. Zero when p names none.
func CountSamples(v Values, p Period) int {
	if p.Samples == "" {
		return 0
	}
	n := 0
	for _, s := range v[p.Samples] {
		if s.Positive() {
			n++
		}
	}
	return n
}

// PeriodSamples is the positive values v records for p's samples property,
// nil when p names none or v records more than p.MaxSamples: the count comes
// first, so a crafted side is never copied. It is the one reading of a side's
// samples and the one place the cap holds, for compare, the shortlist and the
// lifespan.
func PeriodSamples(v Values, p Period) []propertycompare.Value {
	if n := CountSamples(v, p); n == 0 || n > p.MaxSamples {
		return nil
	}
	var out []propertycompare.Value
	for _, s := range v[p.Samples] {
		if s.Positive() {
			out = append(out, s)
		}
	}
	return out
}

// samplesAgainst compares the extreme samples of mine, the ones that end first
// and start last, with the period other records for key. It reads nothing
// unless other has no positive value for key and its start and end build a
// period; mine's own value for key does not stop it. The samples are read with
// AboutEnds as the comparer reads a date and picked in one pass by
// valuecompare.SampleExtremes, whose tie on the extreme end is the
// lowest typed Same key (propertycompare.KeyCompare), so the picks never depend on input order (the event
// dating's pick, valuecompare.DatingOf, breaks it on the dates instead, as it
// shows them). Each pick is
// compared with the period by propertycompare.Compare under meta, the lead's,
// with the period on its own side (swapped puts it on side A). A period with
// an open end bounds but does not agree: an agree or partial against it is
// unknown, its cause unchanged. Match strength therefore reads from the two
// extreme samples only. A side with more than the period's MaxSamples samples has none (PeriodSamples).
func samplesAgainst(kind vocabkey.SubjectType, key vocabkey.PropertyKey, mine, other Values, rules Rules, swapped bool, meta propertymeta.Meta, value valuecompare.Rules) []propertycompare.Result {
	p, ok := rules.Period(kind, key)
	if !ok || slices.ContainsFunc(other[key], propertycompare.Value.Positive) {
		return nil
	}
	standIn, open, ok := period(other[p.Start], other[p.End])
	if !ok {
		return nil
	}
	samples := PeriodSamples(mine, p)
	if len(samples) == 0 {
		return nil
	}

	var reads []propertycompare.Value
	var firsts, lasts []valuecompare.DateEnd
	for _, v := range samples {
		if v.Date == nil {
			continue
		}
		first, last, ok := valuecompare.AboutEnds(*v.Date, value.Dates.AboutUnits)
		if !ok {
			continue
		}
		reads = append(reads, propertycompare.Typed(v, meta))
		firsts, lasts = append(firsts, first), append(lasts, last)
	}
	byKey := func(i, j int) int { return propertycompare.KeyCompare(reads[i], reads[j], value) }
	endsFirst, startsLast := valuecompare.SampleExtremes(firsts, lasts, byKey, func(i, j, _ int) int { return byKey(i, j) })
	picks := []int{endsFirst}
	if startsLast != endsFirst {
		picks = append(picks, startsLast)
	}

	var out []propertycompare.Result
	for _, i := range picks {
		if i < 0 {
			continue
		}
		var res propertycompare.Result
		if swapped {
			res = propertycompare.Compare([]propertycompare.Value{standIn}, []propertycompare.Value{reads[i]}, meta, value)
		} else {
			res = propertycompare.Compare([]propertycompare.Value{reads[i]}, []propertycompare.Value{standIn}, meta, value)
		}
		if open && res.Outcome.Matches() {
			res.Outcome = propertycompare.OutcomeUnknown
		}
		out = append(out, res)
	}
	return out
}

// period is the widest span the positive start and end values record: the
// earliest start and the latest end, each picked by day number, so the order
// of the values never matters. A missing start or end is open. ok is false
// when neither is recorded or the span would end before it begins; open is
// whether the span has an open end.
func period(starts, ends []propertycompare.Value) (propertycompare.Value, bool, bool) {
	var firsts, lasts []valuecompare.DateEnd
	for _, v := range starts {
		if !v.Positive() || v.Date == nil {
			continue
		}
		if e, _, ok := valuecompare.DateEnds(*v.Date); ok {
			firsts = append(firsts, e)
		}
	}
	for _, v := range ends {
		if !v.Positive() || v.Date == nil {
			continue
		}
		if _, e, ok := valuecompare.DateEnds(*v.Date); ok {
			lasts = append(lasts, e)
		}
	}
	first, hasFirst := valuecompare.Earliest(firsts)
	last, hasLast := valuecompare.Latest(lasts)
	if !hasFirst && !hasLast {
		return propertycompare.Value{}, false, false
	}
	if !hasFirst {
		first = valuecompare.DateEnd{Open: true}
	}
	if !hasLast {
		last = valuecompare.DateEnd{Open: true}
	}
	d, ok := valuecompare.EndsDate(first, last)
	if !ok {
		return propertycompare.Value{}, false, false
	}
	return propertycompare.Value{Value: valuecompare.Value{Date: &d}}, first.Open || last.Open, true
}
