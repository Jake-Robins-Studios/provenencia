package subjectcompare

import (
	"slices"
	"strings"

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
	if p, ok := rules.Periods[kind][key]; ok && !slices.ContainsFunc(out, propertycompare.Value.Positive) {
		if v, ok := period(values[p.Start], values[p.End]); ok {
			out = append(out, v)
		}
	}
	return out
}

// Samples is the positive values v records for the samples property of key's
// period, nil when key has no period or its period names no samples. It is
// the one reading of a side's samples, for compare and the shortlist.
func Samples(kind vocabkey.SubjectType, key vocabkey.PropertyKey, v Values, rules Rules) []propertycompare.Value {
	p, ok := rules.Periods[kind][key]
	if !ok || p.Samples == "" {
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

// sample is one of a side's samples with its Same key and the ends it is
// compared by.
type sample struct {
	v           propertycompare.Value
	key         string
	hasKey      bool
	first, last valuecompare.DateEnd
}

// samplesAgainst compares the extreme samples of mine, the ones that end first
// and start last, with the period other records for key. It reads nothing
// unless other has no positive value for key and its start and end build a
// period; mine's own value for key does not stop it. The samples are sorted by
// their typed Same key and read with AboutEnds as the comparer reads a date,
// so the picks never depend on input order; each pick is compared with the
// period by propertycompare.Compare under meta, the lead's, with the period on
// its own side (swapped puts it on side A). A period with an open end bounds
// but does not agree: an agree or partial against it is unknown, its cause
// unchanged. Match strength therefore reads from the two extreme samples only.
func samplesAgainst(kind vocabkey.SubjectType, key vocabkey.PropertyKey, mine, other Values, rules Rules, swapped bool, meta propertymeta.Meta, value valuecompare.Rules) []propertycompare.Result {
	p := rules.Periods[kind][key]
	samples := Samples(kind, key, mine, rules)
	if len(samples) == 0 || slices.ContainsFunc(other[key], propertycompare.Value.Positive) {
		return nil
	}
	standIn, ok := period(other[p.Start], other[p.End])
	if !ok {
		return nil
	}
	open := false
	if first, last, ok := valuecompare.DateEnds(*standIn.Date); ok {
		open = first.Open || last.Open
	}

	read := make([]sample, 0, len(samples))
	for _, v := range samples {
		if v.Date == nil {
			continue
		}
		first, last, ok := valuecompare.AboutEnds(*v.Date, value.Dates.AboutUnits)
		if !ok {
			continue
		}
		k, hasKey := valuecompare.Key(propertycompare.Typed(v, meta).Value, valuecompare.Same, value)
		read = append(read, sample{v: v, key: k, hasKey: hasKey, first: first, last: last})
	}
	slices.SortStableFunc(read, func(x, y sample) int {
		switch {
		case x.hasKey != y.hasKey:
			if x.hasKey {
				return -1
			}
			return 1
		default:
			return strings.Compare(x.key, y.key)
		}
	})
	firsts := make([]valuecompare.DateEnd, len(read))
	lasts := make([]valuecompare.DateEnd, len(read))
	for i, s := range read {
		firsts[i], lasts[i] = s.first, s.last
	}
	endsFirst, startsLast := valuecompare.SampleExtremes(firsts, lasts)
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
			res = propertycompare.Compare([]propertycompare.Value{standIn}, []propertycompare.Value{read[i].v}, meta, value)
		} else {
			res = propertycompare.Compare([]propertycompare.Value{read[i].v}, []propertycompare.Value{standIn}, meta, value)
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
// when neither is recorded or the span would end before it begins.
func period(starts, ends []propertycompare.Value) (propertycompare.Value, bool) {
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
		return propertycompare.Value{}, false
	}
	if !hasFirst {
		first = valuecompare.DateEnd{Open: true}
	}
	if !hasLast {
		last = valuecompare.DateEnd{Open: true}
	}
	d, ok := valuecompare.EndsDate(first, last)
	if !ok {
		return propertycompare.Value{}, false
	}
	return propertycompare.Value{Value: valuecompare.Value{Date: &d}}, true
}
