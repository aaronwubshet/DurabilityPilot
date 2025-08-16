-- Create library schema and core reference tables
CREATE SCHEMA IF NOT EXISTS library;

-- Core reference tables (namespaced to avoid conflicts with public schema)
CREATE TABLE IF NOT EXISTS library.pattern_types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS library.patterns (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  pattern_type_id INT REFERENCES library.pattern_types(id) ON DELETE SET NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS library.exercises (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  pattern_id INT REFERENCES library.patterns(id) ON DELETE SET NULL,
  description TEXT,
  level TEXT,
  video_url TEXT
);

CREATE TABLE IF NOT EXISTS library.tags (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT
);

CREATE TABLE IF NOT EXISTS library.contexts (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  equipment_available BOOLEAN,
  intensity_level TEXT,
  time_limit INT
);

CREATE TABLE IF NOT EXISTS library.metrics (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  unit TEXT,
  description TEXT
);

CREATE TABLE IF NOT EXISTS library.supermetrics (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT
);

-- Avoid conflict with existing public.plan_phases
CREATE TABLE IF NOT EXISTS library.phases_ref (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT
);

-- Optional: maintain a library copy of injuries for mapping by name, while app continues to use public.injuries
CREATE TABLE IF NOT EXISTS library.injuries (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT
);


