-- Add unique constraints required for ON CONFLICT (name) upserts

ALTER TABLE IF EXISTS library.patterns
  ADD CONSTRAINT patterns_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.exercises
  ADD CONSTRAINT exercises_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.tags
  ADD CONSTRAINT tags_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.contexts
  ADD CONSTRAINT contexts_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.metrics
  ADD CONSTRAINT metrics_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.supermetrics
  ADD CONSTRAINT supermetrics_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.phases_ref
  ADD CONSTRAINT phases_ref_name_unique UNIQUE (name);

ALTER TABLE IF EXISTS library.injuries
  ADD CONSTRAINT injuries_name_unique UNIQUE (name);


