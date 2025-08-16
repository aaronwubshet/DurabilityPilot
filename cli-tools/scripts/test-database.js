import { validateConfig, supabaseServiceClient, logger } from '../src/config.js';

async function testDatabase() {
  validateConfig();
  if (!supabaseServiceClient) throw new Error('Service role key required');

  logger.info('Testing refresh_movement_library...');
  let { error } = await supabaseServiceClient.rpc('refresh_movement_library');
  if (error) throw error;

  logger.info('Testing sync_movements_from_library...');
  const res = await supabaseServiceClient.rpc('sync_movements_from_library');
  if (res.error) throw res.error;

  logger.info('Querying movement_library...');
  const { data, error: qErr } = await supabaseServiceClient.from('movement_library').select('*').limit(3);
  if (qErr) throw qErr;
  logger.info(`movement_library sample: ${JSON.stringify(data)}`);
}

testDatabase().catch((e) => {
  console.error(e);
  process.exit(1);
});

#!/usr/bin/env node

import { supabaseClient, validateConfig, logger } from '../src/config.js';

async function testDatabase() {
  try {
    console.log('🧪 Testing Supabase Database Connectivity...\n');
    
    // Validate configuration
    validateConfig();
    console.log('✅ Configuration validated');
    
    // Test basic database connectivity
    console.log('📡 Testing database connectivity...');
    
    // Test profiles table
    try {
      const { data: profiles, error } = await supabaseClient
        .from('profiles')
        .select('count')
        .limit(1);
      
      if (error) {
        console.log('⚠️  Profiles table test:', error.message);
      } else {
        console.log('✅ Profiles table accessible');
      }
    } catch (error) {
      console.log('⚠️  Profiles table test failed:', error.message);
    }
    
    // Test plans table
    try {
      const { data: plans, error } = await supabaseClient
        .from('plans')
        .select('count')
        .limit(1);
      
      if (error) {
        console.log('⚠️  Plans table test:', error.message);
      } else {
        console.log('✅ Plans table accessible');
      }
    } catch (error) {
      console.log('⚠️  Plans table test failed:', error.message);
    }
    
    // Test assessments table
    try {
      const { data: assessments, error } = await supabaseClient
        .from('assessments')
        .select('count')
        .limit(1);
      
      if (error) {
        console.log('⚠️  Assessments table test:', error.message);
      } else {
        console.log('✅ Assessments table accessible');
      }
    } catch (error) {
      console.log('⚠️  Assessments table test failed:', error.message);
    }
    
    // Test atomic_movements table (if it exists)
    try {
      const { data: movements, error } = await supabaseClient
        .from('atomic_movements')
        .select('count')
        .limit(1);
      
      if (error) {
        console.log('⚠️  Atomic movements table test:', error.message);
        console.log('   (This table may not exist yet - that\'s okay)');
      } else {
        console.log('✅ Atomic movements table accessible');
      }
    } catch (error) {
      console.log('⚠️  Atomic movements table test failed:', error.message);
    }
    
    // Test plan_scores table (if it exists)
    try {
      const { data: scores, error } = await supabaseClient
        .from('plan_scores')
        .select('count')
        .limit(1);
      
      if (error) {
        console.log('⚠️  Plan scores table test:', error.message);
        console.log('   (This table may not exist yet - that\'s okay)');
      } else {
        console.log('✅ Plan scores table accessible');
      }
    } catch (error) {
      console.log('⚠️  Plan scores table test failed:', error.message);
    }
    
    console.log('\n🎉 Database connectivity test completed!');
    console.log('\nNext steps:');
    console.log('1. Create atomic_movements table if it doesn\'t exist');
    console.log('2. Create plan_scores table if it doesn\'t exist');
    console.log('3. Deploy edge functions: supabase functions deploy compute-plan-scores');
    
  } catch (error) {
    console.error('\n❌ Database test failed:', error.message);
    process.exit(1);
  }
}

// Run the test
testDatabase();

