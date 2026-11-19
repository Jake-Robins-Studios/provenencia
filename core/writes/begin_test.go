package writes

import (
	"go/ast"
	"go/parser"
	"go/token"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/internal/gosrc"
)

// TestBeginOnlyInDatabaseAndWrites fails when a non-test file outside
// core/database and core/writes calls Begin. Writes go through Run. Reads
// that need a transaction begin it inside core/database.
func TestBeginOnlyInDatabaseAndWrites(t *testing.T) {
	var hits []string
	for _, file := range gosrc.Files(t, "core", "api") {
		if strings.HasSuffix(file.Rel, "_test.go") ||
			strings.HasPrefix(file.Rel, "core/database/") || strings.HasPrefix(file.Rel, "core/writes/") {
			continue
		}
		f, err := parser.ParseFile(token.NewFileSet(), file.Path, nil, 0)
		if err != nil {
			t.Fatal(err)
		}
		ast.Inspect(f, func(n ast.Node) bool {
			sel, ok := n.(*ast.SelectorExpr)
			if ok && sel.Sel != nil && sel.Sel.Name == "Begin" {
				hits = append(hits, file.Rel)
			}
			return true
		})
	}
	if len(hits) > 0 {
		t.Fatalf(".Begin() outside core/database and core/writes: %s", strings.Join(hits, ", "))
	}
}
