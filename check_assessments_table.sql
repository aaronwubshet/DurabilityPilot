-- Check assessments table policies

-- 1. Check current policies on assessments table
SELECT 'Current policies on assessments table:' as info;
SELECT 
    policyname,
    cmd,
    qual,
    with_check,
    roles
FROM pg_policies 
WHERE tablename = 'assessments';

-- 2. Check table structure
SELECT 'Assessments table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'assessments'
ORDER BY ordinal_position;

-- 3. Check if RLS is enabled
SELECT 'RLS status for assessments table:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'assessments';
