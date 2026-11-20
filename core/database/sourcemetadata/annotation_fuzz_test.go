package sourcemetadata

import (
	"hash/fnv"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

// answersFrom resolves a target from the fuzz bytes: the target's hash picks a
// byte, and the byte's low bit says whether it has a value.
type answersFrom []byte

func (a answersFrom) Resolve(t citationformat.Target) citationformat.Value {
	if len(a) == 0 {
		return citationformat.Value{}
	}
	h := fnv.New32a()
	_, _ = h.Write([]byte(string(t.Level) + "|" + t.Builtin + "|" + t.Field.Key))
	_, _ = h.Write(t.Field.ID[:])
	if a[int(h.Sum32())%len(a)]&1 == 0 {
		return citationformat.Value{}
	}
	return citationformat.Value{Text: "v"}
}

// FuzzAnnotate feeds arbitrary format texts through the chain-to-board mapping
// a stored format reaches: parse, Requirements, needsAt at every level, then
// annotate every head. It must not panic.
func FuzzAnnotate(f *testing.F) {
	a, b := uuid.MustParse("00000000-0000-4000-8000-00000000000a"), uuid.MustParse("00000000-0000-4000-8000-00000000000b")
	tok := func(id uuid.UUID) string { return "#" + id.String() }
	f.Add("{source.meta."+tok(a)+"}.", "[{graph.meta."+tok(a)+"|source.meta."+tok(b)+"}]", "{citation.page|source.meta."+tok(b)+"}", []byte{1, 0, 1})
	f.Add("{source.date}, {citation.page|graph.meta."+tok(a)+"|artifact.meta."+tok(b)+"}", "{source.title}", "{source.meta."+tok(a)+"|source.title}", []byte{0})
	f.Add("[{source.meta."+tok(a)+"}]{source.meta."+tok(a)+"}", "{a", `\n`, []byte(nil))
	f.Fuzz(func(t *testing.T, full, short, list string, answers []byte) {
		var tpls []*citationformat.Template
		for _, in := range []struct {
			text string
			form citationformat.Form
		}{{full, citationformat.FormFull}, {short, citationformat.FormShort}, {list, citationformat.FormList}} {
			if tpl, _ := citationformat.Parse(in.text, in.form); tpl != nil {
				tpls = append(tpls, tpl)
			}
		}
		chains := citationformat.Requirements(tpls...)
		r := answersFrom(answers)
		for _, level := range []vocabkey.Level{vocabkey.LevelSource, vocabkey.LevelArtifact, vocabkey.LevelGraph} {
			ln := needsAt(chains, level)
			fields := map[string]metadatafields.Field{}
			for i, id := range ln.fieldIDs() {
				if i%2 == 0 {
					fields[string(id)] = metadatafields.Field{ID: id}
				}
			}
			for _, id := range ln.order {
				annotate(ln, fieldTarget(level, id), r, fields)
			}
			annotate(ln, citationformat.SourceDate, r, fields)
			annotate(ln, citationformat.CitationPage, r, fields)
		}
	})
}
