package deleteimpact

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
)

// TestMetadataFacetOrder pins the facet releases per parent kind and the
// field's inbound probes, which the metadata level list builds.
func TestMetadataFacetOrder(t *testing.T) {
	facetVias := map[catalogmodel.Kind][]string{
		catalogmodel.KindArtifact: {
			"evidence_graph_artifacts.artifact_id", "sources.primary_artifact_id",
			"artifact_metadata.artifact_id", "artifact_metadata_layout.artifact_id",
		},
		catalogmodel.KindEvidenceGraph: {
			"citations.graph_id", "evidence_graph_artifacts.graph_id",
			"evidence_graph_metadata.graph_id", "evidence_graph_metadata_layout.graph_id",
		},
		catalogmodel.KindSource: {
			"source_notes.source_id", "evidence_graphs.source_id", "source_credibility_assessments.source_id",
			"source_metadata.source_id", "source_metadata_layout.source_id",
		},
		catalogmodel.KindMetadataField: {
			"source_metadata_layout.field_id", "artifact_metadata_layout.field_id", "evidence_graph_metadata_layout.field_id",
		},
	}
	for kind, want := range facetVias {
		t.Run("facets "+string(kind), func(t *testing.T) {
			var got []string
			for _, f := range facetReleasesFor(kind) {
				got = append(got, f.Via)
			}
			if !slices.Equal(got, want) {
				t.Fatalf("facet vias = %v, want %v", got, want)
			}
		})
	}
	t.Run("field inbound", func(t *testing.T) {
		want := []string{"source_metadata.field_id", "artifact_metadata.field_id", "evidence_graph_metadata.field_id", ViaCitationFormats}
		var got []string
		for _, e := range inboundFor(catalogmodel.KindMetadataField) {
			got = append(got, e.Via)
		}
		if !slices.Equal(got, want) {
			t.Fatalf("inbound vias = %v, want %v", got, want)
		}
	})
}
