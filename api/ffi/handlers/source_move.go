package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemove"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"google.golang.org/protobuf/proto"
)

// moveSeed reads the picked Artifact or graph; whether exactly one is set is
// sourcemove's to refuse.
func moveSeed(artifactID, graphID string) (evidencegraphs.Seed, error) {
	a, err := optionalID(artifactID)
	if err != nil {
		return evidencegraphs.Seed{}, err
	}
	g, err := optionalID(graphID)
	if err != nil {
		return evidencegraphs.Seed{}, err
	}
	return evidencegraphs.Seed{ArtifactID: a, GraphID: g}, nil
}

// GetSourceMoveImpact is a read: what moving the picked Artifact or Evidence
// graph to another Source moves with it, and the side effects to name.
func GetSourceMoveImpact(in []byte) ([]byte, error) {
	var req engine.GetSourceMoveImpactRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_source_move_impact", err)
	}
	seed, err := moveSeed(req.GetArtifactId(), req.GetGraphId())
	if err != nil {
		return nil, err
	}
	targetID, err := optionalID(req.GetTargetSourceId())
	if err != nil {
		return nil, err
	}
	var out *engine.GetSourceMoveImpactResponse
	pass := &thumbnailPass{}
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		rep, err := sourcemove.Impact(c, seed, targetID)
		if err != nil {
			return err
		}
		out = &engine.GetSourceMoveImpactResponse{
			SourceId:             database.UUIDString(rep.Bundle.SourceID),
			SourceCredibilityKey: rep.SourceCredibilityKey,
			TargetCredibilityKey: rep.TargetCredibilityKey,
			CredibilityDiffers:   rep.CredibilityDiffers,
			LeavesSourceEmpty:    rep.LeavesSourceEmpty,
			LeavesNoGraph:        rep.LeavesNoGraph,
		}
		for _, a := range rep.Artifacts {
			ap, err := artifactProto(c, a, pass)
			if err != nil {
				return err
			}
			out.Artifacts = append(out.Artifacts, ap)
		}
		for _, g := range rep.Graphs {
			out.Graphs = append(out.Graphs, evidenceGraphProto(g))
		}
		for _, p := range rep.Progress {
			out.Progress = append(out.Progress, protoProgress(p))
		}
		return nil
	})
	if err == nil {
		err = pass.run(req.GetProjectDir(), nil)
	}
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// MoveToSource moves the picked Artifact or Evidence graph and its whole
// bundle to another Source in one write.
func MoveToSource(in []byte) ([]byte, error) {
	var req engine.MoveToSourceRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("move_to_source", err)
	}
	userID, err := parseUserID(req.GetUserId())
	if err != nil {
		return nil, err
	}
	seed, err := moveSeed(req.GetArtifactId(), req.GetGraphId())
	if err != nil {
		return nil, err
	}
	targetID, err := optionalID(req.GetTargetSourceId())
	if err != nil {
		return nil, err
	}
	var out *engine.MoveToSourceResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		res, wrote, err := writes.Run(c, writes.Op{Action: "move_to_source", UserID: userID},
			func(tx *database.Tx) (sourcemove.Result, []rowchange.Change, error) {
				return sourcemove.Move(tx, userID, seed, targetID)
			})
		if err != nil {
			return err
		}
		out = &engine.MoveToSourceResponse{
			ArtifactIds:    idStrings(res.Bundle.ArtifactIDs),
			GraphIds:       idStrings(res.Bundle.GraphIDs),
			DefaultGraphId: database.UUIDString(res.DefaultGraphID),
			Effects:        writeEffectsProto(wrote),
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}
