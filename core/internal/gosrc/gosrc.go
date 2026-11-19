// Package gosrc walks the repository's Go source for guard tests. It is test
// support used across packages and imports nothing from the module.
package gosrc

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// Module is the import-path prefix of every package in this repository.
const Module = "github.com/Jake-Robins-Studios/provenencia/"

// File is one Go source file: Rel is its slash-separated path from the repo
// root, Path the path to open it from the test's working directory.
type File struct{ Rel, Path string }

// Files returns every .go file (test files included; callers filter) under
// each root, a path relative to the repo root. It skips vendor, testdata and
// dot directories below a root, never the root itself, and fails the test on a
// walk error or when no file is found, so a guard cannot pass by checking
// nothing.
func Files(t testing.TB, roots ...string) []File {
	t.Helper()
	wd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	repo, err := repoRoot(wd)
	if err != nil {
		t.Fatal(err)
	}
	out, err := files(repo, roots)
	if err != nil {
		t.Fatal(err)
	}
	return out
}

func repoRoot(dir string) (string, error) {
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", errors.New("gosrc: no go.mod above the working directory")
		}
		dir = parent
	}
}

func files(repo string, roots []string) ([]File, error) {
	var out []File
	for _, r := range roots {
		root := filepath.Join(repo, filepath.FromSlash(r))
		err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				if path == root {
					return nil
				}
				if d.Name() == "vendor" || d.Name() == "testdata" || strings.HasPrefix(d.Name(), ".") {
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
			out = append(out, File{Rel: filepath.ToSlash(rel), Path: path})
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	if len(out) == 0 {
		return nil, fmt.Errorf("gosrc: no Go files under %v: the walk skipped its own root", roots)
	}
	return out, nil
}
