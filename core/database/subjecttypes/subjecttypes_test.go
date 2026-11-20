package subjecttypes

import (
	"database/sql"
	"errors"
	"reflect"
	"sort"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func TestSubjectTypes(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "upsert list lookup",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{
					Key: "person", Origin: vocabkey.OriginProvenencia, Label: "Person",
					RefPrefix: "PER", CandidateRefPrefix: "CPR",
				})
				if err != nil {
					t.Fatal(err)
				}
				person, err := Lookup(c, "person", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if string(person.ID) != string(id) || person.RefPrefix != "PER" {
					t.Fatalf("%+v", person)
				}
				list, err := List(c)
				if err != nil || len(list) != 1 {
					t.Fatalf("%v len=%d", err, len(list))
				}
			},
		},
		{
			name: "upsert twice keeps same id",
			run: func(t *testing.T, c *database.Catalog) {
				first, err := upsert(c, Type{
					Key: "person", Origin: vocabkey.OriginProvenencia, Label: "Person",
					RefPrefix: "PER", CandidateRefPrefix: "CPR",
				})
				if err != nil {
					t.Fatal(err)
				}
				second, err := upsert(c, Type{
					Key: "person", Origin: vocabkey.OriginProvenencia, Label: "Person",
					RefPrefix: "PER", CandidateRefPrefix: "CPR",
				})
				if err != nil {
					t.Fatal(err)
				}
				if string(first) != string(second) {
					t.Fatal("id changed")
				}
			},
		},
		{
			name: "reject empty key label",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := upsert(c, Type{Key: "", Origin: vocabkey.OriginProvenencia, Label: "X", RefPrefix: "AAA", CandidateRefPrefix: "BBB"}); !errors.Is(err, ErrInvalid) {
					t.Fatalf("empty key %v", err)
				}
				if _, err := upsert(c, Type{Key: "x", Origin: vocabkey.OriginProvenencia, Label: "", RefPrefix: "AAA", CandidateRefPrefix: "BBB"}); !errors.Is(err, ErrInvalid) {
					t.Fatalf("empty label %v", err)
				}
			},
		},
		{
			name: "reject user origin",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := upsert(c, Type{
					Key: "custom", Origin: "user", Label: "Custom",
					RefPrefix: "AAA", CandidateRefPrefix: "BBB",
				})
				if !errors.Is(err, ErrInvalid) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "accept plugin origin",
			run: func(t *testing.T, c *database.Catalog) {
				id, err := upsert(c, Type{
					Key: "dna_match", Origin: "plugin:example", Label: "DNA match",
					RefPrefix: "DNA", CandidateRefPrefix: "CDM",
				})
				if err != nil {
					t.Fatal(err)
				}
				got, err := Lookup(c, "dna_match", "plugin:example")
				if err != nil || string(got.ID) != string(id) {
					t.Fatalf("%+v %v", got, err)
				}
			},
		},
		{
			name: "reject reserved prefix",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := upsert(c, Type{
					Key: "bad", Origin: vocabkey.OriginProvenencia, Label: "Bad",
					RefPrefix: "SRC", CandidateRefPrefix: "BBB",
				})
				if !errors.Is(err, ref.ErrReservedPrefix) {
					t.Fatalf("got %v", err)
				}
				if apperr.From(err).Code() != apperr.CodeRefReservedPrefix {
					t.Fatalf("code %v", err)
				}
			},
		},
		{
			name: "reject same prefix on both columns",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := upsert(c, Type{
					Key: "dup", Origin: vocabkey.OriginProvenencia, Label: "Dup",
					RefPrefix: "ZZZ", CandidateRefPrefix: "zzz",
				})
				if !errors.Is(err, ErrDuplicatePrefix) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "reject cross-column collision with existing candidate",
			run: func(t *testing.T, c *database.Catalog) {
				if _, err := upsert(c, Type{
					Key: "person", Origin: vocabkey.OriginProvenencia, Label: "Person",
					RefPrefix: "PER", CandidateRefPrefix: "CPR",
				}); err != nil {
					t.Fatal(err)
				}
				_, err := upsert(c, Type{
					Key: "collide", Origin: vocabkey.OriginProvenencia, Label: "Collide",
					RefPrefix: "CPR", CandidateRefPrefix: "QQQ",
				})
				if !errors.Is(err, ErrDuplicatePrefix) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "get missing returns ErrNoRows",
			run: func(t *testing.T, c *database.Catalog) {
				_, err := GetByID(c, make([]byte, 16))
				if !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("got %v", err)
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := database.Create(t.TempDir(), "t.provenencia")
			if err != nil {
				t.Fatal(err)
			}
			defer c.Close()
			tt.run(t, c)
		})
	}
}

func TestUpsertTx(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	run := func(typ Type) ([]rowchange.Change, error) {
		var changes []rowchange.Change
		_, err := writes.Call(c, writes.Op{Action: "upsert_subject_type"}, func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			id, cs, err := UpsertTx(tx, typ)
			changes = cs
			return id, cs, err
		})
		return changes, err
	}
	keys := func(ch rowchange.Change) []string {
		var out []string
		for k := range ch.Fields {
			out = append(out, k)
		}
		sort.Strings(out)
		return out
	}
	person := Type{Key: "person", Origin: vocabkey.OriginProvenencia, Label: "Person", RefPrefix: "PER", CandidateRefPrefix: "PEC"}

	changes, err := run(person)
	if err != nil || len(changes) != 1 {
		t.Fatalf("create: %v %+v", err, changes)
	}
	if ch := changes[0]; ch.EntityType != "subject_type" || ch.Action != rowchange.ActionCreate ||
		!reflect.DeepEqual(keys(ch), []string{"candidate_ref_prefix", "id", "key", "label", "origin", "ref_prefix"}) ||
		ch.Fields["ref_prefix"].New != "PER" || ch.Fields["candidate_ref_prefix"].New != "PEC" {
		t.Fatalf("create change %+v", ch)
	}
	if changes, err = run(person); err != nil || len(changes) != 0 {
		t.Fatalf("same: %v %+v", err, changes)
	}
	renamed := person
	renamed.Label = "Individual"
	changes, err = run(renamed)
	if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionUpdate || !reflect.DeepEqual(keys(changes[0]), []string{"label"}) {
		t.Fatalf("label: %v %+v", err, changes)
	}

	for name, other := range map[string]Type{
		"ref prefix taken":       {Key: "a", Origin: vocabkey.OriginProvenencia, Label: "A", RefPrefix: "PER", CandidateRefPrefix: "AAC"},
		"candidate prefix taken": {Key: "b", Origin: vocabkey.OriginProvenencia, Label: "B", RefPrefix: "BBB", CandidateRefPrefix: "PEC"},
		"equal prefixes":         {Key: "c", Origin: vocabkey.OriginProvenencia, Label: "C", RefPrefix: "CCC", CandidateRefPrefix: "ccc"},
	} {
		if _, err := run(other); !errors.Is(err, ErrDuplicatePrefix) {
			t.Fatalf("%s: got %v", name, err)
		}
	}
	for name, bad := range map[string]Type{
		"bad prefix":   {Key: "d", Origin: vocabkey.OriginProvenencia, Label: "D", RefPrefix: "SRC", CandidateRefPrefix: "DDD"},
		"blank key":    {Origin: vocabkey.OriginProvenencia, Label: "E", RefPrefix: "EEE", CandidateRefPrefix: "EEC"},
		"bogus origin": {Key: "f", Origin: "bogus", Label: "F", RefPrefix: "FFF", CandidateRefPrefix: "FFC"},
		"non-empty ID": {ID: make([]byte, 16), Key: "g", Origin: vocabkey.OriginProvenencia, Label: "G", RefPrefix: "GGG", CandidateRefPrefix: "GGC"},
	} {
		if _, err := run(bad); err == nil {
			t.Fatalf("%s: want an error", name)
		}
	}
	if list, err := List(c); err != nil || len(list) != 1 {
		t.Fatalf("only person is stored: %v %+v", err, list)
	}
}
