import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

class RLSAnalyzer {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL || 'https://atvnjpwmydhqbxjgczti.supabase.co',
      process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicnNpZCI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NTUxMTAsImV4cCI6MjA3MDAzMTExMH0.9EAsCCf9kC5GreyOXJv0b0K4zH08jT14jaG-omzf2ww'
    );
  }

  async analyzeRLSIssues() {
    console.log('🔍 Analyzing RLS Issues...\n');
    
    // Based on our previous test results, here's what we found:
    const rlsStatus = {
      working: [
        'profiles',
        'movement_blocks', 
        'movement_block_items',
        'sports',
        'equipment',
        'goals',
        'injuries',
        'body_parts'
      ],
      needsInvestigation: [
        'assessment_results',
        'assessments',
        'movements',
        'user_programs',
        'user_workouts',
        'user_workout_blocks',
        'user_block_items',
        'user_set_logs',
        'pattern_types',
        'movement_patterns'
      ],
      critical: [
        'programs' // This one showed "Access ALLOWED" which is concerning
      ]
    };

    console.log('✅ Tables with RLS Working Correctly:');
    rlsStatus.working.forEach(table => console.log(`  - ${table}`));
    
    console.log('\n⚠️  Tables That Need RLS Investigation:');
    rlsStatus.needsInvestigation.forEach(table => console.log(`  - ${table}`));
    
    console.log('\n❌ Critical Tables with RLS Issues:');
    rlsStatus.critical.forEach(table => console.log(`  - ${table}`));

    return rlsStatus;
  }

  generateRLSRecommendations() {
    console.log('\n💡 RLS Policy Recommendations:\n');
    
    const recommendations = [
      {
        category: 'User Data Tables (Should have RLS)',
        tables: ['profiles', 'assessment_results', 'assessments', 'user_programs', 'user_workouts', 'user_workout_blocks', 'user_block_items', 'user_set_logs'],
        policies: [
          'Enable RLS',
          'Create SELECT policy: users can only see their own data (WHERE profile_id = auth.uid())',
          'Create INSERT policy: users can only insert their own data (WITH CHECK (profile_id = auth.uid()))',
          'Create UPDATE policy: users can only update their own data (WITH CHECK (profile_id = auth.uid()))',
          'Create DELETE policy: users can only delete their own data (USING (profile_id = auth.uid()))'
        ]
      },
      {
        category: 'Library Tables (Should be read-only for authenticated users)',
        tables: ['movements', 'movement_blocks', 'movement_block_items', 'programs'],
        policies: [
          'Enable RLS',
          'Create SELECT policy: authenticated users can read all data (USING (true))',
          'No INSERT/UPDATE/DELETE policies for regular users',
          'Service role should bypass RLS for admin operations'
        ]
      },
      {
        category: 'Public Reference Tables (Should be accessible to all)',
        tables: ['sports', 'equipment', 'goals', 'injuries', 'body_parts', 'pattern_types', 'movement_patterns'],
        policies: [
          'Enable RLS',
          'Create SELECT policy: all users can read (USING (true))',
          'No INSERT/UPDATE/DELETE policies for regular users'
        ]
      }
    ];

    recommendations.forEach(rec => {
      console.log(`📋 ${rec.category}:`);
      console.log(`   Tables: ${rec.tables.join(', ')}`);
      rec.policies.forEach(policy => console.log(`   - ${policy}`));
      console.log('');
    });
  }

  generateMigrationScript() {
    console.log('🔧 Sample RLS Migration Script:\n');
    
    const migrationScript = `-- Enable RLS on all tables
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_block_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workout_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_block_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_set_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pattern_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_patterns ENABLE ROW LEVEL SECURITY;

-- User data policies (example for profiles table)
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "Users can delete own profile" ON profiles
    FOR DELETE USING (id = auth.uid());

-- Library table policies (example for movements table)
CREATE POLICY "Authenticated users can view movements" ON movements
    FOR SELECT USING (true);

-- Public table policies (example for sports table)
CREATE POLICY "Anyone can view sports" ON sports
    FOR SELECT USING (true);

-- Grant necessary permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT INSERT, UPDATE, DELETE ON profiles TO authenticated;
GRANT INSERT, UPDATE, DELETE ON assessment_results TO authenticated;
GRANT INSERT, UPDATE, DELETE ON assessments TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_programs TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_workouts TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_workout_blocks TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_block_items TO authenticated;
GRANT INSERT, UPDATE, DELETE ON user_set_logs TO authenticated;`;

    console.log(migrationScript);
  }

  async run() {
    console.log('🚀 Starting RLS Analysis...\n');
    
    const rlsStatus = await this.analyzeRLSIssues();
    this.generateRLSRecommendations();
    this.generateMigrationScript();
    
    console.log('\n📊 Summary of RLS Issues:');
    console.log(`  - ${rlsStatus.working.length} tables have RLS working correctly`);
    console.log(`  - ${rlsStatus.needsInvestigation.length} tables need RLS investigation`);
    console.log(`  - ${rlsStatus.critical.length} critical tables have RLS issues`);
    
    console.log('\n✨ RLS Analysis Complete!');
    console.log('\nNext Steps:');
    console.log('1. Review the recommendations above');
    console.log('2. Create and test RLS policies in a development environment');
    console.log('3. Apply the migration script to production');
    console.log('4. Test all user access patterns after applying RLS');
  }
}

// Run the analyzer
async function main() {
  const analyzer = new RLSAnalyzer();
  await analyzer.run();
}

main().catch(console.error);
