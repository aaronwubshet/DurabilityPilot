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

class SimpleFunctionAnalyzer {
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

  async listAllFunctions() {
    try {
      console.log('\n🔍 Listing All RPC Functions...\n');
      
      const query = `
        SELECT 
          p.proname as function_name,
          pg_get_function_arguments(p.oid) as args,
          pg_get_function_result(p.oid) as return_type
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        ORDER BY p.proname;
      `;
      
      const result = await this.client.query(query);
      
      if (result.rows.length === 0) {
        console.log('❌ No functions found in public schema');
        return [];
      }
      
      console.log(`Found ${result.rows.length} functions:\n`);
      
      result.rows.forEach((func, index) => {
        console.log(`${index + 1}. ${func.function_name}`);
        console.log(`   Args: ${func.args || 'None'}`);
        console.log(`   Returns: ${func.return_type || 'void'}`);
        console.log('');
      });
      
      return result.rows;
    } catch (error) {
      console.error('❌ Error listing functions:', error.message);
      return [];
    }
  }

  async analyzeRedundancies(functions) {
    console.log('\n🔍 Analyzing Function Redundancies...\n');
    
    // Group functions by purpose
    const groups = {
      'Phase Management': [],
      'Assignment': [],
      'Synchronization': [],
      'Validation': [],
      'Utility': [],
      'Other': []
    };
    
    functions.forEach(func => {
      const name = func.function_name.toLowerCase();
      
      if (name.includes('prep') || name.includes('build') || 
          name.includes('capacity') || name.includes('finish')) {
        groups['Phase Management'].push(func);
      } else if (name.includes('assign')) {
        groups['Assignment'].push(func);
      } else if (name.includes('sync')) {
        groups['Synchronization'].push(func);
      } else if (name.includes('validate') || name.includes('ensure')) {
        groups['Validation'].push(func);
      } else if (name.includes('normalize') || name.includes('score') || 
                 name.includes('json')) {
        groups['Utility'].push(func);
      } else {
        groups['Other'].push(func);
      }
    });
    
    // Display grouped functions
    Object.entries(groups).forEach(([groupName, funcs]) => {
      if (funcs.length > 0) {
        console.log(`${groupName}:`);
        console.log('─'.repeat(groupName.length + 1));
        funcs.forEach(func => console.log(`  - ${func.function_name}`));
        console.log('');
      }
    });
    
    // Identify specific redundancies
    this.identifySpecificRedundancies(groups);
  }

  identifySpecificRedundancies(groups) {
    console.log('\n🗑️  Redundancy Analysis:\n');
    
    // Phase Management functions
    if (groups['Phase Management'].length > 1) {
      console.log('🔴 Phase Management Functions (HIGH REDUNDANCY):');
      console.log('   These functions appear to do similar work and can likely be consolidated:');
      groups['Phase Management'].forEach(func => {
        console.log(`   - ${func.function_name}`);
      });
      console.log('   💡 Recommendation: Consolidate into a single function like create_phase_workout()');
      console.log('');
    }
    
    // Assignment functions
    if (groups['Assignment'].length > 1) {
      console.log('🟡 Assignment Functions (MEDIUM REDUNDANCY):');
      console.log('   These functions may have overlapping functionality:');
      groups['Assignment'].forEach(func => {
        console.log(`   - ${func.function_name}`);
      });
      console.log('   💡 Recommendation: Review for consolidation opportunities');
      console.log('');
    }
    
    // Synchronization functions
    if (groups['Synchronization'].length > 1) {
      console.log('🟡 Synchronization Functions (MEDIUM REDUNDANCY):');
      console.log('   These functions may have overlapping functionality:');
      groups['Synchronization'].forEach(func => {
        console.log(`   - ${func.function_name}`);
      });
      console.log('   💡 Recommendation: Review for consolidation opportunities');
      console.log('');
    }
    
    // Check for other potential redundancies
    const allNames = Object.values(groups).flat().map(f => f.function_name);
    const similarNames = this.findSimilarFunctionNames(allNames);
    
    if (similarNames.length > 0) {
      console.log('🟡 Similar Named Functions (POTENTIAL REDUNDANCY):');
      similarNames.forEach(group => {
        console.log(`   Functions with similar names:`);
        group.forEach(name => console.log(`   - ${name}`));
        console.log('');
      });
    }
  }

  findSimilarFunctionNames(names) {
    const groups = [];
    const processed = new Set();
    
    names.forEach(name1 => {
      if (processed.has(name1)) return;
      
      const similar = [name1];
      const base1 = this.getBaseName(name1);
      
      names.forEach(name2 => {
        if (name1 !== name2 && !processed.has(name2)) {
          const base2 = this.getBaseName(name2);
          if (base1 === base2 || this.areSimilarNames(name1, name2)) {
            similar.push(name2);
            processed.add(name2);
          }
        }
      });
      
      if (similar.length > 1) {
        groups.push(similar);
        processed.add(name1);
      }
    });
    
    return groups;
  }

  getBaseName(name) {
    // Remove common prefixes/suffixes to find base names
    return name
      .replace(/^(create_|get_|update_|delete_|assign_|sync_)/, '')
      .replace(/(_prep|_build|_capacity|_finish)$/, '');
  }

  areSimilarNames(name1, name2) {
    const words1 = name1.split('_');
    const words2 = name2.split('_');
    
    // Check if they share most words
    const commonWords = words1.filter(w => words2.includes(w));
    return commonWords.length >= Math.min(words1.length, words2.length) * 0.7;
  }

  async explore() {
    try {
      const functions = await this.listAllFunctions();
      if (functions.length > 0) {
        await this.analyzeRedundancies(functions);
      }
    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    }
  }
}

async function main() {
  const analyzer = new SimpleFunctionAnalyzer();
  
  try {
    await analyzer.connect();
    await analyzer.explore();
  } catch (error) {
    console.error('❌ Failed to analyze functions:', error.message);
  } finally {
    await analyzer.disconnect();
  }
}

main();
