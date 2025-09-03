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

class UserTrainingExplorer {
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

  async exploreUserTraining(userId) {
    console.log(`🔍 Exploring Training Data for User: ${userId}\n`);

    // Check user_programs
    console.log('📋 USER_PROGRAMS TABLE:');
    console.log('──────────────────────────────────────────────────');
    const userPrograms = await this.client.query(
      'SELECT * FROM user_programs WHERE user_id = $1',
      [userId]
    );
    
    if (userPrograms.rows.length === 0) {
      console.log('❌ No user programs found for this user');
      return;
    }

    console.log(`Found ${userPrograms.rows.length} user program(s):`);
    userPrograms.rows.forEach((row, i) => {
      console.log(`\n  Program ${i + 1}:`);
      console.log(`    ID: ${row.id}`);
      console.log(`    Program ID: ${row.program_id}`);
      console.log(`    Program Name: ${row.program_name_snapshot}`);
      console.log(`    Status: ${row.status}`);
      console.log(`    Start Date: ${row.start_date}`);
      console.log(`    Workouts per Week: ${row.workouts_per_week}`);
      console.log(`    Created: ${row.created_at}`);
    });

    const userProgramId = userPrograms.rows[0].id;
    console.log(`\n🔗 Following user program ID: ${userProgramId}`);

    // Check user_workouts
    console.log('\n📋 USER_WORKOUTS TABLE:');
    console.log('──────────────────────────────────────────────────');
    const userWorkouts = await this.client.query(
      'SELECT * FROM user_workouts WHERE user_program_id = $1 LIMIT 10',
      [userProgramId]
    );

    console.log(`Found ${userWorkouts.rows.length} user workout(s) (showing first 10):`);
    userWorkouts.rows.forEach((row, i) => {
      console.log(`\n  Workout ${i + 1}:`);
      console.log(`    ID: ${row.id}`);
      console.log(`    Week ${row.week_index}, Day ${row.day_index}`);
      console.log(`    Title: ${row.title_snapshot}`);
      console.log(`    Scheduled Date: ${row.scheduled_date}`);
      console.log(`    Status: ${row.status}`);
      console.log(`    Created: ${row.created_at}`);
    });

    if (userWorkouts.rows.length > 0) {
      const workoutId = userWorkouts.rows[0].id;
      console.log(`\n🔗 Following workout ID: ${workoutId}`);

      // Check user_workout_blocks
      console.log('\n📋 USER_WORKOUT_BLOCKS TABLE:');
      console.log('──────────────────────────────────────────────────');
      const userWorkoutBlocks = await this.client.query(
        'SELECT * FROM user_workout_blocks WHERE user_workout_id = $1 ORDER BY sequence',
        [workoutId]
      );

      console.log(`Found ${userWorkoutBlocks.rows.length} user workout block(s):`);
      userWorkoutBlocks.rows.forEach((row, i) => {
        console.log(`\n  Block ${i + 1} (Sequence ${row.sequence}):`);
        console.log(`    ID: ${row.id}`);
        console.log(`    Block Name: ${row.block_name_snapshot}`);
        console.log(`    Block Type: ${row.block_type_label_snapshot}`);
        console.log(`    Movement Block ID: ${row.movement_block_id}`);
        console.log(`    Created: ${row.created_at}`);
      });

      if (userWorkoutBlocks.rows.length > 0) {
        const blockId = userWorkoutBlocks.rows[0].id;
        console.log(`\n🔗 Following user workout block ID: ${blockId}`);

        // Check user_block_items
        console.log('\n📋 USER_BLOCK_ITEMS TABLE:');
        console.log('──────────────────────────────────────────────────');
        const userBlockItems = await this.client.query(
          'SELECT * FROM user_block_items WHERE user_workout_block_id = $1 ORDER BY sequence',
          [blockId]
        );

        console.log(`Found ${userBlockItems.rows.length} user block item(s):`);
        userBlockItems.rows.forEach((row, i) => {
          console.log(`\n  Item ${i + 1} (Sequence ${row.sequence}):`);
          console.log(`    ID: ${row.id}`);
          console.log(`    Movement Name: ${row.movement_name_snapshot}`);
          console.log(`    Movement ID: ${row.movement_id}`);
          console.log(`    Planned Dose: ${JSON.stringify(row.planned_dose)}`);
          console.log(`    Base Dose Snapshot: ${JSON.stringify(row.base_dose_snapshot)}`);
          console.log(`    Created: ${row.created_at}`);
        });
      }
    }

    // Show relationships summary
    await this.showRelationshipsSummary(userId, userProgramId);
  }

  async showRelationshipsSummary(userId, userProgramId) {
    console.log('\n🔗 RELATIONSHIPS SUMMARY:');
    console.log('──────────────────────────────────────────────────');
    
    try {
      // Count total workouts for this user program
      const workoutCount = await this.client.query(
        'SELECT COUNT(*) as total FROM user_workouts WHERE user_program_id = $1',
        [userProgramId]
      );
      
      // Count total blocks across all workouts
      const blockCount = await this.client.query(
        'SELECT COUNT(*) as total FROM user_workout_blocks uwb JOIN user_workouts uw ON uwb.user_workout_id = uw.id WHERE uw.user_program_id = $1',
        [userProgramId]
      );
      
      // Count total movements across all blocks
      const movementCount = await this.client.query(
        'SELECT COUNT(*) as total FROM user_block_items ubi JOIN user_workout_blocks uwb ON ubi.user_workout_block_id = uwb.id JOIN user_workouts uw ON uwb.user_workout_id = uw.id WHERE uw.user_program_id = $1',
        [userProgramId]
      );
      
      console.log(`📊 Training Program Summary:`);
      console.log(`  User ID: ${userId}`);
      console.log(`  User Program ID: ${userProgramId}`);
      console.log(`  Total Workouts: ${workoutCount.rows[0].total}`);
      console.log(`  Total Blocks: ${blockCount.rows[0].total}`);
      console.log(`  Total Movements: ${movementCount.rows[0].total}`);
      
      // Show table structures
      await this.showTableStructures();
      
    } catch (error) {
      console.error('❌ Error getting relationships summary:', error.message);
    }
  }

  async showTableStructures() {
    console.log('\n🔍 TABLE STRUCTURES:');
    console.log('──────────────────────────────────────────────────');

    const tables = ['user_programs', 'user_workouts', 'user_workout_blocks', 'user_block_items'];

    for (const table of tables) {
      console.log(`\n📋 ${table.toUpperCase()} structure:`);
      const structure = await this.client.query(
        "SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = $1 ORDER BY ordinal_position",
        [table]
      );
      
      structure.rows.forEach(col => {
        const nullable = col.is_nullable === 'NO' ? '(NOT NULL)' : '';
        const defaultValue = col.column_default ? ` DEFAULT ${col.column_default}` : '';
        console.log(`  ${col.column_name}: ${col.data_type}${nullable}${defaultValue}`);
      });
    }
  }

  async explore() {
    const userId = 'ae5810c3-aa90-4022-b9e7-3856c99e9c98';
    
    try {
      await this.connect();
      await this.exploreUserTraining(userId);
    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    } finally {
      await this.disconnect();
    }
  }
}

async function main() {
  const explorer = new UserTrainingExplorer();
  await explorer.explore();
}

main().catch(console.error);
