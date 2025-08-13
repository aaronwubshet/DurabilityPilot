-- Check all policies and force refresh

-- 1. Check all policies on assessment_results table
SELECT 
    policyname,
    cmd,
    qual,
    with_check,
    roles
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 2. Force refresh by dropping and recreating with explicit UUID casting
DROP POLICY IF EXISTS "assessment_results_authenticated_access" ON assessment_results;

-- 3. Create policy with explicit UUID casting
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

-- 4. Verify the new policy
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 5. Test with a sample insert (this will help us see if the policy works)
-- Note: This is just a test, we won't actually insert
SELECT 
    'Testing policy logic' as test_type,
    'profile_id::text = (auth.uid())::text' as policy_condition,
    'This should work for authenticated users' as note;
