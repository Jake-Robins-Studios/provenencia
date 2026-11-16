package valuemark_test

import (
	"errors"
	"testing"

	"github.com/mendahu/provenencia/core/apperr"
	"github.com/mendahu/provenencia/core/valuemark"
)

func TestValidate(t *testing.T) {
	tests := []struct {
		name     string
		mark     valuemark.Mark
		hasValue bool
		invalid  bool
	}{
		{"unknown with a value", valuemark.Mark{Unknown: true}, true, true},
		{"supplied without a value", valuemark.Mark{Supplied: true}, false, true},
		{"both with a value", valuemark.Mark{Unknown: true, Supplied: true}, true, true},
		{"both without a value", valuemark.Mark{Unknown: true, Supplied: true}, false, true},
		{"unknown without a value", valuemark.Mark{Unknown: true}, false, false},
		{"supplied with a value", valuemark.Mark{Supplied: true}, true, false},
		{"neither with a value", valuemark.Mark{}, true, false},
		{"neither without a value", valuemark.Mark{}, false, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := valuemark.Validate(tt.mark, tt.hasValue)
			if !tt.invalid {
				if err != nil {
					t.Fatalf("Validate = %v, want nil", err)
				}
				return
			}
			if !errors.Is(err, valuemark.ErrInvalid) {
				t.Fatalf("Validate = %v, want ErrInvalid", err)
			}
			var ae *apperr.Error
			if !errors.As(err, &ae) || ae.Code() != "valuemark.invalid" {
				t.Fatalf("Validate = %v, want code valuemark.invalid", err)
			}
		})
	}
}
