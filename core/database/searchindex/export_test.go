package searchindex

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
)

// SetNewGraphForTest replaces the graph builder ReprojectHandles uses and
// returns a function that restores it.
func SetNewGraphForTest(fn func(database.Querier) *graphcache.Graph) (restore func()) {
	old := newGraph
	newGraph = fn
	return func() { newGraph = old }
}

// DependentsOfForTest is dependentsOf.
func DependentsOfForTest(q database.Querier, keys []graphcache.InputKey) ([][]byte, error) {
	return dependentsOf(q, keys)
}

// DependentsOfHandlesForTest is dependentsOfHandles.
func DependentsOfHandlesForTest(q database.Querier, ids [][]byte) ([][]byte, error) {
	return dependentsOfHandles(q, ids)
}

// OldEndsForTest is oldEnds.
func OldEndsForTest(q database.Querier, ids [][]byte) (map[string][]graphcache.InputKey, error) {
	return oldEnds(q, ids)
}
