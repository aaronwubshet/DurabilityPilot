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

class ComprehensiveAnalyzer {
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

  async analyzeNewTables() {
    try {
      console.log('\n🔍 **NEW TABLES ANALYSIS**');
      console.log('========================');
      
      // Check new user-related tables
      const newTables = [
        'user_programs',
        'user_workouts', 
        'user_workout_blocks',
        'user_block_items',
        'user_set_logs'
      ];

      for (const tableName of newTables) {
        console.log(`\n📋 **${tableName.toUpperCase()}**`);
        console.log('─'.repeat(50));
        
        const result = await this.client.query(`
          SELECT column_name, data_type, is_nullable, column_default, ordinal_position
          FROM information_schema.columns 
          WHERE table_name = $1 
          ORDER BY ordinal_position
        `, [tableName]);
        
        if (result.rows.length > 0) {
          console.log('Columns:');
          result.rows.forEach(col => {
            const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
            const defaultVal = col.column_default ? ` DEFAULT ${col.column_default}` : '';
            console.log(`  • ${col.column_name}: ${col.data_type} ${nullable}${defaultVal}`);
          });
        } else {
          console.log('  ❌ Table not found');
        }
      }
    } catch (error) {
      console.error('Error analyzing new tables:', error.message);
    }
  }

  async analyzeAssessmentChanges() {
    try {
      console.log('\n🔍 **ASSESSMENT SYSTEM CHANGES**');
      console.log('================================');
      
      // Check assessment_results structure
      const result = await this.client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = 'assessment_results' 
        ORDER BY ordinal_position
      `);
      
      console.log('\n📊 **Assessment Results Table Structure:**');
      result.rows.forEach(col => {
        const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
        const defaultVal = col.column_default ? ` DEFAULT ${col.column_default}` : '';
        console.log(`  • ${col.column_name}: ${col.data_type} ${nullable}${defaultVal}`);
      });

      // Check if there are any assessment results
      const countResult = await this.client.query(`
        SELECT COUNT(*) as total_assessments
        FROM assessment_results
      `);
      
      console.log(`\n📈 **Current Assessment Data:**`);
      console.log(`  • Total assessment results: ${countResult.rows[0].total_assessments}`);
      
    } catch (error) {
      console.error('Error analyzing assessment changes:', error.message);
    }
  }

  async analyzeMovementChanges() {
    try {
      console.log('\n🔍 **MOVEMENT SYSTEM CHANGES**');
      console.log('==============================');
      
      // Check movements table structure
      const result = await this.client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = 'movements' 
        ORDER BY ordinal_position
      `);
      
      console.log('\n🏃 **Movements Table Structure:**');
      result.rows.forEach(col => {
        const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
        const defaultVal = col.column_default ? ` DEFAULT ${col.column_default}` : '';
        console.log(`  • ${col.column_name}: ${col.data_type} ${nullable}${defaultVal}`);
      });

      // Check movement count
      const countResult = await this.client.query(`
        SELECT COUNT(*) as total_movements
        FROM movements
      `);
      
      console.log(`\n📊 **Movement Data:**`);
      console.log(`  • Total movements: ${countResult.rows[0].total_movements}`);
      
      // Check if movements now use UUIDs
      const idTypeResult = await this.client.query(`
        SELECT data_type 
        FROM information_schema.columns 
        WHERE table_name = 'movements' AND column_name = 'id'
      `);
      
      console.log(`  • Movement ID type: ${idTypeResult.rows[0]?.data_type || 'Unknown'}`);
      
    } catch (error) {
      console.error('Error analyzing movement changes:', error.message);
    }
  }

  async analyzeNewFunctions() {
    try {
      console.log('\n🔍 **NEW FUNCTIONS ANALYSIS**');
      console.log('=============================');
      
      const newFunctions = [
        'assign_program',
        'assign_program_self', 
        'update_user_workout_status',
        'progress_dose'
      ];

      for (const funcName of newFunctions) {
        console.log(`\n⚙️ **${funcName.toUpperCase()}**`);
        console.log('─'.repeat(50));
        
        const result = await this.client.query(`
          SELECT 
            p.proname as function_name,
            pg_get_function_arguments(p.oid) as arguments,
            pg_get_function_result(p.oid) as return_type,
            p.prosrc as source_code
          FROM pg_proc p
          WHERE p.proname = $1
        `, [funcName]);
        
        if (result.rows.length > 0) {
          const func = result.rows[0];
          console.log(`  • Arguments: ${func.arguments}`);
          console.log(`  • Returns: ${func.return_type}`);
          console.log(`  • Source: ${func.source_code.substring(0, 100)}...`);
        } else {
          console.log('  ❌ Function not found');
        }
      }
      
    } catch (error) {
      console.error('Error analyzing new functions:', error.message);
    }
  }

  async analyzeDataRelationships() {
    try {
      console.log('\n🔍 **DATA RELATIONSHIP ANALYSIS**');
      console.log('==================================');
      
      // Check foreign key relationships for new tables
      const fkResult = await this.client.query(`
        SELECT 
          tc.table_name, 
          kcu.column_name, 
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name 
        FROM 
          information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
          AND tc.table_name IN ('user_programs', 'user_workouts', 'user_workout_blocks', 'user_block_items', 'user_set_logs')
        ORDER BY tc.table_name, kcu.column_name
      `);
      
      console.log('\n🔗 **Foreign Key Relationships for New Tables:**');
      fkResult.rows.forEach(fk => {
        console.log(`  • ${fk.table_name}.${fk.column_name} → ${fk.foreign_table_name}.${fk.foreign_column_name}`);
      });
      
    } catch (error) {
      console.error('Error analyzing data relationships:', error.message);
    }
  }

  async analyzeRLSPolicies() {
    try {
      console.log('\n🔍 **RLS POLICIES ANALYSIS**');
      console.log('=============================');
      
      // Count policies by table
      const policyCountResult = await this.client.query(`
        SELECT 
          tablename,
          COUNT(*) as policy_count
        FROM pg_policies 
        WHERE schemaname = 'public'
        GROUP BY tablename
        ORDER BY policy_count DESC
      `);
      
      console.log('\n🔒 **RLS Policies by Table:**');
      policyCountResult.rows.forEach(row => {
        console.log(`  • ${row.tablename}: ${row.policy_count} policies`);
      });
      
      // Check policies on new tables
      const newTablePolicies = await this.client.query(`
        SELECT 
          tablename,
          policyname,
          cmd,
          qual
        FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename IN ('user_programs', 'user_workouts', 'user_workout_blocks', 'user_block_items', 'user_set_logs')
        ORDER BY tablename, policyname
      `);
      
      console.log('\n🛡️ **RLS Policies on New Tables:**');
      newTablePolicies.rows.forEach(policy => {
        console.log(`  • ${policy.tablename}.${policy.policyname}: ${policy.cmd}`);
        if (policy.qual) {
          console.log(`    Condition: ${policy.qual.substring(0, 80)}...`);
        }
      });
      
    } catch (error) {
      console.error('Error analyzing RLS policies:', error.message);
    }
  }

  async analyzeIndexes() {
    try {
      console.log('\n🔍 **INDEX ANALYSIS**');
      console.log('====================');
      
      // Count indexes by table
      const indexCountResult = await this.client.query(`
        SELECT 
          schemaname,
          tablename,
          COUNT(*) as index_count
        FROM pg_indexes 
        WHERE schemaname = 'public'
        GROUP BY schemaname, tablename
        ORDER BY index_count DESC
        LIMIT 15
      `);
      
      console.log('\n📊 **Index Count by Table (Top 15):**');
      indexCountResult.rows.forEach(row => {
        console.log(`  • ${row.tablename}: ${row.index_count} indexes`);
      });
      
      // Check unique indexes
      const uniqueIndexes = await this.client.query(`
        SELECT 
          tablename,
          indexname,
          indexdef
        FROM pg_indexes 
        WHERE schemaname = 'public' 
          AND indexdef LIKE '%UNIQUE%'
        ORDER BY tablename, indexname
      `);
      
      console.log('\n🔐 **Unique Indexes:**');
      uniqueIndexes.rows.forEach(idx => {
        console.log(`  • ${idx.tablename}.${idx.indexname}`);
        console.log(`    Definition: ${idx.indexdef.substring(0, 80)}...`);
      });
      
    } catch (error) {
      console.error('Error analyzing indexes:', error.message);
    }
  }

  async runComprehensiveAnalysis() {
    try {
      console.log('🚀 **COMPREHENSIVE DATABASE ANALYSIS**');
      console.log('=====================================');
      console.log('Analyzing your updated Supabase database...\n');
      
      await this.analyzeNewTables();
      await this.analyzeAssessmentChanges();
      await this.analyzeMovementChanges();
      await this.analyzeNewFunctions();
      await this.analyzeDataRelationships();
      await this.analyzeRLSPolicies();
      await this.analyzeIndexes();
      
      console.log('\n✅ **Analysis Complete!**');
      console.log('========================');
      
    } catch (error) {
      console.error('❌ Analysis failed:', error.message);
    }
  }
}

async function main() {
  const analyzer = new ComprehensiveAnalyzer();
  
  try {
    await analyzer.connect();
    await analyzer.runComprehensiveAnalysis();
  } catch (error) {
    console.error('❌ Failed to run analysis:', error.message);
  } finally {
    await analyzer.disconnect();
  }
}

main();
