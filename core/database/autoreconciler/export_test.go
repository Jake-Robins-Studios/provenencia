package autoreconciler

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
)

// LoadQueryCount loads the given handles and reports how many queries it took.
func LoadQueryCount(q database.Querier, ids [][]byte) (int, error) {
	n := 0
	g := graphcache.Over(q)
	g.SetQueryCounterForTest(func() { n++ })
	_, err := load(g, ids)
	return n, err
}
