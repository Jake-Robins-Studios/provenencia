package kinship

import "github.com/Jake-Robins-Studios/provenencia/core/vocabkey"

// eventPattern is one fact an event implies between two of its participants:
// the event type, the roles at each end of the implied link, and the
// relationship term it implies. The implied link's A is the relationship's
// person end.
type eventPattern struct {
	code  Pattern
	event vocabkey.EventType
	a, b  []vocabkey.Role
	term  vocabkey.BridgeTerm
}

// eventPatterns are the product's event patterns, in output order. A catalog's
// own roles and event types imply nothing.
var eventPatterns = []eventPattern{
	{PatternMarriageSpouses, vocabkey.EventMarriage, []vocabkey.Role{vocabkey.RoleSubject}, []vocabkey.Role{vocabkey.RoleSubject}, vocabkey.TermSpouse},
	{PatternBirthParents, vocabkey.EventBirth, []vocabkey.Role{vocabkey.RoleFather, vocabkey.RoleMother}, []vocabkey.Role{vocabkey.RoleSubject}, vocabkey.TermParent},
}

// PivotKind is the Subject type a pattern's pivot is: the event for an event
// pattern, the parent between for a chain, the shared parent for a sibling, and
// "" for a code that is no pattern.
func (p Pattern) PivotKind() vocabkey.SubjectType {
	for _, ep := range eventPatterns {
		if ep.code == p {
			return vocabkey.Event
		}
	}
	if p == PatternParentOfParent || p == PatternSharedParent {
		return vocabkey.Person
	}
	return ""
}

// ImpliesSpouse reports whether the pattern is one whose implied relationship
// is a spouse: its pivots are the events that marry two people.
func (p Pattern) ImpliesSpouse() bool {
	for _, ep := range eventPatterns {
		if ep.code == p {
			return ep.term == vocabkey.TermSpouse
		}
	}
	return false
}

// SpouseEventTypes are the event types of the patterns that imply a spouse, in
// eventPatterns order.
func SpouseEventTypes() []vocabkey.EventType {
	var out []vocabkey.EventType
	for _, ep := range eventPatterns {
		if ep.term == vocabkey.TermSpouse {
			out = append(out, ep.event)
		}
	}
	return out
}

// Patterns are the product's pattern codes: each event pattern in order, then
// the parent-of-parent chain. Page-only codes (PatternSharedParent) are not in
// it.
func Patterns() []Pattern {
	out := make([]Pattern, 0, len(eventPatterns)+1)
	for _, ep := range eventPatterns {
		out = append(out, ep.code)
	}
	return append(out, PatternParentOfParent)
}
