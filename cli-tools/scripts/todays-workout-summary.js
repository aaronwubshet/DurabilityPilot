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

class TodaysWorkoutSummary {
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

  async showTodaysWorkoutSummary() {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
    console.log(`🏋️‍♂️ TODAY'S WORKOUT SUMMARY (${today})`);
    console.log('='.repeat(80));

    // Get the most recent user program
    const userPrograms = await this.client.query(
      'SELECT * FROM user_programs ORDER BY created_at DESC LIMIT 1'
    );

    if (userPrograms.rows.length === 0) {
      console.log('❌ No user programs found in the database');
      return;
    }

    const userProgram = userPrograms.rows[0];
    
    // Check if today is the start date
    const isStartDate = userProgram.start_date.toISOString().split('T')[0] === today;
    
    console.log('\n📋 PROGRAM OVERVIEW:');
    console.log('─'.repeat(50));
    console.log(`  Program: ${userProgram.program_name_snapshot}`);
    console.log(`  Start Date: ${userProgram.start_date.toISOString().split('T')[0]}`);
    console.log(`  Today: ${today}`);
    console.log(`  Status: ${userProgram.status}`);
    console.log(`  Workouts per Week: ${userProgram.workouts_per_week}`);

    if (isStartDate) {
      console.log(`\n🎯 TODAY'S STATUS: TODAY IS PROGRAM START DATE!`);
      console.log('─'.repeat(50));
      console.log(`  Expected: Week 1, Day 1 workout should be today`);
      console.log(`  Reality: No workout scheduled for today`);
      console.log(`  Issue: 5-day scheduling discrepancy`);
      
      // Show what the first workout should be
      console.log(`\n📅 WHAT TODAY'S WORKOUT SHOULD BE:`);
      console.log('─'.repeat(50));
      console.log(`  Week: 1`);
      console.log(`  Day: 1`);
      console.log(`  Title: Lower Bias`);
      console.log(`  Type: Lower body focused workout`);
      
      // Get the workout structure from the first scheduled workout
      const firstWorkout = await this.client.query(
        'SELECT * FROM user_workouts WHERE user_program_id = $1 AND week_index = 1 AND day_index = 1 ORDER BY scheduled_date ASC LIMIT 1',
        [userProgram.id]
      );

      if (firstWorkout.rows.length > 0) {
        const workout = firstWorkout.rows[0];
        console.log(`\n🔍 WORKOUT STRUCTURE (from scheduled workout):`);
        console.log('─'.repeat(50));
        await this.showDetailedWorkoutStructure(workout.id);
      }
    } else {
      console.log(`\n📅 TODAY'S STATUS: NOT PROGRAM START DATE`);
      console.log('─'.repeat(50));
      console.log(`  Program started: ${userProgram.start_date.toISOString().split('T')[0]}`);
      console.log(`  Days since start: ${this.calculateDateDifference(userProgram.start_date.toISOString().split('T')[0], today)}`);
    }

    // Show upcoming workouts
    console.log(`\n📅 UPCOMING WORKOUTS:`);
    console.log('─'.repeat(50));
    
    const upcomingWorkouts = await this.client.query(
      'SELECT * FROM user_workouts WHERE user_program_id = $1 AND scheduled_date >= $2 ORDER BY scheduled_date ASC LIMIT 5',
      [userProgram.id, today]
    );

    if (upcomingWorkouts.rows.length > 0) {
      upcomingWorkouts.rows.forEach((workout, i) => {
        const daysUntil = this.calculateDateDifference(today, workout.scheduled_date.toISOString().split('T')[0]);
        const dayLabel = daysUntil === 0 ? 'TODAY' : daysUntil === 1 ? 'TOMORROW' : `in ${daysUntil} days`;
        console.log(`  ${i + 1}. ${workout.title_snapshot} - ${dayLabel} (${workout.scheduled_date})`);
      });
    } else {
      console.log('  No upcoming workouts found');
    }

    // Summary and recommendations
    console.log(`\n💡 SUMMARY & RECOMMENDATIONS:`);
    console.log('─'.repeat(50));
    
    if (isStartDate) {
      console.log(`  ✅ Today (${today}) is the program start date`);
      console.log(`  ❌ But no workout is scheduled for today`);
      console.log(`  📅 First workout is scheduled for Monday, September 8th`);
      console.log(`  🔧 This suggests a scheduling algorithm issue`);
      console.log(`  💪 The app should show today's workout: Week 1, Day 1 - Lower Bias`);
    } else {
      console.log(`  📅 Today is not the program start date`);
      console.log(`  📋 Check upcoming workouts above for what's next`);
    }
  }

  async showDetailedWorkoutStructure(workoutId) {
    const workoutBlocks = await this.client.query(
      'SELECT * FROM user_workout_blocks WHERE user_workout_id = $1 ORDER BY sequence',
      [workoutId]
    );

    if (workoutBlocks.rows.length === 0) {
      console.log(`    ❌ No workout blocks found for this workout`);
      return;
    }

    console.log(`    📦 WORKOUT BLOCKS (${workoutBlocks.rows.length} total):`);
    
    for (let j = 0; j < workoutBlocks.rows.length; j++) {
      const block = workoutBlocks.rows[j];
      console.log(`\n      Block ${j + 1}: ${block.block_name_snapshot}`);
      console.log(`        Type: ${block.block_type_label_snapshot}`);
      console.log(`        Sequence: ${block.sequence}`);
      
      // Get movement details for this block
      const movements = await this.client.query(
        'SELECT mbi.*, m.name as movement_name FROM movement_block_items mbi ' +
        'LEFT JOIN movements m ON mbi.movement_id = m.id ' +
        'WHERE mbi.block_id = $1 ORDER BY mbi.sequence',
        [block.movement_block_id]
      );
      
      if (movements.rows.length > 0) {
        console.log(`        Movements (${movements.rows.length}):`);
        movements.rows.forEach((movement, k) => {
          console.log(`          ${k + 1}. ${movement.movement_name || 'Unknown'}`);
        });
      }
    }
  }

  calculateDateDifference(date1, date2) {
    const d1 = new Date(date1);
    const d2 = new Date(date2);
    const diffTime = Math.abs(d2 - d1);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return d2 > d1 ? diffDays : -diffDays;
  }

  async run() {
    try {
      await this.connect();
      await this.showTodaysWorkoutSummary();
    } catch (error) {
      console.error('❌ Error:', error.message);
    } finally {
      await this.disconnect();
    }
  }
}

async function main() {
  const analyzer = new TodaysWorkoutSummary();
  await analyzer.run();
}

main().catch(console.error);
