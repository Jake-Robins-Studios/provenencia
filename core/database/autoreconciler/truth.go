package autoreconciler

import (
	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecodec"
)

func init() {
	graphcache.SetTruth(truthRows)
}

// truthRows is the reconcile Verify compares to a loaded node. It does not write.
func truthRows(q database.Querier, ids [][]byte) (map[string][]graphcache.TruthRow, error) {
	out := map[string][]graphcache.TruthRow{}
	ids = database.UniqueBlobIDs(ids)
	if len(ids) == 0 {
		return out, nil
	}
	err := sqlbatch.Each(ids, func(chunk [][]byte) error {
		groups, err := load(q, chunk)
		if err != nil {
			return err
		}
		for _, g := range groups {
			res, err := autoreconcile.Reconcile(ValueRules, g.valueType, g.candidates, nil, g.cardinality)
			if err != nil {
				return err
			}
			key := string(g.entityID)
			for i, cl := range res.Values {
				row, err := truthRow(g, i+1, cl)
				if err != nil {
					return err
				}
				out[key] = append(out[key], row)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func truthRow(g *group, rank int, cl autoreconcile.ReconciledValue) (graphcache.TruthRow, error) {
	v := cl.Value
	row := graphcache.TruthRow{
		PropertyID: append([]byte(nil), g.propertyID...),
		Rank:       rank,
		Reason:     string(cl.Reason),
		Scalar:     v.Scalar,
		TermID:     append([]byte(nil), v.TermID...),
		EntityID:   append([]byte(nil), v.EntityID...),
		Support:    cl.Support,
		Against:    cl.Against,
	}
	if v.Date != nil {
		b, err := valuecodec.MarshalDate(*v.Date)
		if err != nil {
			return graphcache.TruthRow{}, err
		}
		row.Date = b
	}
	if v.Name != nil {
		b, err := valuecodec.MarshalName(*v.Name)
		if err != nil {
			return graphcache.TruthRow{}, err
		}
		row.Name = b
	}
	if v.Depiction != nil {
		row.ImageFileID = append([]byte(nil), v.Depiction.ImageFileID...)
	}
	return row, nil
}
