package dbsql

import (
	"go/ast"
	"go/parser"
	"go/token"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/internal/gosrc"
)

// TestNoLocalSQLSurface fails when a Go file under core or api declares an
// interface made only of Query, QueryRow, Exec or Scan methods, named or
// inline, outside this package. A read takes database.Querier, a write
// database.Execer, a row scan database.Scanner.
func TestNoLocalSQLSurface(t *testing.T) {
	allowed := map[string]bool{"Query": true, "QueryRow": true, "Exec": true, "Scan": true}
	for _, file := range gosrc.Files(t, "core", "api") {
		if strings.HasPrefix(file.Rel, "core/database/dbsql/") {
			continue
		}
		fset := token.NewFileSet()
		f, err := parser.ParseFile(fset, file.Path, nil, 0)
		if err != nil {
			t.Fatal(err)
		}
		ast.Inspect(f, func(n ast.Node) bool {
			it, ok := n.(*ast.InterfaceType)
			if !ok {
				return true
			}
			named := 0
			only := true
			for _, m := range it.Methods.List {
				if len(m.Names) == 0 {
					continue
				}
				for _, name := range m.Names {
					named++
					if !allowed[name.Name] {
						only = false
					}
				}
			}
			if named > 0 && only {
				t.Errorf("%s:%d declares its own querier, execer or scanner interface; use database.Querier, database.Execer or database.Scanner", file.Rel, fset.Position(it.Pos()).Line)
			}
			return true
		})
	}
}

// TestImportsNoModulePackage fails when dbsql imports anything from this
// module: it is a leaf so sqlbatch, graphcache and effects can use it.
func TestImportsNoModulePackage(t *testing.T) {
	entries, err := filepath.Glob("*.go")
	if err != nil {
		t.Fatal(err)
	}
	parsed := 0
	for _, path := range entries {
		if strings.HasSuffix(path, "_test.go") {
			continue
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			t.Fatal(err)
		}
		parsed++
		for _, imp := range f.Imports {
			if p := strings.Trim(imp.Path.Value, `"`); strings.HasPrefix(p, gosrc.Module) {
				t.Errorf("%s imports %s: dbsql must not import the catalog", path, p)
			}
		}
	}
	if parsed == 0 {
		t.Fatal("parsed no dbsql files")
	}
}
