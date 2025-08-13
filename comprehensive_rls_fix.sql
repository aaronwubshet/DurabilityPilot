-- Comprehensive RLS fix for assessment_results table

-- 1. Check current state
SELECT 'Current RLS state:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'assessment_results';

-- 2. Drop all existing policies to start fresh
DROP POLICY IF EXISTS "assessment_results_authenticated_access" ON assessment_results;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON assessment_results;
DROP POLICY IF EXISTS "Enable read access for all users" ON assessment_results;
DROP POLICY IF EXISTS "Enable update for users based on profile_id" ON assessment_results;
DROP POLICY IF EXISTS "Enable delete for users based on profile_id" ON assessment_results;

-- 3. Create a comprehensive policy that handles all operations
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

-- 4. Verify the policy
SELECT 'New policy created:' as info;
SELECT 
    policyname,
    cmd,
    qual,
    with_check,
    roles
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 5. Test the policy logic
SELECT 'Policy test results:' as info;
SELECT 
    'auth.uid()' as function,
    auth.uid() as result,
    'profile_id should match this' as note
UNION ALL
SELECT 
    'auth.uid()::text' as function,
    (auth.uid())::text as result,
    'This is what we compare against' as note;

-- 6. Check if there are any other tables with similar issues
SELECT 'Checking for other tables with RLS:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE rowsecurity = true 
AND tablename LIKE '%assessment%'
ORDER BY tablename;
