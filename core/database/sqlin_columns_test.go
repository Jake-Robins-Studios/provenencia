package database

import "testing"

func TestColumns(t *testing.T) {
	cols := []string{"id", "description|COALESCE(%s, '')", "icon_key"}
	for _, tc := range []struct{ alias, want string }{
		{"", "id, COALESCE(description, ''), icon_key"},
		{"c", "c.id, COALESCE(c.description, ''), c.icon_key"},
	} {
		if got := Columns(tc.alias, cols...); got != tc.want {
			t.Errorf("Columns(%q) = %q, want %q", tc.alias, got, tc.want)
		}
	}
}
