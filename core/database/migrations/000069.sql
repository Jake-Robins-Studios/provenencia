-- S15-62: a format names a metadata field with no level, {meta.key}, and the
-- engine reads it from the nearest level that holds a value. Rewrite every
-- stored format (the seed's and a researcher's own) from {source.meta.K},
-- {artifact.meta.K} and {graph.meta.K}, and the same after a "|", to
-- {meta.K}. A chain this leaves as {meta.K|meta.K} reads as one option.
UPDATE source_types SET citation_full = replace(replace(replace(replace(replace(replace(citation_full,
	'{source.meta.', '{meta.'), '|source.meta.', '|meta.'),
	'{artifact.meta.', '{meta.'), '|artifact.meta.', '|meta.'),
	'{graph.meta.', '{meta.'), '|graph.meta.', '|meta.')
WHERE citation_full IS NOT NULL;
UPDATE source_types SET citation_short = replace(replace(replace(replace(replace(replace(citation_short,
	'{source.meta.', '{meta.'), '|source.meta.', '|meta.'),
	'{artifact.meta.', '{meta.'), '|artifact.meta.', '|meta.'),
	'{graph.meta.', '{meta.'), '|graph.meta.', '|meta.')
WHERE citation_short IS NOT NULL;
UPDATE source_types SET citation_list = replace(replace(replace(replace(replace(replace(citation_list,
	'{source.meta.', '{meta.'), '|source.meta.', '|meta.'),
	'{artifact.meta.', '{meta.'), '|artifact.meta.', '|meta.'),
	'{graph.meta.', '{meta.'), '|graph.meta.', '|meta.')
WHERE citation_list IS NOT NULL;
