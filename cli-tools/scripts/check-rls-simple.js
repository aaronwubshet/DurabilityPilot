import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

class SimpleRLSChecker {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL || 'https://atvnjpwmydhqbxjgczti.supabase.co',
      process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicnNpZCI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NTUxMTAsImV4cCI6MjA3MDAzMTExMH0.9EAsCCf9kC5GreyOXJv0b0K4zH08jT14jaG-omzf2ww'
    );
  }

  async checkTableAccess(tableName) {
    console.log(`\n🔍 Testing access to table: ${tableName}`);
    
    try {
      // Try to select from the table
      const { data, error } = await this.supabase
        .from(tableName)
        .select('*')
        .limit(1);

      if (error) {
        if (error.message.includes('permission denied')) {
          console.log(`  ❌ Access DENIED - RLS is working`);
        } else if (error.message.includes('does not exist')) {
          console.log(`  ⚠️  Table does not exist`);
        } else {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      } else {
        if (data && data.length > 0) {
          console.log(`  ⚠️  Access ALLOWED - RLS may not be working properly`);
        } else {
          console.log(`  ✅ Access allowed but no data returned`);
        }
      }
    } catch (error) {
      console.log(`  ❌ Exception: ${error.message}`);
    }
  }

  async checkCriticalTables() {
    console.log('🚀 Checking RLS on Critical Tables...\n');
    
    const criticalTables = [
      'profiles',
      'assessment_results', 
      'assessments',
      'movements',
      'movement_blocks',
      'movement_block_items',
      'programs',
      'user_programs',
      'user_workouts',
      'user_workout_blocks',
      'user_block_items',
      'user_set_logs'
    ];

    for (const table of criticalTables) {
      await this.checkTableAccess(table);
    }
  }

  async checkPublicTables() {
    console.log('\n🌐 Checking Public Tables (should be accessible)...\n');
    
    const publicTables = [
      'sports',
      'equipment',
      'goals',
      'injuries',
      'body_parts',
      'pattern_types',
      'movement_patterns'
    ];

    for (const table of publicTables) {
      await this.checkTableAccess(table);
    }
  }

  async testAuthenticatedAccess() {
    console.log('\n🔐 Testing Authenticated Access...\n');
    
    try {
      // Try to access a user-specific table without authentication
      const { data, error } = await this.supabase
        .from('profiles')
        .select('id, first_name')
        .limit(1);

      if (error) {
        if (error.message.includes('permission denied')) {
          console.log('✅ RLS is working - unauthenticated users cannot access profiles');
        } else {
          console.log(`⚠️  Unexpected error: ${error.message}`);
        }
      } else {
        console.log('❌ RLS may not be working - unauthenticated users can access profiles');
      }
    } catch (error) {
      console.log(`❌ Exception: ${error.message}`);
    }
  }

  async run() {
    console.log('🔒 Starting Simple RLS Check...\n');
    
    await this.checkCriticalTables();
    await this.checkPublicTables();
    await this.testAuthenticatedAccess();
    
    console.log('\n💡 RLS Check Summary:');
    console.log('  - ❌ Access DENIED = RLS is working (good)');
    console.log('  - ⚠️  Access ALLOWED = RLS may not be working (needs investigation)');
    console.log('  - ✅ Public tables should be accessible to all users');
    console.log('  - 🔐 User data tables should require authentication');
    
    console.log('\n✨ Simple RLS Check Complete!');
  }
}

// Run the checker
async function main() {
  const checker = new SimpleRLSChecker();
  await checker.run();
}

main().catch(console.error);
