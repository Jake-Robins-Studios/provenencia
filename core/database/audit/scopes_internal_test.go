package audit

import (
	"errors"
	"go/ast"
	"go/parser"
	"go/token"
	"strconv"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/internal/gosrc"
)

// TestResolversCoverEveryEntityType parses non-test Go under core/ for every
// audited entity type (EntityType: "…" literals and deleteimpact rowFacet
// arguments) and wants a non-None effect for each, so a new audited table is
// recorded instead of failing at runtime. An entity whose effect is None is
// committed without a revision and is left out of an audited change list.
func TestResolversCoverEveryEntityType(t *testing.T) {
	found := map[string]string{}
	for _, file := range gosrc.Files(t, "core") {
		if strings.HasSuffix(file.Rel, "_test.go") {
			continue
		}
		f, err := parser.ParseFile(token.NewFileSet(), file.Path, nil, 0)
		if err != nil {
			t.Fatal(err)
		}
		ast.Inspect(f, func(n ast.Node) bool {
			switch x := n.(type) {
			case *ast.KeyValueExpr:
				if k, ok := x.Key.(*ast.Ident); ok && k.Name == "EntityType" {
					if s, ok := stringLit(x.Value); ok {
						found[s] = file.Rel
					}
				}
			case *ast.CallExpr:
				// rowFacet(parent, table, fkCol, entityType, entityIDCol, cols...)
				if fn, ok := x.Fun.(*ast.Ident); ok && fn.Name == "rowFacet" && len(x.Args) >= 4 {
					if s, ok := stringLit(x.Args[3]); ok {
						found[s] = file.Rel
					}
				}
			}
			return true
		})
	}
	if len(found) < 10 {
		t.Fatalf("found only %d entity types; parser walk broken? %v", len(found), found)
	}
	for et, path := range found {
		none, err := effects.AllNone([]rowchange.Change{{EntityType: et}})
		if err != nil {
			t.Errorf("entity type %q (%s) is not a non-None effect: %v", et, path, err)
			continue
		}
		if none {
			continue
		}
	}
}

func stringLit(e ast.Expr) (string, bool) {
	lit, ok := e.(*ast.BasicLit)
	if !ok || lit.Kind != token.STRING {
		return "", false
	}
	s, err := strconv.Unquote(lit.Value)
	return s, err == nil
}

func TestRecordRejectsUnknownEntity(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback() }()
	_, err = Record(tx, Revision{ActionType: "x", CreatedAt: "2026-10-04T00:00:00Z", Changes: []rowchange.Change{{
		EntityType: "mystery", EntityID: []byte{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9}, Action: rowchange.ActionCreate, Fields: map[string]rowchange.FieldDiff{},
	}}}, effects.Set{})
	if !errors.Is(err, ErrInvalid) {
		t.Fatalf("want ErrInvalid got %v", err)
	}
}
