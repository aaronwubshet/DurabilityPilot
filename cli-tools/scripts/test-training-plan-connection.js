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

class TrainingPlanConnectionTester {
  constructor() {
    this.client = new Client(DB_CONFIG);
  }

  async connect() {
    try {
      await this.client.connect();
      console.log('✅ Connected to Supabase database');
    } catch (error) {
      console.error('❌ Connection error:', error.message);
      throw error;
    }
  }

  async disconnect() {
    try {
      await this.client.end();
      console.log('✅ Disconnected from database');
    } catch (error) {
      console.error('❌ Disconnection error:', error.message);
    }
  }

  async testTrainingPlanConnection() {
    console.log('🔍 Testing Training Plan Connection...\n');

    try {
      // Test 1: Check if user_programs table exists and has data
      console.log('📋 Test 1: Checking user_programs table...');
      const userProgramsResult = await this.client.query('SELECT COUNT(*) FROM user_programs');
      console.log(`   Found ${userProgramsResult.rows[0].count} user programs`);

      // Test 2: Check if programs table exists and has data
      console.log('\n📋 Test 2: Checking programs table...');
      const programsResult = await this.client.query('SELECT COUNT(*) FROM programs');
      console.log(`   Found ${programsResult.rows[0].count} programs`);

      // Test 3: Check if program_phases table exists and has data
      console.log('\n📋 Test 3: Checking program_phases table...');
      const phasesResult = await this.client.query('SELECT COUNT(*) FROM program_phases');
      console.log(`   Found ${phasesResult.rows[0].count} program phases`);

      // Test 4: Check if program_weeks table exists and has data
      console.log('\n📋 Test 4: Checking program_weeks table...');
      const weeksResult = await this.client.query('SELECT COUNT(*) FROM program_weeks');
      console.log(`   Found ${weeksResult.rows[0].count} program weeks`);

      // Test 5: Check if program_workouts table exists and has data
      console.log('\n📋 Test 5: Checking program_workouts table...');
      const workoutsResult = await this.client.query('SELECT COUNT(*) FROM program_workouts');
      console.log(`   Found ${workoutsResult.rows[0].count} program workouts`);

      // Test 6: Check if movement_blocks table exists and has data
      console.log('\n📋 Test 6: Checking movement_blocks table...');
      const blocksResult = await this.client.query('SELECT COUNT(*) FROM movement_blocks');
      console.log(`   Found ${blocksResult.rows[0].count} movement blocks`);

      // Test 7: Check if movement_block_items table exists and has data
      console.log('\n📋 Test 7: Checking movement_block_items table...');
      const blockItemsResult = await this.client.query('SELECT COUNT(*) FROM movement_block_items');
      console.log(`   Found ${blockItemsResult.rows[0].count} movement block items`);

      // Test 8: Check specific user's training program
      console.log('\n📋 Test 8: Checking specific user training program...');
      const userId = 'ae5810c3-aa90-4022-b9e7-3856c99e9c98';
      const userProgramResult = await this.client.query(
        'SELECT * FROM user_programs WHERE user_id = $1',
        [userId]
      );
      
      if (userProgramResult.rows.length > 0) {
        const userProgram = userProgramResult.rows[0];
        console.log(`   User has program: ${userProgram.program_name_snapshot}`);
        console.log(`   Status: ${userProgram.status}`);
        console.log(`   Start date: ${userProgram.start_date}`);
        
        // Check if this program has phases, weeks, and workouts
        const programId = userProgram.program_id;
        
        const programPhasesResult = await this.client.query(
          'SELECT * FROM program_phases WHERE program_id = $1 ORDER BY phase_index',
          [programId]
        );
        console.log(`   Program has ${programPhasesResult.rows.length} phases`);
        
        const programWeeksResult = await this.client.query(
          'SELECT * FROM program_weeks WHERE program_id = $1 ORDER BY week_index',
          [programId]
        );
        console.log(`   Program has ${programWeeksResult.rows.length} weeks`);
        
        const programWorkoutsResult = await this.client.query(
          'SELECT * FROM program_workouts WHERE program_id = $1 ORDER BY week_id, day_index',
          [programId]
        );
        console.log(`   Program has ${programWorkoutsResult.rows.length} workouts`);
        
        // Show sample data
        if (programPhasesResult.rows.length > 0) {
          console.log('\n   Sample Phase Data:');
          programPhasesResult.rows.slice(0, 3).forEach(phase => {
            console.log(`     Phase ${phase.phase_index}: ${phase.weeks} weeks`);
          });
        }
        
        if (programWeeksResult.rows.length > 0) {
          console.log('\n   Sample Week Data:');
          programWeeksResult.rows.slice(0, 3).forEach(week => {
            console.log(`     Week ${week.week_index}: Phase ${week.phase_week} of Phase ${week.phase_id}`);
          });
        }
        
        if (programWorkoutsResult.rows.length > 0) {
          console.log('\n   Sample Workout Data:');
          programWorkoutsResult.rows.slice(0, 3).forEach(workout => {
            console.log(`     Day ${workout.day}: ${workout.title}`);
          });
        }
      } else {
        console.log('   No training program found for this user');
      }

      console.log('\n✅ All connection tests completed successfully!');
      
    } catch (error) {
      console.error('❌ Error during testing:', error.message);
      throw error;
    }
  }

  async run() {
    try {
      await this.connect();
      await this.testTrainingPlanConnection();
    } catch (error) {
      console.error('❌ Test failed:', error.message);
    } finally {
      await this.disconnect();
    }
  }
}

async function main() {
  const tester = new TrainingPlanConnectionTester();
  await tester.run();
}

main().catch(console.error);
