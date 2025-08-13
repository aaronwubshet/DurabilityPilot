-- Clear all data from assessment-related tables

-- 1. Clear all assessment_results
DELETE FROM assessment_results;

-- 2. Clear all assessments
DELETE FROM assessments;

-- 3. Reset the sequences
SELECT setval('assessment_results_id_seq', 1, false);
SELECT setval('assessments_id_seq', 1, false);

-- 4. Verify everything is cleared
SELECT 'assessment_results count:' as info;
SELECT COUNT(*) as count FROM assessment_results;

SELECT 'assessments count:' as info;
SELECT COUNT(*) as count FROM assessments;

SELECT 'Sequence values:' as info;
SELECT 'assessment_results_id_seq' as sequence_name, last_value FROM assessment_results_id_seq
UNION ALL
SELECT 'assessments_id_seq' as sequence_name, last_value FROM assessments_id_seq;

SELECT 'Database cleared successfully!' as status;
