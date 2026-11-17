package valuecompare_test

import (
	"math"
	"math/rand"
	"testing"

	"github.com/mendahu/provenencia/core/datevalue"
	"github.com/mendahu/provenencia/core/datevalue/datevaluetest"
	"github.com/mendahu/provenencia/core/valuecompare"
)

// FuzzDatingOf checks DatingOf never panics on samples of any dates and gives
// the same Low and High ends, and the same nil High, for any order of them. It
// runs its seeds as a unit test.
func FuzzDatingOf(f *testing.F) {
	for _, y := range []int32{0, 1, -1, 1817, 1990, math.MaxInt32, math.MinInt32} {
		for _, k := range []string{datevalue.KindPoint, datevalue.KindRange, "nonsense", ""} {
			for _, q := range []string{"", datevalue.QualifierABT, datevalue.QualifierBEF, datevalue.QualifierAFT, "XYZ"} {
				f.Add(k, q, y, y+1, int32(1990), int32(1991), int64(1))
				f.Add(k, q, y, -y, y, int32(2000), int64(2))
			}
		}
	}
	f.Fuzz(func(t *testing.T, kind, qualifier string, y1, y2, y3, y4 int32, seed int64) {
		sample := func(k, q string, a, b int32) datevalue.Value {
			d := datevaluetest.Between(int(a), 0, 0, int(b), 0, 0)
			d.Kind, d.Qualifier = k, q
			return *d
		}
		samples := []datevalue.Value{
			sample(kind, qualifier, y1, y2),
			sample(datevalue.KindPoint, "", y3, y3),
			sample(datevalue.KindRange, "", y3, y4),
			sample(kind, "", y4, y1),
		}
		ends := func(d *datevalue.Value) [2]valuecompare.DateEnd {
			if d == nil {
				return [2]valuecompare.DateEnd{}
			}
			first, last, _ := valuecompare.DateEnds(*d)
			return [2]valuecompare.DateEnd{first, last}
		}
		want := valuecompare.DatingOf(nil, nil, nil, samples)
		r := rand.New(rand.NewSource(seed))
		r.Shuffle(len(samples), func(i, j int) { samples[i], samples[j] = samples[j], samples[i] })
		got := valuecompare.DatingOf(nil, nil, nil, samples)
		if (got.High == nil) != (want.High == nil) || ends(got.Low) != ends(want.Low) || ends(got.High) != ends(want.High) {
			t.Fatalf("shuffled: low %+v high %+v, want low %+v high %+v (samples %+v)", ends(got.Low), ends(got.High), ends(want.Low), ends(want.High), samples)
		}
	})
}
