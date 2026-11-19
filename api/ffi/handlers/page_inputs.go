package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
)

// pageInputsProto maps what a page read recorded to the wire: each list
// distinct and in byte order, as UUID strings.
func pageInputsProto(in *graphcache.PageInputs) *engine.PageInputs {
	handles, graphs, sources := in.Lists()
	return &engine.PageInputs{
		Handles:        idStrings(handles),
		EvidenceGraphs: idStrings(graphs),
		Sources:        idStrings(sources),
	}
}
