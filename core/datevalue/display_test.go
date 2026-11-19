package datevalue_test

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
)

func TestCompactDisplay(t *testing.T) {
	y, m, d := 1882, 4, 3
	tests := []struct {
		name string
		v    datevalue.Value
		want string
	}{
		{
			name: "year only",
			v:    datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y},
			want: "1882",
		},
		{
			name: "about month",
			v: datevalue.Value{
				Kind: datevalue.KindPoint, Qualifier: datevalue.QualifierABT,
				StartYear: &y, StartMonth: &m,
			},
			want: "About 1882-04",
		},
		{
			name: "full day",
			v: datevalue.Value{
				Kind:      datevalue.KindPoint,
				StartYear: &y, StartMonth: &m, StartDay: &d,
			},
			want: "1882-04-03",
		},
		{
			name: "month only",
			v:    datevalue.Value{Kind: datevalue.KindPoint, StartMonth: &m},
			want: "--04",
		},
		{
			name: "day without month",
			v:    datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y, StartDay: &d},
			want: "1882--03",
		},
		{
			name: "phrase only",
			v:    datevalue.Value{Kind: datevalue.KindPoint, Phrase: "Christmas"},
			want: "Christmas",
		},
		{
			name: "range",
			v: datevalue.Value{
				Kind:      datevalue.KindRange,
				StartYear: &y, EndYear: &y, EndMonth: &m, EndDay: &d,
			},
			want: "Between 1882 and 1882-04-03",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := datevalue.CompactDisplay(tt.v); got != tt.want {
				t.Fatalf("got %q want %q", got, tt.want)
			}
		})
	}
}

func TestCitationDisplay(t *testing.T) {
	hour := 9
	withPhrase := func(v *datevalue.Value, p string) datevalue.Value {
		c := *v
		c.Phrase = p
		return c
	}
	tests := []struct {
		name  string
		v     datevalue.Value
		style datevalue.CitationStyle
		want  string
	}{
		{"long", *datevaluetest.YMD(1830, 3, 3), datevalue.CitationLong, "3 March 1830"},
		{"short", *datevaluetest.YMD(1830, 3, 3), datevalue.CitationShort, "3 Mar. 1830"},
		{"about", *datevaluetest.About(1880, 0, 0), datevalue.CitationLong, "ca. 1880"},
		{"before", *datevaluetest.Before(1830, 3, 3), datevalue.CitationLong, "bef. 3 March 1830"},
		{"after", *datevaluetest.After(1880, 0, 0), datevalue.CitationLong, "aft. 1880"},
		{"range", *datevaluetest.Between(1878, 0, 0, 1882, 0, 0), datevalue.CitationLong, "1878\u20131882"},
		{"year style", *datevaluetest.YMD(1830, 3, 3), datevalue.CitationYear, "1830"},
		{"phrase only", *datevaluetest.Phrase("Christmas"), datevalue.CitationLong, "Christmas"},
		{"point ignores phrase", withPhrase(datevaluetest.YMD(1882, 0, 0), "Christmas"), datevalue.CitationLong, "1882"},
		{"month only", *datevaluetest.YMD(0, 3, 0), datevalue.CitationLong, "March"},
		{"month and year", *datevaluetest.YMD(1830, 3, 0), datevalue.CitationLong, "March 1830"},
		{"day and month", *datevaluetest.YMD(0, 3, 3), datevalue.CitationLong, "3 March"},
		{"year and day without month", *datevaluetest.YMD(1882, 0, 3), datevalue.CitationLong, "1882"},
		{"day alone", *datevaluetest.YMD(0, 0, 3), datevalue.CitationLong, ""},
		{"sept short", *datevaluetest.YMD(1830, 9, 0), datevalue.CitationShort, "Sept. 1830"},
		{"june short", *datevaluetest.YMD(1830, 6, 0), datevalue.CitationShort, "June 1830"},
		{"year style keeps qualifier", *datevaluetest.About(1830, 3, 3), datevalue.CitationYear, "ca. 1830"},
		{"range one year", *datevaluetest.Between(1882, 1, 0, 1882, 12, 0), datevalue.CitationYear, "1882"},
		{"year style, month only", *datevaluetest.YMD(0, 3, 0), datevalue.CitationYear, ""},
		{"time only", datevalue.Value{Kind: datevalue.KindPoint, StartHour: &hour}, datevalue.CitationLong, ""},
		{"range with a time-only end", datevalue.Value{
			Kind: datevalue.KindRange, StartYear: datevaluetest.Part(1882), EndHour: &hour, Phrase: "Lent",
		}, datevalue.CitationLong, "Lent"},
		{"negative year", *datevaluetest.YMD(-50, 0, 0), datevalue.CitationLong, "-50"},
		{"no kind", datevalue.Value{Phrase: "x"}, datevalue.CitationLong, "x"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := datevalue.CitationDisplay(tt.v, tt.style); got != tt.want {
				t.Fatalf("got %q want %q", got, tt.want)
			}
		})
	}
}
