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

class ProgramExplorer {
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

  async explorePrograms() {
    try {
      console.log('\n🏋️‍♂️ Exploring Training Programs');
      console.log('─'.repeat(50));
      
      const query = `
        SELECT 
          p.id,
          p.name,
          p.slug,
          p.weeks,
          p.workouts_per_week,
          p.version,
          p.is_active,
          p.created_at,
          p.updated_at
        FROM programs p
        ORDER BY p.created_at DESC
        LIMIT 10
      `;
      
      const result = await this.client.query(query);
      console.log(`📝 Found ${result.rows.length} programs:`);
      
      result.rows.forEach((program, index) => {
        console.log(`\n  Program ${index + 1}:`);
        console.log(`    ID: ${program.id}`);
        console.log(`    Name: ${program.name}`);
        console.log(`    Slug: ${program.slug}`);
        console.log(`    Duration: ${program.weeks} weeks`);
        console.log(`    Workouts per week: ${program.workouts_per_week}`);
        console.log(`    Version: ${program.version}`);
        console.log(`    Active: ${program.is_active}`);
        console.log(`    Created: ${program.created_at}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring programs:', error.message);
    }
  }

  async exploreProgramStructure() {
    try {
      console.log('\n🏗️ Exploring Program Structure');
      console.log('─'.repeat(50));
      
      // Get program phases
      const phasesQuery = `
        SELECT 
          pp.id,
          pp.program_id,
          pp.phase_index,
          pp.weeks_count,
          p.name as program_name
        FROM program_phases pp
        JOIN programs p ON pp.program_id = p.id
        ORDER BY pp.program_id, pp.phase_index
        LIMIT 10
      `;
      
      const phasesResult = await this.client.query(phasesQuery);
      console.log(`📋 Found ${phasesResult.rows.length} program phases:`);
      
      phasesResult.rows.forEach((phase, index) => {
        console.log(`\n  Phase ${index + 1}:`);
        console.log(`    ID: ${phase.id}`);
        console.log(`    Program: ${phase.program_name}`);
        console.log(`    Phase Index: ${phase.phase_index}`);
        console.log(`    Weeks: ${phase.weeks_count}`);
      });
      
      // Get program weeks
      const weeksQuery = `
        SELECT 
          pw.id,
          pw.program_id,
          pw.phase_id,
          pw.week_index,
          pw.phase_week_index,
          p.name as program_name
        FROM program_weeks pw
        JOIN programs p ON pw.program_id = p.id
        ORDER BY pw.program_id, pw.week_index
        LIMIT 10
      `;
      
      const weeksResult = await this.client.query(weeksQuery);
      console.log(`\n📅 Found ${weeksResult.rows.length} program weeks:`);
      
      weeksResult.rows.forEach((week, index) => {
        console.log(`\n  Week ${index + 1}:`);
        console.log(`    ID: ${week.id}`);
        console.log(`    Program: ${week.program_name}`);
        console.log(`    Week Index: ${week.week_index}`);
        console.log(`    Phase Week: ${week.phase_week_index}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring program structure:', error.message);
    }
  }

  async exploreWorkouts() {
    try {
      console.log('\n💪 Exploring Workouts');
      console.log('─'.repeat(50));
      
      const query = `
        SELECT 
          pw.id,
          pw.program_id,
          pw.week_id,
          pw.day_index,
          pw.title,
          p.name as program_name
        FROM program_workouts pw
        JOIN programs p ON pw.program_id = p.id
        ORDER BY pw.program_id, pw.week_id, pw.day_index
        LIMIT 15
      `;
      
      const result = await this.client.query(query);
      console.log(`📝 Found ${result.rows.length} workouts:`);
      
      result.rows.forEach((workout, index) => {
        console.log(`\n  Workout ${index + 1}:`);
        console.log(`    ID: ${workout.id}`);
        console.log(`    Program: ${workout.program_name}`);
        console.log(`    Day: ${workout.day_index}`);
        console.log(`    Title: ${workout.title}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring workouts:', error.message);
    }
  }

  async exploreMovementBlocks() {
    try {
      console.log('\n🧱 Exploring Movement Blocks');
      console.log('─'.repeat(50));
      
      const query = `
        SELECT 
          mb.id,
          mb.name,
          mb.slug,
          mb.block_type_id,
          bt.label as block_type_label,
          mb.required_equipment,
          mb.created_at
        FROM movement_blocks mb
        LEFT JOIN block_types bt ON mb.block_type_id = bt.id
        ORDER BY mb.created_at DESC
        LIMIT 10
      `;
      
      const result = await this.client.query(query);
      console.log(`📝 Found ${result.rows.length} movement blocks:`);
      
      result.rows.forEach((block, index) => {
        console.log(`\n  Block ${index + 1}:`);
        console.log(`    ID: ${block.id}`);
        console.log(`    Name: ${block.name}`);
        console.log(`    Slug: ${block.slug}`);
        console.log(`    Type: ${block.block_type_label}`);
        console.log(`    Equipment: ${block.required_equipment}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring movement blocks:', error.message);
    }
  }

  async explore() {
    try {
      console.log('🔍 Starting Program and Workout Exploration...\n');
      
      await this.explorePrograms();
      await this.exploreProgramStructure();
      await this.exploreWorkouts();
      await this.exploreMovementBlocks();
      
      console.log('\n🎉 Program exploration completed!');
      
    } catch (error) {
      console.error('❌ Exploration failed:', error.message);
    }
  }
}

async function main() {
  const explorer = new ProgramExplorer();
  
  try {
    await explorer.connect();
    await explorer.explore();
  } catch (error) {
    console.error('❌ Main execution failed:', error.message);
  } finally {
    await explorer.disconnect();
  }
}

main();
