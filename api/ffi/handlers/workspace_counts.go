package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/canonicalentities"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"google.golang.org/protobuf/proto"
)

func GetWorkspaceNavCounts(in []byte) ([]byte, error) {
	var req engine.GetWorkspaceNavCountsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_workspace_nav_counts", err)
	}
	var out *engine.GetWorkspaceNavCountsResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		sourceCount, err := sources.Count(c)
		if err != nil {
			return err
		}
		persons, err := canonicalentities.CountByTypeKey(c, vocabkey.Person)
		if err != nil {
			return err
		}
		events, err := canonicalentities.CountByTypeKey(c, vocabkey.Event)
		if err != nil {
			return err
		}
		places, err := canonicalentities.CountByTypeKey(c, vocabkey.Place)
		if err != nil {
			return err
		}
		out = &engine.GetWorkspaceNavCountsResponse{
			Sources: int32(sourceCount),
			Persons: int32(persons),
			Events:  int32(events),
			Places:  int32(places),
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}
