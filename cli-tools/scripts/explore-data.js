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

class DataExplorer {
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

  async exploreTable(tableName, limit = 5) {
    try {
      console.log(`\n📊 Exploring table: ${tableName}`);
      console.log('─'.repeat(50));
      
      // Get table structure
      const structureQuery = `
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = $1 
        ORDER BY ordinal_position
      `;
      
      const structureResult = await this.client.query(structureQuery, [tableName]);
      console.log('📋 Table Structure:');
      structureResult.rows.forEach(col => {
        console.log(`  ${col.column_name}: ${col.data_type}${col.is_nullable === 'NO' ? ' (NOT NULL)' : ''}`);
      });
      
      // Get sample data
      const dataQuery = `SELECT * FROM ${tableName} LIMIT $1`;
      const dataResult = await this.client.query(dataQuery, [limit]);
      
      console.log(`\n📝 Sample Data (${dataResult.rows.length} rows):`);
      if (dataResult.rows.length > 0) {
        dataResult.rows.forEach((row, index) => {
          console.log(`\n  Row ${index + 1}:`);
          Object.entries(row).forEach(([key, value]) => {
            if (value !== null && value !== undefined) {
              const displayValue = typeof value === 'object' ? JSON.stringify(value).substring(0, 100) : String(value);
              console.log(`    ${key}: ${displayValue}`);
            }
          });
        });
      } else {
        console.log('  No data found');
      }
      
      // Get row count
      const countQuery = `SELECT COUNT(*) as total FROM ${tableName}`;
      const countResult = await this.client.query(countQuery);
      console.log(`\n📊 Total rows: ${countResult.rows[0].total}`);
      
    } catch (error) {
      console.error(`❌ Error exploring ${tableName}:`, error.message);
    }
  }

  async exploreMovements() {
    try {
      console.log('\n🏃‍♂️ Exploring Movements Table (Special Focus)');
      console.log('─'.repeat(60));
      
      // Get movements with their patterns
      const query = `
        SELECT 
          m.id,
          m.name,
          mp.name as pattern_name,
          m.default_module_impact_vector,
          m.default_sport_impact_vector,
          m.is_assessment,
          m.created_at
        FROM movements m
        LEFT JOIN movement_patterns mp ON m.pattern_id = mp.id
        LIMIT 10
      `;
      
      const result = await this.client.query(query);
      console.log(`📝 Found ${result.rows.length} movements:`);
      
      result.rows.forEach((movement, index) => {
        console.log(`\n  Movement ${index + 1}:`);
        console.log(`    ID: ${movement.id}`);
        console.log(`    Name: ${movement.name}`);
        console.log(`    Pattern: ${movement.pattern_name}`);
        console.log(`    Assessment: ${movement.is_assessment}`);
        console.log(`    Module Impact: ${JSON.stringify(movement.default_module_impact_vector)}`);
        console.log(`    Sport Impact: ${JSON.stringify(movement.default_sport_impact_vector)}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring movements:', error.message);
    }
  }

  async exploreProfiles() {
    try {
      console.log('\n👤 Exploring Profiles Table');
      console.log('─'.repeat(50));
      
      const query = `
        SELECT 
          id,
          first_name,
          last_name,
          age,
          sex,
          height_cm,
          weight_kg,
          onboarding_completed,
          assessment_completed,
          created_at
        FROM profiles
        LIMIT 5
      `;
      
      const result = await this.client.query(query);
      console.log(`📝 Found ${result.rows.length} profiles:`);
      
      result.rows.forEach((profile, index) => {
        console.log(`\n  Profile ${index + 1}:`);
        console.log(`    ID: ${profile.id}`);
        console.log(`    Name: ${profile.first_name} ${profile.last_name}`);
        console.log(`    Age: ${profile.age}`);
        console.log(`    Sex: ${profile.sex}`);
        console.log(`    Height: ${profile.height_cm} cm`);
        console.log(`    Weight: ${profile.weight_kg} kg`);
        console.log(`    Onboarding: ${profile.onboarding_completed}`);
        console.log(`    Assessment: ${profile.assessment_completed}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring profiles:', error.message);
    }
  }

  async exploreAssessmentResults() {
    try {
      console.log('\n📊 Exploring Assessment Results');
      console.log('─'.repeat(50));
      
      const query = `
        SELECT 
          ar.assessment_id,
          ar.profile_id,
          ar.body_area,
          ar.durability_score,
          ar.range_of_motion_score,
          ar.flexibility_score,
          ar.functional_strength_score,
          ar.mobility_score,
          ar.aerobic_capacity_score,
          ar.created_at
        FROM assessment_results ar
        LIMIT 5
      `;
      
      const result = await this.client.query(query);
      console.log(`📝 Found ${result.rows.length} assessment results:`);
      
      result.rows.forEach((result, index) => {
        console.log(`\n  Assessment Result ${index + 1}:`);
        console.log(`    Assessment ID: ${result.assessment_id}`);
        console.log(`    Profile ID: ${result.profile_id}`);
        console.log(`    Body Area: ${result.body_area}`);
        console.log(`    Durability Score: ${result.durability_score}`);
        console.log(`    ROM Score: ${result.range_of_motion_score}`);
        console.log(`    Flexibility Score: ${result.flexibility_score}`);
        console.log(`    Strength Score: ${result.functional_strength_score}`);
        console.log(`    Mobility Score: ${result.mobility_score}`);
        console.log(`    Aerobic Score: ${result.aerobic_capacity_score}`);
      });
      
    } catch (error) {
      console.error('❌ Error exploring assessment results:', error.message);
    }
  }

  async explore() {
    try {
      console.log('🔍 Starting Database Data Exploration...\n');
      
      // Explore key tables
      await this.exploreProfiles();
      await this.exploreMovements();
      await this.exploreAssessmentResults();
      
      // Explore other important tables
      await this.exploreTable('assessments');
      await this.exploreTable('equipment');
      await this.exploreTable('goals');
      await this.exploreTable('injuries');
      await this.exploreTable('sports');
      
      console.log('\n🎉 Data exploration completed!');
      
    } catch (error) {
      console.error('❌ Exploration failed:', error.message);
    }
  }
}

async function main() {
  const explorer = new DataExplorer();
  
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
