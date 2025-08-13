-- Check existing assessment_results records

-- 1. Check total count
SELECT 'Total assessment_results records:' as info;
SELECT COUNT(*) as total_records FROM assessment_results;

-- 2. Check records for the current user
SELECT 'Records for current user:' as info;
SELECT 
    assessment_id,
    profile_id,
    body_area,
    durability_score,
    created_at
FROM assessment_results 
WHERE profile_id::text = '13B02BF5-640F-4120-A151-ABDA678A2F35'
ORDER BY assessment_id, body_area;

-- 3. Check for potential duplicates
SELECT 'Potential duplicate combinations:' as info;
SELECT 
    assessment_id,
    profile_id,
    body_area,
    COUNT(*) as count
FROM assessment_results 
GROUP BY assessment_id, profile_id, body_area
HAVING COUNT(*) > 1
ORDER BY assessment_id;

-- 4. Check the latest assessment_id
SELECT 'Latest assessment_id:' as info;
SELECT MAX(assessment_id) as max_assessment_id FROM assessment_results;
