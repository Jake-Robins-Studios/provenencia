package onboarding

import (
	"database/sql"
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func TestOpenCatalogDoesNotHealSourceVocab(t *testing.T) {
	ident := t.TempDir()
	parent := t.TempDir()
	created, err := Complete(ident, parent, "Jake", "Heal Check")
	if err != nil {
		t.Fatal(err)
	}

	c, err := OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	cert, err := sourcetypes.Lookup(c, "birth_certificate", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	if err := runSourceTypeDelete(c, created.Identity.UserID[:], cert.ID); err != nil {
		t.Fatal(err)
	}
	c.Close()

	c, err = OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	_, err = sourcetypes.Lookup(c, "birth_certificate", vocabkey.OriginProvenencia)
	if !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("open healed seed: %v", err)
	}
}

func TestOpenCatalogDoesNotHealCredibilityGrades(t *testing.T) {
	ident := t.TempDir()
	parent := t.TempDir()
	created, err := Complete(ident, parent, "Jake", "Cred Heal")
	if err != nil {
		t.Fatal(err)
	}

	c, err := OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	low, err := sourcecredibilitygrades.Lookup(c, "low_trust", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`DELETE FROM source_credibility_grades WHERE id = ?`, low.ID); err != nil {
		t.Fatal(err)
	}
	c.Close()

	c, err = OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	_, err = sourcecredibilitygrades.Lookup(c, "low_trust", vocabkey.OriginProvenencia)
	if !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("open healed credibility grade: %v", err)
	}
}

func TestCreateCatalogSeedsCredibilityGrades(t *testing.T) {
	ident := t.TempDir()
	parent := t.TempDir()
	created, err := Complete(ident, parent, "Jake", "Cred Seed")
	if err != nil {
		t.Fatal(err)
	}
	c, err := OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	list, err := sourcecredibilitygrades.List(c)
	if err != nil || len(list) == 0 {
		t.Fatalf("create installed no credibility grades: %v", err)
	}
}

func TestCreateCatalogSeedsSubjectTypes(t *testing.T) {
	ident := t.TempDir()
	parent := t.TempDir()
	created, err := Complete(ident, parent, "Jake", "Subject Seed")
	if err != nil {
		t.Fatal(err)
	}
	c, err := OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	list, err := subjecttypes.List(c)
	if err != nil || len(list) == 0 {
		t.Fatalf("create installed no subject types: %v", err)
	}
}

func TestOpenCatalogDoesNotHealSubjectTypes(t *testing.T) {
	ident := t.TempDir()
	parent := t.TempDir()
	created, err := Complete(ident, parent, "Jake", "Subject Heal")
	if err != nil {
		t.Fatal(err)
	}

	c, err := OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	person, err := subjecttypes.Lookup(c, "person", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`DELETE FROM subject_types WHERE id = ?`, person.ID); err != nil {
		t.Fatal(err)
	}
	c.Close()

	c, err = OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	_, err = subjecttypes.Lookup(c, "person", vocabkey.OriginProvenencia)
	if !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("open healed subject type: %v", err)
	}
}

func TestOpenCatalogDoesNotSeedAliasTables(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	dir := c.Dir()
	if err := c.Close(); err != nil {
		t.Fatal(err)
	}
	c, err = OpenCatalog(dir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	var n int
	if err := db.QueryRow(`SELECT COUNT(*) FROM name_alias_tables`).Scan(&n); err != nil {
		t.Fatal(err)
	}
	if n != 0 {
		t.Fatalf("open seeded %d alias tables", n)
	}
}

func TestOpenCatalogDoesNotHealAliasTables(t *testing.T) {
	ident := t.TempDir()
	parent := t.TempDir()
	created, err := Complete(ident, parent, "Jake", "Alias Heal")
	if err != nil {
		t.Fatal(err)
	}
	c, err := OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`DELETE FROM name_alias_tables WHERE key = 'abbreviations' AND origin = 'provenencia'`); err != nil {
		t.Fatal(err)
	}
	c.Close()

	c, err = OpenCatalog(created.ProjectDir)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	db, err = c.DB()
	if err != nil {
		t.Fatal(err)
	}
	var n int
	if err := db.QueryRow(`SELECT COUNT(*) FROM name_alias_tables WHERE key = 'abbreviations'`).Scan(&n); err != nil {
		t.Fatal(err)
	}
	if n != 0 {
		t.Fatalf("open restored abbreviations: %d", n)
	}
}

func runSourceTypeDelete(c *database.Catalog, userID, id []byte) error {
	_, err := writes.RunChanges(c, writes.Op{Action: "delete_source_type", UserID: userID},
		func(tx *database.Tx) ([]rowchange.Change, error) {
			return sourcetypes.Delete(tx, userID, id)
		})
	return err
}

func TestOpenCatalogMintsGraphRefs(t *testing.T) {
	parent := t.TempDir()
	c, err := createCatalog(parent, "graphs.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	dir := c.Dir()
	sourceID := evidencegraphstest.SeedRefless(t, c)

	reopened, err := OpenCatalog(dir)
	if err != nil {
		t.Fatal(err)
	}
	defer reopened.Close()
	if got := evidencegraphstest.SoleGraph(t, reopened, sourceID).Ref; !ref.Valid(got) {
		t.Fatalf("graph ref %q", got)
	}
}
