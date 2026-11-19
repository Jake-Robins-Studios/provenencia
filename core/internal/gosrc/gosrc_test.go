package gosrc

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func writeTree(t *testing.T, files ...string) string {
	t.Helper()
	repo := t.TempDir()
	files = append(files, "go.mod")
	for _, f := range files {
		p := filepath.Join(repo, filepath.FromSlash(f))
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte("package x\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return repo
}

func TestFiles(t *testing.T) {
	repo := writeTree(t,
		"pkg/a.go", "pkg/a_test.go", "pkg/sub/b.go", "pkg/sub/deep/c.go", "pkg/notes.txt",
		"pkg/vendor/v.go", "pkg/testdata/t.go", "pkg/.hidden/h.go", "pkg/sub/.git/g.go",
		".dot/root.go", "other/o.go", "bare/vendor/v.go",
	)
	tests := []struct {
		name    string
		roots   []string
		want    []string
		wantErr bool
	}{
		{"skips vendor, testdata and dot dirs below the root", []string{"pkg"}, []string{"pkg/a.go", "pkg/a_test.go", "pkg/sub/b.go", "pkg/sub/deep/c.go"}, false},
		{"a dot root is walked", []string{".dot"}, []string{".dot/root.go"}, false},
		{"several roots", []string{"pkg/sub", "other"}, []string{"other/o.go", "pkg/sub/b.go", "pkg/sub/deep/c.go"}, false},
		{"no Go file fails", []string{"bare"}, nil, true},
		{"missing root fails", []string{"nope"}, nil, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := files(repo, tt.roots)
			if (err != nil) != tt.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tt.wantErr)
			}
			var rels []string
			for _, f := range got {
				rels = append(rels, f.Rel)
				if want := filepath.Join(repo, filepath.FromSlash(f.Rel)); f.Path != want {
					t.Errorf("Path = %q, want %q", f.Path, want)
				}
			}
			slices.Sort(rels)
			if !slices.Equal(rels, tt.want) {
				t.Errorf("files = %v, want %v", rels, tt.want)
			}
		})
	}
}

func TestRepoRoot(t *testing.T) {
	repo := writeTree(t, "a/b/x.go")
	got, err := repoRoot(filepath.Join(repo, "a", "b"))
	if err != nil || got != repo {
		t.Fatalf("repoRoot = %q, %v; want %q", got, err, repo)
	}
	if _, err := repoRoot(t.TempDir()); err == nil {
		t.Fatal("repoRoot found a go.mod above a bare temp dir")
	}
}

func TestFilesFindsThisRepo(t *testing.T) {
	found := Files(t, "core/internal/gosrc")
	if len(found) < 2 {
		t.Fatalf("found %d files, want this package's own", len(found))
	}
}
