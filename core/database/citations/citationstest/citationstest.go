// Package citationstest holds shared Citation fixtures for tests: creating a
// Citation with no Observations.
package citationstest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// PageLocator is the locator of a Citation that points at page 1 of its
// Artifact, the default Create gives one with no locator of its own.
const PageLocator = `{"version":1,"selectors":[{"type":"page","artifact_page":1}]}`

// Create makes a Citation with no Observations through the write pipeline. An
// empty LocatorJSON becomes PageLocator.
func Create(c *database.Catalog, userID []byte, in citations.CreateInput) (citations.Citation, error) {
	if in.LocatorJSON == "" {
		in.LocatorJSON = PageLocator
	}
	res, _, err := writes.Run(c, writes.Op{Action: "create_citation", UserID: userID},
		func(tx *database.Tx) (citations.CreateResult, []rowchange.Change, error) {
			return citations.CreateWithObservations(tx, userID, in, nil)
		})
	return res.Citation, err
}
