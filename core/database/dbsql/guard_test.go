package dbsql

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"path/filepath"
	"strings"
	"testing"
)

const modulePath = "github.com/Jake-Robins-Studios/provenencia/"

// TestNoLocalSQLSurface fails when a Go file under core or api declares an
// interface made only of Query, QueryRow, Exec or Scan methods, named or
// inline, outside this package. A read takes database.Querier, a write
// database.Execer, a row scan database.Scanner.
func TestNoLocalSQLSurface(t *testing.T) {
	repo := filepath.Join("..", "..", "..")
	allowed := map[string]bool{"Query": true, "QueryRow": true, "Exec": true, "Scan": true}
	parsed := 0
	for _, top := range []string{"core", "api"} {
		root := filepath.Join(repo, top)
		err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				switch d.Name() {
				case "vendor", "testdata":
					return filepath.SkipDir
				}
				if path != root && strings.HasPrefix(d.Name(), ".") {
					return filepath.SkipDir
				}
				return nil
			}
			if !strings.HasSuffix(path, ".go") {
				return nil
			}
			rel, err := filepath.Rel(repo, path)
			if err != nil {
				return err
			}
			rel = filepath.ToSlash(rel)
			if strings.HasPrefix(rel, "core/database/dbsql/") {
				return nil
			}
			fset := token.NewFileSet()
			f, err := parser.ParseFile(fset, path, nil, 0)
			if err != nil {
				return err
			}
			parsed++
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
					t.Errorf("%s:%d declares its own querier, execer or scanner interface; use database.Querier, database.Execer or database.Scanner", rel, fset.Position(it.Pos()).Line)
				}
				return true
			})
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
	if parsed == 0 {
		t.Fatal("parsed no Go files: the walk skipped its own root")
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
			if p := strings.Trim(imp.Path.Value, `"`); strings.HasPrefix(p, modulePath) {
				t.Errorf("%s imports %s: dbsql must not import the catalog", path, p)
			}
		}
	}
	if parsed == 0 {
		t.Fatal("parsed no dbsql files")
	}
}
