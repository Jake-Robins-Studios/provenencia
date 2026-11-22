package citationformat_test

import (
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

func find(reqs []citationformat.Requirement, targets ...citationformat.Target) *citationformat.Requirement {
	for i := range reqs {
		if reflect.DeepEqual(reqs[i].Targets, targets) {
			return &reqs[i]
		}
	}
	return nil
}

func TestRequirements(t *testing.T) {
	src := vocabkey.LevelSource
	full := mustParse(t, censusFull, citationformat.FormFull)

	reqs := citationformat.Requirements(full)
	if r := find(reqs, meta("jurisdiction")); r == nil || r.Need != citationformat.NeedNeeded {
		t.Errorf("jurisdiction = %+v", r)
	}
	if r := find(reqs, meta("line_number")); r == nil || r.Need != citationformat.NeedUsed {
		t.Errorf("line number = %+v", r)
	}
	if r := find(reqs, builtin(src, "date")); r == nil || r.Need != citationformat.NeedNeeded {
		t.Errorf("date = %+v", r)
	}

	one := func(format string, form citationformat.Form) []citationformat.Requirement {
		return citationformat.Requirements(mustParse(t, format, form))
	}
	if r := one("{meta.short_title|source.title}", "full"); len(r) != 1 || r[0].Need != citationformat.NeedUsed {
		t.Errorf("always-set chain = %+v", r)
	}
	// A chain needed in the short form and used in the full.
	r := citationformat.Requirements(mustParse(t, "[{meta.x}]", "full"), mustParse(t, "{meta.x}", "short"))
	if len(r) != 1 || r[0].Need != citationformat.NeedNeeded {
		t.Errorf("needed in one = %+v", r)
	}
	r = citationformat.Requirements(mustParse(t, "{meta.x}", "short"), mustParse(t, "[{meta.x}]", "full"))
	if len(r) != 1 || r[0].Need != citationformat.NeedNeeded {
		t.Errorf("needed first = %+v", r)
	}
	// A date in two options and two forms is one requirement.
	r = citationformat.Requirements(mustParse(t, "{source.date:year}", "full"), mustParse(t, "{source.date}", "list"))
	if len(r) != 1 || r[0].Need != citationformat.NeedNeeded {
		t.Errorf("date = %+v", r)
	}
	// A field in two different chains is two requirements.
	r = one("{meta.x}{meta.x|source.title}", "full")
	if len(r) != 2 {
		t.Errorf("two chains = %+v", r)
	}
	// A chain keeps each target once.
	r = one("{meta.x|meta.x}", "full")
	if len(r) != 1 || !reflect.DeepEqual(r[0].Targets, []citationformat.Target{meta("x")}) {
		t.Errorf("repeated target = %+v", r)
	}
	// The same field in the full and the list form is two requirements: one
	// read nearest-first, one at the Source.
	r = citationformat.Requirements(mustParse(t, "{meta.x}", "full"), mustParse(t, "{meta.x}", "list"))
	if len(r) != 2 || r[0].Targets[0] != meta("x") || r[1].Targets[0] != (citationformat.Target{Level: src, Field: citationformat.FieldRef{Key: "x"}}) {
		t.Errorf("full and list = %+v", r)
	}
	if got := citationformat.Requirements(nil, nil); len(got) != 0 {
		t.Errorf("nil templates = %+v", got)
	}
}

func TestMissing(t *testing.T) {
	src := vocabkey.LevelSource
	reqs := citationformat.Requirements(mustParse(t, censusFull, citationformat.FormFull), mustParse(t, censusShort, citationformat.FormShort))
	onlyDate := values{builtin(src, "date"): date(datevaluetest.YMD(1880, 0, 0))}
	missing := citationformat.Missing(reqs, onlyDate)
	if len(missing) != 1 || !reflect.DeepEqual(missing[0].Targets, []citationformat.Target{meta("jurisdiction")}) {
		t.Fatalf("missing = %+v", missing)
	}

	// Month-only date: needed in full as year, in list as bare; either order.
	for _, order := range [][2]citationformat.Form{{"full", "list"}, {"list", "full"}} {
		texts := map[citationformat.Form]string{"full": "{source.date:year}", "list": "{source.date}"}
		reqs := citationformat.Requirements(mustParse(t, texts[order[0]], order[0]), mustParse(t, texts[order[1]], order[1]))
		got := citationformat.Missing(reqs, values{builtin(src, "date"): date(datevaluetest.YMD(0, 3, 0))})
		if len(got) != 0 {
			t.Errorf("%v: month-only date listed missing: %+v", order, got)
		}
	}

	needed := citationformat.Requirements(mustParse(t, "{meta.edition}", "full"))
	if got := citationformat.Missing(needed, values{meta("edition"): {Mark: valuemark.Mark{Unknown: true}}}); len(got) != 0 {
		t.Errorf("unknown listed missing: %+v", got)
	}
	if got := citationformat.Missing(needed, values{}); len(got) != 1 {
		t.Errorf("zero value not missing: %+v", got)
	}
	if got := citationformat.Missing(needed, nil); len(got) != 1 {
		t.Errorf("nil resolver not missing: %+v", got)
	}
	used := citationformat.Requirements(mustParse(t, "[{meta.edition}]", "full"))
	if got := citationformat.Missing(used, values{}); len(got) != 0 {
		t.Errorf("used listed missing: %+v", got)
	}
	for name, target := range map[string]citationformat.Target{
		"unknown_builtin_target": {Level: vocabkey.LevelSource, Builtin: "nope"},
		"builtin_at_wrong_level": {Level: vocabkey.LevelArtifact, Builtin: "date"},
	} {
		t.Run(name, func(t *testing.T) {
			req := citationformat.Requirement{Targets: []citationformat.Target{target}, Need: citationformat.NeedNeeded}
			got := citationformat.Missing([]citationformat.Requirement{req}, values{})
			if len(got) != 1 {
				t.Fatalf("missing = %+v", got)
			}
		})
	}
}

func TestNeedMax(t *testing.T) {
	const none citationformat.Need = ""
	needs := []citationformat.Need{none, citationformat.NeedUsed, citationformat.NeedNeeded}
	for i, a := range needs {
		for j, b := range needs {
			want := needs[max(i, j)]
			if got := a.Max(b); got != want {
				t.Errorf("%q.Max(%q) = %q, want %q", a, b, got, want)
			}
		}
	}
}
