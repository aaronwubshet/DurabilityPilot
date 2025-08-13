-- Generated Supabase Schema
-- Extracted on: 2025-08-13T20:54:33.279Z

CREATE SEQUENCE IF NOT EXISTS assessments_id_seq;
CREATE SEQUENCE IF NOT EXISTS daily_workout_movements_id_seq;
CREATE SEQUENCE IF NOT EXISTS daily_workouts_id_seq;
CREATE SEQUENCE IF NOT EXISTS equipment_id_seq;
CREATE SEQUENCE IF NOT EXISTS goals_id_seq;
CREATE SEQUENCE IF NOT EXISTS injuries_id_seq;
CREATE SEQUENCE IF NOT EXISTS movements_id_seq;
CREATE SEQUENCE IF NOT EXISTS plan_phases_id_seq;
CREATE SEQUENCE IF NOT EXISTS plans_id_seq;
CREATE SEQUENCE IF NOT EXISTS sports_id_seq;

-- Table: assessment_results
CREATE TABLE IF NOT EXISTS assessment_results (
  assessment_id integer NOT NULL,
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

-- Table: daily_workout_movements
CREATE TABLE IF NOT EXISTS daily_workout_movements (
  id bigint DEFAULT nextval('daily_workout_movements_id_seq'::regclass) NOT NULL,
  daily_workout_id bigint NOT NULL,
  movement_id integer NOT NULL,
  sequence integer NOT NULL,
  status text DEFAULT 'pending'::text,
  assigned_intensity jsonb,
  recovery_impact_score numeric(5,2),
  resilience_impact_score numeric(5,2),
  results_impact_score numeric(5,2)
);

-- Table: daily_workouts
CREATE TABLE IF NOT EXISTS daily_workouts (
  id bigint DEFAULT nextval('daily_workouts_id_seq'::regclass) NOT NULL,
  plan_phase_id bigint NOT NULL,
  workout_date date NOT NULL,
  status text DEFAULT 'pending'::text
);

-- Table: equipment
CREATE TABLE IF NOT EXISTS equipment (
  id integer DEFAULT nextval('equipment_id_seq'::regclass) NOT NULL,
  name text NOT NULL
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

-- Table: movements
CREATE TABLE IF NOT EXISTS movements (
  id integer DEFAULT nextval('movements_id_seq'::regclass) NOT NULL,
  name text NOT NULL,
  description text,
  video_url text,
  joints_impacted jsonb,
  muscles_impacted jsonb,
  super_metrics_impacted jsonb
);

-- Table: plan_phases
CREATE TABLE IF NOT EXISTS plan_phases (
  id bigint DEFAULT nextval('plan_phases_id_seq'::regclass) NOT NULL,
  plan_id bigint NOT NULL,
  phase_number integer NOT NULL,
  recovery_weight numeric(3,2) NOT NULL,
  resilience_weight numeric(3,2) NOT NULL,
  results_weight numeric(3,2) NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL
);

-- Table: plans
CREATE TABLE IF NOT EXISTS plans (
  id bigint DEFAULT nextval('plans_id_seq'::regclass) NOT NULL,
  profile_id uuid NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
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
  movement_id integer NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
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

-- Table: sports
CREATE TABLE IF NOT EXISTS sports (
  id integer DEFAULT nextval('sports_id_seq'::regclass) NOT NULL,
  name text NOT NULL
);

ALTER TABLE assessment_results ADD CONSTRAINT assessment_results_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES assessments(assessment_id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE assessment_results ADD CONSTRAINT assessment_results_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE assessments ADD CONSTRAINT assessments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE daily_workout_movements ADD CONSTRAINT daily_workout_movements_daily_workout_id_fkey FOREIGN KEY (daily_workout_id) REFERENCES daily_workouts(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE daily_workout_movements ADD CONSTRAINT daily_workout_movements_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES movements(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE daily_workouts ADD CONSTRAINT daily_workouts_plan_phase_id_fkey FOREIGN KEY (plan_phase_id) REFERENCES plan_phases(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE plan_phases ADD CONSTRAINT plan_phases_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES plans(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE plans ADD CONSTRAINT plans_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_equipment ADD CONSTRAINT profile_equipment_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_equipment ADD CONSTRAINT profile_equipment_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_goals ADD CONSTRAINT profile_goals_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES goals(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_goals ADD CONSTRAINT profile_goals_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_injuries ADD CONSTRAINT profile_injuries_injury_id_fkey FOREIGN KEY (injury_id) REFERENCES injuries(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_injuries ADD CONSTRAINT profile_injuries_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_movement_blacklist ADD CONSTRAINT profile_movement_blacklist_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES movements(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_movement_blacklist ADD CONSTRAINT profile_movement_blacklist_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_sports ADD CONSTRAINT profile_sports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE profile_sports ADD CONSTRAINT profile_sports_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES sports(id) ON UPDATE NO ACTION ON DELETE CASCADE;

