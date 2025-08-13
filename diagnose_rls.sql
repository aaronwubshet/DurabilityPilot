-- Diagnostic script to check RLS policies and table structure

-- 1. Check if RLS is enabled on the table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'assessment_results';

-- 2. Check all policies on the assessment_results table
SELECT 
    policyname,
    cmd,
    qual,
    with_check,
    roles
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 3. Check the table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'assessment_results'
ORDER BY ordinal_position;

-- 4. Check if there are any conflicting policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'assessment_results';

-- 5. Test the current user context
SELECT 
    'Current user context' as test_type,
    auth.uid() as current_user_id,
    auth.uid()::text as current_user_id_text,
    current_user as database_user;
