package handlers

import (
	"github.com/mendahu/provenencia/api/proto/engine"
	"github.com/mendahu/provenencia/core/valuemark"
)

// valueMarkProto is a mark on the wire: nil for the zero mark, so a value with
// no mark carries no message.
func valueMarkProto(m valuemark.Mark) *engine.ValueMark {
	if m == (valuemark.Mark{}) {
		return nil
	}
	return &engine.ValueMark{Unknown: m.Unknown, Supplied: m.Supplied}
}

// parseValueMark reads a mark off the wire. An absent message is the zero mark.
// The stores check the mark (valuemark.Validate), not this.
func parseValueMark(m *engine.ValueMark) valuemark.Mark {
	return valuemark.Mark{Unknown: m.GetUnknown(), Supplied: m.GetSupplied()}
}
