// Package doctable reads a section of a docs/ markdown file for the tests that
// hold a doc table to a registry. It is a test helper: a failed read fails the
// test.
package doctable

import (
	"os"
	"strings"
	"testing"
)

// Section returns the text under the "## <section>" heading of the file at
// path, up to the next "## " heading. It fails the test when the heading is
// missing or the section is empty.
func Section(t testing.TB, path, section string) string {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var out []string
	in, found := false, false
	for _, line := range strings.Split(string(raw), "\n") {
		if strings.HasPrefix(line, "## ") {
			in = strings.TrimSpace(strings.TrimPrefix(line, "## ")) == section
			found = found || in
			continue
		}
		if in {
			out = append(out, line)
		}
	}
	if !found {
		t.Fatalf("%s has no ## %s section", path, section)
	}
	body := strings.Join(out, "\n")
	if strings.TrimSpace(body) == "" {
		t.Fatalf("%s: ## %s is empty", path, section)
	}
	return body
}

// FirstColumn returns the first backticked span of the first cell of each table
// row in the section. It fails the test when the section has none.
func FirstColumn(t testing.TB, path, section string) []string {
	t.Helper()
	var keys []string
	for _, line := range strings.Split(Section(t, path, section), "\n") {
		if !strings.HasPrefix(line, "| `") {
			continue
		}
		cell := strings.TrimPrefix(line, "| `")
		if end := strings.Index(cell, "`"); end >= 0 {
			keys = append(keys, cell[:end])
		}
	}
	if len(keys) == 0 {
		t.Fatalf("%s: no rows found under ## %s", path, section)
	}
	return keys
}
