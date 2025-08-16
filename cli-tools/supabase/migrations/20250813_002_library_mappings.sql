-- Mapping/junction tables for exercises
CREATE TABLE IF NOT EXISTS library.exercise_tags (
  exercise_id INT REFERENCES library.exercises(id) ON DELETE CASCADE,
  tag_id INT REFERENCES library.tags(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, tag_id)
);

CREATE TABLE IF NOT EXISTS library.exercise_contraindications (
  exercise_id INT REFERENCES library.exercises(id) ON DELETE CASCADE,
  injury_id INT REFERENCES library.injuries(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, injury_id)
);

CREATE TABLE IF NOT EXISTS library.exercise_indications (
  exercise_id INT REFERENCES library.exercises(id) ON DELETE CASCADE,
  injury_id INT REFERENCES library.injuries(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, injury_id)
);

-- Impacts of an exercise on supermetrics used by plan logic and UI mapping
CREATE TABLE IF NOT EXISTS library.exercise_supermetric_impacts (
  exercise_id INT REFERENCES library.exercises(id) ON DELETE CASCADE,
  supermetric_id INT REFERENCES library.supermetrics(id) ON DELETE CASCADE,
  recovery_weight NUMERIC(5,2) DEFAULT 0.0,
  resilience_weight NUMERIC(5,2) DEFAULT 0.0,
  results_weight NUMERIC(5,2) DEFAULT 0.0,
  PRIMARY KEY (exercise_id, supermetric_id)
);

-- Optional mapping to sports; app uses public.sports
CREATE TABLE IF NOT EXISTS library.exercise_sports (
  exercise_id INT REFERENCES library.exercises(id) ON DELETE CASCADE,
  sport_id INT REFERENCES public.sports(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, sport_id)
);


