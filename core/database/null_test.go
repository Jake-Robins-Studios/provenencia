package database

import (
	"bytes"
	"testing"
)

func TestNullBlob(t *testing.T) {
	id := bytes.Repeat([]byte{0xab}, 16)
	tests := []struct {
		name string
		in   []byte
		want any
	}{
		{name: "nil", in: nil, want: nil},
		{name: "empty slice", in: []byte{}, want: nil},
		{name: "16-byte id", in: id, want: id},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := NullBlob(tt.in)
			if tt.want == nil {
				if got != nil {
					t.Fatalf("NullBlob(%v) = %v, want nil", tt.in, got)
				}
				return
			}
			b, ok := got.([]byte)
			if !ok || !bytes.Equal(b, tt.want.([]byte)) {
				t.Fatalf("NullBlob(%v) = %v, want %v", tt.in, got, tt.want)
			}
		})
	}
}

func TestNullTrimmed(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want any
	}{
		{name: "empty", in: "", want: nil},
		{name: "whitespace only", in: " \t\n", want: nil},
		{name: "plain", in: "abc", want: "abc"},
		{name: "padded", in: "  abc ", want: "abc"},
		{name: "inner space kept", in: " a b ", want: "a b"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := NullTrimmed(tt.in); got != tt.want {
				t.Fatalf("NullTrimmed(%q) = %v, want %v", tt.in, got, tt.want)
			}
		})
	}
}

func TestNullInt(t *testing.T) {
	zero, year := 0, 1890
	tests := []struct {
		name string
		in   *int
		want any
	}{
		{name: "nil", in: nil, want: nil},
		{name: "zero", in: &zero, want: 0},
		{name: "value", in: &year, want: 1890},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := NullInt(tt.in); got != tt.want {
				t.Fatalf("NullInt(%v) = %v, want %v", tt.in, got, tt.want)
			}
		})
	}
}
