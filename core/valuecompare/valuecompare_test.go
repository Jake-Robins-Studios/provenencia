package valuecompare_test

import (
	"bytes"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/matchregistry"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
)

func TestCompareUnsupported(t *testing.T) {
	// noComparer are the value types with no comparer: Compare is Unknown.
	// Every real value type has one, so this is a type no catalog has.
	noComparer := map[string]bool{"unregistered": true}
	var want []string
	for _, vt := range propertymeta.ValueTypes() {
		if !noComparer[vt] {
			want = append(want, vt)
		}
	}
	slices.Sort(want)
	if got := valuecompare.ComparerTypes(); !slices.Equal(got, want) {
		t.Errorf("ComparerTypes() = %v, want %v", got, want)
	}
	rules := matchregistry.Default().Value
	for typ := range noComparer {
		v := valuecompare.Value{Type: typ, Text: "x"}
		res, det := valuecompare.Compare(v, v, rules)
		if res.Relation != valuecompare.Unknown || res.Similarity != 0 || det.Cause != valuecompare.CauseUnsupported {
			t.Errorf("%s: %+v %+v", typ, res, det)
		}
		if k, ok := valuecompare.Key(v, valuecompare.Same, rules); ok || k != "" {
			t.Errorf("%s: Key = %q, %v", typ, k, ok)
		}
	}
	mixed := []valuecompare.Value{
		{Type: propertymeta.ValueTypeText, Text: "male"},
		{Type: propertymeta.ValueTypeTerm, Term: "male"},
	}
	res, det := valuecompare.Compare(mixed[0], mixed[1], rules)
	if res.Relation != valuecompare.Unknown || det.Cause != valuecompare.CauseUnsupported {
		t.Errorf("text against term: %+v %+v", res, det)
	}
}

func TestCompareEchoesRefs(t *testing.T) {
	rules := matchregistry.Default().Value
	r1, r2 := []byte("r1"), []byte("r2")
	term := func(key string, ref []byte) valuecompare.Value {
		return valuecompare.Value{Type: propertymeta.ValueTypeTerm, Term: key, Ref: ref}
	}
	for name, pair := range map[string][2]valuecompare.Value{
		"same":      {term("male", r1), term("male", r2)},
		"different": {term("male", r1), term("female", r2)},
		"unknown":   {term("", r1), term("male", r2)},
	} {
		_, det := valuecompare.Compare(pair[0], pair[1], rules)
		if !bytes.Equal(det.RefA, r1) || !bytes.Equal(det.RefB, r2) {
			t.Errorf("%s: refs %q %q", name, det.RefA, det.RefB)
		}
	}
}

func TestStronger(t *testing.T) {
	// Every Relation constant, once: a new constant missing from relationOrder fails here.
	all := []valuecompare.Relation{
		valuecompare.Same, valuecompare.Equivalent, valuecompare.Contains, valuecompare.Overlaps,
		valuecompare.Near, valuecompare.Different, valuecompare.Unknown,
	}
	order := valuecompare.Relations()
	if len(order) != len(all) {
		t.Fatalf("Relations() has %d relations, want %d", len(order), len(all))
	}
	for _, r := range all {
		if !slices.Contains(order, r) {
			t.Errorf("Relations() lacks %s", r)
		}
	}
	for i := 0; i+1 < len(order); i++ {
		x, y := order[i], order[i+1]
		if !valuecompare.Stronger(x, y) {
			t.Errorf("Stronger(%s, %s) = false, want true", x, y)
		}
		if valuecompare.Stronger(y, x) {
			t.Errorf("Stronger(%s, %s) = true, want false", y, x)
		}
	}
	if valuecompare.Stronger(valuecompare.Same, valuecompare.Same) {
		t.Error("Stronger(Same, Same) = true, want false")
	}
}

func TestSubjectCompare(t *testing.T) {
	rules := matchregistry.Default().Value
	const a, b, c = 1, 2, 3
	subj := func(entity byte, within ...byte) valuecompare.Value {
		v := valuecompare.Value{Type: propertymeta.ValueTypeSubject}
		if entity != 0 {
			v.Entity = []byte{entity}
		}
		for _, w := range within {
			v.Within = append(v.Within, []byte{w})
		}
		return v
	}
	tests := []struct {
		name     string
		x, y     valuecompare.Value
		relation valuecompare.Relation
		sim      float64
		broader  valuecompare.Side // for x against y
		cause    valuecompare.Cause
	}{
		{"same entity", subj(a), subj(a), valuecompare.Same, 1, valuecompare.SideNone, valuecompare.CauseExact},
		{"same entity, whatever it lies within", subj(a, c), subj(a), valuecompare.Same, 1, valuecompare.SideNone, valuecompare.CauseExact},
		{"x within y", subj(a, c), subj(c), valuecompare.Contains, rules.Subjects.Partial, valuecompare.SideB, valuecompare.CauseWithin},
		{"y within x", subj(c), subj(a, c), valuecompare.Contains, rules.Subjects.Partial, valuecompare.SideA, valuecompare.CauseWithin},
		{"within through the list, not nearest only", subj(a, b, c), subj(c), valuecompare.Contains, rules.Subjects.Partial, valuecompare.SideB, valuecompare.CauseWithin},
		{"each within the other is a cycle", subj(a, b), subj(b, a), valuecompare.Different, 0, valuecompare.SideNone, valuecompare.CauseNoMatch},
		{"siblings under one parent", subj(a, c), subj(b, c), valuecompare.Different, 0, valuecompare.SideNone, valuecompare.CauseNoMatch},
		{"unrelated", subj(a), subj(b), valuecompare.Different, 0, valuecompare.SideNone, valuecompare.CauseNoMatch},
		{"no entity", subj(0), subj(a), valuecompare.Unknown, 0, valuecompare.SideNone, valuecompare.CauseEmpty},
		{"neither has an entity", subj(0), subj(0), valuecompare.Unknown, 0, valuecompare.SideNone, valuecompare.CauseEmpty},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			res, det := valuecompare.Compare(tc.x, tc.y, rules)
			if res.Relation != tc.relation || res.Similarity != tc.sim || det.Broader != tc.broader || det.Cause != tc.cause {
				t.Fatalf("%+v %+v, want %s %v broader %q cause %s", res, det, tc.relation, tc.sim, tc.broader, tc.cause)
			}
			// From the other side the relation holds and the broader side flips.
			back, backDet := valuecompare.Compare(tc.y, tc.x, rules)
			wantBroader := map[valuecompare.Side]valuecompare.Side{valuecompare.SideA: valuecompare.SideB, valuecompare.SideB: valuecompare.SideA}[tc.broader]
			if back != res || backDet.Cause != tc.cause || backDet.Broader != wantBroader {
				t.Fatalf("swapped %+v %+v", back, backDet)
			}
			kx, okx := valuecompare.Key(tc.x, valuecompare.Same, rules)
			ky, oky := valuecompare.Key(tc.y, valuecompare.Same, rules)
			if equal := okx && oky && kx == ky; equal != (tc.relation == valuecompare.Same) {
				t.Fatalf("keys %q/%q at %s", kx, ky, tc.relation)
			}
		})
	}
}
