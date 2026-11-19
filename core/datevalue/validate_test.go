package datevalue

import (
	"errors"
	"strings"
	"testing"
)

func TestValidate(t *testing.T) {
	n := func(v int) *int { return &v }
	tests := []struct {
		name    string
		v       Value
		wantErr bool
	}{
		{name: "point month 13", v: Value{Kind: KindPoint, StartYear: n(1882), StartMonth: n(13)}, wantErr: true},
		{name: "range start after end", v: Value{Kind: KindRange, StartYear: n(1900), EndYear: n(1890)}, wantErr: true},
		{name: "point about year", v: Value{Kind: KindPoint, Qualifier: QualifierABT, StartYear: n(1817)}},
		{name: "empty value", v: Value{}, wantErr: true},
		{name: "point year above the window", v: Value{Kind: KindPoint, StartYear: n(10000)}, wantErr: true},
		{name: "point year below the window", v: Value{Kind: KindPoint, StartYear: n(-10000)}, wantErr: true},
		{name: "range end year above the window", v: Value{Kind: KindRange, StartYear: n(1900), EndYear: n(10000)}, wantErr: true},
		{name: "range end year below the window", v: Value{Kind: KindRange, StartYear: n(-10000), EndYear: n(1900)}, wantErr: true},
		{name: "point year at the window edge", v: Value{Kind: KindPoint, StartYear: n(MaxYear)}},
		{name: "range across the window", v: Value{Kind: KindRange, StartYear: n(MinYear), EndYear: n(MaxYear)}},
		{name: "phrase at the cap", v: Value{Kind: KindPoint, Phrase: strings.Repeat("a", MaxPhraseBytes)}},
		{name: "phrase over the cap", v: Value{Kind: KindPoint, Phrase: strings.Repeat("a", MaxPhraseBytes+1)}, wantErr: true},
		{name: "point year with a phrase over the cap", v: Value{Kind: KindPoint, StartYear: n(1880), Phrase: strings.Repeat("a", MaxPhraseBytes+1)}, wantErr: true},
		{name: "range with a phrase over the cap", v: Value{Kind: KindRange, StartYear: n(1880), EndYear: n(1890), Phrase: strings.Repeat("a", MaxPhraseBytes+1)}, wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := Validate(tt.v)
			if tt.wantErr {
				if !errors.Is(err, ErrInvalid) {
					t.Fatalf("Validate = %v, want ErrInvalid", err)
				}
				return
			}
			if err != nil {
				t.Fatalf("Validate = %v, want nil", err)
			}
		})
	}
}
