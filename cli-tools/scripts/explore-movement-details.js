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

class MovementDetailsExplorer {
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

  async exploreMovementBlocks() {
    console.log('🔍 MOVEMENT BLOCKS (Referenced in your training program):');
    console.log('──────────────────────────────────────────────────');
    
    // These are the movement block IDs found in your user_workout_blocks
    const blockIds = [
      '800c03cc-3374-421c-93c4-431614f9e5e1', // Hips & Hinge Primer
      '34c6447c-169a-4a31-a939-0f19f68fa9c6', // Lower Strength — Squat + Hinge
      '0a0738a1-048c-4580-ba0f-5125ac2166bc', // Aerobic Mix — Run + Rope
      'ff822aa3-d5c7-446e-b058-67c34638f07b', // Mobility Reset — Shoulder + Lumbar
      '9354a236-91fe-463c-a725-397dcd5ded38', // Upper Mobility & Core
      '94008b9c-66ba-4407-92e1-4cb3bb4bd93d', // Upper Strength — Press + Row
      'ce3876f9-1e0b-46a0-a828-769f43368fe4', // Aerobic Steps — Step-Up + Lunge
      '3e4bef2a-b584-45f0-8704-88951f1adb46'  // Antirotation Core — Tall Kneel + Band
    ];

    for (const blockId of blockIds) {
      try {
        const blockResult = await this.client.query(
          'SELECT * FROM movement_blocks WHERE id = $1',
          [blockId]
        );
        
        if (blockResult.rows.length > 0) {
          const block = blockResult.rows[0];
          console.log(`\n📋 Block: ${block.name}`);
          console.log(`  ID: ${block.id}`);
          console.log(`  Type: ${block.block_type}`);
          console.log(`  Equipment: ${block.equipment || 'None'}`);
          console.log(`  Created: ${block.created_at}`);
          
          // Get movement block items
          const itemsResult = await this.client.query(
            'SELECT * FROM movement_block_items WHERE movement_block_id = $1 ORDER BY sequence',
            [blockId]
          );
          
          console.log(`  Movements (${itemsResult.rows.length}):`);
          itemsResult.rows.forEach((item, i) => {
            console.log(`    ${i + 1}. Sequence ${item.sequence}: Movement ID ${item.movement_id}`);
          });
        }
      } catch (error) {
        console.error(`❌ Error exploring block ${blockId}:`, error.message);
      }
    }
  }

  async exploreMovements() {
    console.log('\n🔍 MOVEMENTS (Referenced in your training program):');
    console.log('──────────────────────────────────────────────────');
    
    // These are the movement IDs found in your user_block_items
    const movementIds = [
      '76062d2e-0eef-491c-a888-358e4739248a', // Toe Touch (Assessment)
      'b4d05813-3c4f-4d96-99cb-c2fe50542d27'  // Hip Hinge (Assessment)
    ];

    for (const movementId of movementIds) {
      try {
        const movementResult = await this.client.query(
          'SELECT * FROM movements WHERE id = $1',
          [movementId]
        );
        
        if (movementResult.rows.length > 0) {
          const movement = movementResult.rows[0];
          console.log(`\n📋 Movement: ${movement.name}`);
          console.log(`  ID: ${movement.id}`);
          console.log(`  Pattern: ${movement.pattern_id}`);
          console.log(`  Assessment: ${movement.is_assessment}`);
          console.log(`  Created: ${movement.created_at}`);
          
          // Get movement pattern
          if (movement.pattern_id) {
            const patternResult = await this.client.query(
              'SELECT * FROM movement_patterns WHERE id = $1',
              [movement.pattern_id]
            );
            
            if (patternResult.rows.length > 0) {
              const pattern = patternResult.rows[0];
              console.log(`  Pattern Name: ${pattern.name}`);
              console.log(`  Pattern Description: ${pattern.description}`);
            }
          }
        }
      } catch (error) {
        console.error(`❌ Error exploring movement ${movementId}:`, error.message);
      }
    }
  }

  async exploreDoseMetrics() {
    console.log('\n🔍 DOSE METRICS (Referenced in planned_dose):');
    console.log('──────────────────────────────────────────────────');
    
    // The dose metric ID found in your planned_dose
    const doseMetricId = '429c427b-db1b-4dab-b72a-85399f28aa12';
    
    try {
      const doseResult = await this.client.query(
        'SELECT * FROM dose_metrics WHERE id = $1',
        [doseMetricId]
      );
      
      if (doseResult.rows.length > 0) {
        const dose = doseResult.rows[0];
        console.log(`📋 Dose Metric: ${dose.name}`);
        console.log(`  ID: ${dose.id}`);
        console.log(`  Unit: ${dose.unit}`);
        console.log(`  Description: ${dose.description}`);
        console.log(`  Created: ${dose.created_at}`);
      } else {
        console.log(`❌ Dose metric ${doseMetricId} not found`);
      }
    } catch (error) {
      console.error(`❌ Error exploring dose metric:`, error.message);
    }
  }

  async explore() {
    try {
      await this.connect();
      await this.exploreMovementBlocks();
      await this.exploreMovements();
      await this.exploreDoseMetrics();
    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    } finally {
      await this.disconnect();
    }
  }
}

async function main() {
  const explorer = new MovementDetailsExplorer();
  await explorer.explore();
}

main().catch(console.error);
