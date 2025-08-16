-- Seed library schema from CSVs using client-side \copy
-- Note: This script expects to be run via psql from a machine that has access to the CSV files on disk

-- Using absolute file paths for \copy to avoid variable substitution issues

-- Pattern Types
CREATE TEMP TABLE tmp_pattern_types(name TEXT, description TEXT);
\copy tmp_pattern_types FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/pattern_types.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.pattern_types(name, description)
SELECT DISTINCT ON (name) name, NULLIF(description,'')
FROM tmp_pattern_types
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Patterns (pattern_type by name)
CREATE TEMP TABLE tmp_patterns(name TEXT, pattern_type TEXT, description TEXT);
\copy tmp_patterns FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/patterns.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.patterns(name, pattern_type_id, description)
SELECT p.name,
       pt.id AS pattern_type_id,
       NULLIF(p.description,'')
FROM tmp_patterns p
JOIN library.pattern_types pt ON pt.name = p.pattern_type
ON CONFLICT (name) DO UPDATE SET pattern_type_id = EXCLUDED.pattern_type_id, description = EXCLUDED.description;

-- Exercises (pattern by name)
CREATE TEMP TABLE tmp_exercises(name TEXT, pattern TEXT, description TEXT, level TEXT);
\copy tmp_exercises FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/exercises.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.exercises(name, pattern_id, description, level, video_url)
SELECT e.name,
       pat.id AS pattern_id,
       NULLIF(e.description,''),
       NULLIF(e.level,''),
       NULL
FROM tmp_exercises e
LEFT JOIN library.patterns pat ON pat.name = e.pattern
ON CONFLICT (name) DO UPDATE SET pattern_id = EXCLUDED.pattern_id, description = EXCLUDED.description, level = EXCLUDED.level;

-- Tags
CREATE TEMP TABLE tmp_tags(name TEXT, category TEXT);
\copy tmp_tags FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/tags.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.tags(name, category)
SELECT DISTINCT ON (name) name, NULLIF(category,'')
FROM tmp_tags
ON CONFLICT (name) DO UPDATE SET category = EXCLUDED.category;

-- Contexts
CREATE TEMP TABLE tmp_contexts(name TEXT, description TEXT, equipment_available BOOLEAN, intensity_level TEXT, time_limit INT);
\copy tmp_contexts FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/contexts.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.contexts(name, description, equipment_available, intensity_level, time_limit)
SELECT DISTINCT ON (name) name, NULLIF(description,''), equipment_available, NULLIF(intensity_level,''), time_limit
FROM tmp_contexts
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description,
  equipment_available = EXCLUDED.equipment_available,
  intensity_level = EXCLUDED.intensity_level,
  time_limit = EXCLUDED.time_limit;

-- Metrics
-- Expecting columns: name,unit,description
CREATE TEMP TABLE tmp_metrics(name TEXT, unit TEXT, description TEXT);
\copy tmp_metrics FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/metrics.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.metrics(name, unit, description)
SELECT DISTINCT ON (name) name, NULLIF(unit,''), NULLIF(description,'') FROM tmp_metrics
ON CONFLICT (name) DO UPDATE SET unit = EXCLUDED.unit, description = EXCLUDED.description;

-- Supermetrics
CREATE TEMP TABLE tmp_supermetrics(name TEXT, description TEXT);
\copy tmp_supermetrics FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/supermetrics.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.supermetrics(name, description)
SELECT DISTINCT ON (name) name, NULLIF(description,'') FROM tmp_supermetrics
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Phases
CREATE TEMP TABLE tmp_phases(name TEXT, description TEXT);
\copy tmp_phases FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/phases.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.phases_ref(name, description)
SELECT DISTINCT ON (name) name, NULLIF(description,'') FROM tmp_phases
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Injuries
CREATE TEMP TABLE tmp_injuries(name TEXT, description TEXT);
\copy tmp_injuries FROM '/Users/aaronwubshet/Documents/KAI/app/Durability/schema_update_from_gpt/durability_system_package/seeds/injuries.csv' WITH (FORMAT csv, HEADER true);
INSERT INTO library.injuries(name, description)
SELECT DISTINCT ON (name) name, NULLIF(description,'') FROM tmp_injuries
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Build adapter and sync
SELECT public.refresh_movement_library();
SELECT public.sync_movements_from_library();


