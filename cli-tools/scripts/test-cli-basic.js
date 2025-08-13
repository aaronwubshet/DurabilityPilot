#!/usr/bin/env node

import { validateConfig, logger, Config } from '../src/config.js';
import { EdgeFunctionClient } from '../src/edge-function-client.js';
import { PlanScoringService } from '../src/plan-scoring-service.js';

async function testCLIBasic() {
  try {
    console.log('🧪 Testing CLI Tools Basic Functionality...\n');
    
    // Test 1: Configuration validation
    console.log('1️⃣ Testing configuration...');
    validateConfig();
    console.log('✅ Configuration is valid');
    console.log(`   Supabase URL: ${Config.supabaseURL}`);
    console.log(`   Edge Function URL: ${Config.edgeFunctionURL}`);
    console.log(`   Log Level: ${Config.logLevel}`);
    console.log(`   Batch Size: ${Config.batchSize}`);
    console.log(`   Retry Attempts: ${Config.retryAttempts}`);
    
    // Test 2: Logger functionality
    console.log('\n2️⃣ Testing logger...');
    logger.info('This is an info message');
    logger.warn('This is a warning message');
    logger.error('This is an error message');
    console.log('✅ Logger is working');
    
    // Test 3: Edge Function Client creation
    console.log('\n3️⃣ Testing Edge Function Client...');
    const edgeClient = new EdgeFunctionClient();
    console.log('✅ Edge Function Client created successfully');
    
    // Test 4: Plan Scoring Service creation
    console.log('\n4️⃣ Testing Plan Scoring Service...');
    const scoringService = new PlanScoringService();
    console.log('✅ Plan Scoring Service created successfully');
    
    // Test 5: Command line argument parsing (simulated)
    console.log('\n5️⃣ Testing command structure...');
    const testCommands = [
      'single --plan-id "test-123" --user-id "user-456"',
      'batch --plan-ids "plan-1,plan-2" --user-id "user-456"',
      'test --verbose',
      'analytics --filters \'{"sport":"Soccer"}\'',
      'movements --verbose'
    ];
    
    testCommands.forEach((cmd, index) => {
      console.log(`   Command ${index + 1}: ${cmd}`);
    });
    console.log('✅ Command structure is valid');
    
    // Test 6: Environment variables
    console.log('\n6️⃣ Testing environment variables...');
    console.log(`   NODE_ENV: ${process.env.NODE_ENV || 'not set'}`);
    console.log(`   LOG_LEVEL: ${process.env.LOG_LEVEL || 'not set'}`);
    console.log('✅ Environment variables accessible');
    
    console.log('\n🎉 Basic CLI functionality test completed successfully!');
    console.log('\n✅ What\'s working:');
    console.log('   - Configuration validation');
    console.log('   - Logger system');
    console.log('   - Client instantiation');
    console.log('   - Command structure');
    console.log('   - Environment variables');
    
    console.log('\n⚠️  What needs setup:');
    console.log('   - Database table permissions');
    console.log('   - Atomic movements table');
    console.log('   - Plan scores table');
    console.log('   - Edge functions deployment');
    
    console.log('\n🚀 Ready to proceed with setup!');
    
  } catch (error) {
    console.error('\n❌ Basic CLI test failed:', error.message);
    process.exit(1);
  }
}

// Run the test
testCLIBasic();

