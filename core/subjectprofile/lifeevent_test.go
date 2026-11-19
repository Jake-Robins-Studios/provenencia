package subjectprofile_test

import (
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/matchregistry"
	"github.com/Jake-Robins-Studios/provenencia/core/propertycompare"
	"github.com/Jake-Robins-Studios/provenencia/core/subjectcompare"
	"github.com/Jake-Robins-Studios/provenencia/core/subjectprofile"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

func TestLifeEventOf(t *testing.T) {
	in := func(v autoreconcile.Value, neg bool) []propertycompare.Value {
		return []propertycompare.Value{subjectprofile.Value(v, neg, "")}
	}
	d1, d2, d3, d4 := datevaluetest.YMD(1901, 0, 0), datevaluetest.YMD(1902, 0, 0), datevaluetest.YMD(1903, 0, 0), datevaluetest.YMD(1904, 0, 0)
	period := matchregistry.Default().Subject.Periods[vocabkey.Event][vocabkey.PropertyDate]
	for _, tc := range []struct {
		name  string
		event subjectcompare.Values
		want  subjectprofile.LifeEvent
	}{
		{
			name:  "a positive type",
			event: subjectcompare.Values{vocabkey.PropertyEventType: in(term("birth"), false)},
			want:  subjectprofile.LifeEvent{Role: vocabkey.RoleSubject, EventType: vocabkey.EventBirth},
		},
		{
			name:  "a negative type is left out",
			event: subjectcompare.Values{vocabkey.PropertyEventType: in(term("death"), true)},
			want:  subjectprofile.LifeEvent{Role: vocabkey.RoleSubject},
		},
		{
			name: "a negative type beside a positive one",
			event: subjectcompare.Values{vocabkey.PropertyEventType: {
				subjectprofile.Value(term("death"), true, ""),
				subjectprofile.Value(term("birth"), false, ""),
			}},
			want: subjectprofile.LifeEvent{Role: vocabkey.RoleSubject, EventType: vocabkey.EventBirth},
		},
		{
			name: "every date, in key order",
			event: subjectcompare.Values{
				vocabkey.PropertyEndDate:   in(autoreconcile.Value{Date: d3}, false),
				vocabkey.PropertyStartDate: in(autoreconcile.Value{Date: d2}, false),
				vocabkey.PropertyDate:      in(autoreconcile.Value{Date: d1}, false),
				vocabkey.PropertyAsOf:      in(autoreconcile.Value{Date: d4}, false),
			},
			want: subjectprofile.LifeEvent{
				Role: vocabkey.RoleSubject, Dates: []datevalue.Value{*d1, *d2, *d3}, Samples: []datevalue.Value{*d4},
			},
		},
		{
			name:  "a negative date is left out",
			event: subjectcompare.Values{vocabkey.PropertyDate: in(autoreconcile.Value{Date: d1}, true)},
			want:  subjectprofile.LifeEvent{Role: vocabkey.RoleSubject},
		},
		{
			name:  "no type",
			event: subjectcompare.Values{},
			want:  subjectprofile.LifeEvent{Role: vocabkey.RoleSubject},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got := subjectprofile.LifeEventOf(tc.event, vocabkey.RoleSubject, vocabkey.PropertyDate, period)
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
		})
	}
	t.Run("the role is passed through", func(t *testing.T) {
		if got := subjectprofile.LifeEventOf(nil, "spouse", vocabkey.PropertyDate, period).Role; got != "spouse" {
			t.Fatalf("role %q, want spouse", got)
		}
	})
}
