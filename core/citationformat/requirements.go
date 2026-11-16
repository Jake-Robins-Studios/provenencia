package citationformat

import "slices"

// Need is how much a format wants a value.
type Need string

const (
	// NeedNeeded: outside every group, so an empty value leaves a hole.
	NeedNeeded Need = "needed"
	// NeedUsed: inside a group, or in a chain that always has a value, so an
	// empty value drops its group or falls through.
	NeedUsed Need = "used"
)

// Requirement is one chain of targets a format reads, met when any has a value.
type Requirement struct {
	Targets []Target
	Need    Need
}

// Requirements derives what the templates read: one requirement per distinct
// sequence of targets, in order of first appearance, needed when any template
// needs it. Nil templates are skipped.
func Requirements(ts ...*Template) []Requirement {
	var out []Requirement
	for _, t := range ts {
		if t == nil {
			continue
		}
		collect(t.root, false, &out)
	}
	return out
}

func collect(nodes []node, inGroup bool, out *[]Requirement) {
	for _, n := range nodes {
		switch n.kind {
		case nodePlaceholder:
			targets := make([]Target, len(n.chain))
			need := NeedNeeded
			if inGroup {
				need = NeedUsed
			}
			for i, r := range n.chain {
				targets[i] = r.Target
				if r.Builtin != "" {
					if b, _ := LookupBuiltin(r.Level, r.Builtin); b.AlwaysSet {
						need = NeedUsed
					}
				}
			}
			add(out, targets, need)
		case nodeItalic:
			collect(n.children, inGroup, out)
		case nodeGroup:
			collect(n.children, true, out)
		}
	}
}

func add(out *[]Requirement, targets []Target, need Need) {
	for i := range *out {
		if slices.Equal((*out)[i].Targets, targets) {
			if need == NeedNeeded {
				(*out)[i].Need = NeedNeeded
			}
			return
		}
	}
	*out = append(*out, Requirement{Targets: targets, Need: need})
}

// Missing returns the needed requirements with no answered target, in input
// order. Each target is tested at the full form with no option, the most a date
// can print, so the answer does not depend on which template came first.
func Missing(reqs []Requirement, r Resolver) []Requirement {
	var out []Requirement
	for _, req := range reqs {
		if req.Need != NeedNeeded {
			continue
		}
		met := slices.ContainsFunc(req.Targets, func(t Target) bool {
			_, answered := resolve(Ref{Target: t}, FormFull, r)
			return answered
		})
		if !met {
			out = append(out, req)
		}
	}
	return out
}
