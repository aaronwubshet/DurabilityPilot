-- Ontology extensions: enums, columns, assessment profile tables, and movement_library update

-- 1) Enums for strict typing
DO $$ BEGIN
  CREATE TYPE public.metric_target_type AS ENUM ('joint','muscle','movement','systemic');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.rom_mode AS ENUM ('passive','active','loaded','speed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.eval_method AS ENUM ('cv','coach','self_report','sensor');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2) Extend library.metrics to encode ontology fields
ALTER TABLE IF EXISTS library.metrics
  ADD COLUMN IF NOT EXISTS target_type public.metric_target_type,
  ADD COLUMN IF NOT EXISTS target_id TEXT,
  ADD COLUMN IF NOT EXISTS rom_mode public.rom_mode,
  ADD COLUMN IF NOT EXISTS supermetric_id INT REFERENCES library.supermetrics(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS eval_method public.eval_method,
  ADD COLUMN IF NOT EXISTS context JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS quality_flags TEXT[] DEFAULT '{}'::text[];

-- 3) Extend library.exercises with static attributes used by scoring/UX
ALTER TABLE IF EXISTS library.exercises
  ADD COLUMN IF NOT EXISTS required_equipment TEXT[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS base_suitability JSONB DEFAULT '{"recovery":0, "resilience":0, "results":0}'::jsonb,
  ADD COLUMN IF NOT EXISTS assessment_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS assessment_protocol_notes TEXT;

-- 4) Assessment profile: per-exercise metric requirements and thresholds
CREATE TABLE IF NOT EXISTS library.exercise_assessment_metrics (
  exercise_id INT REFERENCES library.exercises(id) ON DELETE CASCADE,
  metric_id INT REFERENCES library.metrics(id) ON DELETE CASCADE,
  required BOOLEAN DEFAULT true,
  thresholds JSONB,
  PRIMARY KEY (exercise_id, metric_id)
);

-- 5) Add weight to sport relevance mapping
ALTER TABLE IF EXISTS library.exercise_sports
  ADD COLUMN IF NOT EXISTS weight NUMERIC(5,2) DEFAULT 0.50 CHECK (weight >= 0 AND weight <= 1);

-- 6) Update movement_library to include sport weights (drop and recreate)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_matviews WHERE schemaname = 'public' AND matviewname = 'movement_library'
  ) THEN
    DROP INDEX IF EXISTS public.ux_movement_library_id;
    DROP MATERIALIZED VIEW public.movement_library;
  END IF;
END $$;

CREATE MATERIALIZED VIEW IF NOT EXISTS public.movement_library AS
WITH tag_lists AS (
  SELECT
    et.exercise_id,
    json_agg(t.name ORDER BY t.name) AS tags
  FROM library.exercise_tags et
  JOIN library.tags t ON t.id = et.tag_id
  GROUP BY et.exercise_id
),
supermetric_impacts AS (
  SELECT
    esi.exercise_id,
    json_agg(sm.name ORDER BY sm.name) AS super_metrics_impacted,
    COALESCE(AVG(esi.recovery_weight)::numeric, 0.0) AS recovery_impact_score,
    COALESCE(AVG(esi.resilience_weight)::numeric, 0.0) AS resilience_impact_score,
    COALESCE(AVG(esi.results_weight)::numeric, 0.0) AS results_impact_score
  FROM library.exercise_supermetric_impacts esi
  JOIN library.supermetrics sm ON sm.id = esi.supermetric_id
  GROUP BY esi.exercise_id
),
sport_lists AS (
  SELECT
    es.exercise_id,
    json_agg(json_build_object('sport', s.name, 'weight', COALESCE(es.weight, 0.5)) ORDER BY s.name) AS sports_impacted
  FROM library.exercise_sports es
  JOIN public.sports s ON s.id = es.sport_id
  GROUP BY es.exercise_id
)
SELECT
  e.id::int AS id,
  e.name,
  e.description,
  e.video_url,
  COALESCE((SELECT json_agg(tag) FROM json_array_elements_text(COALESCE(tag_lists.tags, '[]'::json)) tag WHERE tag LIKE ANY (ARRAY['%ankle%','%knee%','%hip%','%shoulder%','%elbow%','%torso%'])), '[]'::json) AS joints_impacted,
  COALESCE((SELECT json_agg(tag) FROM json_array_elements_text(COALESCE(tag_lists.tags, '[]'::json)) tag WHERE tag LIKE ANY (ARRAY['%quad%','%hamstring%','%glute%','%back%','%chest%','%core%'])), '[]'::json) AS muscles_impacted,
  COALESCE(si.super_metrics_impacted, '[]'::json) AS super_metrics_impacted,
  COALESCE(sport_lists.sports_impacted, '[]'::json) AS sports_impacted,
  '[]'::json AS intensity_options,
  COALESCE(si.recovery_impact_score, 0.0) AS recovery_impact_score,
  COALESCE(si.resilience_impact_score, 0.0) AS resilience_impact_score,
  COALESCE(si.results_impact_score, 0.0) AS results_impact_score
FROM library.exercises e
LEFT JOIN tag_lists ON tag_lists.exercise_id = e.id
LEFT JOIN supermetric_impacts si ON si.exercise_id = e.id
LEFT JOIN sport_lists ON sport_lists.exercise_id = e.id;

CREATE UNIQUE INDEX IF NOT EXISTS ux_movement_library_id ON public.movement_library (id);

CREATE OR REPLACE FUNCTION public.refresh_movement_library()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW public.movement_library;
END$$;

CREATE INDEX IF NOT EXISTS idx_movement_library_name ON public.movement_library (name);


