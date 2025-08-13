
-- SQL schema for Durability AI

CREATE TABLE pattern_types (id SERIAL PRIMARY KEY, name TEXT NOT NULL UNIQUE, description TEXT);
CREATE TABLE patterns (id SERIAL PRIMARY KEY, name TEXT NOT NULL, pattern_type_id INT REFERENCES pattern_types(id), description TEXT);
CREATE TABLE exercises (id SERIAL PRIMARY KEY, name TEXT NOT NULL, pattern_id INT REFERENCES patterns(id), description TEXT, level TEXT);
CREATE TABLE tags (id SERIAL PRIMARY KEY, name TEXT NOT NULL, category TEXT);
CREATE TABLE contexts (id SERIAL PRIMARY KEY, name TEXT NOT NULL, description TEXT, equipment_available BOOLEAN, intensity_level TEXT, time_limit INT);
CREATE TABLE metrics (id SERIAL PRIMARY KEY, name TEXT NOT NULL, unit TEXT, description TEXT);
CREATE TABLE supermetrics (id SERIAL PRIMARY KEY, name TEXT NOT NULL, description TEXT);
CREATE TABLE phases (id SERIAL PRIMARY KEY, name TEXT NOT NULL, description TEXT);
CREATE TABLE injuries (id SERIAL PRIMARY KEY, name TEXT NOT NULL, description TEXT);
CREATE TABLE exercise_tags (exercise_id INT REFERENCES exercises(id), tag_id INT REFERENCES tags(id), PRIMARY KEY (exercise_id, tag_id));
CREATE TABLE exercise_contraindications (exercise_id INT REFERENCES exercises(id), injury_id INT REFERENCES injuries(id), PRIMARY KEY (exercise_id, injury_id));
CREATE TABLE exercise_indications (exercise_id INT REFERENCES exercises(id), injury_id INT REFERENCES injuries(id), PRIMARY KEY (exercise_id, injury_id));
