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

class TableSchemaExplorer {
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

  async exploreTableSchema(tableName) {
    console.log(`\n🔍 Table Schema: ${tableName}`);
    console.log('─'.repeat(50));
    
    try {
      // Get table structure
      const structureQuery = `
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = $1 
        ORDER BY ordinal_position
      `;
      
      const structureResult = await this.client.query(structureQuery, [tableName]);
      console.log('📋 Columns:');
      structureResult.rows.forEach(col => {
        const nullable = col.is_nullable === 'NO' ? '(NOT NULL)' : '';
        const defaultValue = col.column_default ? ` DEFAULT ${col.column_default}` : '';
        console.log(`  ${col.column_name}: ${col.data_type}${nullable}${defaultValue}`);
      });
      
      // Get sample data
      const dataQuery = `SELECT * FROM ${tableName} LIMIT 3`;
      const dataResult = await this.client.query(dataQuery);
      
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

  async explore() {
    const tables = ['user_programs', 'user_workouts', 'user_workout_blocks', 'user_block_items', 'movement_blocks', 'movement_block_items'];
    
    try {
      await this.connect();
      
      for (const table of tables) {
        await this.exploreTableSchema(table);
      }
      
    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    } finally {
      await this.disconnect();
    }
  }
}

async function main() {
  const explorer = new TableSchemaExplorer();
  await explorer.explore();
}

main().catch(console.error);
