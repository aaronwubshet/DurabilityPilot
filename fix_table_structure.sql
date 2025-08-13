-- Fix assessment_results table structure

-- 1. Check if there's an 'id' column that should be the primary key
SELECT 'Checking for id column:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns 
WHERE table_name = 'assessment_results'
AND column_name = 'id';

-- 2. Add an auto-incrementing id column if it doesn't exist
ALTER TABLE assessment_results 
ADD COLUMN IF NOT EXISTS id SERIAL;

-- 3. Drop the existing composite primary key
ALTER TABLE assessment_results 
DROP CONSTRAINT IF EXISTS assessment_results_pkey;

-- 4. Add a new primary key on the id column
ALTER TABLE assessment_results 
ADD CONSTRAINT assessment_results_pkey PRIMARY KEY (id);

-- 5. Add a unique constraint on the combination of assessment_id, profile_id, and body_area
ALTER TABLE assessment_results 
ADD CONSTRAINT assessment_results_unique_assessment_profile_body 
UNIQUE (assessment_id, profile_id, body_area);

-- 6. Verify the new structure
SELECT 'New table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns 
WHERE table_name = 'assessment_results'
ORDER BY ordinal_position;

-- 7. Verify constraints
SELECT 'New constraints:' as info;
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'assessment_results'
ORDER BY tc.constraint_type, kcu.column_name;
