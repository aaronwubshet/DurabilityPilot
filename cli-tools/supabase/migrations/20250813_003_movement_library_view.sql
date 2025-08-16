-- Denormalized adapter for the iOS app expected Movement shape
-- Use a materialized view for performance and to avoid complex queries in the app

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
    json_agg(s.name ORDER BY s.name) AS sports_impacted
  FROM library.exercise_sports es
  JOIN public.sports s ON s.id = es.sport_id
  GROUP BY es.exercise_id
)
SELECT
  e.id::int AS id,
  e.name,
  e.description,
  e.video_url,
  -- Derive joints/muscles from tags where possible; adjust mapping logic later as needed
  COALESCE((SELECT json_agg(tag) FROM json_array_elements_text(COALESCE(tag_lists.tags, '[]'::json)) tag WHERE tag LIKE ANY (ARRAY['%ankle%','%knee%','%hip%','%shoulder%','%elbow%','%torso%'])), '[]'::json) AS joints_impacted,
  COALESCE((SELECT json_agg(tag) FROM json_array_elements_text(COALESCE(tag_lists.tags, '[]'::json)) tag WHERE tag LIKE ANY (ARRAY['%quad%','%hamstring%','%glute%','%back%','%chest%','%core%'])), '[]'::json) AS muscles_impacted,
  COALESCE(si.super_metrics_impacted, '[]'::json) AS super_metrics_impacted,
  COALESCE(sport_lists.sports_impacted, '[]'::json) AS sports_impacted,
  -- Static intensity options for now; can be extended via tags or a new table
  '["reps","weight","distance","time"]'::json AS intensity_options,
  COALESCE(si.recovery_impact_score, 0.0) AS recovery_impact_score,
  COALESCE(si.resilience_impact_score, 0.0) AS resilience_impact_score,
  COALESCE(si.results_impact_score, 0.0) AS results_impact_score
FROM library.exercises e
LEFT JOIN tag_lists ON tag_lists.exercise_id = e.id
LEFT JOIN supermetric_impacts si ON si.exercise_id = e.id
LEFT JOIN sport_lists ON sport_lists.exercise_id = e.id;

-- Helper to refresh the materialized view
-- Unique index required for CONCURRENT refresh; we will use non-concurrent refresh to avoid TX issues
CREATE UNIQUE INDEX IF NOT EXISTS ux_movement_library_id ON public.movement_library (id);

CREATE OR REPLACE FUNCTION public.refresh_movement_library()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW public.movement_library;
END$$;

-- Indexes for common filters
CREATE INDEX IF NOT EXISTS idx_movement_library_name ON public.movement_library (name);


