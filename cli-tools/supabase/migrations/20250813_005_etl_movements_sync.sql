-- Optional: ETL to sync movement_library into public.movements for zero app changes

-- Ensure public.movements exists with expected columns
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='movements'
  ) THEN
    CREATE TABLE public.movements (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      video_url TEXT,
      joints_impacted JSONB,
      muscles_impacted JSONB,
      super_metrics_impacted JSONB
    );
  END IF;
END$$;

CREATE OR REPLACE FUNCTION public.sync_movements_from_library()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Upsert into public.movements from the materialized view
  INSERT INTO public.movements AS m (id, name, description, video_url, joints_impacted, muscles_impacted, super_metrics_impacted)
  SELECT id, name, description, video_url, joints_impacted, muscles_impacted, super_metrics_impacted
  FROM public.movement_library
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    video_url = EXCLUDED.video_url,
    joints_impacted = EXCLUDED.joints_impacted,
    muscles_impacted = EXCLUDED.muscles_impacted,
    super_metrics_impacted = EXCLUDED.super_metrics_impacted;
END$$;


