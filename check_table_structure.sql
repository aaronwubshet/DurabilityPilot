-- Check assessment_results table structure and constraints

-- 1. Check table structure
SELECT 'Table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns 
WHERE table_name = 'assessment_results'
ORDER BY ordinal_position;

-- 2. Check primary key constraints
SELECT 'Primary key constraints:' as info;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'assessment_results'
AND tc.constraint_type = 'PRIMARY KEY';

-- 3. Check sequences
SELECT 'Sequences:' as info;
SELECT 
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value,
    increment
FROM information_schema.sequences 
WHERE sequence_name LIKE '%assessment_results%';

-- 4. Check current sequence value
SELECT 'Current sequence value:' as info;
SELECT 
    'assessment_results_id_seq' as sequence_name,
    last_value,
    is_called
FROM assessment_results_id_seq;
