package handlers

import (
	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusiondetails"
	"google.golang.org/protobuf/proto"
)

// GetProvenanceRecords reads one provenance sheet: the fields a row names, each
// with its records, the records' citations rendered, and what the read used.
// A row is the (owner, Property) pairs of a field row or a Person's life row;
// a request with neither, an unspecified kind, an unknown owner or a row the
// Person lacks answers no owners.
func GetProvenanceRecords(in []byte) ([]byte, error) {
	var req engine.GetProvenanceRecordsRequest
	if err := proto.Unmarshal(in, &req); err != nil {
		return nil, unmarshalErr("get_provenance_records", err)
	}
	var sheet conclusiondetails.SheetRequest
	switch row := req.GetRow().(type) {
	case *engine.GetProvenanceRecordsRequest_Fields:
		for _, p := range row.Fields.GetPairs() {
			owner, err := parseID(p.GetOwnerId())
			if err != nil {
				return nil, err
			}
			property, err := parseID(p.GetPropertyId())
			if err != nil {
				return nil, err
			}
			sheet.Pairs = append(sheet.Pairs, conclusiondetails.Pair{OwnerID: owner, PropertyID: property})
		}
	case *engine.GetProvenanceRecordsRequest_Derived:
		person, err := parseID(row.Derived.GetPersonId())
		if err != nil {
			return nil, err
		}
		sheet.PersonID = person
		for kind, wire := range derivedRowKinds {
			if wire == row.Derived.GetKind() {
				sheet.Kind = kind
			}
		}
	}
	var out *engine.GetProvenanceRecordsResponse
	err := withProjectCatalog(req.GetProjectDir(), func(c *database.Catalog) error {
		inputs := c.Graph().PageInputs()
		got, err := conclusiondetails.ProvenanceSheet(c, sheet, inputs)
		if err != nil {
			return err
		}
		out = &engine.GetProvenanceRecordsResponse{Citations: renderedCitationsProto(got.Citations)}
		for _, o := range got.Owners {
			po := ownerFieldProto(o)
			for _, oc := range o.Field.Outcomes {
				po.Field.Outcomes = append(po.Field.Outcomes, reconcilerOutcomeProto(oc))
			}
			out.Owners = append(out.Owners, po)
		}
		out.Inputs = pageInputsProto(inputs)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return proto.Marshal(out)
}
