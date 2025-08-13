-- Final fix for assessment_results RLS policy with proper type casting

-- 1. Drop the existing policy
DROP POLICY IF EXISTS "assessment_results_authenticated_access" ON assessment_results;

-- 2. Create the correct policy with proper type casting
-- Note: profile_id is UUID, so we need to cast auth.uid() to UUID
CREATE POLICY "assessment_results_authenticated_access"
ON assessment_results
FOR ALL
TO authenticated
USING (
    profile_id = (auth.uid())::uuid
)
WITH CHECK (
    profile_id = (auth.uid())::uuid
);

-- 3. Verify the policy was created
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 4. Test the policy with proper type casting
SELECT 
    'Policy test with UUID casting' as test_type,
    auth.uid() as current_user_id,
    (auth.uid())::uuid as current_user_id_uuid,
    (auth.uid())::text as current_user_id_text;
