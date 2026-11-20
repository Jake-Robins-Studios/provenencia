package sources_test

import (
	"strconv"
	"testing"
	"time"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/datevalues"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades/sourcecredibilitygradestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// BenchmarkSourceRecords: Build of the records at 3,000 Sources of 10
// Artifacts (every tenth assessed, every Source dated), and Apply of one commit that names an
// ordinary Source and one that names a Source of 10,000 Artifacts.
func BenchmarkSourceRecords(b *testing.B) {
	const sourcesN, perSource, crafted = 3000, 10, 10000
	c, err := database.Create(b.TempDir(), "t.provenencia")
	if err != nil {
		b.Fatal(err)
	}
	b.Cleanup(func() { _ = c.Close() })
	if err := sourcecredibilitygradestest.Install(c); err != nil {
		b.Fatal(err)
	}
	typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{Key: "book", Origin: vocabkey.OriginProvenencia, Label: "Book"})
	if err != nil {
		b.Fatal(err)
	}
	db, err := c.DB()
	if err != nil {
		b.Fatal(err)
	}
	tx, err := db.Begin()
	if err != nil {
		b.Fatal(err)
	}
	var gradeID []byte
	if err := tx.QueryRow(`SELECT id FROM source_credibility_grades WHERE key = 'low_trust'`).Scan(&gradeID); err != nil {
		b.Fatal(err)
	}
	n := 0
	seed := func(src, artifacts int) {
		sid := databasetest.BenchID(1, src)
		year := 1800 + src%200
		dateID, err := datevalues.InsertTx(tx, datevalue.Value{Kind: datevalue.KindPoint, StartYear: &year})
		if err != nil {
			b.Fatal(err)
		}
		if _, err := tx.Exec(`INSERT INTO sources (id, ref, source_type_id, title, date_value_id) VALUES (?, ?, ?, ?, ?)`, sid, "SRC-B"+string(rune('A'+src%26))+strconv.Itoa(src), typeID, "Source "+strconv.Itoa(src), dateID); err != nil {
			b.Fatal(err)
		}
		if src%10 == 0 {
			if _, err := tx.Exec(`INSERT INTO source_credibility_assessments (id, source_id, credibility_grade_id) VALUES (?, ?, ?)`, databasetest.BenchID(3, src), sid, gradeID); err != nil {
				b.Fatal(err)
			}
		}
		for i := 0; i < artifacts; i++ {
			n++
			if _, err := tx.Exec(`INSERT INTO artifacts (id, ref, source_id, label) VALUES (?, ?, ?, ?)`, databasetest.BenchID(2, n), "ART-B"+strconv.Itoa(n), sid, "Page "+strconv.Itoa(i)); err != nil {
				b.Fatal(err)
			}
		}
	}
	for s := 1; s <= sourcesN; s++ {
		seed(s, perSource)
	}
	if err := tx.Commit(); err != nil {
		b.Fatal(err)
	}

	g := c.Graph()
	g.Drop()
	var build time.Duration
	heap := databasetest.HeapDelta(func() {
		start := time.Now()
		if _, err := sources.RecordsOf(g); err != nil {
			b.Fatal(err)
		}
		build = time.Since(start)
	})
	b.ReportMetric(float64(build.Microseconds())/1000, "build-ms")
	b.ReportMetric(heap/(1<<20), "heap-MB")

	// The crafted Source joins after the Build measure, which is the 3,000 x 10 shape.
	if tx, err = db.Begin(); err != nil {
		b.Fatal(err)
	}
	seed(sourcesN+1, crafted)
	if err := tx.Commit(); err != nil {
		b.Fatal(err)
	}
	g.Drop()
	if _, err := sources.RecordsOf(g); err != nil {
		b.Fatal(err)
	}

	apply := func(metric string, id []byte) {
		start := time.Now()
		for i := 0; i < b.N; i++ {
			if err := g.OnCommit(effects.Commit{Effects: effects.Set{Reads: []effects.ReadIDs{{Read: effects.ReadSourceRecords, IDs: [][]byte{id}}}}}); err != nil {
				b.Fatal(err)
			}
		}
		b.ReportMetric(float64(time.Since(start).Microseconds())/1000/float64(b.N), metric)
	}
	apply("apply-ms", databasetest.BenchID(1, 7))
	apply("apply-10k-ms", databasetest.BenchID(1, sourcesN+1))
}
