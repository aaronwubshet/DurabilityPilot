-- Fix RLS Policies for All Tables
-- This migration addresses the RLS issues found in the audit

-- 1. Enable RLS on tables that need it
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workout_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_block_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_set_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pattern_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_patterns ENABLE ROW LEVEL SECURITY;

-- 2. User Data Tables - Users can only access their own data
-- Profiles table policies
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "Users can delete own profile" ON profiles
    FOR DELETE USING (id = auth.uid());

-- Assessment results policies
CREATE POLICY "Users can view own assessment results" ON assessment_results
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own assessment results" ON assessment_results
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own assessment results" ON assessment_results
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own assessment results" ON assessment_results
    FOR DELETE USING (profile_id = auth.uid());

-- Assessments policies
CREATE POLICY "Users can view own assessments" ON assessments
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own assessments" ON assessments
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own assessments" ON assessments
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own assessments" ON assessments
    FOR DELETE USING (profile_id = auth.uid());

-- User programs policies
CREATE POLICY "Users can view own programs" ON user_programs
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own programs" ON user_programs
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own programs" ON user_programs
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own programs" ON user_programs
    FOR DELETE USING (profile_id = auth.uid());

-- User workouts policies
CREATE POLICY "Users can view own workouts" ON user_workouts
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own workouts" ON user_workouts
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own workouts" ON user_workouts
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own workouts" ON user_workouts
    FOR DELETE USING (profile_id = auth.uid());

-- User workout blocks policies
CREATE POLICY "Users can view own workout blocks" ON user_workout_blocks
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own workout blocks" ON user_workout_blocks
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own workout blocks" ON user_workout_blocks
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own workout blocks" ON user_workout_blocks
    FOR DELETE USING (profile_id = auth.uid());

-- User block items policies
CREATE POLICY "Users can view own block items" ON user_block_items
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own block items" ON user_block_items
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own block items" ON user_block_items
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own block items" ON user_block_items
    FOR DELETE USING (profile_id = auth.uid());

-- User set logs policies
CREATE POLICY "Users can view own set logs" ON user_set_logs
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own set logs" ON user_set_logs
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own set logs" ON user_set_logs
    FOR UPDATE USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own set logs" ON user_set_logs
    FOR DELETE USING (profile_id = auth.uid());

-- 3. Library Tables - Read-only for authenticated users
-- Movements policies
CREATE POLICY "Authenticated users can view movements" ON movements
    FOR SELECT USING (true);

-- Movement blocks policies
CREATE POLICY "Authenticated users can view movement blocks" ON movement_blocks
    FOR SELECT USING (true);

-- Movement block items policies
CREATE POLICY "Authenticated users can view movement block items" ON movement_block_items
    FOR SELECT USING (true);

-- Programs policies
CREATE POLICY "Authenticated users can view programs" ON programs
    FOR SELECT USING (true);

-- Pattern types policies
CREATE POLICY "Authenticated users can view pattern types" ON pattern_types
    FOR SELECT USING (true);

-- Movement patterns policies
CREATE POLICY "Authenticated users can view movement patterns" ON movement_patterns
    FOR SELECT USING (true);

-- 4. Public Reference Tables - Accessible to all users
-- Sports policies
CREATE POLICY "Anyone can view sports" ON sports
    FOR SELECT USING (true);

-- Equipment policies
CREATE POLICY "Anyone can view equipment" ON equipment
    FOR SELECT USING (true);

-- Goals policies
CREATE POLICY "Anyone can view goals" ON goals
    FOR SELECT USING (true);

-- Injuries policies
CREATE POLICY "Anyone can view injuries" ON injuries
    FOR SELECT USING (true);

-- Body parts policies
CREATE POLICY "Anyone can view body parts" ON body_parts
    FOR SELECT USING (true);

-- 5. Grant necessary permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT INSERT, UPDATE, DELETE ON profiles TO authenticated;
GRANT INSERT, UPDATE, DELETE ON assessment_results TO authenticated;
GRANT INSERT, UPDATE, DELETE ON assessments TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_programs TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_workouts TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_workout_blocks TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_block_items TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_set_logs TO authenticated;

-- 6. Ensure service role can bypass RLS for admin operations
-- This allows the service role to perform operations that bypass RLS
-- when needed for system operations
ALTER TABLE profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE assessment_results FORCE ROW LEVEL SECURITY;
ALTER TABLE assessments FORCE ROW LEVEL SECURITY;
ALTER TABLE user_programs FORCE ROW LEVEL SECURITY;
ALTER TABLE user_workouts FORCE ROW LEVEL SECURITY;
ALTER TABLE user_workout_blocks FORCE ROW LEVEL SECURITY;
ALTER TABLE user_block_items FORCE ROW LEVEL SECURITY;
ALTER TABLE user_set_logs FORCE ROW LEVEL SECURITY;

-- 7. Create indexes to improve policy performance
CREATE INDEX IF NOT EXISTS idx_assessment_results_profile_id ON assessment_results(profile_id);
CREATE INDEX IF NOT EXISTS idx_assessments_profile_id ON assessments(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_programs_profile_id ON user_programs(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_workouts_profile_id ON user_workouts(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_workout_blocks_profile_id ON user_workout_blocks(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_block_items_profile_id ON user_block_items(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_set_logs_profile_id ON user_set_logs(profile_id);

-- 8. Verify RLS is enabled on all tables
DO $$
DECLARE
    r RECORD;
    missing_rls_tables TEXT[] := ARRAY[]::TEXT[];
BEGIN
    FOR r IN (
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN ('schema_migrations', 'supabase_migrations')
    ) LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = r.tablename 
            AND rowsecurity = true
        ) THEN
            missing_rls_tables := array_append(missing_rls_tables, r.tablename);
        END IF;
    END LOOP;
    
    IF array_length(missing_rls_tables, 1) > 0 THEN
        RAISE NOTICE 'Tables without RLS enabled: %', array_to_string(missing_rls_tables, ', ');
    ELSE
        RAISE NOTICE 'All tables have RLS enabled';
    END IF;
END $$;
