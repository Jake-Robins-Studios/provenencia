package handlers

import (
	"errors"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/catalogsession"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"google.golang.org/protobuf/proto"
)

// metadataOwners is the graphFixture's Source with its two metadata fields
// suggested for its type at the artifact and graph levels, and the owners
// whose boards the cases edit.
type metadataOwners struct {
	graphFixture
	suggested, extra string // field ids: suggested at artifact and graph, not suggested
	artifact, graph  *engine.MetadataOwner
}

func newMetadataOwners(t *testing.T) metadataOwners {
	t.Helper()
	f := newGraphFixture(t)
	var ws engine.GetSourceWorkspaceResponse
	mustRPC(t, GetSourceWorkspace, &engine.GetSourceWorkspaceRequest{ProjectDir: f.dir, SourceId: f.sourceID}, &ws)
	sourceType := ws.GetSource().GetSourceTypeId()
	m := metadataOwners{
		graphFixture: f,
		suggested:    newUserField(t, f.dir, f.userID, "Provider"),
		extra:        newUserField(t, f.dir, f.userID, "Line"),
		artifact:     &engine.MetadataOwner{Level: "artifact", Id: f.page1},
		graph:        &engine.MetadataOwner{Level: "graph", Id: f.defaultGraphID},
	}
	mustRPC(t, AssignTypeField, &engine.AssignTypeFieldRequest{
		ProjectDir: f.dir, TypeId: sourceType, FieldId: m.suggested,
	}, &engine.AssignTypeFieldResponse{})
	return m
}

func TestMetadataOwners(t *testing.T) {
	m := newMetadataOwners(t)
	for name, owner := range map[string]*engine.MetadataOwner{"artifact": m.artifact, "graph": m.graph} {
		t.Run(name, func(t *testing.T) {
			var set engine.SetMetadataResponse
			mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: m.suggested, ValueText: "FamilySearch",
			}, &set)
			if got := metadataByField(set.GetMetadata(), m.suggested); got == nil || got.GetValueText() != "FamilySearch" || !got.GetSuggested() {
				t.Fatalf("set metadata %+v", set.GetMetadata())
			}
			if !slices.Contains(set.GetEffects().GetSourceScopes(), m.sourceID) {
				t.Fatalf("source_scopes %v, want %s", set.GetEffects().GetSourceScopes(), m.sourceID)
			}

			var dismissed engine.DismissMetadataSuggestionResponse
			var setExtra engine.SetMetadataResponse
			mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: m.extra, ValueText: "14",
			}, &setExtra)
			if ids := metadataFieldIDs(withoutFormatRows(setExtra.GetMetadata())); !slices.Equal(ids, []string{m.suggested, m.extra}) {
				t.Fatalf("set extra order %v, want suggested then extra", ids)
			}
			var reordered engine.ReorderMetadataResponse
			mustRPC(t, ReorderMetadata, &engine.ReorderMetadataRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldIds: []string{m.extra, m.suggested},
			}, &reordered)
			if rows := withoutFormatRows(reordered.GetMetadata()); len(rows) != 2 || rows[0].GetField().GetId() != m.extra ||
				!slices.Contains(reordered.GetEffects().GetSourceScopes(), m.sourceID) {
				t.Fatalf("reordered %+v", &reordered)
			}

			var clearedSuggested engine.ClearMetadataResponse
			mustRPC(t, ClearMetadata, &engine.ClearMetadataRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: m.suggested,
			}, &clearedSuggested)
			if got := metadataByField(clearedSuggested.GetMetadata(), m.suggested); got == nil || got.GetHasValue() || !got.GetSuggested() {
				t.Fatalf("cleared suggested field %+v, want an empty suggestion", clearedSuggested.GetMetadata())
			}
			var cleared engine.ClearMetadataResponse
			mustRPC(t, ClearMetadata, &engine.ClearMetadataRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: m.extra,
			}, &cleared)
			if metadataByField(cleared.GetMetadata(), m.extra) != nil {
				t.Fatalf("cleared extra field still listed: %+v", cleared.GetMetadata())
			}
			if !slices.Contains(cleared.GetEffects().GetSourceScopes(), m.sourceID) {
				t.Fatalf("clear source_scopes %v", cleared.GetEffects().GetSourceScopes())
			}

			mustRPC(t, DismissMetadataSuggestion, &engine.DismissMetadataSuggestionRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: m.suggested,
			}, &dismissed)
			for _, e := range dismissed.GetMetadata() {
				if e.GetField().GetId() == m.suggested {
					t.Fatalf("dismissed suggestion still listed: %+v", e)
				}
			}
			if !slices.Contains(dismissed.GetEffects().GetSourceScopes(), m.sourceID) {
				t.Fatalf("dismiss source_scopes %v", dismissed.GetEffects().GetSourceScopes())
			}
		})
	}

	t.Run("a refused url value names its field", func(t *testing.T) {
		link := newField(t, m.dir, m.userID, "Link", "url")
		err := rpc(t, SetMetadata, &engine.SetMetadataRequest{
			ProjectDir: m.dir, UserId: m.userID, Owner: m.artifact, FieldId: link, ValueText: "not a link",
		}, &engine.SetMetadataResponse{})
		if !errors.Is(err, sourcemetadata.ErrInvalid) || !slices.Equal(errParams(t, err), []string{link}) {
			t.Fatalf("got %v, params %v, want params [%s]", err, errParams(t, err), link)
		}
	})

	// Owners the wire refuses: an unwired level and a missing owner are
	// sourcemetadata.invalid; a malformed id is request.invalid_id.
	bad := map[string]struct {
		owner *engine.MetadataOwner
		want  error
	}{
		"citation level": {&engine.MetadataOwner{Level: "citation", Id: m.page1}, sourcemetadata.ErrInvalid},
		"empty level":    {&engine.MetadataOwner{Level: "", Id: m.page1}, sourcemetadata.ErrInvalid},
		"missing owner":  {nil, sourcemetadata.ErrInvalid},
		"unknown artifact": {&engine.MetadataOwner{Level: "artifact", Id: "01890000-0000-7000-8000-000000000001"},
			sourcemetadata.ErrInvalid},
		"malformed id": {&engine.MetadataOwner{Level: "artifact", Id: "nope"}, errInvalidID},
	}
	for name, tt := range bad {
		t.Run(name, func(t *testing.T) {
			err := rpc(t, SetMetadata, &engine.SetMetadataRequest{
				ProjectDir: m.dir, UserId: m.userID, Owner: tt.owner, FieldId: m.suggested, ValueText: "x",
			}, &engine.SetMetadataResponse{})
			if !errors.Is(err, tt.want) {
				t.Fatalf("got %v, want %v", err, tt.want)
			}
		})
	}
}

func TestMetadataValueMarks(t *testing.T) {
	m := newMetadataOwners(t)
	set := func(in *engine.SetMetadataRequest) (*engine.MetadataWorkspaceEntry, error) {
		in.ProjectDir, in.UserId, in.Owner, in.FieldId = m.dir, m.userID, m.artifact, m.suggested
		var out engine.SetMetadataResponse
		if err := rpc(t, SetMetadata, in, &out); err != nil {
			return nil, err
		}
		return metadataByField(out.GetMetadata(), m.suggested), nil
	}

	// The steps run in order: each sets over the value the one before left.
	steps := []struct {
		name  string
		in    *engine.SetMetadataRequest
		check func(t *testing.T, got *engine.MetadataWorkspaceEntry, err error)
	}{
		{"unknown", &engine.SetMetadataRequest{Mark: &engine.ValueMark{Unknown: true}},
			func(t *testing.T, got *engine.MetadataWorkspaceEntry, err error) {
				if err != nil || !got.GetHasValue() || got.GetValueText() != "" || !got.GetMark().GetUnknown() || got.GetMark().GetSupplied() {
					t.Fatalf("unknown = %+v, %v", got, err)
				}
			}},
		{"a set with no mark over the unknown value clears the mark", &engine.SetMetadataRequest{ValueText: "FamilySearch"},
			func(t *testing.T, got *engine.MetadataWorkspaceEntry, err error) {
				if err != nil || got.GetValueText() != "FamilySearch" || got.GetMark() != nil {
					t.Fatalf("no mark = %+v, %v", got, err)
				}
			}},
		{"supplied", &engine.SetMetadataRequest{ValueText: "Topeka", Mark: &engine.ValueMark{Supplied: true}},
			func(t *testing.T, got *engine.MetadataWorkspaceEntry, err error) {
				if err != nil || got.GetValueText() != "Topeka" || !got.GetMark().GetSupplied() || got.GetMark().GetUnknown() {
					t.Fatalf("supplied = %+v, %v", got, err)
				}
			}},
		{"unknown with text is refused, naming the field", &engine.SetMetadataRequest{ValueText: "Topeka", Mark: &engine.ValueMark{Unknown: true}},
			func(t *testing.T, got *engine.MetadataWorkspaceEntry, err error) {
				if !errors.Is(err, valuemark.ErrInvalid) || !slices.Equal(errParams(t, err), []string{m.suggested}) {
					t.Fatalf("unknown with text = %v, params %v", err, errParams(t, err))
				}
			}},
	}
	for _, tt := range steps {
		t.Run(tt.name, func(t *testing.T) {
			got, err := set(tt.in)
			tt.check(t, got, err)
		})
	}

	t.Run("a board entry's field carries the field's unknown text", func(t *testing.T) {
		entry := metadataByField(boardEntries(t, m.dir, m.artifact), m.suggested)
		mustRPC(t, UpdateMetadataField, &engine.UpdateMetadataFieldRequest{
			ProjectDir: m.dir, UserId: m.userID, FieldId: m.suggested,
			Label: entry.GetField().GetLabel(), DataType: entry.GetField().GetDataType(),
			UnknownText: proto.String("n.p."),
		}, &engine.UpdateMetadataFieldResponse{})
		got, err := set(&engine.SetMetadataRequest{Mark: &engine.ValueMark{Unknown: true}})
		if err != nil || got.GetField().GetUnknownText() != "n.p." {
			t.Fatalf("entry field unknown_text = %q, %v", got.GetField().GetUnknownText(), err)
		}
	})
}

// metadataByField is the entry for a field id, or nil.
func metadataByField(entries []*engine.MetadataWorkspaceEntry, fieldID string) *engine.MetadataWorkspaceEntry {
	for _, e := range entries {
		if e.GetField().GetId() == fieldID {
			return e
		}
	}
	return nil
}

// withoutFormatRows is the board without the empty entries only the Source
// type's citation formats put on it (not suggested, no value): the seeded
// type's formats head fields these boards' tests do not set.
func withoutFormatRows(entries []*engine.MetadataWorkspaceEntry) []*engine.MetadataWorkspaceEntry {
	var out []*engine.MetadataWorkspaceEntry
	for _, e := range entries {
		if e.GetSuggested() || e.GetHasValue() || e.GetRequirement() == nil {
			out = append(out, e)
		}
	}
	return out
}

// metadataFieldIDs lists the field ids of a board in its order.
func metadataFieldIDs(entries []*engine.MetadataWorkspaceEntry) []string {
	ids := make([]string, len(entries))
	for i, e := range entries {
		ids[i] = e.GetField().GetId()
	}
	return ids
}

func TestGetMetadataBoard(t *testing.T) {
	m := newMetadataOwners(t)
	mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
		ProjectDir: m.dir, UserId: m.userID, Owner: m.graph, FieldId: m.extra, ValueText: "14",
	}, &engine.SetMetadataResponse{})
	var got engine.GetMetadataBoardResponse
	mustRPC(t, GetMetadataBoard, &engine.GetMetadataBoardRequest{ProjectDir: m.dir, Owner: m.graph}, &got)
	board := got.GetBoard()
	if board.GetOwnerId() != m.defaultGraphID || len(withoutFormatRows(board.GetEntries())) != 2 {
		t.Fatalf("board %+v", board)
	}
	byField := map[string]*engine.MetadataWorkspaceEntry{}
	for _, e := range board.GetEntries() {
		byField[e.GetField().GetId()] = e
	}
	if e := byField[m.suggested]; e == nil || !e.GetSuggested() || e.GetHasValue() {
		t.Errorf("suggested entry %+v", e)
	}
	if e := byField[m.extra]; e == nil || e.GetSuggested() || e.GetValueText() != "14" {
		t.Errorf("extra entry %+v", e)
	}

	if err := rpc(t, GetMetadataBoard, &engine.GetMetadataBoardRequest{ProjectDir: m.dir}, &got); !errors.Is(err, sourcemetadata.ErrInvalid) {
		t.Errorf("no owner: %v", err)
	}
}

// latestRevisionTypes lists the entity type and action of every change in the
// project's latest revision, in write order.
func latestRevisionTypes(t *testing.T, dir string) []string {
	t.Helper()
	var out []string
	err := catalogsession.Do(dir, func(c *database.Catalog) error {
		_, changes := dbtest.LatestRevision(t, dbtest.MustDB(t, c))
		for _, ch := range changes {
			out = append(out, ch.EntityType+" "+ch.Action)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	return out
}

// errParams is the params of the *apperr.Error in err's chain.
func errParams(t *testing.T, err error) []string {
	t.Helper()
	var ae *apperr.Error
	if !errors.As(err, &ae) {
		t.Fatalf("not an apperr: %v", err)
	}
	return ae.Params()
}

// boardEntries is the owner's board entries as GetMetadataBoard reads them.
func boardEntries(t *testing.T, dir string, owner *engine.MetadataOwner) []*engine.MetadataWorkspaceEntry {
	t.Helper()
	var board engine.GetMetadataBoardResponse
	mustRPC(t, GetMetadataBoard, &engine.GetMetadataBoardRequest{ProjectDir: dir, Owner: owner}, &board)
	return board.GetBoard().GetEntries()
}

// assertReplyBoard fails unless got is the owner's board as GetMetadataBoard
// reads it now, entry for entry.
func assertReplyBoard(t *testing.T, dir string, owner *engine.MetadataOwner, got []*engine.MetadataWorkspaceEntry) {
	t.Helper()
	want := boardEntries(t, dir, owner)
	if len(got) != len(want) {
		t.Fatalf("reply board has %d entries, want %d: %+v vs %+v", len(got), len(want), got, want)
	}
	for i := range want {
		if !proto.Equal(got[i], want[i]) {
			t.Fatalf("reply entry %d = %+v, want %+v", i, got[i], want[i])
		}
	}
}

// draftOf is a draft with one value and its layout row at the top.
func draftOf(fieldID, text string) *engine.MetadataDraft {
	return &engine.MetadataDraft{
		Values: []*engine.MetadataValue{{FieldId: fieldID, ValueText: text}},
		Layout: []*engine.MetadataLayoutRow{{FieldId: fieldID, SortOrder: 0}},
	}
}

// TestMetadataBoardsOfferTheTypeList suggests two more fields on the type: the
// Artifact board, the graph board and the Source page's Artifact boards all
// list the type's one list.
func TestMetadataBoardsOfferTheTypeList(t *testing.T) {
	m := newMetadataOwners(t)
	more := newUserField(t, m.dir, m.userID, "Provider URL")
	tree := newUserField(t, m.dir, m.userID, "Tree")
	var ws engine.GetSourceWorkspaceResponse
	mustRPC(t, GetSourceWorkspace, &engine.GetSourceWorkspaceRequest{ProjectDir: m.dir, SourceId: m.sourceID}, &ws)
	for _, field := range []string{more, tree} {
		mustRPC(t, AssignTypeField, &engine.AssignTypeFieldRequest{
			ProjectDir: m.dir, TypeId: ws.GetSource().GetSourceTypeId(), FieldId: field,
		}, &engine.AssignTypeFieldResponse{})
	}
	ids := func(entries []*engine.MetadataWorkspaceEntry) []string {
		var out []string
		for _, e := range entries {
			out = append(out, e.GetField().GetId())
		}
		slices.Sort(out)
		return out
	}
	sorted := func(ids ...string) []string { slices.Sort(ids); return ids }
	want := sorted(m.suggested, more, tree)
	for name, owner := range map[string]*engine.MetadataOwner{"artifact": m.artifact, "graph": m.graph} {
		t.Run(name, func(t *testing.T) {
			if got := ids(withoutFormatRows(boardEntries(t, m.dir, owner))); !slices.Equal(got, want) {
				t.Fatalf("board fields %v, want %v", got, want)
			}
		})
	}
	// The Source page's Artifact boards carry the same list.
	var after engine.GetSourceWorkspaceResponse
	mustRPC(t, GetSourceWorkspace, &engine.GetSourceWorkspaceRequest{ProjectDir: m.dir, SourceId: m.sourceID}, &after)
	for _, board := range after.GetArtifactMetadata() {
		if got := ids(withoutFormatRows(board.GetEntries())); !slices.Equal(got, want) {
			t.Fatalf("Artifact board fields %v, want %v", got, want)
		}
	}
}

// metadataByKey is the entry for the field key, nil when the board holds none.
func metadataByKey(entries []*engine.MetadataWorkspaceEntry, key string) *engine.MetadataWorkspaceEntry {
	for _, e := range entries {
		if e.GetField().GetKey() == key {
			return e
		}
	}
	return nil
}

func TestMetadataBoardRequirements(t *testing.T) {
	dir, userID, _ := sourceFixture(t)
	sourceID := seededSourceOfType(t, dir, userID, "census")
	owner := &engine.MetadataOwner{Level: "source", Id: sourceID}
	board := boardEntries(t, dir, owner)
	jurisdiction := metadataByKey(board, "jurisdiction")
	if jurisdiction == nil || jurisdiction.GetRequirement().GetNeed() != engine.CitationNeed_CITATION_NEED_NEEDED ||
		jurisdiction.GetRequirement().GetMetElsewhere() || len(jurisdiction.GetRequirement().GetAlternatives()) != 0 {
		t.Fatalf("jurisdiction %+v, want needed, not met, no alternatives", jurisdiction)
	}
	if creator := metadataByKey(board, "creator"); creator.GetRequirement().GetNeed() != engine.CitationNeed_CITATION_NEED_USED {
		t.Fatalf("creator %+v, want used", creator)
	}
	fieldID := jurisdiction.GetField().GetId()
	needed := func(t *testing.T, entries []*engine.MetadataWorkspaceEntry) *engine.MetadataWorkspaceEntry {
		t.Helper()
		e := metadataByField(entries, fieldID)
		if e == nil || e.GetRequirement().GetNeed() != engine.CitationNeed_CITATION_NEED_NEEDED {
			t.Fatalf("reply entry %+v, want jurisdiction, needed", e)
		}
		return e
	}

	var set engine.SetMetadataResponse
	mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
		ProjectDir: dir, UserId: userID, Owner: owner, FieldId: fieldID, ValueText: "Massachusetts",
	}, &set)
	if e := needed(t, set.GetMetadata()); !e.GetHasValue() || e.GetValueText() != "Massachusetts" {
		t.Fatalf("set reply %+v, want the value", e)
	}
	assertReplyBoard(t, dir, owner, set.GetMetadata())

	var reordered engine.ReorderMetadataResponse
	mustRPC(t, ReorderMetadata, &engine.ReorderMetadataRequest{
		ProjectDir: dir, UserId: userID, Owner: owner, FieldIds: []string{fieldID},
	}, &reordered)
	needed(t, reordered.GetMetadata())
	assertReplyBoard(t, dir, owner, reordered.GetMetadata())

	var cleared engine.ClearMetadataResponse
	mustRPC(t, ClearMetadata, &engine.ClearMetadataRequest{
		ProjectDir: dir, UserId: userID, Owner: owner, FieldId: fieldID,
	}, &cleared)
	needed(t, cleared.GetMetadata())
	assertReplyBoard(t, dir, owner, cleared.GetMetadata())

	err := rpc(t, DismissMetadataSuggestion, &engine.DismissMetadataSuggestionRequest{
		ProjectDir: dir, UserId: userID, Owner: owner, FieldId: fieldID,
	}, &engine.DismissMetadataSuggestionResponse{})
	if !errors.Is(err, sourcemetadata.ErrInvalid) || !slices.Equal(errParams(t, err), []string{fieldID}) {
		t.Fatalf("dismissing a needed field = %v, params %v, want sourcemetadata.invalid [%s]", err, errParams(t, err), fieldID)
	}

	var creator engine.DismissMetadataSuggestionResponse
	mustRPC(t, DismissMetadataSuggestion, &engine.DismissMetadataSuggestionRequest{
		ProjectDir: dir, UserId: userID, Owner: owner, FieldId: metadataByKey(board, "creator").GetField().GetId(),
	}, &creator)
	if metadataByKey(creator.GetMetadata(), "creator") != nil {
		t.Errorf("a used field's dismissal left it on the board: %+v", creator.GetMetadata())
	}
	assertReplyBoard(t, dir, owner, creator.GetMetadata())
}

// lineLedgerSource is a Source of a new type whose full format reads line_number
// from the nearest level, with line_number suggested at graph and "14" on
// the Source.
func lineLedgerSource(t *testing.T, dir, userID string) (sourceID, lineID string) {
	t.Helper()
	lineID = fieldIDsByKey(t, dir)["line_number"]
	var ty engine.CreateSourceTypeResponse
	mustRPC(t, CreateSourceType, &engine.CreateSourceTypeRequest{ProjectDir: dir, UserId: userID, Label: "Line ledger"}, &ty)
	mustRPC(t, AssignTypeField, &engine.AssignTypeFieldRequest{
		ProjectDir: dir, TypeId: ty.GetType().GetId(), FieldId: lineID,
	}, &engine.AssignTypeFieldResponse{})
	formats := setFormats(t, dir, userID, ty.GetType().GetId(), &engine.CitationFormats{
		Full: "{meta.line_number}.",
	})
	if len(formats.GetDiagnostics()) != 0 {
		t.Fatalf("diagnostics %+v", formats.GetDiagnostics())
	}
	var src engine.CreateSourceResponse
	mustRPC(t, CreateSource, &engine.CreateSourceRequest{
		ProjectDir: dir, UserId: userID, SourceTypeId: ty.GetType().GetId(), Title: "Ledger",
	}, &src)
	mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
		ProjectDir: dir, UserId: userID, Owner: &engine.MetadataOwner{Level: "source", Id: src.GetSource().GetId()},
		FieldId: lineID, ValueText: "14",
	}, &engine.SetMetadataResponse{})
	return src.GetSource().GetId(), lineID
}

func TestGetDraftMetadataBoard(t *testing.T) {
	dir, userID, _ := sourceFixture(t)
	census := seededSourceOfType(t, dir, userID, "census")
	ledger, lineID := lineLedgerSource(t, dir, userID)
	draft := func(source, level string) ([]*engine.MetadataWorkspaceEntry, error) {
		var out engine.GetDraftMetadataBoardResponse
		err := rpc(t, GetDraftMetadataBoard, &engine.GetDraftMetadataBoardRequest{ProjectDir: dir, SourceId: source, Level: level}, &out)
		return out.GetEntries(), err
	}

	t.Run("census artifact", func(t *testing.T) {
		var ws engine.GetSourceWorkspaceResponse
		mustRPC(t, GetSourceWorkspace, &engine.GetSourceWorkspaceRequest{ProjectDir: dir, SourceId: census}, &ws)
		entries, err := draft(census, "artifact")
		if err != nil {
			t.Fatal(err)
		}
		want := listSuggestions(t, dir, ws.GetSource().GetSourceTypeId())
		// The type's suggestions lead, then every other field its formats read,
		// unsuggested: a field with no level heads on every board.
		if len(entries) < len(want) {
			t.Fatalf("%d entries, want at least the type's %d suggestions", len(entries), len(want))
		}
		for i, e := range entries {
			if i < len(want) && (e.GetField().GetId() != want[i].GetField().GetId() || !e.GetSuggested()) {
				t.Errorf("entry %d = %+v, want suggestion %s", i, e, want[i].GetField().GetId())
			}
			if i >= len(want) && (e.GetSuggested() || e.GetRequirement().GetNeed() == engine.CitationNeed_CITATION_NEED_UNSPECIFIED) {
				t.Errorf("entry %d = %+v, want an unsuggested head the formats read", i, e)
			}
			if e.GetHasValue() {
				t.Errorf("entry %d = %+v, want empty", i, e)
			}
		}
		if url := metadataByKey(entries, "url"); url.GetRequirement().GetNeed() != engine.CitationNeed_CITATION_NEED_USED {
			t.Errorf("url = %+v, want used", url)
		}
	})
	t.Run("the Source answers a graph's needed field", func(t *testing.T) {
		entries, err := draft(ledger, "graph")
		if err != nil {
			t.Fatal(err)
		}
		e := metadataByField(entries, lineID)
		if e == nil || e.GetRequirement().GetNeed() != engine.CitationNeed_CITATION_NEED_NEEDED || !e.GetRequirement().GetMetElsewhere() ||
			len(e.GetRequirement().GetAlternatives()) != 0 {
			t.Errorf("line_number = %+v, want needed, met elsewhere (the Source holds it), no alternative", e)
		}
	})
	t.Run("refusals", func(t *testing.T) {
		for name, tt := range map[string]struct {
			source, level string
			want          error
		}{
			"no such Source": {"01890000-0000-7000-8000-000000000001", "artifact", sourcemetadata.ErrInvalid},
			"source level":   {census, "source", sourcemetadata.ErrInvalid},
			"citation level": {census, "citation", sourcemetadata.ErrInvalid},
			"malformed id":   {"not-an-id", "artifact", errInvalidID},
			"unknown level":  {census, "page", sourcemetadata.ErrInvalid},
			"an empty level": {census, "", sourcemetadata.ErrInvalid},
			"a version 4 id": {"01890000-0000-4000-8000-000000000001", "graph", errInvalidID},
		} {
			if _, err := draft(tt.source, tt.level); !errors.Is(err, tt.want) {
				t.Errorf("%s: %v, want %v", name, err, tt.want)
			}
		}
	})
}

// TestMetadataBoardInherited: the boards below a Source carry the Source's values
// as inherited, printed as a citation prints them; the Source's own board
// carries none.
func TestMetadataBoardInherited(t *testing.T) {
	m := newMetadataOwners(t)
	source := sourceOwnerProto(m.sourceID)
	set := func(owner *engine.MetadataOwner, fieldID, text string, mark *engine.ValueMark) {
		t.Helper()
		mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
			ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: fieldID, ValueText: text, Mark: mark,
		}, &engine.SetMetadataResponse{})
	}
	set(source, m.suggested, "Ancestry", nil)
	set(source, m.extra, "Calder County", nil)

	var ws engine.GetSourceWorkspaceResponse
	mustRPC(t, GetSourceWorkspace, &engine.GetSourceWorkspaceRequest{ProjectDir: m.dir, SourceId: m.sourceID}, &ws)
	for name, boards := range map[string][]*engine.MetadataBoard{"artifact": ws.GetArtifactMetadata(), "graph": ws.GetGraphMetadata()} {
		if len(boards) == 0 {
			t.Fatalf("no %s boards", name)
		}
		for _, b := range boards {
			provider := metadataByField(b.GetEntries(), m.suggested)
			in := provider.GetInherited()
			if in.GetDisplayText() != "Ancestry" || in.GetOwner().GetLevel() != "source" || in.GetOwner().GetId() != m.sourceID ||
				!provider.GetStaysWithoutValue() || provider.GetHasValue() {
				t.Fatalf("%s board provider = %+v, want Ancestry inherited from the Source, kept", name, provider)
			}
			if extra := metadataByField(b.GetEntries(), m.extra); extra != nil {
				t.Fatalf("%s board holds the Source's extra: %+v", name, extra)
			}
		}
	}
	if sb := boardEntries(t, m.dir, source); len(sb) == 0 {
		t.Fatal("no Source board")
	} else {
		for _, e := range sb {
			if e.GetInherited() != nil {
				t.Fatalf("Source entry %+v inherits", e)
			}
		}
	}

	set(source, m.suggested, "Calder County", &engine.ValueMark{Supplied: true})
	mustRPC(t, GetSourceWorkspace, &engine.GetSourceWorkspaceRequest{ProjectDir: m.dir, SourceId: m.sourceID}, &ws)
	if in := metadataByField(ws.GetArtifactMetadata()[0].GetEntries(), m.suggested).GetInherited(); in.GetDisplayText() != "[Calder County]" || !in.GetMark().GetSupplied() {
		t.Fatalf("a supplied Source value inherits as %+v, want [Calder County] marked supplied", in)
	}

	census := seededSourceOfType(t, m.dir, m.userID, "census")
	censusOwner := sourceOwnerProto(census)
	url := metadataByKey(boardEntries(t, m.dir, censusOwner), "url").GetField().GetId()
	set(censusOwner, url, "https://example.org/calder/1880", nil)
	for _, level := range []string{"artifact", "graph"} {
		var draft engine.GetDraftMetadataBoardResponse
		mustRPC(t, GetDraftMetadataBoard, &engine.GetDraftMetadataBoardRequest{ProjectDir: m.dir, SourceId: census, Level: level}, &draft)
		e := metadataByKey(draft.GetEntries(), "url")
		if e.GetInherited().GetDisplayText() != "https://example.org/calder/1880" || e.GetInherited().GetOpenHref() == "" ||
			e.GetInherited().GetOwner().GetId() != census || !e.GetStaysWithoutValue() {
			t.Fatalf("%s draft url = %+v, want the Source's link inherited", level, e)
		}
	}
}

// TestSetMetadataReportsInheritedValues: a Source's metadata value write reports
// the inherited_values read for that Source; an Artifact's does not.
func TestSetMetadataReportsInheritedValues(t *testing.T) {
	m := newMetadataOwners(t)
	reads := func(owner *engine.MetadataOwner) []*engine.WriteEffectsRead {
		var set engine.SetMetadataResponse
		mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
			ProjectDir: m.dir, UserId: m.userID, Owner: owner, FieldId: m.suggested, ValueText: "Ancestry",
		}, &set)
		var out []*engine.WriteEffectsRead
		for _, r := range set.GetEffects().GetReads() {
			if r.GetRead() == "inherited_values" {
				out = append(out, r)
			}
		}
		return out
	}
	if got := reads(sourceOwnerProto(m.sourceID)); len(got) != 1 || !slices.Equal(got[0].GetIds(), []string{m.sourceID}) {
		t.Fatalf("a Source write reports %v, want inherited_values for %s", got, m.sourceID)
	}
	if got := reads(m.artifact); len(got) != 0 {
		t.Fatalf("an Artifact write reports %v, want no inherited_values", got)
	}
}
