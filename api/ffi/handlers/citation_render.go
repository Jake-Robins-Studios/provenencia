package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citationrender"
	"google.golang.org/protobuf/proto"
)

// RenderCitations renders the full and short citation of each Citation named,
// with a group key each and the Evidence graphs and Sources the read used.
func RenderCitations(in []byte) ([]byte, error) {
	var req engine.RenderCitationsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("render_citations", err)
	}
	ids, err := parseIDs(req.GetCitationIds())
	if err != nil {
		return nil, err
	}
	var out *engine.RenderCitationsResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		inputs := c.Graph().PageInputs()
		got, err := citationrender.Render(c, ids, inputs)
		if err != nil {
			return err
		}
		out = &engine.RenderCitationsResponse{Inputs: pageInputsProto(inputs)}
		for _, r := range got {
			out.Citations = append(out.Citations, &engine.RenderedCitation{
				CitationId: database.UUIDString(r.CitationID),
				Full:       citationRenderProto(r.Full),
				Short:      citationRenderProto(r.Short),
				GroupKey:   r.GroupKey,
			})
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// RenderCitationPreview renders one form against one Citation, or the list form
// against one Source, with what it lacks and what is wrong with an unsaved
// format.
func RenderCitationPreview(in []byte) ([]byte, error) {
	var req engine.RenderCitationPreviewRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("render_citation_preview", err)
	}
	choices, err := fieldChoicesFromProto(req.GetFieldChoices())
	if err != nil {
		return nil, err
	}
	pin := citationrender.PreviewInput{Form: citationformat.Form(req.GetForm()), Format: req.Format, Choices: choices}
	switch t := req.GetTarget().(type) {
	case *engine.RenderCitationPreviewRequest_CitationId:
		if pin.Target.CitationID, err = parseID(t.CitationId); err != nil {
			return nil, err
		}
	case *engine.RenderCitationPreviewRequest_SourceId:
		if pin.Target.SourceID, err = parseID(t.SourceId); err != nil {
			return nil, err
		}
	}
	var out *engine.RenderCitationPreviewResponse
	err = withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		got, err := citationrender.RenderPreview(c, pin)
		if err != nil {
			return err
		}
		out = &engine.RenderCitationPreviewResponse{
			Render:      citationRenderProto(got.Rendered),
			Diagnostics: citationFormatDiagnosticsProto(got.Diagnostics),
		}
		for _, opts := range got.Missing {
			m := &engine.CitationMissing{}
			for _, o := range opts {
				m.Options = append(m.Options, citationOptionProto(o))
			}
			out.Missing = append(out.Missing, m)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}

// ListCitationBuiltins lists the built-in placeholders from the engine's one
// table. It reads no catalog.
func ListCitationBuiltins(in []byte) ([]byte, error) {
	var req engine.ListCitationBuiltinsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("list_citation_builtins", err)
	}
	out := &engine.ListCitationBuiltinsResponse{}
	for _, b := range citationformat.Builtins() {
		pb := &engine.CitationBuiltin{
			Level:       string(b.Level),
			Name:        b.Name,
			Date:        b.Date,
			AlwaysSet:   b.AlwaysSet,
			InListForm:  b.InListForm(),
			UnknownText: b.UnknownText,
		}
		for _, o := range b.Options {
			pb.Options = append(pb.Options, string(o))
		}
		out.Builtins = append(out.Builtins, pb)
	}
	return proto.Marshal(out)
}

// citationRenderProto is a rendered format on the wire: its runs and their text.
func citationRenderProto(r citationformat.Rendered) *engine.CitationRender {
	out := &engine.CitationRender{Plain: r.Plain()}
	for _, run := range r.Runs {
		out.Runs = append(out.Runs, &engine.CitationRun{Text: run.Text, Italic: run.Italic})
	}
	return out
}
