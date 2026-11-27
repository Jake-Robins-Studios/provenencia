// Package gradeorder reads a Source's credibility grade as an order relative to
// the provenencia default grade. It is SQL text only and imports no catalog
// package, so the graph cache and the readers above it share one definition.
package gradeorder

import "github.com/Jake-Robins-Studios/provenencia/core/vocabkey"

// DefaultKey is the provenencia grade a Source with no assessment reads as:
// every other grade weighs relative to it.
const DefaultKey = "standard"

// orderBound clamps a stored sort_order before it is subtracted, so the
// difference is always an INTEGER. Real grades are small; the bound only stops
// a crafted catalog from overflowing the column to REAL.
const orderBound = "1000000"

// Column is the select-list column that reads a Source's grade as its
// sort_order relative to the provenencia default grade (DefaultKey). No
// assessment, no grade, or no vocabulary reads as 0. It binds the alias sg
// (source_credibility_grades); Joins puts it in scope.
const Column = `COALESCE(MAX(-` + orderBound + `, MIN(` + orderBound + `, sg.sort_order)) - MAX(-` + orderBound + `, MIN(` + orderBound + `,
	(SELECT sort_order FROM source_credibility_grades
				WHERE key = '` + DefaultKey + `' AND origin = '` + vocabkey.OriginProvenencia + `'))), 0)`

// Joins is the join pair that binds sg (the Source's grade) and sca (its
// assessment) for Column. sourceIDExpr is the Source's id in the query, such as
// "s.id".
func Joins(sourceIDExpr string) string {
	return `LEFT JOIN source_credibility_assessments sca ON sca.source_id = ` + sourceIDExpr + `
		LEFT JOIN source_credibility_grades sg ON sg.id = sca.credibility_grade_id`
}
