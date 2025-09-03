-- Generated Supabase Schema
-- Extracted on: 2025-09-02T21:29:22.762Z

CREATE SEQUENCE IF NOT EXISTS assessments_id_seq;
CREATE SEQUENCE IF NOT EXISTS equipment_id_seq;
CREATE SEQUENCE IF NOT EXISTS goals_id_seq;
CREATE SEQUENCE IF NOT EXISTS injuries_id_seq;
CREATE SEQUENCE IF NOT EXISTS sports_id_seq;

-- Table: assessment_results
CREATE TABLE IF NOT EXISTS assessment_results (
  assessment_id bigint NOT NULL,
  profile_id uuid NOT NULL,
  body_area text NOT NULL,
  durability_score double precision NOT NULL,
  range_of_motion_score double precision NOT NULL,
  flexibility_score double precision NOT NULL,
  functional_strength_score double precision NOT NULL,
  mobility_score double precision NOT NULL,
  aerobic_capacity_score double precision NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  id integer NOT NULL
);

-- Table: assessments
CREATE TABLE IF NOT EXISTS assessments (
  assessment_id bigint DEFAULT nextval('assessments_id_seq'::regclass) NOT NULL,
  profile_id uuid NOT NULL,
  video_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table: block_types
CREATE TABLE IF NOT EXISTS block_types (
  id smallint NOT NULL,
  slug text NOT NULL,
  label text NOT NULL,
  render_order smallint NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: body_parts
CREATE TABLE IF NOT EXISTS body_parts (
  id integer NOT NULL,
  body_part text NOT NULL,
  joint text,
  muscle_group text,
  tendon text
);

-- Table: dose_metrics
CREATE TABLE IF NOT EXISTS dose_metrics (
  key text NOT NULL,
  display_name text NOT NULL,
  unit text NOT NULL,
  description text DEFAULT ''::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  id uuid DEFAULT gen_random_uuid() NOT NULL
);

-- Table: equipment
CREATE TABLE IF NOT EXISTS equipment (
  id integer DEFAULT nextval('equipment_id_seq'::regclass) NOT NULL,
  name text NOT NULL
);

-- Table: facilities
CREATE TABLE IF NOT EXISTS facilities (
  id bigint NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  location text
);

-- Table: goals
CREATE TABLE IF NOT EXISTS goals (
  id integer DEFAULT nextval('goals_id_seq'::regclass) NOT NULL,
  name text NOT NULL
);

-- Table: injuries
CREATE TABLE IF NOT EXISTS injuries (
  id integer DEFAULT nextval('injuries_id_seq'::regclass) NOT NULL,
  name text NOT NULL
);

-- Table: modules
CREATE TABLE IF NOT EXISTS modules (
  id smallint NOT NULL,
  key text NOT NULL,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: movement_block_items
CREATE TABLE IF NOT EXISTS movement_block_items (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  block_id uuid NOT NULL,
  sequence integer NOT NULL,
  movement_id uuid NOT NULL,
  default_dose jsonb DEFAULT '{}'::jsonb NOT NULL
);

-- Table: movement_blocks
CREATE TABLE IF NOT EXISTS movement_blocks (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  block_type_id smallint NOT NULL,
  slug text,
  required_equipment ARRAY DEFAULT '{}'::integer[] NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: movement_content
CREATE TABLE IF NOT EXISTS movement_content (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  movement_id uuid NOT NULL,
  locale text DEFAULT 'en'::text NOT NULL,
  title text,
  short_description text,
  long_description text,
  coaching_cues jsonb DEFAULT '[]'::jsonb,
  safety_notes text,
  version integer DEFAULT 1 NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  primary_image_path text,
  primary_image_alt text,
  demo_video_path text,
  demo_video_mime text,
  thumbnail_path text,
  gallery jsonb DEFAULT '[]'::jsonb NOT NULL,
  captions jsonb DEFAULT '[]'::jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: movement_patterns
CREATE TABLE IF NOT EXISTS movement_patterns (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  pattern_type_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: movements
CREATE TABLE IF NOT EXISTS movements (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  pattern_id uuid NOT NULL,
  default_module_impact_vector jsonb DEFAULT '{}'::jsonb NOT NULL,
  default_sport_impact_vector jsonb DEFAULT '{}'::jsonb NOT NULL,
  is_assessment boolean DEFAULT false NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  default_goal_impact_vector jsonb DEFAULT '{}'::jsonb NOT NULL,
  default_body_part_impact_vector jsonb DEFAULT '{}'::jsonb NOT NULL,
  default_injury_flags jsonb DEFAULT jsonb_build_object('indication', '[]'::jsonb, 'contraindication', '[]'::jsonb) NOT NULL,
  default_super_metric_impact_vector jsonb DEFAULT '{}'::jsonb NOT NULL,
  allowed_dose_metric_ids ARRAY DEFAULT '{}'::uuid[] NOT NULL,
  required_equipment ARRAY DEFAULT '{}'::integer[] NOT NULL
);

-- Table: pattern_types
CREATE TABLE IF NOT EXISTS pattern_types (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  intensity_schema text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: profile_equipment
CREATE TABLE IF NOT EXISTS profile_equipment (
  profile_id uuid NOT NULL,
  equipment_id integer NOT NULL,
  reported_at timestamp with time zone DEFAULT now()
);

-- Table: profile_goals
CREATE TABLE IF NOT EXISTS profile_goals (
  profile_id uuid NOT NULL,
  goal_id integer NOT NULL,
  reported_at timestamp with time zone DEFAULT now()
);

-- Table: profile_injuries
CREATE TABLE IF NOT EXISTS profile_injuries (
  profile_id uuid NOT NULL,
  injury_id integer NOT NULL,
  other_injury_text text,
  is_active boolean DEFAULT true,
  reported_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table: profile_movement_blacklist
CREATE TABLE IF NOT EXISTS profile_movement_blacklist (
  profile_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  movement_uuid uuid
);

-- Table: profile_sports
CREATE TABLE IF NOT EXISTS profile_sports (
  profile_id uuid NOT NULL,
  sport_id integer NOT NULL,
  reported_at timestamp with time zone DEFAULT now()
);

-- Table: profiles
CREATE TABLE IF NOT EXISTS profiles (
  id uuid NOT NULL,
  first_name text,
  last_name text,
  age integer,
  sex text,
  height_cm numeric,
  weight_kg numeric,
  is_pilot boolean DEFAULT false,
  training_plan_info text,
  training_plan_image_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  assessment_completed boolean DEFAULT false,
  onboarding_completed boolean DEFAULT false,
  date_of_birth date
);

-- Table: program_phases
CREATE TABLE IF NOT EXISTS program_phases (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  program_id uuid NOT NULL,
  phase_index smallint NOT NULL,
  weeks_count smallint NOT NULL
);

-- Table: program_weeks
CREATE TABLE IF NOT EXISTS program_weeks (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  program_id uuid NOT NULL,
  phase_id uuid NOT NULL,
  week_index smallint NOT NULL,
  phase_week_index smallint NOT NULL
);

-- Table: program_workout_blocks
CREATE TABLE IF NOT EXISTS program_workout_blocks (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  program_workout_id uuid NOT NULL,
  sequence smallint NOT NULL,
  movement_block_id uuid NOT NULL
);

-- Table: program_workouts
CREATE TABLE IF NOT EXISTS program_workouts (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  program_id uuid NOT NULL,
  week_id uuid NOT NULL,
  day_index smallint NOT NULL,
  title text
);

-- Table: programs
CREATE TABLE IF NOT EXISTS programs (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  slug text,
  weeks integer NOT NULL,
  workouts_per_week integer NOT NULL,
  version integer DEFAULT 1 NOT NULL,
  created_by uuid,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Table: sports
CREATE TABLE IF NOT EXISTS sports (
  id integer DEFAULT nextval('sports_id_seq'::regclass) NOT NULL,
  name text NOT NULL
);

-- Table: super_metrics
CREATE TABLE IF NOT EXISTS super_metrics (
  id integer NOT NULL,
  key text NOT NULL,
  name text NOT NULL,
  unit text,
  position smallint DEFAULT 0 NOT NULL
);

ALTER TABLE assessment_results ADD CONSTRAINT assessment_results_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES assessments(assessment_id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE assessment_results ADD CONSTRAINT assessment_results_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE assessments ADD CONSTRAINT assessments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE movement_block_items ADD CONSTRAINT movement_block_items_block_id_fkey FOREIGN KEY (block_id) REFERENCES movement_blocks(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE movement_block_items ADD CONSTRAINT movement_block_items_movement_uuid_fkey FOREIGN KEY (movement_id) REFERENCES movements(id) ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE movement_blocks ADD CONSTRAINT movement_blocks_block_type_id_fkey FOREIGN KEY (block_type_id) REFERENCES block_types(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE movement_content ADD CONSTRAINT movement_content_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES movements(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE movement_patterns ADD CONSTRAINT movement_patterns_pattern_type_id_fkey FOREIGN KEY (pattern_type_id) REFERENCES pattern_types(id) ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE movements ADD CONSTRAINT movements_pattern_id_fkey FOREIGN KEY (pattern_id) REFERENCES movement_patterns(id) ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE profile_equipment ADD CONSTRAINT profile_equipment_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_equipment ADD CONSTRAINT profile_equipment_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_goals ADD CONSTRAINT profile_goals_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES goals(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_goals ADD CONSTRAINT profile_goals_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_injuries ADD CONSTRAINT profile_injuries_injury_id_fkey FOREIGN KEY (injury_id) REFERENCES injuries(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_injuries ADD CONSTRAINT profile_injuries_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_movement_blacklist ADD CONSTRAINT profile_movement_blacklist_movement_uuid_fkey FOREIGN KEY (movement_uuid) REFERENCES movements(id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE profile_movement_blacklist ADD CONSTRAINT profile_movement_blacklist_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_sports ADD CONSTRAINT profile_sports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_sports ADD CONSTRAINT profile_sports_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES sports(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE program_phases ADD CONSTRAINT program_phases_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE program_weeks ADD CONSTRAINT program_weeks_phase_id_fkey FOREIGN KEY (phase_id) REFERENCES program_phases(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE program_weeks ADD CONSTRAINT program_weeks_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE program_workout_blocks ADD CONSTRAINT program_workout_blocks_movement_block_id_fkey FOREIGN KEY (movement_block_id) REFERENCES movement_blocks(id) ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE program_workout_blocks ADD CONSTRAINT program_workout_blocks_program_workout_id_fkey FOREIGN KEY (program_workout_id) REFERENCES program_workouts(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE program_workouts ADD CONSTRAINT program_workouts_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE program_workouts ADD CONSTRAINT program_workouts_week_id_fkey FOREIGN KEY (week_id) REFERENCES program_weeks(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE programs ADD CONSTRAINT programs_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE SET NULL;

