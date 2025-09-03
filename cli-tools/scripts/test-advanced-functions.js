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

class AdvancedFunctionTester {
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

  async testProgramAssignment() {
    try {
      console.log('\n🎯 Testing Program Assignment Functions...\n');

      // First, let's see what programs exist
      const programs = await this.client.query(`
        SELECT slug, name, description FROM public.programs LIMIT 5
      `);

      if (programs.rows.length === 0) {
        console.log('No programs found - skipping program assignment tests');
        return;
      }

      console.log('Available programs:');
      programs.rows.forEach((program, index) => {
        console.log(`  ${index + 1}. ${program.name} (${program.slug})`);
        console.log(`     Description: ${program.description || 'No description'}`);
      });

      // Get a sample user profile
      const profiles = await this.client.query(`
        SELECT id, first_name, last_name FROM public.profiles LIMIT 1
      `);

      if (profiles.rows.length > 0) {
        const profile = profiles.rows[0];
        const program = programs.rows[0];
        
        console.log(`\nTesting assign_program for user: ${profile.first_name} ${profile.last_name}`);
        console.log(`Program: ${program.name} (${program.slug})`);
        
        try {
          const result = await this.client.query(`
            SELECT public.assign_program($1, $2, $3, $4) as program_id
          `, [profile.id, program.slug, new Date(), [0, 2, 4]]);
          
          console.log(`✅ Successfully assigned program: ${result.rows[0].program_id}`);
          
          // Check what was created
          const programWeeks = await this.client.query(`
            SELECT COUNT(*) as week_count FROM public.program_weeks WHERE program_id = $1
          `, [result.rows[0].program_id]);
          
          const programWorkouts = await this.client.query(`
            SELECT COUNT(*) as workout_count FROM public.program_workouts pw
            JOIN public.program_weeks pw2 ON pw.program_week_id = pw2.id
            WHERE pw2.program_id = $1
          `, [result.rows[0].program_id]);
          
          console.log(`  Created ${programWeeks.rows[0].week_count} weeks`);
          console.log(`  Created ${programWorkouts.rows[0].workout_count} workouts`);
          
        } catch (error) {
          console.log(`❌ Error assigning program: ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Error testing program assignment:', error.message);
    }
  }

  async testProgressDose() {
    try {
      console.log('\n📈 Testing Progress Dose Function...\n');

      // Test the progress_dose function with different parameters
      const testCases = [
        {
          weekIndex: 1,
          blockType: 'strength',
          base: { 'reps': 8, 'load_kg': 100, 'time_s': 60 }
        },
        {
          weekIndex: 3,
          blockType: 'endurance',
          base: { 'reps': 12, 'load_kg': 80, 'time_s': 90 }
        },
        {
          weekIndex: 6,
          blockType: 'mobility',
          base: { 'reps': 15, 'load_kg': 0, 'time_s': 120 }
        }
      ];

      for (const testCase of testCases) {
        try {
          console.log(`Testing progress_dose for week ${testCase.weekIndex}, ${testCase.blockType}:`);
          console.log(`  Base: ${JSON.stringify(testCase.base)}`);
          
          const result = await this.client.query(`
            SELECT public.progress_dose($1, $2, $3) as progressed_dose
          `, [testCase.weekIndex, testCase.blockType, JSON.stringify(testCase.base)]);
          
          console.log(`  Result: ${JSON.stringify(result.rows[0].progressed_dose, null, 2)}`);
          console.log('');
          
        } catch (error) {
          console.log(`  ❌ Error: ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Error testing progress dose:', error.message);
    }
  }

  async testMovementLibrarySync() {
    try {
      console.log('\n🔄 Testing Movement Library Sync Functions...\n');

      // Check current movement library state
      const libraryCheck = await this.client.query(`
        SELECT COUNT(*) as count FROM public.movement_library
      `);
      
      console.log(`Current movement library has ${libraryCheck.rows[0].count} movements`);

      // Check public.movements table
      const movementsCheck = await this.client.query(`
        SELECT COUNT(*) as count FROM public.movements
      `);
      
      console.log(`Public movements table has ${movementsCheck.rows[0].count} movements`);

      // Test refresh_movement_library function
      try {
        console.log('\nTesting refresh_movement_library...');
        await this.client.query('SELECT public.refresh_movement_library()');
        console.log('✅ Successfully refreshed movement library');
        
        // Check if count changed
        const newLibraryCheck = await this.client.query(`
          SELECT COUNT(*) as count FROM public.movement_library
        `);
        console.log(`Movement library now has ${newLibraryCheck.rows[0].count} movements`);
        
      } catch (error) {
        console.log(`❌ Error refreshing library: ${error.message}`);
      }

      // Test sync_movements_from_library function
      try {
        console.log('\nTesting sync_movements_from_library...');
        await this.client.query('SELECT public.sync_movements_from_library()');
        console.log('✅ Successfully synced movements from library');
        
        // Check if count changed
        const newMovementsCheck = await this.client.query(`
          SELECT COUNT(*) as count FROM public.movements
        `);
        console.log(`Public movements table now has ${newMovementsCheck.rows[0].count} movements`);
        
      } catch (error) {
        console.log(`❌ Error syncing movements: ${error.message}`);
      }

    } catch (error) {
      console.error('❌ Error testing movement library sync:', error.message);
    }
  }

  async testValidationTriggers() {
    try {
      console.log('\n✅ Testing Validation Triggers...\n');

      // Get information about validation triggers
      const triggerInfo = await this.client.query(`
        SELECT 
          t.tgname as trigger_name,
          p.proname as function_name,
          c.relname as table_name,
          CASE 
            WHEN t.tgtype & 66 = 2 THEN 'BEFORE'
            WHEN t.tgtype & 66 = 64 THEN 'AFTER'
            ELSE 'INSTEAD OF'
          END as timing,
          CASE 
            WHEN t.tgtype & 28 = 4 THEN 'INSERT'
            WHEN t.tgtype & 28 = 8 THEN 'DELETE'
            WHEN t.tgtype & 28 = 16 THEN 'UPDATE'
            WHEN t.tgtype & 28 = 12 THEN 'INSERT OR DELETE'
            WHEN t.tgtype & 28 = 20 THEN 'INSERT OR UPDATE'
            WHEN t.tgtype & 28 = 24 THEN 'DELETE OR UPDATE'
            WHEN t.tgtype & 28 = 28 THEN 'INSERT OR DELETE OR UPDATE'
            ELSE 'UNKNOWN'
          END as events
        FROM pg_trigger t
        JOIN pg_proc p ON t.tgfoid = p.oid
        JOIN pg_class c ON t.tgrelid = c.oid
        WHERE p.proname LIKE '%validate%' OR p.proname LIKE '%guard%'
        ORDER BY c.relname, p.proname;
      `);

      if (triggerInfo.rows.length > 0) {
        console.log('Validation triggers found:\n');
        
        triggerInfo.rows.forEach((trigger, index) => {
          console.log(`${index + 1}. ${trigger.trigger_name}`);
          console.log(`   Table: ${trigger.table_name}`);
          console.log(`   Function: ${trigger.function_name}`);
          console.log(`   Timing: ${trigger.timing}`);
          console.log(`   Events: ${trigger.events}`);
          console.log('');
        });
      }

      // Test some validation by trying to insert invalid data
      console.log('Testing validation by attempting invalid operations...');
      
      // Try to insert a movement with invalid equipment IDs
      try {
        await this.client.query(`
          INSERT INTO public.movements (name, description, required_equipment)
          VALUES ('Test Movement', 'Test Description', ARRAY[99999])
        `);
        console.log('❌ Should have failed validation');
      } catch (error) {
        if (error.message.includes('required_equipment contains unknown equipment id')) {
          console.log('✅ Validation correctly prevented invalid equipment ID');
        } else {
          console.log(`❌ Unexpected error: ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Error testing validation triggers:', error.message);
    }
  }

  async testComplexFunctions() {
    try {
      console.log('\n🧠 Testing Complex Functions...\n');

      // Test the compute_default_sport_vector function with various inputs
      const testCases = [
        {
          pattern: 'gait / locomotion',
          type: 'strength',
          movement: 'walk',
          description: 'Walking (low impact)'
        },
        {
          pattern: 'gait / locomotion',
          type: 'endurance',
          movement: 'run',
          description: 'Running (mid impact)'
        },
        {
          pattern: 'gait / locomotion',
          type: 'strength',
          movement: 'sprint',
          description: 'Sprinting (high impact)'
        },
        {
          pattern: 'carry / load transport',
          type: 'strength',
          movement: 'deadlift',
          description: 'Deadlift (high carry impact)'
        },
        {
          pattern: 'mixed modal conditioning',
          type: 'endurance',
          movement: 'burpee',
          description: 'Burpee (high crossfit impact)'
        }
      ];

      console.log('Testing compute_default_sport_vector with various inputs:\n');
      
      for (const testCase of testCases) {
        try {
          const result = await this.client.query(`
            SELECT public.compute_default_sport_vector($1, $2, $3) as sport_vector
          `, [testCase.pattern, testCase.type, testCase.movement]);
          
          console.log(`${testCase.description}:`);
          console.log(`  Pattern: ${testCase.pattern} (${testCase.type})`);
          console.log(`  Movement: ${testCase.movement}`);
          
          const vector = result.rows[0].sport_vector;
          const topSports = Object.entries(vector)
            .sort(([,a], [,b]) => b - a)
            .slice(0, 3)
            .map(([sport, score]) => `${sport}: ${score}`)
            .join(', ');
          
          console.log(`  Top 3 sports: ${topSports}`);
          console.log('');
          
        } catch (error) {
          console.log(`❌ Error testing ${testCase.movement}: ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Error testing complex functions:', error.message);
    }
  }

  async runAllTests() {
    try {
      console.log('🚀 Starting Advanced Function Testing...\n');

      await this.testProgramAssignment();
      await this.testProgressDose();
      await this.testMovementLibrarySync();
      await this.testValidationTriggers();
      await this.testComplexFunctions();

      console.log('\n🎉 Advanced function testing completed!');

    } catch (error) {
      console.error('❌ Error during testing:', error.message);
    }
  }
}

async function main() {
  const tester = new AdvancedFunctionTester();
  
  try {
    await tester.connect();
    await tester.runAllTests();
  } catch (error) {
    console.error('❌ Fatal error:', error.message);
  } finally {
    await tester.disconnect();
  }
}

main();
