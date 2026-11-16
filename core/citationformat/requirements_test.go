package citationformat_test

import (
	"reflect"
	"testing"

	"github.com/mendahu/provenencia/core/citationformat"
	"github.com/mendahu/provenencia/core/datevalue/datevaluetest"
	"github.com/mendahu/provenencia/core/valuemark"
	"github.com/mendahu/provenencia/core/vocabkey"
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
	src, gr := vocabkey.LevelSource, vocabkey.LevelGraph
	formFull, censusFull := seedFormat(t, 1)
	full := mustParse(t, censusFull, formFull)

	reqs := citationformat.Requirements(full)
	if r := find(reqs, meta(src, "jurisdiction")); r == nil || r.Need != citationformat.NeedNeeded {
		t.Errorf("jurisdiction = %+v", r)
	}
	if r := find(reqs, meta(gr, "line_number"), meta(src, "line_number")); r == nil || r.Need != citationformat.NeedUsed {
		t.Errorf("line chain = %+v", r)
	}
	if r := find(reqs, builtin(src, "date")); r == nil || r.Need != citationformat.NeedNeeded {
		t.Errorf("date = %+v", r)
	}

	one := func(format string, form citationformat.Form) []citationformat.Requirement {
		return citationformat.Requirements(mustParse(t, format, form))
	}
	if r := one("{source.meta.short_title|source.title}", "full"); len(r) != 1 || r[0].Need != citationformat.NeedUsed {
		t.Errorf("always-set chain = %+v", r)
	}
	// A chain needed in the short form and used in the full.
	r := citationformat.Requirements(mustParse(t, "[{source.meta.x}]", "full"), mustParse(t, "{source.meta.x}", "short"))
	if len(r) != 1 || r[0].Need != citationformat.NeedNeeded {
		t.Errorf("needed in one = %+v", r)
	}
	r = citationformat.Requirements(mustParse(t, "{source.meta.x}", "short"), mustParse(t, "[{source.meta.x}]", "full"))
	if len(r) != 1 || r[0].Need != citationformat.NeedNeeded {
		t.Errorf("needed first = %+v", r)
	}
	// A date in two options and two forms is one requirement.
	r = citationformat.Requirements(mustParse(t, "{source.date:year}", "full"), mustParse(t, "{source.date}", "list"))
	if len(r) != 1 || r[0].Need != citationformat.NeedNeeded {
		t.Errorf("date = %+v", r)
	}
	// A field in two different chains is two requirements.
	r = one("{source.meta.x}{graph.meta.x|source.meta.x}", "full")
	if len(r) != 2 {
		t.Errorf("two chains = %+v", r)
	}
	if got := citationformat.Requirements(nil, nil); len(got) != 0 {
		t.Errorf("nil templates = %+v", got)
	}
}

func TestMissing(t *testing.T) {
	src := vocabkey.LevelSource
	formFull, censusFull := seedFormat(t, 1)
	formShort, censusShort := seedFormat(t, 2)
	reqs := citationformat.Requirements(mustParse(t, censusFull, formFull), mustParse(t, censusShort, formShort))
	onlyDate := values{builtin(src, "date"): date(datevaluetest.YMD(1880, 0, 0))}
	missing := citationformat.Missing(reqs, onlyDate)
	if len(missing) != 1 || !reflect.DeepEqual(missing[0].Targets, []citationformat.Target{meta(src, "jurisdiction")}) {
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

	needed := citationformat.Requirements(mustParse(t, "{source.meta.edition}", "full"))
	if got := citationformat.Missing(needed, values{meta(src, "edition"): {Mark: valuemark.Mark{Unknown: true}}}); len(got) != 0 {
		t.Errorf("unknown listed missing: %+v", got)
	}
	if got := citationformat.Missing(needed, values{}); len(got) != 1 {
		t.Errorf("zero value not missing: %+v", got)
	}
	if got := citationformat.Missing(needed, nil); len(got) != 1 {
		t.Errorf("nil resolver not missing: %+v", got)
	}
	used := citationformat.Requirements(mustParse(t, "[{source.meta.edition}]", "full"))
	if got := citationformat.Missing(used, values{}); len(got) != 0 {
		t.Errorf("used listed missing: %+v", got)
	}
}
