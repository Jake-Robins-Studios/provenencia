package sourcecredibilitygrades

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// DefaultKey is the provenencia grade a Source with no assessment reads as:
// every other grade weighs relative to it.
const DefaultKey = "standard"

// orderBound clamps a stored sort_order before it is subtracted, so the
// difference is always an INTEGER. Real grades are small; the bound only stops
// a crafted catalog from overflowing the column to REAL.
const orderBound = "1000000"

// RelativeOrderColumn is the select-list column that reads a Source's grade as
// its sort_order relative to the provenencia default grade (DefaultKey). No
// assessment, no grade, or no vocabulary reads as 0. It binds the alias sg
// (source_credibility_grades); RelativeOrderJoins puts it in scope.
const RelativeOrderColumn = `COALESCE(MAX(-` + orderBound + `, MIN(` + orderBound + `, sg.sort_order)) - MAX(-` + orderBound + `, MIN(` + orderBound + `,
	(SELECT sort_order FROM source_credibility_grades
				WHERE key = '` + DefaultKey + `' AND origin = '` + vocabkey.OriginProvenencia + `'))), 0)`

// RelativeOrderJoins is the join pair that binds sg (the Source's grade) and
// sca (its assessment) for RelativeOrderColumn. sourceIDExpr is the Source's id
// in the query, such as "s.id".
func RelativeOrderJoins(sourceIDExpr string) string {
	return `LEFT JOIN source_credibility_assessments sca ON sca.source_id = ` + sourceIDExpr + `
		LEFT JOIN source_credibility_grades sg ON sg.id = sca.credibility_grade_id`
}

type seedGrade struct {
	Key, Label string
	SortOrder  int
}

// Declarative provenencia seed (create-time only).
var seedGrades = []seedGrade{
	{Key: "low_trust", Label: "Low trust", SortOrder: 1},
	{Key: DefaultKey, Label: "Standard", SortOrder: 2},
	{Key: "high_trust", Label: "High trust", SortOrder: 3},
}

// ActionInstall is the audit action of the create-time grade seed. No revision
// carries it while source_credibility_grades is None in the effects registry:
// writes.Run commits a None-only change list without a revision.
const ActionInstall = "install_source_credibility_grades"

// Install writes the provenencia credibility grade registry into a new catalog
// on tx and returns the grade changes. It composes on the caller's transaction
// and never calls writes.Run (core/writes imports this package):
// onboarding.createCatalog runs it in one writes.Call. Call only at create time.
func Install(tx *database.Tx) ([]rowchange.Change, error) {
	if tx == nil {
		return nil, ErrInvalid
	}
	var changes []rowchange.Change
	for _, g := range seedGrades {
		_, cs, err := UpsertTx(tx, Grade{
			Key:       g.Key,
			Origin:    vocabkey.OriginProvenencia,
			Label:     g.Label,
			SortOrder: g.SortOrder,
		})
		if err != nil {
			return nil, err
		}
		changes = append(changes, cs...)
	}
	return changes, nil
}
