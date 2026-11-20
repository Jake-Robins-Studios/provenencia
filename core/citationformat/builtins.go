package citationformat

import (
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// Builtin is a placeholder that is not metadata, named directly under its
// level: {source.title}. The table is the one declaration of them.
type Builtin struct {
	Level vocabkey.Level
	// Name is the bare name: "date" for {source.date}.
	Name string
	// Date: the value is a DateValue, written in citation terms.
	Date bool
	// Options are the options the placeholder takes after a colon.
	Options []Option
	// AlwaysSet: the value is never empty, so a chain holding it is never needed.
	AlwaysSet bool
	// UnknownText prints when the researcher marked the value unknown.
	UnknownText string
}

// The target of each built-in, for code that sets or reads one's value. The
// table below is the one declaration; a test holds these to it.
var (
	SourceTitle   = Target{Level: vocabkey.LevelSource, Builtin: "title"}
	SourceType    = Target{Level: vocabkey.LevelSource, Builtin: "type"}
	SourceDate    = Target{Level: vocabkey.LevelSource, Builtin: "date"}
	ArtifactLabel = Target{Level: vocabkey.LevelArtifact, Builtin: "label"}
	GraphName     = Target{Level: vocabkey.LevelGraph, Builtin: "name"}
	CitationPage  = Target{Level: vocabkey.LevelCitation, Builtin: "page"}
	CitationImage = Target{Level: vocabkey.LevelCitation, Builtin: "image"}
	CitationLabel = Target{Level: vocabkey.LevelCitation, Builtin: "label"}
)

var builtins = []Builtin{
	{Level: vocabkey.LevelSource, Name: "title", AlwaysSet: true},
	{Level: vocabkey.LevelSource, Name: "type", AlwaysSet: true},
	{Level: vocabkey.LevelSource, Name: "date", Date: true, Options: []Option{OptionYear, OptionFull}, UnknownText: "n.d."},
	{Level: vocabkey.LevelArtifact, Name: "label", AlwaysSet: true},
	{Level: vocabkey.LevelGraph, Name: "name", AlwaysSet: true},
	{Level: vocabkey.LevelCitation, Name: "page", UnknownText: "unpaginated"},
	{Level: vocabkey.LevelCitation, Name: "image"},
	{Level: vocabkey.LevelCitation, Name: "label"},
}

// Builtins returns every built-in placeholder, a new slice in order on each
// call.
func Builtins() []Builtin {
	out := slices.Clone(builtins)
	for i := range out {
		out[i].Options = slices.Clone(out[i].Options)
	}
	return out
}

// LookupBuiltin finds the built-in called name at level l.
func LookupBuiltin(l vocabkey.Level, name string) (Builtin, bool) {
	i, ok := builtinRow(l, name)
	if !ok {
		return Builtin{}, false
	}
	b := builtins[i]
	b.Options = slices.Clone(b.Options)
	return b, true
}

// builtinRow is the index in builtins of the built-in called name at level l.
func builtinRow(l vocabkey.Level, name string) (int, bool) {
	i := slices.IndexFunc(builtins, func(b Builtin) bool { return b.Level == l && b.Name == name })
	return i, i >= 0
}

// ListFormAllows reports whether the list form may read level l: it describes
// the Source as a whole, so only the Source level.
func ListFormAllows(l vocabkey.Level) bool { return l == vocabkey.LevelSource }

// InListForm reports whether the list form may use b.
func (b Builtin) InListForm() bool { return ListFormAllows(b.Level) }

func (b Builtin) hasOption(o Option) bool { return slices.Contains(b.Options, o) }
