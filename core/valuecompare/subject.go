package valuecompare

import (
	"bytes"
	"slices"
)

// subject compares subject values (a Place, say) by the entity each names and
// by the containment the value carries: Value.Within lists the entities that
// contain Value.Entity at the value's date. The same entity is Same. One
// entity inside the other's Within, and not the reverse, is Contains, with the
// container as the broader side. Anything else, two entities that contain each
// other included, is Different. A value with no Entity is Unknown (empty).
// Matching leaves Entity empty (subjectprofile.Value), so only a caller that
// fills it, the reconciler for an event's places, sees a relation.
type subject struct{}

func (subject) compare(a, b Value, r Rules) (Result, Detail) {
	switch {
	case len(a.Entity) == 0 || len(b.Entity) == 0:
		return Result{Relation: Unknown}, Detail{Cause: CauseEmpty}
	case bytes.Equal(a.Entity, b.Entity):
		return Result{Relation: Same, Similarity: 1}, Detail{Cause: CauseExact}
	}
	aIn, bIn := within(a, b.Entity), within(b, a.Entity)
	switch {
	case aIn && !bIn:
		return Result{Relation: Contains, Similarity: r.Subjects.Partial}, Detail{Broader: SideB, Cause: CauseWithin}
	case bIn && !aIn:
		return Result{Relation: Contains, Similarity: r.Subjects.Partial}, Detail{Broader: SideA, Cause: CauseWithin}
	}
	return Result{Relation: Different}, Detail{Cause: CauseNoMatch}
}

// within reports whether v's Within holds the entity.
func within(v Value, entity []byte) bool {
	return slices.ContainsFunc(v.Within, func(w []byte) bool { return bytes.Equal(w, entity) })
}

// key is the entity at both levels: a subject has no looser form.
func (subject) key(v Value, _ Relation, _ Rules) (string, bool) {
	return string(v.Entity), len(v.Entity) > 0
}
