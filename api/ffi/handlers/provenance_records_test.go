package handlers

import (
	"bytes"
	"testing"
	"time"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/catalogsession"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citationrender"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations/observationstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue/namevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
	"google.golang.org/protobuf/proto"
)

// researchedPerson is one Person promoted from sources Sources, each with
// perSource name records of the same value, every one its own Citation. It
// returns the project, the Person's handle and the name Property's id.
func researchedPerson(t *testing.T, sources, perSource int) (dir, entityID, namePropertyID string) {
	t.Helper()
	dir, userID, _, typeID := subjectFixture(t)
	uid := uuid.MustParse(userID)
	var subjectIDs []string
	for i := 0; i < sources; i++ {
		_, subjectID := namedPersonOnNewSource(t, dir, userID, typeID, "James Robins", "male", observations.PolarityPositive)
		subjectIDs = append(subjectIDs, subjectID)
	}
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		db, err := c.DB()
		if err != nil {
			return err
		}
		name, err := properties.Lookup(c, "name", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		for _, subjectID := range subjectIDs {
			subject := uuid.MustParse(subjectID)
			var sourceID, graphID []byte
			if err := db.QueryRow(`SELECT source_id, graph_id FROM subjects WHERE id = ?`, subject[:]).Scan(&sourceID, &graphID); err != nil {
				return err
			}
			art, err := artifactstest.Create(c, uid[:], artifacts.CreateInput{SourceID: sourceID, Label: "Page"})
			if err != nil {
				return err
			}
			for k := 1; k < perSource; k++ {
				if _, _, err := observationstest.Cite(c, uid[:], graphID, art.ID, depictionvaluetest.Locator, observations.Input{
					SubjectID: subject[:], PropertyID: name.ID, Name: namevaluetest.Western("James Robins"),
				}); err != nil {
					return err
				}
			}
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	handle := promoteInDir(t, dir, userID, subjectIDs[0], "")
	for _, subjectID := range subjectIDs[1:] {
		promoteInDir(t, dir, userID, subjectID, database.UUIDString(handle.Entity.ID))
	}
	return dir, database.UUIDString(handle.Entity.ID), propertyIDByKey(t, dir, "name")
}

func provenanceFields(owner, property string) *engine.GetProvenanceRecordsRequest_Fields {
	return &engine.GetProvenanceRecordsRequest_Fields{Fields: &engine.ProvenancePairs{
		Pairs: []*engine.ProvenancePair{{OwnerId: owner, PropertyId: property}},
	}}
}

// TestDetailPayloadWithoutRecords logs what the page read's records weigh: the
// payload S15-29 stops sending once the sheet loads them.
func TestDetailPayloadWithoutRecords(t *testing.T) {
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	dir, entityID, _ := researchedPerson(t, 30, 2)
	var d engine.ConclusionDetail
	mustRPC(t, GetConclusionDetail, &engine.GetConclusionDetailRequest{ProjectDir: dir, EntityId: entityID}, &d)
	with, err := proto.Marshal(&d)
	if err != nil {
		t.Fatal(err)
	}
	for _, f := range d.GetFields() {
		f.Outcomes = nil
	}
	for _, row := range d.GetDerivedRows() {
		for _, o := range row.GetOwners() {
			o.GetField().Outcomes = nil
		}
	}
	without, err := proto.Marshal(&d)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("detail payload: %d bytes with outcomes, %d bytes with every outcome cleared", len(with), len(without))
	if len(without) >= len(with) {
		t.Fatalf("clearing the outcomes did not shrink the payload: %d, %d", len(with), len(without))
	}
}

// TestProvenanceRecordsScale: one name field with 1,200 records, each its own
// Citation, over 30 Sources, reads within the budget warm.
func TestProvenanceRecordsScale(t *testing.T) {
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	dir, entityID, nameID := researchedPerson(t, 30, 40)
	req := &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: provenanceFields(entityID, nameID)}
	read := func() *engine.GetProvenanceRecordsResponse {
		var resp engine.GetProvenanceRecordsResponse
		mustRPC(t, GetProvenanceRecords, req, &resp)
		return &resp
	}
	resp := read()
	if len(resp.GetOwners()) != 1 || len(resp.GetOwners()[0].GetField().GetOutcomes()) != 1200 || len(resp.GetCitations()) != 1200 {
		t.Fatalf("%d owners, %d outcomes, %d citations", len(resp.GetOwners()), len(resp.GetOwners()[0].GetField().GetOutcomes()), len(resp.GetCitations()))
	}
	databasetest.WithinBudget(t, "1200 records", databasetest.Warm(func() { read() }), 600*time.Millisecond)
}

func TestGetProvenanceRecords(t *testing.T) {
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	runRPC(t, GetProvenanceRecords, []rpcTest{
		{name: "bad proto", raw: []byte{0xff}, wantErr: true},
		{
			name: "a name field with its records and their citation",
			reqFn: func(t *testing.T) proto.Message {
				dir, id := namedPersonID(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: provenanceFields(id, propertyIDByKey(t, dir, "name"))}
			},
			after: func(t *testing.T, out []byte, req proto.Message) {
				var got engine.GetProvenanceRecordsResponse
				if err := proto.Unmarshal(out, &got); err != nil {
					t.Fatal(err)
				}
				owner := req.(*engine.GetProvenanceRecordsRequest).GetFields().GetPairs()[0].GetOwnerId()
				if len(got.GetOwners()) != 1 {
					t.Fatalf("owners %+v", got.GetOwners())
				}
				o := got.GetOwners()[0]
				f := o.GetField()
				if o.GetEntity().GetId() != owner || o.GetEvent() != nil || o.GetPlace() != nil || f.GetPropertyKey() != "name" ||
					len(f.GetValues()) != 1 || len(f.GetOutcomes()) != 2 ||
					f.GetRecordCounts().GetRecords() != 2 || f.GetRecordCounts().GetSources() != 1 {
					t.Fatalf("owner %+v", o)
				}
				if len(got.GetCitations()) != 1 || got.GetCitations()[0].GetCitationId() != f.GetOutcomes()[0].GetCitationId() ||
					f.GetOutcomes()[0].GetCitationId() != f.GetOutcomes()[1].GetCitationId() {
					t.Fatalf("citations %+v", got.GetCitations())
				}
				var graphs, srcs []string
				for _, out := range f.GetOutcomes() {
					graphs, srcs = append(graphs, out.GetGraphId()), append(srcs, out.GetSourceId())
				}
				wantInputs(t, got.GetInputs(), []string{owner}, graphs, srcs)
			},
		},
		{
			name: "a Person's birth date row",
			reqFn: func(t *testing.T) proto.Message {
				dir, person, _ := derivedRowsFixture(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: &engine.GetProvenanceRecordsRequest_Derived{
					Derived: &engine.ProvenanceDerivedRow{PersonId: database.UUIDString(person.Entity.ID), Kind: engine.DerivedRowKind_DERIVED_ROW_KIND_BIRTH_DATE},
				}}
			},
			after: func(t *testing.T, out []byte, req proto.Message) {
				var got engine.GetProvenanceRecordsResponse
				if err := proto.Unmarshal(out, &got); err != nil {
					t.Fatal(err)
				}
				if len(got.GetOwners()) != 1 {
					t.Fatalf("owners %+v", got.GetOwners())
				}
				o := got.GetOwners()[0]
				if o.GetEvent().GetEntity().GetId() != o.GetEntity().GetId() || len(o.GetField().GetOutcomes()) != 2 || len(got.GetCitations()) != 2 {
					t.Fatalf("owner %+v, %d citations", o, len(got.GetCitations()))
				}
				person := req.(*engine.GetProvenanceRecordsRequest).GetDerived().GetPersonId()
				wantInputs(t, got.GetInputs(), []string{person, o.GetEntity().GetId()}, nil, nil)
			},
		},
		{
			name: "an unspecified kind answers no owners",
			reqFn: func(t *testing.T) proto.Message {
				dir, person, _ := derivedRowsFixture(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: &engine.GetProvenanceRecordsRequest_Derived{
					Derived: &engine.ProvenanceDerivedRow{PersonId: database.UUIDString(person.Entity.ID)},
				}}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) { noOwners(t, out) },
		},
		{
			name: "no row answers no owners",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) { noOwners(t, out) },
		},
		{
			name: "an unknown owner answers no owners",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: provenanceFields("00000000-0000-7000-8000-000000000001", propertyIDByKey(t, dir, "name"))}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) { noOwners(t, out) },
		},
		{
			name: "a malformed owner id",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: provenanceFields("nope", propertyIDByKey(t, dir, "name"))}
			},
			wantErr: true, wantErrIs: errInvalidID,
		},
		{
			name: "a malformed Property id",
			reqFn: func(t *testing.T) proto.Message {
				dir, id := namedPersonID(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: provenanceFields(id, "nope")}
			},
			wantErr: true, wantErrIs: errInvalidID,
		},
		{
			name: "a malformed Person id",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: &engine.GetProvenanceRecordsRequest_Derived{
					Derived: &engine.ProvenanceDerivedRow{PersonId: "nope", Kind: engine.DerivedRowKind_DERIVED_ROW_KIND_BIRTH_DATE},
				}}
			},
			wantErr: true, wantErrIs: errInvalidID,
		},
	})
}

func noOwners(t *testing.T, out []byte) {
	t.Helper()
	var got engine.GetProvenanceRecordsResponse
	if err := proto.Unmarshal(out, &got); err != nil {
		t.Fatal(err)
	}
	if len(got.GetOwners()) != 0 || len(got.GetCitations()) != 0 {
		t.Fatalf("answered %+v", &got)
	}
}

// TestGetProvenanceRecordsWarmReadsNoRecordSQL: a second read answers the same
// bytes, queries no graph, and prepares only what rendering the same Citations
// prepares.
func TestGetProvenanceRecordsWarmReadsNoRecordSQL(t *testing.T) {
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	dir, id := namedPersonID(t)
	req := marshalProto(t, &engine.GetProvenanceRecordsRequest{ProjectDir: dir, Row: provenanceFields(id, propertyIDByKey(t, dir, "name"))})
	first, err := GetProvenanceRecords(req)
	if err != nil {
		t.Fatal(err)
	}
	var sel *databasetest.Selects
	var graphQueries int
	if err := catalogsession.Do(dir, func(c *database.Catalog) error {
		sel = databasetest.CountSelects(t, c)
		c.Graph().SetQueryCounterForTest(func() { graphQueries++ })
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	second, err := GetProvenanceRecords(req)
	if err != nil {
		t.Fatal(err)
	}
	var got engine.GetProvenanceRecordsResponse
	if err := proto.Unmarshal(second, &got); err != nil {
		t.Fatal(err)
	}
	readSelects := sel.N()
	sel.Reset()
	if err := catalogsession.Do(dir, func(c *database.Catalog) error {
		var ids [][]byte
		for _, rc := range got.GetCitations() {
			u := uuid.MustParse(rc.GetCitationId())
			ids = append(ids, u[:])
		}
		_, err := citationrender.Render(c, ids, c.Graph().PageInputs())
		return err
	}); err != nil {
		t.Fatal(err)
	}
	if len(got.GetCitations()) == 0 {
		t.Fatal("no Citations rendered")
	}
	if renderSelects := sel.N(); readSelects != renderSelects {
		t.Errorf("a warm read prepared %d SELECTs, rendering its Citations alone %d", readSelects, renderSelects)
	}
	if graphQueries != 0 {
		t.Errorf("a warm read issued %d graph queries", graphQueries)
	}
	if !bytes.Equal(first, second) {
		t.Error("the second read answers other bytes")
	}
}
