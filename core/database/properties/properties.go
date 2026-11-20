// Package properties accesses the properties vocabulary table with audited mutations.
package properties

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/slug"
	"github.com/google/uuid"
)

var ErrInvalid = apperr.New(apperr.CodePropertiesInvalid, apperr.KindUser)

// ErrDuplicateKey is returned by Create when the label-derived key already
// names a user-origin Property.
var ErrDuplicateKey = apperr.New(apperr.CodePropertiesDuplicateKey, apperr.KindConflict)

// ErrLocked is returned by Update when the target is plugin-origin.
var ErrLocked = apperr.New(apperr.CodePropertiesInvalid, apperr.KindUser)

// ErrInUse is returned by Delete when observations or property terms still
// reference the Property. Type bindings CASCADE and are not a blocker.
var ErrInUse = apperr.New(apperr.CodePropertiesInUse, apperr.KindConflict)

// ErrOriginLocked is returned by Delete when the Property is plugin-origin
// or product-seeded (provenencia).
var ErrOriginLocked = apperr.New(apperr.CodePropertiesOriginLocked, apperr.KindConflict)

const (
	// sqlInsert is the one insert of a new Property.
	sqlInsert = `INSERT INTO properties (id, key, origin, label, description, value_type, cardinality)
		VALUES (?, ?, ?, ?, ?, ?, ?)`
	sqlLookup = `SELECT id, key, origin, label, COALESCE(description, ''), value_type, cardinality
		FROM properties WHERE key = ? AND origin = ?`
	sqlGetByID = `SELECT id, key, origin, label, COALESCE(description, ''), value_type, cardinality
		FROM properties WHERE id = ?`
	sqlList = `SELECT id, key, origin, label, COALESCE(description, ''), value_type, cardinality
		FROM properties ORDER BY label COLLATE NOCASE, origin, key`
	sqlUpdate = `UPDATE properties SET label = ?, description = ?, cardinality = ? WHERE id = ?`
	sqlDelete = `DELETE FROM properties WHERE id = ?`
)

// Property is one properties row.
type Property struct {
	ID          []byte
	Key         string
	Origin      string
	Label       string
	Description string
	ValueType   string
	// Cardinality is single or multiple. Empty on input means single.
	Cardinality string
	// UsedBy is how many Observations and terms hold this Property: the
	// delete-impact total, so a Property is deletable only at 0. Type bindings
	// do not count. Only List and Update populate it; other readers leave it 0.
	UsedBy int
}

// rowFields is the audit view of a Property: the one column list that create,
// update and delete changes are built from. Description is present only when
// not empty.
func rowFields(p Property) map[string]any {
	fields := map[string]any{
		"id":          database.UUIDString(p.ID),
		"key":         p.Key,
		"origin":      p.Origin,
		"label":       p.Label,
		"value_type":  p.ValueType,
		"cardinality": p.Cardinality,
	}
	if p.Description != "" {
		fields["description"] = p.Description
	}
	return fields
}

// UpsertTx inserts or updates by (key, origin) on tx and returns the id and the
// row changes. Missing: a new Property, one create change. Present: label,
// description and cardinality are written and one update change names what
// differs; nothing differing writes nothing and returns no change. A stored
// value type that differs from the input's is ErrInvalid (an Observation
// stores its value by type). An empty cardinality is single. A non-empty p.ID
// is ErrInvalid. The caller records the changes.
func UpsertTx(tx *database.Tx, p Property) ([]byte, []rowchange.Change, error) {
	if tx == nil || len(p.ID) != 0 {
		return nil, nil, ErrInvalid
	}
	p.Key = strings.TrimSpace(p.Key)
	p.Origin = strings.TrimSpace(p.Origin)
	p.Label = strings.TrimSpace(p.Label)
	p.Description = strings.TrimSpace(p.Description)
	p.ValueType = strings.TrimSpace(p.ValueType)
	p.Cardinality = strings.TrimSpace(p.Cardinality)
	if p.Cardinality == "" {
		p.Cardinality = propertymeta.CardinalitySingle
	}
	if p.Key == "" || p.Label == "" || !vocabkey.ValidOrigin(p.Origin) || !valueTypeOK(p.ValueType) || !cardinalityAllowed(p.ValueType, p.Cardinality) {
		return nil, nil, ErrInvalid
	}
	existing, err := LookupTx(tx.Tx, p.Key, p.Origin)
	if errors.Is(err, sql.ErrNoRows) {
		uid, err := uuid.NewV7()
		if err != nil {
			return nil, nil, err
		}
		p.ID = uid[:]
		if _, err := tx.Exec(sqlInsert, p.ID, p.Key, p.Origin, p.Label, database.NullString(p.Description), p.ValueType, p.Cardinality); err != nil {
			return nil, nil, err
		}
		return append([]byte(nil), p.ID...), []rowchange.Change{rowchange.Created("property", p.ID, rowFields(p))}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	if existing.ValueType != p.ValueType {
		return nil, nil, ErrInvalid
	}
	next := existing
	next.Label, next.Description, next.Cardinality = p.Label, p.Description, p.Cardinality
	change := rowchange.Updated("property", existing.ID, rowFields(existing), rowFields(next), "id", "key", "origin")
	if change == nil {
		return append([]byte(nil), existing.ID...), nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, next.Label, database.NullString(next.Description), next.Cardinality, existing.ID); err != nil {
		return nil, nil, err
	}
	return append([]byte(nil), existing.ID...), []rowchange.Change{*change}, nil
}

// Create mints a kebab-case key from label and inserts a user-origin Property.
// The caller records the returned change as create_property.
// value_type = term and depiction are registry/Install only — Create refuses
// them for researchers (researcherCreatable).
// An empty cardinality is single.
func Create(tx *database.Tx, userID []byte, label, valueType, description, cardinality string) (Property, []rowchange.Change, error) {
	if tx == nil {
		return Property{}, nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Property{}, nil, err
	}
	valueType = strings.TrimSpace(valueType)
	if !researcherCreatable(valueType) {
		return Property{}, nil, ErrInvalid
	}
	key := slug.Kebab(label)
	if key == "" {
		return Property{}, nil, ErrInvalid
	}
	if _, err := LookupTx(tx.Tx, key, vocabkey.OriginUser); err == nil {
		return Property{}, nil, ErrDuplicateKey.WithParams(key)
	} else if !errors.Is(err, sql.ErrNoRows) {
		return Property{}, nil, err
	}

	uid, err := uuid.NewV7()
	if err != nil {
		return Property{}, nil, err
	}
	id := uid[:]
	label = strings.TrimSpace(label)
	description = strings.TrimSpace(description)
	cardinality = strings.TrimSpace(cardinality)
	if cardinality == "" {
		cardinality = propertymeta.CardinalitySingle
	}
	if label == "" || !cardinalityAllowed(valueType, cardinality) {
		return Property{}, nil, ErrInvalid
	}
	if _, err := tx.Exec(sqlInsert, id, key, vocabkey.OriginUser, label, database.NullString(description), valueType, cardinality); err != nil {
		return Property{}, nil, err
	}
	created := Property{
		ID:          append([]byte(nil), id...),
		Key:         key,
		Origin:      vocabkey.OriginUser,
		Label:       label,
		Description: description,
		ValueType:   valueType,
		Cardinality: cardinality,
	}
	return created, []rowchange.Change{rowchange.Created("property", created.ID, rowFields(created))}, nil
}

// Update patches label, description, and cardinality for a project Property
// (user or provenencia). Key, origin, and value_type are immutable. An empty
// cardinality leaves the stored one. Provenencia cardinality is fixed:
// changing it returns ErrLocked, as does a plugin-origin Property. An empty
// diff returns no changes. The caller records update_property.
func Update(tx *database.Tx, userID, id []byte, label, valueType, description, cardinality string) (Property, []rowchange.Change, error) {
	if tx == nil {
		return Property{}, nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return Property{}, nil, err
	}
	label = strings.TrimSpace(label)
	valueType = strings.TrimSpace(valueType)
	description = strings.TrimSpace(description)
	cardinality = strings.TrimSpace(cardinality)
	if len(id) != 16 || label == "" || !valueTypeOK(valueType) {
		return Property{}, nil, ErrInvalid
	}
	existing, err := GetByIDTx(tx.Tx, id)
	if err != nil {
		return Property{}, nil, err
	}
	if !vocabkey.Editable(existing.Origin) {
		return Property{}, nil, ErrLocked
	}
	if valueType != existing.ValueType {
		return Property{}, nil, ErrInvalid
	}
	if cardinality == "" {
		cardinality = existing.Cardinality
	}
	if !cardinalityAllowed(existing.ValueType, cardinality) {
		return Property{}, nil, ErrInvalid
	}
	cardinalityChanged := cardinality != existing.Cardinality
	if cardinalityChanged && existing.Origin != vocabkey.OriginUser {
		return Property{}, nil, ErrLocked
	}

	next := existing
	next.Label, next.Description, next.Cardinality = label, description, cardinality
	change := rowchange.Updated("property", existing.ID, rowFields(existing), rowFields(next), "id", "key", "origin")
	used, err := deleteimpact.InboundTotal(tx.Tx, catalogmodel.KindProperty, id)
	if err != nil {
		return Property{}, nil, err
	}
	next.UsedBy = used
	if change == nil {
		return next, nil, nil
	}
	if _, err := tx.Exec(sqlUpdate, label, database.NullString(description), cardinality, id); err != nil {
		return Property{}, nil, err
	}
	return next, []rowchange.Change{*change}, nil
}

// GetByID returns the Property with the given id, or sql.ErrNoRows.
func GetByID(c *database.Catalog, id []byte) (Property, error) {
	db, err := c.DB()
	if err != nil {
		return Property{}, err
	}
	if len(id) != 16 {
		return Property{}, ErrInvalid
	}
	return scanProperty(db.QueryRow(sqlGetByID, id))
}

// GetByIDTx returns the Property with the given id on an open transaction.
func GetByIDTx(tx *sql.Tx, id []byte) (Property, error) {
	if len(id) != 16 {
		return Property{}, ErrInvalid
	}
	return scanProperty(tx.QueryRow(sqlGetByID, id))
}

// Lookup returns the Property for (key, origin), or sql.ErrNoRows.
func Lookup(c *database.Catalog, key, origin string) (Property, error) {
	db, err := c.DB()
	if err != nil {
		return Property{}, err
	}
	return LookupTx(db, key, origin)
}

// LookupTx returns the Property for (key, origin) on an open transaction.
func LookupTx(q database.Querier, key, origin string) (Property, error) {
	key = strings.TrimSpace(key)
	origin = strings.TrimSpace(origin)
	if key == "" || origin == "" {
		return Property{}, ErrInvalid
	}
	return scanProperty(q.QueryRow(sqlLookup, key, origin))
}

// List returns all properties rows, each with its UsedBy total, read in one
// transaction.
func List(c *database.Catalog) ([]Property, error) {
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	rows, err := tx.Query(sqlList)
	if err != nil {
		return nil, err
	}
	var out []Property
	for rows.Next() {
		var p Property
		if err := rows.Scan(&p.ID, &p.Key, &p.Origin, &p.Label, &p.Description, &p.ValueType, &p.Cardinality); err != nil {
			rows.Close()
			return nil, err
		}
		out = append(out, p)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	err = deleteimpact.FillUsedBy(tx, catalogmodel.KindProperty, out,
		func(p Property) []byte { return p.ID }, func(p *Property, n int) { p.UsedBy = n })
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Delete erases a user-origin Property when no observations or terms
// reference it. Its type bindings are released and audited before it goes
// (the FK cascade stays as a backstop). Seeded and plugin-origin rows are
// origin_locked even when unused. The caller records delete_property.
func Delete(tx *database.Tx, userID, id []byte) ([]rowchange.Change, error) {
	if tx == nil {
		return nil, ErrInvalid
	}
	if err := database.RequireUserID(userID, ErrInvalid); err != nil {
		return nil, err
	}
	if len(id) != 16 {
		return nil, ErrInvalid
	}
	prev, err := GetByIDTx(tx.Tx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrInvalid
	}
	if err != nil {
		return nil, err
	}

	report, err := deleteimpact.Impact(tx.Tx, catalogmodel.KindProperty, id)
	if err != nil {
		return nil, err
	}
	if err := deleteimpact.Refuse(report, deleteimpact.Codes{
		InUse: ErrInUse, OriginLocked: ErrOriginLocked, NotFound: ErrInvalid,
	}); err != nil {
		return nil, err
	}
	released, err := deleteimpact.ReleaseFacets(tx, catalogmodel.KindProperty, id)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(sqlDelete, id); err != nil {
		return nil, err
	}
	return append(released, rowchange.Deleted("property", id, rowFields(prev))), nil
}

func valueTypeOK(vt string) bool {
	_, ok := propertymeta.Rule(vt)
	return ok
}

// researcherCreatable lists the value types a researcher may give a new
// Property: the propertymeta.Types rows marked creatable.
func researcherCreatable(valueType string) bool {
	r, ok := propertymeta.Rule(valueType)
	return ok && r.ResearcherCreatable
}

// cardinalityAllowed is cardinalityOK, and not multiple for a single-only type.
func cardinalityAllowed(valueType, cardinality string) bool {
	if !cardinalityOK(cardinality) {
		return false
	}
	r, _ := propertymeta.Rule(valueType)
	return !(r.SingleOnly && cardinality == propertymeta.CardinalityMultiple)
}

func cardinalityOK(cardinality string) bool {
	return cardinality == propertymeta.CardinalitySingle || cardinality == propertymeta.CardinalityMultiple
}

func scanProperty(row database.Scanner) (Property, error) {
	var p Property
	err := row.Scan(&p.ID, &p.Key, &p.Origin, &p.Label, &p.Description, &p.ValueType, &p.Cardinality)
	if err != nil {
		return Property{}, err
	}
	return p, nil
}
