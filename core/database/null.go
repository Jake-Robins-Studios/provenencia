package database

import "strings"

// NullBlob binds an empty BLOB as SQL NULL, so an optional blob column such as
// a foreign-key id stores NULL rather than a zero-length value.
func NullBlob(b []byte) any {
	if len(b) == 0 {
		return nil
	}
	return b
}

// NullString binds an empty string as SQL NULL, so an optional text column
// stores NULL rather than "".
func NullString(s string) any {
	if s == "" {
		return nil
	}
	return s
}

// NullTrimmed trims s and binds an empty result as SQL NULL. NullString does
// not trim.
func NullTrimmed(s string) any {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	return s
}

// NullInt binds a nil pointer as SQL NULL and an integer as itself, so an
// optional integer column keeps 0 distinct from absent.
func NullInt(p *int) any {
	if p == nil {
		return nil
	}
	return *p
}

// NullInt64 binds a nil pointer as SQL NULL and an integer as itself, so an
// optional integer column keeps 0 distinct from absent.
func NullInt64(p *int64) any {
	if p == nil {
		return nil
	}
	return *p
}

// NullBool binds a nil pointer as SQL NULL and a bool as 0 or 1, so an
// optional boolean column keeps false distinct from absent.
func NullBool(p *bool) any {
	if p == nil {
		return nil
	}
	if *p {
		return int64(1)
	}
	return int64(0)
}
