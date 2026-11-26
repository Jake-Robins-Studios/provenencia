package handlers

import (
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/catalogsession"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/canonicalentities"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations/observationstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/promote"
	"github.com/Jake-Robins-Studios/provenencia/core/database/promote/promotetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/propertyterms"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects/subjectstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/eventtitle"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue/namevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"github.com/google/uuid"
	"google.golang.org/protobuf/proto"
)

// namedPerson promotes a person Subject with two disagreeing name
// Observations and returns the project dir and the handle ref.
func namedPerson(t *testing.T) (dir, handleRef string) {
	t.Helper()
	dir, userIDStr, subjectIDStr := promotableSubject(t)
	subjectID, userID := uuid.MustParse(subjectIDStr), uuid.MustParse(userIDStr)
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		name, err := properties.Lookup(c, "name", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		var sourceID, graphID []byte
		db, err := c.DB()
		if err != nil {
			return err
		}
		if err := db.QueryRow(`SELECT source_id, graph_id FROM subjects WHERE id = ?`, subjectID[:]).Scan(&sourceID, &graphID); err != nil {
			return err
		}
		art, err := artifactstest.Create(c, userID[:], artifacts.CreateInput{SourceID: sourceID, Label: "Scan"})
		if err != nil {
			return err
		}
		_, _, err = observationstest.Cite(c, userID[:], graphID, art.ID, depictionvaluetest.Locator, []observations.Input{
			{SubjectID: subjectID[:], PropertyID: name.ID, Name: &namevalue.Value{Form: "James Robins", Parts: []namevalue.Part{
				{Idx: 0, Value: "James", Type: namevalue.PartTypeGiven}, {Idx: 1, Value: "Robins", Type: namevalue.PartTypeSurname},
			}}},
			{SubjectID: subjectID[:], PropertyID: name.ID, Name: namevaluetest.Western("Kenneth Robins")},
		}...)
		return err
	}); err != nil {
		t.Fatal(err)
	}
	return dir, promoteInDir(t, dir, userIDStr, subjectIDStr, "").Entity.Ref
}

func TestListPersonSummaries(t *testing.T) {
	runRPC(t, ListPersonSummaries, []rpcTest{
		{name: "bad proto", raw: []byte{0xff}, wantErr: true},
		{
			name: "empty project lists nothing",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.ListPersonSummariesRequest{ProjectDir: dir}
			},
			want:  &engine.ListPersonSummariesResponse{},
			exact: true,
		},
		{
			name: "promoted Person carries its auto-reconciled name and value count",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := namedPerson(t)
				return &engine.ListPersonSummariesRequest{ProjectDir: dir}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) {
				var resp engine.ListPersonSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Summaries) != 1 {
					t.Fatalf("%+v", resp.Summaries)
				}
				h := resp.Summaries[0]
				// James Robins + Kenneth Robins reconcile into one name (S9-13b).
				if !strings.HasPrefix(h.Entity.GetRef(), "PER-") || h.GetNameValueCount() != 1 {
					t.Fatalf("%+v", h)
				}
				if h.GetUpdatedRevision() <= 0 || h.GetUpdatedAt() == "" {
					t.Fatalf("updated %d %q", h.GetUpdatedRevision(), h.GetUpdatedAt())
				}
				if h.GetPictureImageRelPath() != "" {
					t.Fatalf("picture path %q on a person without one", h.GetPictureImageRelPath())
				}
				n := h.GetName()
				if n.GetForm() != "James Kenneth Robins" || len(n.GetParts()) != 3 || n.GetParts()[2].GetType() != namevalue.PartTypeSurname {
					t.Fatalf("name %+v", n)
				}
			},
		},
		{
			name: "every row carries a list key in list order",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := namedPerson(t)
				return &engine.ListPersonSummariesRequest{ProjectDir: dir}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) {
				var resp engine.ListPersonSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Summaries) == 0 {
					t.Fatal("no rows")
				}
				for i, h := range resp.Summaries {
					if h.GetListKey().GetRef() == "" || strings.ToLower(h.GetEntity().GetRef()) != h.GetListKey().GetRef() {
						t.Fatalf("row %d: list key %+v", i, h.GetListKey())
					}
					if i > 0 && !listKeyBefore(resp.Summaries[i-1].GetListKey(), h.GetListKey()) {
						t.Fatalf("keys do not increase at row %d", i)
					}
				}
			},
		},
		{
			name: "filtered to one person",
			reqFn: func(t *testing.T) proto.Message {
				dir, id := namedPersonID(t)
				return &engine.ListPersonSummariesRequest{ProjectDir: dir, EntityIds: []string{id, uuid.Must(uuid.NewV7()).String()}}
			},
			after: func(t *testing.T, out []byte, req proto.Message) {
				var resp engine.ListPersonSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Summaries) != 1 {
					t.Fatalf("%+v", resp.Summaries)
				}
				dir := req.(*engine.ListPersonSummariesRequest).GetProjectDir()
				raw, err := ListPersonSummaries(marshalProto(t, &engine.ListPersonSummariesRequest{ProjectDir: dir}))
				if err != nil {
					t.Fatal(err)
				}
				var all engine.ListPersonSummariesResponse
				if err := proto.Unmarshal(raw, &all); err != nil {
					t.Fatal(err)
				}
				if len(all.Summaries) != 1 || !proto.Equal(all.Summaries[0], resp.Summaries[0]) || resp.Summaries[0].GetListKey().GetRef() == "" {
					t.Fatalf("filtered %+v, whole %+v", resp.Summaries, all.Summaries)
				}
			},
		},
		{
			name: "a malformed id is an error",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := namedPerson(t)
				return &engine.ListPersonSummariesRequest{ProjectDir: dir, EntityIds: []string{"not-an-id"}}
			},
			wantErr: true,
		},
		{
			name: "a Person with a likeness carries its image path",
			reqFn: func(t *testing.T) proto.Message {
				dir, userID, _, artifactID, personID, likenessID := likenessFixture(t)
				saveLikeness(t, dir, userID, artifactID, personID, likenessID, writeCrop(t, 300, 200, 128))
				promoteInDir(t, dir, userID, personID, "")
				return &engine.ListPersonSummariesRequest{ProjectDir: dir}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) {
				var resp engine.ListPersonSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Summaries) != 1 {
					t.Fatalf("%+v", resp.Summaries)
				}
				if p := resp.Summaries[0].GetPictureImageRelPath(); !objectPathPattern.MatchString(p) || !strings.HasSuffix(p, ".png") {
					t.Fatalf("picture path %q", p)
				}
			},
		},
	})
}

func namedPersonID(t *testing.T) (dir, id string) {
	t.Helper()
	dir, ref := namedPerson(t)
	raw, err := ListPersonSummaries(marshalProto(t, &engine.ListPersonSummariesRequest{ProjectDir: dir}))
	if err != nil {
		t.Fatal(err)
	}
	var resp engine.ListPersonSummariesResponse
	if err := proto.Unmarshal(raw, &resp); err != nil {
		t.Fatal(err)
	}
	for _, h := range resp.GetSummaries() {
		if h.GetEntity().GetRef() == ref {
			return dir, h.GetEntity().GetId()
		}
	}
	t.Fatalf("no summary for %s", ref)
	return "", ""
}

func TestListEventSummaries(t *testing.T) {
	runRPC(t, ListEventSummaries, []rpcTest{
		{name: "bad proto", raw: []byte{0xff}, wantErr: true},
		{
			name: "empty project lists nothing",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.ListEventSummariesRequest{ProjectDir: dir}
			},
			want:  &engine.ListEventSummariesResponse{},
			exact: true,
		},
		{
			name: "promoted Event carries its name, type, and date",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := citedEvent(t)
				return &engine.ListEventSummariesRequest{ProjectDir: dir}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) {
				var resp engine.ListEventSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Summaries) != 1 {
					t.Fatalf("%+v", resp.Summaries)
				}
				h := resp.Summaries[0]
				if !strings.HasPrefix(h.Entity.GetRef(), "EVT-") || h.GetEventName() != "The Great Fire" || h.GetEventNameCount() != 1 {
					t.Fatalf("%+v", h)
				}
				if h.GetUpdatedRevision() <= 0 || h.GetUpdatedAt() == "" {
					t.Fatalf("updated %d %q", h.GetUpdatedRevision(), h.GetUpdatedAt())
				}
				if h.GetEventType().GetKey() != "birth" || h.GetEventType().GetLabel() != "Birth" {
					t.Fatalf("type %v", h.GetEventType())
				}
				if d := h.GetDating(); d.GetKind() != engine.EventDatingKind_EVENT_DATING_KIND_OCCURRENCE || d.GetLow().GetStartYear() != 1849 || d.GetHigh() != nil || d.GetOpenLow() || d.GetOpenHigh() {
					t.Fatalf("dating %v", d)
				}
			},
		},
		{
			name: "filtered to one event",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := citedEvent(t)
				all := listedEvents(t, &engine.ListEventSummariesRequest{ProjectDir: dir})
				return &engine.ListEventSummariesRequest{ProjectDir: dir, EntityIds: []string{all[0].GetEntity().GetId(), uuid.Must(uuid.NewV7()).String()}}
			},
			after: func(t *testing.T, out []byte, req proto.Message) {
				var resp engine.ListEventSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				whole := listedEvents(t, &engine.ListEventSummariesRequest{ProjectDir: req.(*engine.ListEventSummariesRequest).GetProjectDir()})
				if len(resp.Summaries) != 1 || len(whole) != 1 || !proto.Equal(whole[0], resp.Summaries[0]) || resp.Summaries[0].GetListKey().GetLast() || len(resp.Summaries[0].GetListKey().GetPrimary()) != 8 {
					t.Fatalf("filtered %+v, whole %+v", resp.Summaries, whole)
				}
			},
		},
	})
}

// citedEvent promotes an event with a recorded name, a birth type, and a date.
func citedEvent(t *testing.T) (dir, entityID string) {
	t.Helper()
	dir, user, sourceID, _ := subjectFixture(t)
	userID, err := uuid.Parse(user)
	if err != nil {
		t.Fatal(err)
	}
	source, err := uuid.Parse(sourceID)
	if err != nil {
		t.Fatal(err)
	}
	var subjectID []byte
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		graph := evidencegraphstest.SoleGraph(t, c, source[:]).ID
		s := subjectstest.On(t, c, userID[:], graph, "event", "")
		subjectID = s.ID
		name, err := properties.Lookup(c, "event_name", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		eventType, err := properties.Lookup(c, "event_type", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		term, err := propertyterms.Lookup(c, eventType.ID, "birth", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		dateProp, err := properties.Lookup(c, "date", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		art, err := artifactstest.Create(c, userID[:], artifacts.CreateInput{SourceID: source[:], Label: "Scan"})
		if err != nil {
			return err
		}
		_, _, err = observationstest.Cite(c, userID[:], s.GraphID, art.ID, depictionvaluetest.Locator, []observations.Input{
			{SubjectID: s.ID, PropertyID: name.ID, Scalar: propertymeta.TextScalar("The Great Fire")},
			{SubjectID: s.ID, PropertyID: eventType.ID, ValueTermID: term.ID},
			{SubjectID: s.ID, PropertyID: dateProp.ID, Date: datevaluetest.YMD(1849, 0, 0)},
		}...)
		if err != nil {
			return err
		}
		p := promotetest.Save(t, c, userID[:], promote.Input{SubjectID: subjectID})
		entityID = database.UUIDString(p.Entity.ID)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	return dir, entityID
}

func TestListPlaceSummaries(t *testing.T) {
	runRPC(t, ListPlaceSummaries, []rpcTest{
		{name: "bad proto", raw: []byte{0xff}, wantErr: true},
		{
			name: "empty project lists nothing",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.ListPlaceSummariesRequest{ProjectDir: dir}
			},
			want:  &engine.ListPlaceSummariesResponse{},
			exact: true,
		},
		{
			name: "promoted Place carries every kept toponym",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := citedPlace(t)
				return &engine.ListPlaceSummariesRequest{ProjectDir: dir}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) {
				var resp engine.ListPlaceSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Summaries) != 1 || len(resp.Summaries[0].GetNames()) != 2 ||
					resp.Summaries[0].GetNames()[0] != "York" || resp.Summaries[0].GetNames()[1] != "Toronto" ||
					resp.Summaries[0].GetKind() != "" || len(resp.Summaries[0].GetParents()) != 0 ||
					resp.Summaries[0].GetStartDate() != nil || resp.Summaries[0].GetEndDate() != nil {
					t.Fatalf("%+v", resp.Summaries)
				}
				if h := resp.Summaries[0]; h.GetUpdatedRevision() <= 0 || h.GetUpdatedAt() == "" {
					t.Fatalf("updated %d %q", h.GetUpdatedRevision(), h.GetUpdatedAt())
				}
			},
		},
		{
			name: "filtered to one place",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := citedPlace(t)
				all := listedPlaces(t, &engine.ListPlaceSummariesRequest{ProjectDir: dir})
				return &engine.ListPlaceSummariesRequest{ProjectDir: dir, EntityIds: []string{all[0].GetEntity().GetId(), uuid.Must(uuid.NewV7()).String()}}
			},
			after: func(t *testing.T, out []byte, req proto.Message) {
				var resp engine.ListPlaceSummariesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				whole := listedPlaces(t, &engine.ListPlaceSummariesRequest{ProjectDir: req.(*engine.ListPlaceSummariesRequest).GetProjectDir()})
				if len(resp.Summaries) != 1 || len(whole) != 1 || !proto.Equal(whole[0], resp.Summaries[0]) || len(resp.Summaries[0].GetListKey().GetPrimary()) == 0 {
					t.Fatalf("filtered %+v, whole %+v", resp.Summaries, whole)
				}
			},
		},
	})
}

// citedPlace promotes a Place named York and Toronto.
func citedPlace(t *testing.T) (dir, entityID string) {
	t.Helper()
	dir, user, sourceID, _ := subjectFixture(t)
	userID, err := uuid.Parse(user)
	if err != nil {
		t.Fatal(err)
	}
	source, err := uuid.Parse(sourceID)
	if err != nil {
		t.Fatal(err)
	}
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		graph := evidencegraphstest.SoleGraph(t, c, source[:]).ID
		s := subjectstest.On(t, c, userID[:], graph, "place", "")
		toponym, err := properties.Lookup(c, "toponym", vocabkey.OriginProvenencia)
		if err != nil {
			return err
		}
		art, err := artifactstest.Create(c, userID[:], artifacts.CreateInput{SourceID: source[:], Label: "Scan"})
		if err != nil {
			return err
		}
		_, _, err = observationstest.Cite(c, userID[:], s.GraphID, art.ID, depictionvaluetest.Locator, []observations.Input{
			{SubjectID: s.ID, PropertyID: toponym.ID, Scalar: propertymeta.TextScalar("York")},
			{SubjectID: s.ID, PropertyID: toponym.ID, Scalar: propertymeta.TextScalar("Toronto")},
		}...)
		if err != nil {
			return err
		}
		p := promotetest.Save(t, c, userID[:], promote.Input{SubjectID: s.ID})
		entityID = database.UUIDString(p.Entity.ID)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	return dir, entityID
}

func TestWorkspaceNavCountsConclusionHandles(t *testing.T) {
	dir, _ := namedPerson(t)
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	// One event and two place handles, minted directly: the count is of
	// handles, whatever their members.
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		db, err := c.DB()
		if err != nil {
			return err
		}
		var userID []byte
		if err := db.QueryRow(`SELECT id FROM users LIMIT 1`).Scan(&userID); err != nil {
			return err
		}
		for _, key := range []string{"event", "place", "place"} {
			st, err := subjecttypes.Lookup(c, key, vocabkey.OriginProvenencia)
			if err != nil {
				return err
			}
			if _, err := writes.Call(c, writes.Op{Action: "create_canonical_entity", UserID: userID}, func(tx *database.Tx) (canonicalentities.Entity, []rowchange.Change, error) {
				return canonicalentities.Create(tx, userID, canonicalentities.CreateInput{SubjectTypeID: st.ID})
			}); err != nil {
				return err
			}
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	out, err := GetWorkspaceNavCounts(marshalProto(t, &engine.GetWorkspaceNavCountsRequest{ProjectDir: dir}))
	if err != nil {
		t.Fatal(err)
	}
	var resp engine.GetWorkspaceNavCountsResponse
	if err := proto.Unmarshal(out, &resp); err != nil {
		t.Fatal(err)
	}
	if resp.GetPersons() != 1 || resp.GetEvents() != 1 || resp.GetPlaces() != 2 {
		t.Fatalf("persons %d events %d places %d", resp.GetPersons(), resp.GetEvents(), resp.GetPlaces())
	}
}

func TestListSubjectMembershipsCarriesAutoReconciledName(t *testing.T) {
	dir, ref := namedPerson(t)
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	var sourceID string
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		db, err := c.DB()
		if err != nil {
			return err
		}
		var id []byte
		if err := db.QueryRow(`SELECT source_id FROM subjects LIMIT 1`).Scan(&id); err != nil {
			return err
		}
		sourceID = database.UUIDString(id)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	out, err := ListSubjectMemberships(marshalProto(t, &engine.ListSubjectMembershipsRequest{ProjectDir: dir, GraphId: soleGraphID(t, dir, sourceID)}))
	if err != nil {
		t.Fatal(err)
	}
	var resp engine.ListSubjectMembershipsResponse
	if err := proto.Unmarshal(out, &resp); err != nil {
		t.Fatal(err)
	}
	if len(resp.Memberships) != 1 || resp.Memberships[0].Entity.GetRef() != ref ||
		resp.Memberships[0].GetName().GetForm() != "James Kenneth Robins" {
		t.Fatalf("%+v", resp.Memberships)
	}
}

func TestLifeFactsProtoCarriesIdentities(t *testing.T) {
	event := canonicalentities.Entity{ID: mustUUIDBytes(t), Ref: "EVT-1"}
	place := canonicalentities.Entity{ID: mustUUIDBytes(t), Ref: "PLC-1", Label: "York"}
	tests := []struct {
		name      string
		in        conclusionsummaries.LifeFacts
		wantEvent string
		wantPlace string
	}{
		{name: "no event linked", in: conclusionsummaries.LifeFacts{}},
		{
			name: "event and place",
			in: conclusionsummaries.LifeFacts{
				Event:  &event,
				Places: []conclusionsummaries.ChainedPlace{{Entity: place, Names: []string{"York"}}},
			},
			wantEvent: "EVT-1",
			wantPlace: "PLC-1",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := lifeFactsProto(tt.in)
			if got.GetEvent().GetRef() != tt.wantEvent {
				t.Fatalf("event %+v", got.GetEvent())
			}
			if tt.wantEvent != "" && got.GetEvent().GetId() != database.UUIDString(event.ID) {
				t.Fatalf("event id %q", got.GetEvent().GetId())
			}
			var placeRef string
			if len(got.GetPlaces()) > 0 {
				placeRef = got.GetPlaces()[0].GetEntity().GetRef()
			}
			if placeRef != tt.wantPlace {
				t.Fatalf("place %+v", got.GetPlaces())
			}
		})
	}
}

func TestSummaryProtosCarryTerms(t *testing.T) {
	termID := mustUUIDBytes(t)
	t.Run("person", func(t *testing.T) {
		got := personSummaryProto(conclusionsummaries.PersonSummary{
			Gender: conclusionsummaries.TermFacts{
				Term:  &conclusionsummaries.Term{ID: termID, Key: "woman", Origin: "provenencia", Label: "Woman"},
				Count: 1, PropertyLabel: "Gender",
			},
		}, nil)
		g := got.GetGender()
		if g.GetTerm().GetId() != database.UUIDString(termID) || g.GetTerm().GetKey() != "woman" || g.GetTerm().GetLabel() != "Woman" || g.GetTerm().GetOrigin() != "provenencia" || g.GetCount() != 1 || g.GetPropertyLabel() != "Gender" {
			t.Fatalf("gender %+v", g)
		}
		if got.GetSexAtBirth() == nil || got.GetSexAtBirth().GetTerm() != nil || got.GetSexAtBirth().GetCount() != 0 {
			t.Fatalf("sex at birth %+v", got.GetSexAtBirth())
		}
	})
	t.Run("event type", func(t *testing.T) {
		got := eventSummaryProto(conclusionsummaries.EventSummary{Type: conclusionsummaries.TermFacts{
			Term:  &conclusionsummaries.Term{ID: termID, Key: "birth", Origin: "provenencia", Label: "Birth"},
			Count: 2,
		}}, nil)
		if et := got.GetEventType(); et.GetKey() != "birth" || et.GetLabel() != "Birth" || et.GetOrigin() != "provenencia" || got.GetEventTypeCount() != 2 {
			t.Fatalf("event type %+v count %d", et, got.GetEventTypeCount())
		}
		if bare := eventSummaryProto(conclusionsummaries.EventSummary{}, nil); bare.GetEventType() != nil {
			t.Fatalf("event type %+v", bare.GetEventType())
		}
	})
}

func mustUUIDBytes(t *testing.T) []byte {
	t.Helper()
	id := uuid.Must(uuid.NewV7())
	return id[:]
}

func eventSourceID(t *testing.T, dir string) string {
	t.Helper()
	var sourceID string
	if err := withProjectCatalog(dir, func(c *database.Catalog) error {
		db, err := c.DB()
		if err != nil {
			return err
		}
		var id []byte
		if err := db.QueryRow(`SELECT s.source_id FROM subjects s
			JOIN subject_types st ON st.id = s.subject_type_id AND st.key = 'event' LIMIT 1`).Scan(&id); err != nil {
			return err
		}
		sourceID = database.UUIDString(id)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	return sourceID
}

func TestEventTitlesUseOneRule(t *testing.T) {
	t.Run("an Event summary carries its chosen title", func(t *testing.T) {
		dir, _ := citedEvent(t)
		t.Cleanup(func() { _ = catalogsession.CloseAll() })
		out, err := ListEventSummaries(marshalProto(t, &engine.ListEventSummariesRequest{ProjectDir: dir}))
		if err != nil {
			t.Fatal(err)
		}
		var resp engine.ListEventSummariesResponse
		if err := proto.Unmarshal(out, &resp); err != nil {
			t.Fatal(err)
		}
		title := resp.GetSummaries()[0].GetTitle()
		if title.GetRule() != engine.EventTitleRule_EVENT_TITLE_RULE_RECORDED_NAME || title.GetRecordedName() != "The Great Fire" ||
			title.GetTypeKey() != "birth" || !strings.HasPrefix(title.GetRef(), "EVT-") {
			t.Fatalf("%+v", title)
		}
	})
	runRPC(t, ListEvidenceGraphEventTitles, []rpcTest{
		{name: "bad proto", raw: []byte{0xff}, wantErr: true},
		{
			name: "bad source id",
			reqFn: func(t *testing.T) proto.Message {
				dir, _, _, _ := subjectFixture(t)
				return &engine.ListEvidenceGraphEventTitlesRequest{ProjectDir: dir, GraphId: "nope"}
			},
			wantErr: true,
		},
		{
			name: "the Source's Event card is titled by the same rule",
			reqFn: func(t *testing.T) proto.Message {
				dir, _ := citedEvent(t)
				return &engine.ListEvidenceGraphEventTitlesRequest{ProjectDir: dir, GraphId: soleGraphID(t, dir, eventSourceID(t, dir))}
			},
			after: func(t *testing.T, out []byte, _ proto.Message) {
				var resp engine.ListEvidenceGraphEventTitlesResponse
				if err := proto.Unmarshal(out, &resp); err != nil {
					t.Fatal(err)
				}
				if len(resp.Titles) != 1 || resp.Titles[0].GetSubjectId() == "" {
					t.Fatalf("%+v", resp.Titles)
				}
				title := resp.Titles[0].GetTitle()
				if title.GetRule() != engine.EventTitleRule_EVENT_TITLE_RULE_RECORDED_NAME || title.GetRecordedName() != "The Great Fire" {
					t.Fatalf("%+v", title)
				}
			},
		},
	})
}

// A user event type keyed like a product one crosses with its origin, so the
// app never reads it as the product's.
func TestEventTitleProtoCarriesTheTypeOrigin(t *testing.T) {
	got := eventTitleProto(eventtitle.Choose(eventtitle.Parts{TypeKey: "birth", TypeOrigin: "user", TypeLabel: "Arrival"}))
	if got.GetTypeKey() != "birth" || got.GetTypeOrigin() != "user" {
		t.Fatalf("type = %q (%q)", got.GetTypeKey(), got.GetTypeOrigin())
	}
}

// listKeyBefore is whether a sorts before b on the wire.
func listKeyBefore(a, b *engine.ListKey) bool {
	return conclusionsummaries.ListKey{Last: a.GetLast(), Primary: a.GetPrimary(), Ref: a.GetRef()}.
		Less(conclusionsummaries.ListKey{Last: b.GetLast(), Primary: b.GetPrimary(), Ref: b.GetRef()})
}

func listedEvents(t *testing.T, req *engine.ListEventSummariesRequest) []*engine.EventSummary {
	t.Helper()
	raw, err := ListEventSummaries(marshalProto(t, req))
	if err != nil {
		t.Fatal(err)
	}
	var resp engine.ListEventSummariesResponse
	if err := proto.Unmarshal(raw, &resp); err != nil {
		t.Fatal(err)
	}
	return resp.Summaries
}

func listedPlaces(t *testing.T, req *engine.ListPlaceSummariesRequest) []*engine.PlaceSummary {
	t.Helper()
	raw, err := ListPlaceSummaries(marshalProto(t, req))
	if err != nil {
		t.Fatal(err)
	}
	var resp engine.ListPlaceSummariesResponse
	if err := proto.Unmarshal(raw, &resp); err != nil {
		t.Fatal(err)
	}
	return resp.Summaries
}

func TestEventDatingPropertiesProto(t *testing.T) {
	d, st, en, as := "date", "start_date", "end_date", "as_of"
	type pr struct {
		key  string
		role engine.EventDatingRole
	}
	occ, start := engine.EventDatingRole_EVENT_DATING_ROLE_OCCURRENCE, engine.EventDatingRole_EVENT_DATING_ROLE_START
	end, asOf := engine.EventDatingRole_EVENT_DATING_ROLE_END, engine.EventDatingRole_EVENT_DATING_ROLE_AS_OF
	cases := []struct {
		name string
		in   []conclusionsummaries.DatingProperty
		want []pr
	}{
		{"an occurrence", []conclusionsummaries.DatingProperty{{Key: vocabkey.PropertyKey(d), Role: conclusionsummaries.DatingRoleOccurrence}}, []pr{{d, occ}}},
		{"a span", []conclusionsummaries.DatingProperty{{Key: vocabkey.PropertyKey(st), Role: conclusionsummaries.DatingRoleStart}, {Key: vocabkey.PropertyKey(en), Role: conclusionsummaries.DatingRoleEnd}}, []pr{{st, start}, {en, end}}},
		{"as-ofs", []conclusionsummaries.DatingProperty{{Key: vocabkey.PropertyKey(st), Role: conclusionsummaries.DatingRoleStart}, {Key: vocabkey.PropertyKey(as), Role: conclusionsummaries.DatingRoleAsOf}, {Key: vocabkey.PropertyKey(en), Role: conclusionsummaries.DatingRoleEnd}}, []pr{{st, start}, {as, asOf}, {en, end}}},
		{"undated", []conclusionsummaries.DatingProperty{{Key: vocabkey.PropertyKey(d), Role: conclusionsummaries.DatingRoleOccurrence}, {Key: vocabkey.PropertyKey(st), Role: conclusionsummaries.DatingRoleStart}, {Key: vocabkey.PropertyKey(en), Role: conclusionsummaries.DatingRoleEnd}, {Key: vocabkey.PropertyKey(as), Role: conclusionsummaries.DatingRoleAsOf}}, []pr{{d, occ}, {st, start}, {en, end}, {as, asOf}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := eventSummaryProto(conclusionsummaries.EventSummary{DatingProperties: tc.in}, nil).GetDatingProperties()
			if len(got) != len(tc.want) {
				t.Fatalf("%d properties, want %d", len(got), len(tc.want))
			}
			for i, w := range tc.want {
				if got[i].GetPropertyKey() != w.key || got[i].GetRole() != w.role {
					t.Fatalf("property %d = %v, want %v", i, got[i], w)
				}
			}
		})
	}
}

func TestEventDatingProto(t *testing.T) {
	ymd := datevaluetest.YMD
	cases := []struct {
		name string
		in   valuecompare.Dating
		want engine.EventDatingKind
	}{
		{"none", valuecompare.Dating{}, engine.EventDatingKind_EVENT_DATING_KIND_UNSPECIFIED},
		{"an occurrence", valuecompare.DatingOf(ymd(1849, 0, 0), nil, nil, nil), engine.EventDatingKind_EVENT_DATING_KIND_OCCURRENCE},
		{"a span", valuecompare.DatingOf(nil, ymd(1985, 0, 0), ymd(2015, 0, 0), nil), engine.EventDatingKind_EVENT_DATING_KIND_SPAN},
		{"as-ofs", valuecompare.DatingOf(nil, nil, nil, []datevalue.Value{*ymd(1990, 1, 10), *ymd(2015, 2, 10)}), engine.EventDatingKind_EVENT_DATING_KIND_AS_OF},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := eventDatingProto(tc.in)
			if got.GetKind() != tc.want || (tc.in.Low == nil) != (got.GetLow() == nil) || (tc.in.High == nil) != (got.GetHigh() == nil) ||
				got.GetOpenLow() != tc.in.OpenLow || got.GetOpenHigh() != tc.in.OpenHigh {
				t.Fatalf("eventDatingProto = %v, want kind %v of %+v", got, tc.want, tc.in)
			}
		})
	}
	as := eventDatingProto(valuecompare.DatingOf(nil, nil, nil, []datevalue.Value{*ymd(1990, 1, 10), *ymd(2015, 2, 10)}))
	if as.GetLow().GetStartYear() != 1990 || as.GetHigh().GetStartYear() != 2015 || !as.GetOpenLow() || !as.GetOpenHigh() {
		t.Fatalf("as-of dating %v", as)
	}
}
