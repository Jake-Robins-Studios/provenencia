package citationrender

import (
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

// Target is what a preview renders against: one of a Citation and a Source,
// each a 16-byte id, or neither when only an unsaved format is checked. A
// Source target takes every form: the full and short read the Source's first
// Citation, or the Source alone when it has none.
type Target struct {
	CitationID, SourceID []byte
}

// PreviewInput is one form rendered against one target.
type PreviewInput struct {
	Form citationformat.Form
	// Format is unsaved text written with field keys (Choices say which field
	// a shared key means); nil renders the target's type's stored format.
	Format  *string
	Choices []sourcetypes.FieldChoice
	Target  Target
}

// Preview is the render, what a needed placeholder lacks, and what is wrong
// with the unsaved text.
type Preview struct {
	Rendered citationformat.Rendered
	// Missing holds one entry per needed chain no option of answers, each the
	// chain's options that can be shown, in chain order; a chain with none is
	// left out.
	Missing [][]sourcemetadata.Alternative
	// Diagnostics are the mistakes in an unsaved format. With any, Rendered and
	// Missing are empty.
	Diagnostics []citationformat.FormDiagnostic
}

// RenderPreview renders in.Form against in.Target in one read transaction.
// citations.ErrInvalid refuses an unknown form, both targets, an id that is not
// 16 bytes, and neither target with no format. An unsaved format is checked
// first: with diagnostics they come back alone, and with no target that is all
// there is (an empty Preview when it parses). A Source target renders the full
// and short forms against the Source's first Citation (citations.FirstOfSourceTx)
// and the Source alone when it has none; the list form renders the Source alone.
// citations.ErrNotFound is a Citation that is not in the catalog and
// sources.ErrNotFound a Source that is not; sourcetypes.ErrInvalid a field
// choice that names no field of its key. A blank format, or a stored one that
// does not parse, renders nothing.
func RenderPreview(c *database.Catalog, in PreviewInput) (Preview, error) {
	t := in.Target
	if !in.Form.Valid() || (t.CitationID != nil && t.SourceID != nil) || (t.CitationID == nil && t.SourceID == nil && in.Format == nil) {
		return Preview{}, citations.ErrInvalid
	}
	if (t.CitationID != nil && len(t.CitationID) != 16) || (t.SourceID != nil && len(t.SourceID) != 16) {
		return Preview{}, citations.ErrInvalid
	}
	db, err := c.DB()
	if err != nil {
		return Preview{}, err
	}
	tx, err := db.Begin()
	if err != nil {
		return Preview{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var typed string
	if in.Format != nil {
		stored, diags, err := sourcetypes.ToStored(tx, sourcetypes.Formats{}.With(in.Form, *in.Format), in.Choices, "")
		if err != nil {
			return Preview{}, err
		}
		if len(diags) > 0 {
			return Preview{Diagnostics: diags}, nil
		}
		typed = stored.Text(in.Form)
	}
	if t.CitationID == nil && t.SourceID == nil {
		return Preview{}, nil
	}

	var sub *subject
	if t.CitationID != nil {
		subs, err := loadCitations(tx, [][]byte{t.CitationID})
		if err != nil {
			return Preview{}, err
		}
		if len(subs) == 0 {
			return Preview{}, citations.ErrNotFound
		}
		sub = subs[0]
	} else if sub, err = loadSource(tx, t.SourceID); err != nil {
		return Preview{}, err
	} else if in.Form != citationformat.FormList {
		first, err := citations.FirstOfSourceTx(tx, t.SourceID)
		if err != nil {
			return Preview{}, err
		}
		if first != nil {
			subs, err := loadCitations(tx, [][]byte{first})
			if err != nil {
				return Preview{}, err
			}
			if len(subs) > 0 {
				sub = subs[0]
			}
		}
	}

	text := typed
	if in.Format == nil {
		if id := sub.typeID(); id != nil {
			formats, err := sourcetypes.StoredFormatsTx(tx, [][]byte{id})
			if err != nil {
				return Preview{}, err
			}
			text = formats[string(id)].Text(in.Form)
		}
	}
	parsed, _ := sourcetypes.Formats{}.With(in.Form, text).Parse()
	tpl := parsed[in.Form]
	if tpl == nil {
		return Preview{}, nil
	}
	if err := fillValues(tx, []*subject{sub}, []*citationformat.Template{tpl}); err != nil {
		return Preview{}, err
	}
	out := Preview{Rendered: citationformat.Render(tpl, sub.values)}
	for _, req := range citationformat.Missing(citationformat.Requirements(tpl), sub.values) {
		opts := sourcemetadata.AppendOptions(nil, map[citationformat.Target]bool{}, req.Targets, sub.values.Fields)
		if len(opts) > 0 {
			out.Missing = append(out.Missing, opts)
		}
	}
	return out, nil
}
