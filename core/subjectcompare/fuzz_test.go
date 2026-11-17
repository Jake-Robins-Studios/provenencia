package subjectcompare_test

import (
	"math"
	"math/rand"
	"testing"

	"github.com/mendahu/provenencia/core/datevalue"
	"github.com/mendahu/provenencia/core/datevalue/datevaluetest"
	"github.com/mendahu/provenencia/core/matchregistry"
	pt "github.com/mendahu/provenencia/core/propertycompare/propertycomparetest"
	"github.com/mendahu/provenencia/core/subjectcompare"
	"github.com/mendahu/provenencia/core/subjectcompare/subjectcomparetest"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// fuzzDate is a date from raw numbers: any kind, qualifier and year the fuzzer
// invents, so inverted ranges, unknown qualifiers and extreme years reach
// the comparer.
func fuzzDate(kind, qualifier string, y1, y2 int32) V {
	d := datevaluetest.Between(int(y1), 0, 0, int(y2), 0, 0)
	d.Kind, d.Qualifier = kind, qualifier
	return pt.Date(d)
}

// FuzzCompareProperty checks Compare never panics on events of any dates and
// reads the same mirrored and shuffled. It runs its seeds as a unit test.
func FuzzCompareProperty(f *testing.F) {
	for _, y := range []int32{0, 1, -1, 1817, math.MaxInt32, math.MinInt32} {
		for _, k := range []string{datevalue.KindPoint, datevalue.KindRange, "nonsense", ""} {
			for _, q := range []string{"", datevalue.QualifierABT, datevalue.QualifierBEF, datevalue.QualifierAFT, "XYZ"} {
				f.Add(k, q, y, y+1, int32(1990), int32(1985), int64(1))
				f.Add(k, q, y, -y, y, int32(2000), int64(2))
			}
		}
	}
	rules := matchregistry.Default()
	f.Fuzz(func(t *testing.T, kind, qualifier string, y1, y2, y3, y4 int32, seed int64) {
		a := Vals{
			asOf:  {fuzzDate(kind, qualifier, y1, y2), fuzzDate(datevalue.KindPoint, "", y3, y3)},
			start: {fuzzDate(kind, qualifier, y4, y4)},
		}
		b := Vals{
			start: {fuzzDate(kind, qualifier, y3, y4)},
			end:   {fuzzDate(datevalue.KindPoint, qualifier, y2, y2)},
			date:  {fuzzDate(kind, "", y1, y3)},
		}
		cmp := func(x, y Vals) subjectcompare.Result {
			return subjectcompare.Compare(vocabkey.Event, x, y, subjectcomparetest.Metas(), rules.Subject, rules.Value)
		}
		got := cmp(a, b)
		if msg := same(got, cmp(b, a)); msg != "" {
			t.Fatalf("mirrored: %s", msg)
		}
		r := rand.New(rand.NewSource(seed))
		if msg := same(got, cmp(shuffled(r, a), shuffled(r, b))); msg != "" {
			t.Fatalf("shuffled: %s", msg)
		}
	})
}
