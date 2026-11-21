package handlers

import (
	"errors"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/catalogsession"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemove"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/google/uuid"
)

func newV7(t *testing.T) string {
	t.Helper()
	id, err := uuid.NewV7()
	if err != nil {
		t.Fatal(err)
	}
	return id.String()
}

func moveIDs(arts []*engine.Artifact) []string {
	var out []string
	for _, a := range arts {
		out = append(out, a.GetId())
	}
	return out
}

func graphIDsOf(gs []*engine.EvidenceGraph) []string {
	var out []string
	for _, g := range gs {
		out = append(out, g.GetId())
	}
	return out
}

func TestGetSourceMoveImpact(t *testing.T) {
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	f := newGraphFixture(t)
	target, _ := f.otherSource(t)
	page3 := f.createArtifact(t, f.sourceID, "Page 3", &engine.GraphLinks{})
	jones := f.createGraph(t, "Jones", page3).GetGraph().GetId()
	impact := func(req *engine.GetSourceMoveImpactRequest) (*engine.GetSourceMoveImpactResponse, error) {
		req.ProjectDir = f.dir
		var resp engine.GetSourceMoveImpactResponse
		err := rpc(t, GetSourceMoveImpact, req, &resp)
		return &resp, err
	}

	t.Run("an Artifact with its own graph", func(t *testing.T) {
		resp, err := impact(&engine.GetSourceMoveImpactRequest{ArtifactId: page3})
		if err != nil {
			t.Fatal(err)
		}
		if resp.GetSourceId() != f.sourceID || !slices.Equal(moveIDs(resp.GetArtifacts()), []string{page3}) ||
			!slices.Equal(graphIDsOf(resp.GetGraphs()), []string{jones}) || len(resp.GetProgress()) != 1 || resp.GetProgress()[0].GetGraphId() != jones ||
			resp.GetLeavesSourceEmpty() || resp.GetLeavesNoGraph() || resp.GetCredibilityDiffers() {
			t.Fatalf("response %+v", resp)
		}
	})

	t.Run("a shared graph carries its Subjects count", func(t *testing.T) {
		resp, err := impact(&engine.GetSourceMoveImpactRequest{GraphId: f.defaultGraphID})
		if err != nil {
			t.Fatal(err)
		}
		if len(resp.GetArtifacts()) != 2 || len(resp.GetGraphs()) != 1 || resp.GetProgress()[0].GetSubjectCount() != 1 {
			t.Fatalf("response %+v", resp)
		}
	})

	t.Run("a target with a different grade", func(t *testing.T) {
		mustRPC(t, UpsertSourceCredibilityAssessment, &engine.UpsertSourceCredibilityAssessmentRequest{
			ProjectDir: f.dir, UserId: f.userID, SourceId: f.sourceID, GradeKey: "low_trust", GradeOrigin: "provenencia",
		}, &engine.UpsertSourceCredibilityAssessmentResponse{})
		resp, err := impact(&engine.GetSourceMoveImpactRequest{ArtifactId: page3, TargetSourceId: target})
		if err != nil {
			t.Fatal(err)
		}
		if resp.GetSourceCredibilityKey() != "low_trust" || resp.GetTargetCredibilityKey() != "" || !resp.GetCredibilityDiffers() {
			t.Fatalf("response %+v", resp)
		}
	})

	refused := []struct {
		name string
		req  *engine.GetSourceMoveImpactRequest
		want error
	}{
		{"malformed id", &engine.GetSourceMoveImpactRequest{ArtifactId: "nope"}, errInvalidID},
		{"malformed target", &engine.GetSourceMoveImpactRequest{ArtifactId: page3, TargetSourceId: "nope"}, errInvalidID},
		{"no seed", &engine.GetSourceMoveImpactRequest{}, sourcemove.ErrInvalid},
		{"two seeds", &engine.GetSourceMoveImpactRequest{ArtifactId: page3, GraphId: jones}, sourcemove.ErrInvalid},
		{"missing seed", &engine.GetSourceMoveImpactRequest{ArtifactId: newV7(t)}, sourcemove.ErrNotFound},
		{"missing target", &engine.GetSourceMoveImpactRequest{ArtifactId: page3, TargetSourceId: newV7(t)}, sources.ErrNotFound},
		{"same Source", &engine.GetSourceMoveImpactRequest{ArtifactId: page3, TargetSourceId: f.sourceID}, sourcemove.ErrInvalid},
	}
	for _, tt := range refused {
		t.Run(tt.name, func(t *testing.T) {
			if _, err := impact(tt.req); !errors.Is(err, tt.want) {
				t.Fatalf("got %v want %v", err, tt.want)
			}
		})
	}
	t.Run("bad proto", func(t *testing.T) {
		if _, err := GetSourceMoveImpact([]byte{0xff, 0xff}); err == nil {
			t.Fatal("expected error")
		}
	})
}

func TestMoveToSource(t *testing.T) {
	t.Cleanup(func() { _ = catalogsession.CloseAll() })
	f := newGraphFixture(t)
	target, _ := f.otherSource(t)
	page3 := f.createArtifact(t, f.sourceID, "Page 3", &engine.GraphLinks{})
	jones := f.createGraph(t, "Jones", page3).GetGraph().GetId()
	move := func(req *engine.MoveToSourceRequest) (*engine.MoveToSourceResponse, error) {
		req.ProjectDir = f.dir
		var resp engine.MoveToSourceResponse
		err := rpc(t, MoveToSource, req, &resp)
		return &resp, err
	}

	refused := []struct {
		name string
		req  *engine.MoveToSourceRequest
		want error
	}{
		{"empty user", &engine.MoveToSourceRequest{ArtifactId: page3, TargetSourceId: target}, errInvalidUserID},
		{"same Source", &engine.MoveToSourceRequest{UserId: f.userID, ArtifactId: page3, TargetSourceId: f.sourceID}, sourcemove.ErrInvalid},
	}
	for _, tt := range refused {
		t.Run(tt.name, func(t *testing.T) {
			if _, err := move(tt.req); !errors.Is(err, tt.want) {
				t.Fatalf("got %v want %v", err, tt.want)
			}
		})
	}

	t.Run("a pair moves", func(t *testing.T) {
		resp, err := move(&engine.MoveToSourceRequest{UserId: f.userID, ArtifactId: page3, TargetSourceId: target})
		if err != nil {
			t.Fatal(err)
		}
		if !slices.Equal(resp.GetArtifactIds(), []string{page3}) || !slices.Equal(resp.GetGraphIds(), []string{jones}) || resp.GetDefaultGraphId() != "" {
			t.Fatalf("response %+v", resp)
		}
		scopes := resp.GetEffects().GetSourceScopes()
		if len(scopes) != 2 || !slices.Contains(scopes, f.sourceID) || !slices.Contains(scopes, target) {
			t.Fatalf("source scopes %v", scopes)
		}
		if !slices.Contains(graphIDsOf(f.graphsOf(t, target)), jones) || slices.Contains(graphIDsOf(f.graphsOf(t, f.sourceID)), jones) {
			t.Fatal("the graph did not change Source")
		}
	})

	t.Run("the last graph leaves a Default graph", func(t *testing.T) {
		resp, err := move(&engine.MoveToSourceRequest{UserId: f.userID, GraphId: f.defaultGraphID, TargetSourceId: target})
		if err != nil {
			t.Fatal(err)
		}
		if resp.GetDefaultGraphId() == "" || resp.GetDefaultGraphId() == f.defaultGraphID {
			t.Fatalf("default graph id %q", resp.GetDefaultGraphId())
		}
		left := f.graphsOf(t, f.sourceID)
		if len(left) != 1 || left[0].GetId() != resp.GetDefaultGraphId() {
			t.Fatalf("graphs left %+v", left)
		}
	})
}
