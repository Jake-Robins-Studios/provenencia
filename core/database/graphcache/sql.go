package graphcache

// sqlActivityByScope is every id's newest revision of one scope type, with the
// time of that revision (SQLite takes created_at from the MAX row).
const sqlActivityByScope = `SELECT sc.scope_id, MAX(t.revision), t.created_at
	FROM audit_transaction_scopes sc
	JOIN audit_transactions t ON t.id = sc.audit_transaction_id
	WHERE sc.scope_type = ?
	GROUP BY sc.scope_id`

func uniqueIDs(ids [][]byte) [][]byte {
	seen := map[string]bool{}
	var out [][]byte
	for _, id := range ids {
		if len(id) != 16 || seen[string(id)] {
			continue
		}
		seen[string(id)] = true
		out = append(out, id)
	}
	return out
}

func cloneID(id []byte) []byte {
	if len(id) == 0 {
		return nil
	}
	return append([]byte(nil), id...)
}

func sameID(a, b []byte) bool {
	return string(a) == string(b)
}
