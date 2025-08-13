-- Fix the id column to be a proper identity column

-- 1. Drop the existing id column
ALTER TABLE assessment_results DROP COLUMN IF EXISTS id;

-- 2. Add a new id column as GENERATED ALWAYS AS IDENTITY
ALTER TABLE assessment_results 
ADD COLUMN id INTEGER GENERATED ALWAYS AS IDENTITY;

-- 3. Make it the primary key
ALTER TABLE assessment_results 
ADD CONSTRAINT assessment_results_pkey PRIMARY KEY (id);

-- 4. Verify the new structure
SELECT 'Fixed table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns 
WHERE table_name = 'assessment_results'
ORDER BY ordinal_position;

-- 5. Test inserting a record to make sure it works
SELECT 'Testing insert...' as info;
INSERT INTO assessment_results (
    assessment_id, 
    profile_id, 
    body_area, 
    durability_score, 
    range_of_motion_score, 
    flexibility_score, 
    functional_strength_score, 
    mobility_score, 
    aerobic_capacity_score
) VALUES (
    31, 
    '13B02BF5-640F-4120-A151-ABDA678A2F35'::uuid, 
    'Test Area', 
    0.8, 
    0.7, 
    0.6, 
    0.9, 
    0.8, 
    0.7
) RETURNING id, assessment_id, profile_id, body_area;

-- 6. Clean up the test record
DELETE FROM assessment_results WHERE body_area = 'Test Area';
