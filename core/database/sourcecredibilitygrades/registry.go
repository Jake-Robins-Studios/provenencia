package sourcecredibilitygrades

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades/gradeorder"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

type seedGrade struct {
	Key, Label string
	SortOrder  int
}

// Declarative provenencia seed (create-time only).
var seedGrades = []seedGrade{
	{Key: "low_trust", Label: "Low trust", SortOrder: 1},
	{Key: gradeorder.DefaultKey, Label: "Standard", SortOrder: 2},
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
