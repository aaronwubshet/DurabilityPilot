-- Fix RLS policies for both assessments and assessment_results tables

-- 1. Fix assessments table policy
SELECT 'Fixing assessments table policy...' as info;
DROP POLICY IF EXISTS "assessments_authenticated_access" ON assessments;

CREATE POLICY "assessments_authenticated_access"
ON assessments
FOR ALL
TO authenticated
USING (
    profile_id::text = (auth.uid())::text
)
WITH CHECK (
    profile_id::text = (auth.uid())::text
);

-- 2. Verify assessments table policy
SELECT 'Assessments table policy:' as info;
SELECT 
    policyname,
    cmd,
    qual,
    with_check,
    roles
FROM pg_policies 
WHERE tablename = 'assessments';

-- 3. Ensure assessment_results table policy is correct
SELECT 'Ensuring assessment_results table policy...' as info;
DROP POLICY IF EXISTS "assessment_results_authenticated_access" ON assessment_results;

CREATE POLICY "assessment_results_authenticated_access"
ON assessment_results
FOR ALL
TO authenticated
USING (
    profile_id::text = (auth.uid())::text
)
WITH CHECK (
    profile_id::text = (auth.uid())::text
);

-- 4. Verify assessment_results table policy
SELECT 'Assessment_results table policy:' as info;
SELECT 
    policyname,
    cmd,
    qual,
    with_check,
    roles
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 5. Final verification
SELECT 'Final verification - both tables should have proper policies:' as info;
SELECT 
    tablename,
    policyname,
    cmd,
    CASE WHEN with_check IS NOT NULL THEN 'Has WITH CHECK' ELSE 'Missing WITH CHECK' END as check_status
FROM pg_policies 
WHERE tablename IN ('assessments', 'assessment_results')
ORDER BY tablename;
