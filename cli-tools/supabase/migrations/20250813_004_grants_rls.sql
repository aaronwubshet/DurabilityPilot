-- Grants and RLS for library schema and adapter view

-- Library schema is read-only for authenticated users; write only for service role
GRANT USAGE ON SCHEMA library TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA library TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA library GRANT SELECT ON TABLES TO authenticated;

-- Prevent public writes
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA library FROM anon, authenticated;

-- Adapter materialized view readable by authenticated
GRANT SELECT ON TABLE public.movement_library TO authenticated;

-- RLS not applicable to materialized views; ensure base tables are not writable
ALTER TABLE IF EXISTS library.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.pattern_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.supermetrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.phases_ref ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.injuries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.exercise_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.exercise_contraindications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.exercise_indications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.exercise_supermetric_impacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS library.exercise_sports ENABLE ROW LEVEL SECURITY;

-- Policies: read-all for authenticated; no writes
DO $$
DECLARE r RECORD; polname TEXT; BEGIN
  FOR r IN (
    SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'library'
  ) LOOP
    polname := r.tablename || '_read';
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies p
      WHERE p.schemaname = r.schemaname AND p.tablename = r.tablename AND p.policyname = polname
    ) THEN
      EXECUTE format('CREATE POLICY %I ON %I.%I FOR SELECT TO authenticated USING (true);', polname, r.schemaname, r.tablename);
    END IF;
  END LOOP;
END$$;


