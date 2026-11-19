package conclusionsummaries

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
)

func countList(c *database.Catalog, list func(*database.Catalog) error) (int, error) {
	n := 0
	c.Graph().SetQueryCounterForTest(func() { n++ })
	defer c.Graph().SetQueryCounterForTest(nil)
	err := list(c)
	return n, err
}

// ListPersonsQueryCount lists Persons and reports how many graph queries it took.
func ListPersonsQueryCount(c *database.Catalog) (int, error) {
	return countList(c, func(c *database.Catalog) error {
		_, err := ListPersons(c)
		return err
	})
}

// ListEventsQueryCount lists Events and reports how many graph queries it took.
func ListEventsQueryCount(c *database.Catalog) (int, error) {
	return countList(c, func(c *database.Catalog) error {
		_, err := ListEvents(c)
		return err
	})
}

// ListPlacesQueryCount lists Places and reports how many graph queries it took.
func ListPlacesQueryCount(c *database.Catalog) (int, error) {
	return countList(c, func(c *database.Catalog) error {
		_, err := ListPlaces(c)
		return err
	})
}

// SortPersons, SortPlaces and SortEvents apply the list orders to rows;
// PlaceListKey and EventListKey are the keys they sort by.
var (
	SortPersons  = sortPersons
	SortPlaces   = sortPlaces
	SortEvents   = sortEvents
	PlaceListKey = placeListKey
	EventListKey = eventListKey
)

// TitleListKey is a title's list key.
func TitleListKey(title, ref string) ListKey { return titleListKey(title, ref) }

// DateListKey is a date's list key: a nil date is undated.
func DateListKey(v *datevalue.Value, ref string) ListKey { return dateKeyOf(v, ref).listKey() }

// SetInputKeyCapForTest lowers the per-call input key cap and returns the
// function that restores it.
func SetInputKeyCapForTest(n int) (restore func()) {
	old := inputKeyCap
	inputKeyCap = n
	return func() { inputKeyCap = old }
}

// HeldPlaceEntryForTest reports whether g holds an entry for the place.
func HeldPlaceEntryForTest(g *graphcache.Graph, id []byte) bool {
	_, ok := placeEntries.k.Peek(g, id)
	return ok
}

// PlaceEntryForTest returns whether the chain entry for the place is held and
// found, and the keys it is dropped by (the keys a summary row records for it).
func PlaceEntryForTest(g *graphcache.Graph, id []byte) (held, found bool, inputs []graphcache.InputKey) {
	e, ok := placeEntries.k.Peek(g, id)
	return ok, e.found, e.inputs
}

// PlacePageForTest returns whether the page entry for the place is held and the
// keys it is dropped by.
func PlacePageForTest(g *graphcache.Graph, id []byte) (held bool, inputs []graphcache.InputKey) {
	p, ok := placePages.k.Peek(g, id)
	return ok, p.inputs
}

// SetPlaceEntryCapForTest lowers the place entries g holds to n.
func SetPlaceEntryCapForTest(g *graphcache.Graph, n int) { placeEntries.k.SetCapForTest(g, n) }

// CorruptPlaceEntryForTest replaces the held entry's names so it no longer
// matches a fresh load.
func CorruptPlaceEntryForTest(g *graphcache.Graph, id []byte) {
	e, ok := placeEntries.k.Peek(g, id)
	if !ok {
		return
	}
	e.shell.Names = []string{"corrupt"}
	placeEntries.k.Set(g, id, e)
}

// FillPlaceEntriesForTest holds the entries of ids on g, as a chain read does.
func FillPlaceEntriesForTest(g *graphcache.Graph, ids ...[]byte) error {
	v, err := vocabulary(g)
	if err != nil {
		return err
	}
	_, err = placeEntries.of(g, v, ids)
	return err
}

// FillPlacePagesForTest holds the pages of ids on g, as the place page does.
func FillPlacePagesForTest(g *graphcache.Graph, ids ...[]byte) error {
	v, err := vocabulary(g)
	if err != nil {
		return err
	}
	_, err = placePages.of(g, v, ids)
	return err
}

// PlaceSuccessionForTest returns whether the succession entry for the place is
// held and the keys it is dropped by.
func PlaceSuccessionForTest(g *graphcache.Graph, id []byte) (held bool, inputs []graphcache.InputKey) {
	s, ok := placeSuccessions.k.Peek(g, id)
	return ok, s.inputs
}

// FillPlaceSuccessionsForTest holds the succession entries of ids on g, as a
// succession read does.
func FillPlaceSuccessionsForTest(g *graphcache.Graph, ids ...[]byte) error {
	v, err := vocabulary(g)
	if err != nil {
		return err
	}
	_, err = placeSuccessions.of(g, v, ids)
	return err
}
