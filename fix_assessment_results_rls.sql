-- Fix for assessment_results RLS policy
-- This creates the proper policy to allow authenticated users to insert assessment results

-- 1. Drop the existing policy if it exists
DROP POLICY IF EXISTS "assessment_results_authenticated_access" ON assessment_results;

-- 2. Create a new comprehensive policy that handles all operations properly
CREATE POLICY "assessment_results_authenticated_access"
ON assessment_results
FOR ALL
TO authenticated
USING (
    profile_id::uuid = auth.uid()
)
WITH CHECK (
    profile_id::uuid = auth.uid()
);

-- 3. Verify the policy was created
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 4. Test the policy with a sample query
SELECT 
    'Policy test' as test_type,
    auth.uid() as current_user_id,
    (auth.uid())::text as current_user_id_text;
