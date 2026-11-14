package graphalign

import (
	"bytes"
	"slices"
	"strings"

	"github.com/mendahu/provenencia/core/connectrules"
	"github.com/mendahu/provenencia/core/vocabkey"
)

// ConnectionOutcome is what Done will do with one connection, as a code the
// page words. It is connectrules' filing decision, split by why a connection
// waits.
type ConnectionOutcome string

const (
	// ConnectionFiles: Done files the connection.
	ConnectionFiles ConnectionOutcome = ConnectionOutcome(connectrules.DecisionFiles)
	// ConnectionSkipped: an end is set to Skip.
	ConnectionSkipped ConnectionOutcome = "skipped"
	// ConnectionUnset: an end has no target yet.
	ConnectionUnset ConnectionOutcome = "unset"
	// ConnectionNotOnPage: an end is not on the page, or the connection is
	// not complete (no Subject at an end, two records at one, no type).
	ConnectionNotOnPage ConnectionOutcome = "not_on_page"
)

// ConnectionOutcomes lists every outcome: files, the three waits, then each
// refusal connectrules.Refusals reports.
func ConnectionOutcomes() []ConnectionOutcome {
	out := []ConnectionOutcome{ConnectionFiles, ConnectionSkipped, ConnectionUnset, ConnectionNotOnPage}
	for _, d := range connectrules.Refusals() {
		out = append(out, ConnectionOutcome(d))
	}
	return out
}

// PageBridge is one unfiled bridge Subject on the page's graph. Ends holds,
// per endpoint in rule order, the Subjects its Observations name, in graph
// order; Terms are its disambiguation term keys.
type PageBridge struct {
	ID      []byte
	TypeKey vocabkey.SubjectType
	Terms   []vocabkey.BridgeTerm
	Ends    [][][]byte
}

// EndTarget is where the page has put one Subject: a handle, TargetNew, or a
// wait (skipped, unset or not on the page).
type EndTarget struct {
	Target   Target
	HandleID []byte
	Waits    ConnectionOutcome
}

// Connection is the outcome for one bridge. Waiting is the Subject a wait
// names, nil for any other outcome.
type Connection struct {
	BridgeID []byte
	Outcome  ConnectionOutcome
	Waiting  []byte
}

// FiledLinks reads filed links: for each handle id, the handles its filed
// links of one bridge type and term lead to, from the rule's first endpoint to
// its second. A handle with no such link is absent from the answer.
type FiledLinks func(typeKey vocabkey.SubjectType, term vocabkey.BridgeTerm, handles [][]byte) (map[string][][]byte, error)

// Connections decides each bridge the way Done files it: in bridge id order,
// through connectrules, with the filed links filed reads, only as far as a loop
// check reaches, and the page's own earlier connections as the links a loop is
// checked against. A Subject absent from ends is not on the page. A bridge of
// an unknown type is left out. A read error stops the pass and is returned.
func Connections(bridges []PageBridge, ends map[string]EndTarget, filed FiledLinks) ([]Connection, error) {
	sorted := slices.Clone(bridges)
	slices.SortStableFunc(sorted, func(a, b PageBridge) int { return bytes.Compare(a.ID, b.ID) })
	pass := connectrules.NewFiled(func(rule connectrules.Bridge, term vocabkey.BridgeTerm) (*connectrules.Links, error) {
		return connectrules.NewLinksReading(func(records []string) (map[string][]string, error) {
			var handles [][]byte
			for _, r := range records {
				if id, ok := strings.CutPrefix(r, handlePrefix); ok {
					handles = append(handles, []byte(id))
				}
			}
			out := map[string][]string{}
			if len(handles) == 0 {
				return out, nil
			}
			got, err := filed(vocabkey.SubjectType(rule.BridgeTypeKey), term, handles)
			if err != nil {
				return nil, err
			}
			for from, tos := range got {
				for _, to := range tos {
					out[handlePrefix+from] = append(out[handlePrefix+from], handlePrefix+string(to))
				}
			}
			return out, nil
		}), nil
	})
	var out []Connection
	for _, b := range sorted {
		rule, ok := connectrules.LookupBridge(string(b.TypeKey))
		if !ok {
			continue
		}
		values := make([][]connectrules.Value, len(b.Ends))
		for i, subjects := range b.Ends {
			for _, id := range subjects {
				values[i] = append(values[i], endValue(id, ends))
			}
		}
		res, err := pass.Decide(rule, b.Terms, values)
		if err != nil {
			return nil, err
		}
		c := Connection{BridgeID: b.ID}
		switch res.Decision {
		case connectrules.DecisionFiles:
			c.Outcome = ConnectionFiles
		case connectrules.DecisionWaits:
			c.Outcome = ConnectionOutcome(res.Wait)
			c.Waiting = b.Ends[res.Endpoint][res.Value]
		case connectrules.DecisionIncomplete:
			c.Outcome = ConnectionNotOnPage
		default:
			c.Outcome = ConnectionOutcome(res.Decision)
		}
		out = append(out, c)
	}
	return out, nil
}

// handlePrefix and newPrefix mark a record key as a handle or a New record.
const (
	handlePrefix = "h:"
	newPrefix    = "n:"
)

// endValue is the record one Subject lands on, or why it has none. A handle
// and a New record key apart.
func endValue(id []byte, ends map[string]EndTarget) connectrules.Value {
	e, ok := ends[string(id)]
	switch {
	case !ok:
		return connectrules.Value{Wait: string(ConnectionNotOnPage)}
	case e.Waits != "":
		return connectrules.Value{Wait: string(e.Waits)}
	case e.Target == TargetNew:
		return connectrules.Value{Record: newPrefix + string(id)}
	}
	return connectrules.Value{Record: handlePrefix + string(e.HandleID)}
}
