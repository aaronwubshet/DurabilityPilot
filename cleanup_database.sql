-- Clean up existing records and check for conflicts

-- 1. Check all existing records
SELECT 'All existing assessment_results records:' as info;
SELECT 
    id,
    assessment_id,
    profile_id,
    body_area,
    created_at
FROM assessment_results 
ORDER BY id;

-- 2. Check for the specific user's records
SELECT 'Records for current user:' as info;
SELECT 
    id,
    assessment_id,
    profile_id,
    body_area,
    created_at
FROM assessment_results 
WHERE profile_id::text = '13B02BF5-640F-4120-A151-ABDA678A2F35'
ORDER BY assessment_id, body_area;

-- 3. Check for assessment_id 31 specifically
SELECT 'Records for assessment_id 31:' as info;
SELECT 
    id,
    assessment_id,
    profile_id,
    body_area,
    created_at
FROM assessment_results 
WHERE assessment_id = 31
ORDER BY body_area;

-- 4. Delete any existing records for assessment_id 31 to allow fresh insert
DELETE FROM assessment_results WHERE assessment_id = 31;

-- 5. Verify deletion
SELECT 'Records after deletion:' as info;
SELECT COUNT(*) as remaining_records FROM assessment_results;

-- 6. Reset the sequence to start fresh
SELECT 'Resetting sequence...' as info;
SELECT setval('assessment_results_id_seq', 1, false);

-- 7. Verify sequence reset
SELECT 'Sequence value after reset:' as info;
SELECT currval('assessment_results_id_seq') as current_value;
