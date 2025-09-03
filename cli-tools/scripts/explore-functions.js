#!/usr/bin/env node

import pkg from 'pg';
const { Client } = pkg;

// Database connection configuration
const DB_CONFIG = {
  connectionString: 'postgresql://postgres:DNgp0mt3CutQkehw@db.atvnjpwmydhqbxjgczti.supabase.co:5432/postgres',
  ssl: {
    rejectUnauthorized: false
  }
};

class FunctionExplorer {
  constructor() {
    this.client = new Client(DB_CONFIG);
  }

  async connect() {
    try {
      await this.client.connect();
      console.log('✅ Connected to Supabase database');
    } catch (error) {
      console.error('❌ Failed to connect to database:', error.message);
      throw error;
    }
  }

  async disconnect() {
    await this.client.end();
    console.log('✅ Disconnected from database');
  }

  async listAllFunctions() {
    try {
      console.log('\n🔍 Listing all RPC functions in the database...\n');
      
      const query = `
        SELECT 
          n.nspname as schema_name,
          p.proname as function_name,
          pg_get_function_arguments(p.oid) as arguments,
          pg_get_function_result(p.oid) as return_type,
          p.prosrc as source_code,
          CASE 
            WHEN p.prosecdef THEN 'SECURITY DEFINER'
            ELSE 'SECURITY INVOKER'
          END as security_type,
          CASE 
            WHEN p.provolatile = 'i' THEN 'IMMUTABLE'
            WHEN p.provolatile = 's' THEN 'STABLE'
            WHEN p.provolatile = 'v' THEN 'VOLATILE'
            ELSE 'UNKNOWN'
          END as volatility
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        ORDER BY p.proname;
      `;
      
      const result = await this.client.query(query);
      
      if (result.rows.length === 0) {
        console.log('No functions found in public schema');
        return;
      }

      console.log(`Found ${result.rows.length} functions:\n`);
      
      result.rows.forEach((func, index) => {
        console.log(`${index + 1}. ${func.function_name}`);
        console.log(`   Schema: ${func.schema_name}`);
        console.log(`   Arguments: ${func.arguments || 'none'}`);
        console.log(`   Return Type: ${func.return_type}`);
        console.log(`   Security: ${func.security_type}`);
        console.log(`   Volatility: ${func.volatility}`);
        console.log(`   Source Length: ${func.source_code ? func.source_code.length : 0} chars`);
        console.log('');
      });

      return result.rows;
    } catch (error) {
      console.error('❌ Error listing functions:', error.message);
      throw error;
    }
  }

  async testUtilityFunctions() {
    try {
      console.log('\n🧪 Testing utility functions...\n');

      // Test normalize_int4_array function
      console.log('Testing normalize_int4_array...');
      const normalizeResult = await this.client.query(
        'SELECT public.normalize_int4_array(ARRAY[3,1,2,1,3,NULL,4]) as result'
      );
      console.log('  Input: [3,1,2,1,3,NULL,4]');
      console.log(`  Output: ${JSON.stringify(normalizeResult.rows[0].result)}`);

      // Test json_score_object_in_range function
      console.log('\nTesting json_score_object_in_range...');
      const jsonScoreResult = await this.client.query(`
        SELECT 
          public.json_score_object_in_range('{"a": 0.5, "b": 0.8}'::jsonb, 0.0, 1.0) as valid_range,
          public.json_score_object_in_range('{"a": 0.5, "b": 1.5}'::jsonb, 0.0, 1.0) as invalid_range
      `);
      console.log('  Valid range (0.0-1.0):', jsonScoreResult.rows[0].valid_range);
      console.log('  Invalid range (0.0-1.0):', jsonScoreResult.rows[0].invalid_range);

      // Test json_keys_exist_in_modules function
      console.log('\nTesting json_keys_exist_in_modules...');
      const modulesResult = await this.client.query(`
        SELECT 
          public.json_keys_exist_in_modules('{"1": 0.5, "2": 0.8}'::jsonb) as valid_keys,
          public.json_keys_exist_in_modules('{"999": 0.5, "invalid": 0.8}'::jsonb) as invalid_keys
      `);
      console.log('  Valid module keys:', modulesResult.rows[0].valid_keys);
      console.log('  Invalid module keys:', modulesResult.rows[0].invalid_keys);

    } catch (error) {
      console.error('❌ Error testing utility functions:', error.message);
    }
  }

  async testWorkoutFunctions() {
    try {
      console.log('\n🏋️‍♂️ Testing workout-related functions...\n');

      // Check if we have any daily workouts to test with
      const workoutCheck = await this.client.query(`
        SELECT COUNT(*) as count FROM public.daily_workouts
      `);
      
      if (parseInt(workoutCheck.rows[0].count) === 0) {
        console.log('No daily workouts found - skipping workout function tests');
        return;
      }

      console.log(`Found ${workoutCheck.rows[0].count} daily workouts`);

      // Get a sample workout ID
      const sampleWorkout = await this.client.query(`
        SELECT id FROM public.daily_workouts LIMIT 1
      `);

      if (sampleWorkout.rows.length > 0) {
        const workoutId = sampleWorkout.rows[0].id;
        console.log(`\nTesting with workout ID: ${workoutId}`);

        // Test materialize_daily_workout_movements function
        try {
          console.log('\nTesting materialize_daily_workout_movements...');
          const materializeResult = await this.client.query(`
            SELECT public.materialize_daily_workout_movements($1, true) as result
          `, [workoutId]);
          console.log(`  Result: ${materializeResult.rows[0].result} movements materialized`);
        } catch (error) {
          console.log(`  Error: ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Error testing workout functions:', error.message);
    }
  }

  async testMovementFunctions() {
    try {
      console.log('\n🏃‍♂️ Testing movement-related functions...\n');

      // Test compute_default_sport_vector function
      console.log('Testing compute_default_sport_vector...');
      const sportVectorResult = await this.client.query(`
        SELECT 
          public.compute_default_sport_vector('gait / locomotion', 'strength', 'sprint') as sprint_vector,
          public.compute_default_sport_vector('carry / load transport', 'strength', 'deadlift') as carry_vector
      `);
      
      console.log('  Sprint vector (strength):', JSON.stringify(sportVectorResult.rows[0].sprint_vector, null, 2));
      console.log('  Carry vector (strength):', JSON.stringify(sportVectorResult.rows[0].carry_vector, null, 2));

      // Test set_movement_dose_metrics_by_keys function
      console.log('\nTesting set_movement_dose_metrics_by_keys...');
      
      // First, let's see what dose metrics exist
      const doseMetrics = await this.client.query(`
        SELECT key, id FROM public.dose_metrics LIMIT 5
      `);
      
      if (doseMetrics.rows.length > 0) {
        console.log('  Available dose metrics:', doseMetrics.rows.map(r => r.key).join(', '));
        
        // Get a sample movement
        const sampleMovement = await this.client.query(`
          SELECT name FROM public.movements LIMIT 1
        `);
        
        if (sampleMovement.rows.length > 0) {
          const movementName = sampleMovement.rows[0].name;
          const metricKeys = doseMetrics.rows.slice(0, 2).map(r => r.key);
          
          console.log(`  Testing with movement: ${movementName}`);
          console.log(`  Setting metrics: ${metricKeys.join(', ')}`);
          
          try {
            await this.client.query(`
              SELECT public.set_movement_dose_metrics_by_keys($1, $2)
            `, [movementName, metricKeys]);
            console.log('  ✅ Successfully set dose metrics');
          } catch (error) {
            console.log(`  ❌ Error: ${error.message}`);
          }
        }
      }

    } catch (error) {
      console.error('❌ Error testing movement functions:', error.message);
    }
  }

  async testBlockFunctions() {
    try {
      console.log('\n🧱 Testing block-related functions...\n');

      // Check if we have any movement blocks
      const blockCheck = await this.client.query(`
        SELECT COUNT(*) as count FROM public.movement_blocks
      `);
      
      if (parseInt(blockCheck.rows[0].count) === 0) {
        console.log('No movement blocks found - skipping block function tests');
        return;
      }

      console.log(`Found ${blockCheck.rows[0].count} movement blocks`);

      // Test rebuild_block_goal_vectors function
      try {
        console.log('\nTesting rebuild_block_goal_vectors...');
        await this.client.query('SELECT public.rebuild_block_goal_vectors()');
        console.log('  ✅ Successfully rebuilt block goal vectors');
      } catch (error) {
        console.log(`  ❌ Error: ${error.message}`);
      }

      // Show some sample blocks with their goal vectors
      const sampleBlocks = await this.client.query(`
        SELECT 
          id, 
          block_type, 
          goal_impact_vector,
          created_at
        FROM public.movement_blocks 
        LIMIT 3
      `);

      if (sampleBlocks.rows.length > 0) {
        console.log('\n  Sample blocks with goal vectors:');
        sampleBlocks.rows.forEach((block, index) => {
          console.log(`    ${index + 1}. ${block.block_type} (${block.id})`);
          console.log(`       Goals: ${JSON.stringify(block.goal_impact_vector)}`);
        });
      }

    } catch (error) {
      console.error('❌ Error testing block functions:', error.message);
    }
  }

  async testValidationFunctions() {
    try {
      console.log('\n✅ Testing validation functions...\n');

      // Test the validation functions by checking their triggers
      const triggerQuery = `
        SELECT 
          t.tgname as trigger_name,
          p.proname as function_name,
          c.relname as table_name,
          t.tgtype
        FROM pg_trigger t
        JOIN pg_proc p ON t.tgfoid = p.oid
        JOIN pg_class c ON t.tgrelid = c.oid
        WHERE p.proname LIKE '%validate%' OR p.proname LIKE '%guard%'
        ORDER BY p.proname;
      `;

      const triggers = await this.client.query(triggerQuery);
      
      if (triggers.rows.length > 0) {
        console.log(`Found ${triggers.rows.length} validation triggers:\n`);
        
        triggers.rows.forEach((trigger, index) => {
          console.log(`${index + 1}. ${trigger.trigger_name}`);
          console.log(`   Function: ${trigger.function_name}`);
          console.log(`   Table: ${trigger.table_name}`);
          console.log(`   Type: ${trigger.tgtype}`);
          console.log('');
        });
      } else {
        console.log('No validation triggers found');
      }

    } catch (error) {
      console.error('❌ Error testing validation functions:', error.message);
    }
  }

  async explore() {
    try {
      console.log('🚀 Starting RPC Function Exploration...\n');

      // List all functions
      const functions = await this.listAllFunctions();

      // Test different categories of functions
      await this.testUtilityFunctions();
      await this.testWorkoutFunctions();
      await this.testMovementFunctions();
      await this.testBlockFunctions();
      await this.testValidationFunctions();

      console.log('\n🎉 RPC Function exploration completed!');
      
      // Summary
      if (functions) {
        const functionTypes = {
          utility: functions.filter(f => f.function_name.includes('normalize') || f.function_name.includes('json_')),
          workout: functions.filter(f => f.function_name.includes('workout') || f.function_name.includes('materialize')),
          movement: functions.filter(f => f.function_name.includes('movement') || f.function_name.includes('sport')),
          block: functions.filter(f => f.function_name.includes('block')),
          validation: functions.filter(f => f.function_name.includes('validate') || f.function_name.includes('guard')),
          trigger: functions.filter(f => f.return_type === 'trigger'),
          other: functions.filter(f => !f.function_name.includes('workout') && !f.function_name.includes('movement') && !f.function_name.includes('block') && !f.function_name.includes('validate') && !f.function_name.includes('guard') && !f.function_name.includes('normalize') && !f.function_name.includes('json_'))
        };

        console.log('\n📊 Function Summary by Category:');
        Object.entries(functionTypes).forEach(([category, funcs]) => {
          if (funcs.length > 0) {
            console.log(`  ${category}: ${funcs.length} functions`);
          }
        });
      }

    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    }
  }
}

async function main() {
  const explorer = new FunctionExplorer();
  
  try {
    await explorer.connect();
    await explorer.explore();
  } catch (error) {
    console.error('❌ Fatal error:', error.message);
  } finally {
    await explorer.disconnect();
  }
}

main();
