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

class ComprehensiveTrainingSummary {
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

  async showTrainingProgramSummary(userId) {
    console.log('🏋️‍♂️ COMPREHENSIVE TRAINING PROGRAM SUMMARY');
    console.log('='.repeat(80));
    console.log(`User ID: ${userId}\n`);

    // Get user program details
    const userPrograms = await this.client.query(
      'SELECT * FROM user_programs WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
      [userId]
    );

    if (userPrograms.rows.length === 0) {
      console.log('❌ No training program found for this user');
      return;
    }

    const userProgram = userPrograms.rows[0];
    console.log('📋 USER PROGRAM DETAILS:');
    console.log('─'.repeat(50));
    console.log(`  Program Name: ${userProgram.program_name_snapshot}`);
    console.log(`  Program ID: ${userProgram.program_id}`);
    console.log(`  User Program ID: ${userProgram.id}`);
    console.log(`  Status: ${userProgram.status}`);
    console.log(`  Start Date: ${userProgram.start_date}`);
    console.log(`  Workouts per Week: ${userProgram.workouts_per_week}`);
    console.log(`  Timezone: ${userProgram.timezone}`);
    console.log(`  Created: ${userProgram.created_at}`);

    // Get workout count
    const workoutCount = await this.client.query(
      'SELECT COUNT(*) as total FROM user_workouts WHERE user_program_id = $1',
      [userProgram.id]
    );

    console.log(`\n📊 PROGRAM STATISTICS:`);
    console.log('─'.repeat(50));
    console.log(`  Total Workouts: ${workoutCount.rows[0].total}`);
    console.log(`  Program Duration: 12 weeks`);
    console.log(`  Workout Pattern: 3 workouts per week`);

    // Show workout structure
    await this.showWorkoutStructure(userProgram.id);
    
    // Show movement details
    await this.showMovementDetails();
    
    // Show table relationships
    await this.showTableRelationships();
  }

  async showWorkoutStructure(userProgramId) {
    console.log('\n📅 WORKOUT STRUCTURE:');
    console.log('─'.repeat(50));
    
    // Get sample workouts from different weeks
    const workouts = await this.client.query(
      'SELECT * FROM user_workouts WHERE user_program_id = $1 ORDER BY week_index, day_index LIMIT 9',
      [userProgramId]
    );

    console.log('Sample Workouts (3 weeks × 3 days):');
    workouts.rows.forEach((workout, i) => {
      console.log(`  Week ${workout.week_index}, Day ${workout.day_index}: ${workout.title_snapshot}`);
    });

    // Get workout blocks for first workout
    if (workouts.rows.length > 0) {
      const firstWorkout = workouts.rows[0];
      console.log(`\n🔍 DETAILED BREAKDOWN - ${firstWorkout.title_snapshot} (Week ${firstWorkout.week_index}, Day ${firstWorkout.day_index}):`);
      
      const workoutBlocks = await this.client.query(
        'SELECT * FROM user_workout_blocks WHERE user_workout_id = $1 ORDER BY sequence',
        [firstWorkout.id]
      );

      workoutBlocks.rows.forEach((block, i) => {
        console.log(`\n  Block ${i + 1} (Sequence ${block.sequence}):`);
        console.log(`    Name: ${block.block_name_snapshot}`);
        console.log(`    Type: ${block.block_type_label_snapshot}`);
        console.log(`    Movement Block ID: ${block.movement_block_id}`);
        
        // Get movement block items
        this.showMovementBlockItems(block.movement_block_id, block.sequence);
      });
    }
  }

  async showMovementBlockItems(movementBlockId, blockSequence) {
    try {
      const blockItems = await this.client.query(
        'SELECT * FROM movement_block_items WHERE block_id = $1 ORDER BY sequence',
        [movementBlockId]
      );

      console.log(`    Movements (${blockItems.rows.length}):`);
      blockItems.rows.forEach((item, i) => {
        console.log(`      ${i + 1}. Sequence ${item.sequence}: Movement ID ${item.movement_id}`);
        console.log(`         Default Dose: ${JSON.stringify(item.default_dose)}`);
      });
    } catch (error) {
      console.log(`      ❌ Error getting movement block items: ${error.message}`);
    }
  }

  async showMovementDetails() {
    console.log('\n🏃‍♂️ MOVEMENT DETAILS:');
    console.log('─'.repeat(50));
    
    // Get movements from your training program
    const movements = await this.client.query(`
      SELECT DISTINCT m.id, m.name, m.is_assessment, mp.name as pattern_name
      FROM movements m
      LEFT JOIN movement_patterns mp ON m.pattern_id = mp.id
      WHERE m.id IN (
        SELECT DISTINCT ubi.movement_id 
        FROM user_block_items ubi 
        JOIN user_workout_blocks uwb ON ubi.user_workout_block_id = uwb.id
        JOIN user_workouts uw ON uwb.user_workout_id = uw.id
        JOIN user_programs up ON uw.user_program_id = up.id
        WHERE up.user_id = 'ae5810c3-aa90-4022-b9e7-3856c99e9c98'
      )
      LIMIT 10
    `);

    console.log(`Found ${movements.rows.length} unique movements in your training program:`);
    movements.rows.forEach((movement, i) => {
      console.log(`  ${i + 1}. ${movement.name}`);
      console.log(`     Pattern: ${movement.pattern_name || 'Unknown'}`);
      console.log(`     Assessment: ${movement.is_assessment ? 'Yes' : 'No'}`);
    });
  }

  async showTableRelationships() {
    console.log('\n🔗 DATABASE TABLE RELATIONSHIPS:');
    console.log('─'.repeat(50));
    
    console.log('📊 TABLE HIERARCHY:');
    console.log('  1. user_programs (stores your program assignment)');
    console.log('     ↓ user_program_id');
    console.log('  2. user_workouts (stores your scheduled workouts)');
    console.log('     ↓ user_workout_id');
    console.log('  3. user_workout_blocks (stores workout structure)');
    console.log('     ↓ user_workout_block_id');
    console.log('  4. user_block_items (stores individual movements)');
    console.log('');
    console.log('📊 REFERENCE TABLES:');
    console.log('  • programs (template program definition)');
    console.log('  • movement_blocks (workout block templates)');
    console.log('  • movement_block_items (block movement templates)');
    console.log('  • movements (individual movement definitions)');
    console.log('  • movement_patterns (movement categories)');
    console.log('  • dose_metrics (measurement units)');
    
    console.log('\n📊 KEY RELATIONSHIPS:');
    console.log('  • Your UUID (ae5810c3-aa90-4022-b9e7-3856c99e9c98) → user_programs.user_id');
    console.log('  • Training Program ID (712f20d3-dbed-4ab6-a358-4e7e0429815d) → user_programs.program_id');
    console.log('  • Each user_program creates 36 user_workouts (12 weeks × 3 days)');
    console.log('  • Each user_workout has 4 user_workout_blocks (warm-up, strength, aerobic, cool-down)');
    console.log('  • Each user_workout_block contains 2-3 user_block_items (individual movements)');
  }

  async explore() {
    const userId = 'ae5810c3-aa90-4022-b9e7-3856c99e9c98';
    
    try {
      await this.connect();
      await this.showTrainingProgramSummary(userId);
    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    } finally {
      await this.disconnect();
    }
  }
}

async function main() {
  const explorer = new ComprehensiveTrainingSummary();
  await explorer.explore();
}

main().catch(console.error);
