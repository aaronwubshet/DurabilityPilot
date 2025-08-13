-- Check current state and clean up any conflicts

-- 1. Check what's currently in the database
SELECT 'Current assessment_results:' as info;
SELECT 
    id,
    assessment_id,
    profile_id,
    body_area,
    created_at
FROM assessment_results 
ORDER BY id;

-- 2. Check assessments table
SELECT 'Current assessments:' as info;
SELECT 
    id,
    profile_id,
    created_at
FROM assessments 
ORDER BY id;

-- 3. Check for any duplicate combinations
SELECT 'Checking for duplicates:' as info;
SELECT 
    assessment_id,
    profile_id,
    body_area,
    COUNT(*) as count,
    array_agg(id) as ids
FROM assessment_results 
GROUP BY assessment_id, profile_id, body_area 
HAVING COUNT(*) > 1
ORDER BY assessment_id, body_area;

-- 4. Clear everything to start completely fresh
SELECT 'Clearing all data...' as info;
DELETE FROM assessment_results;
DELETE FROM assessments;

-- 5. Reset sequences
SELECT setval('assessment_results_id_seq', 1, false);
SELECT setval('assessments_id_seq', 1, false);

-- 6. Verify clean state
SELECT 'Clean state verification:' as info;
SELECT 'assessment_results count:' as table_name, COUNT(*) as count FROM assessment_results
UNION ALL
SELECT 'assessments count:' as table_name, COUNT(*) as count FROM assessments;

SELECT 'Sequence values:' as info;
SELECT 'assessment_results_id_seq' as sequence_name, last_value FROM assessment_results_id_seq
UNION ALL
SELECT 'assessments_id_seq' as sequence_name, last_value FROM assessments_id_seq;

SELECT 'Database is now completely clean!' as status;
