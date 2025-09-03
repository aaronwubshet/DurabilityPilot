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

class FunctionUsageAnalyzer {
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

  async analyzeFunctionUsage() {
    try {
      console.log('\n🔍 Analyzing RPC Function Usage and Redundancy...\n');

      // Get all functions
      const functionsQuery = `
        SELECT 
          p.proname as function_name,
          p.prosrc as source_code,
          pg_get_function_arguments(p.oid) as args,
          pg_get_function_result(p.oid) as return_type,
          p.prolang as language
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prolang = 12  -- plpgsql
        ORDER BY p.proname;
      `;

      const functions = await this.client.query(functionsQuery);
      
      // Analyze each function
      const analysis = [];
      
      for (const func of functions.rows) {
        const analysisResult = this.analyzeFunction(func);
        analysis.push(analysisResult);
      }

      // Group functions by category and identify redundancies
      this.groupAndAnalyzeFunctions(analysis);

    } catch (error) {
      console.error('❌ Error analyzing functions:', error.message);
    }
  }

  analyzeFunction(func) {
    const { function_name, source_code, args, return_type } = func;
    
    // Analyze function purpose and complexity
    const purpose = this.determineFunctionPurpose(function_name, source_code);
    const complexity = this.assessComplexity(source_code);
    const potentialRedundancy = this.assessRedundancy(function_name, source_code);
    
    return {
      name: function_name,
      purpose,
      complexity,
      potentialRedundancy,
      arguments,
      return_type,
      source_length: source_code ? source_code.length : 0
    };
  }

  determineFunctionPurpose(name, source) {
    const nameLower = name.toLowerCase();
    const sourceLower = source ? source.toLowerCase() : '';

    if (nameLower.includes('prep') || nameLower.includes('build') || 
        nameLower.includes('capacity') || nameLower.includes('finish')) {
      return 'Phase Management (Potentially Redundant)';
    }
    
    if (nameLower.includes('assign')) {
      return 'Assignment/Allocation';
    }
    
    if (nameLower.includes('sync')) {
      return 'Data Synchronization';
    }
    
    if (nameLower.includes('validate') || nameLower.includes('ensure')) {
      return 'Validation/Verification';
    }
    
    if (nameLower.includes('normalize') || nameLower.includes('score')) {
      return 'Data Processing';
    }
    
    if (nameLower.includes('get') || nameLower.includes('fetch')) {
      return 'Data Retrieval';
    }
    
    if (nameLower.includes('create') || nameLower.includes('insert')) {
      return 'Data Creation';
    }
    
    if (nameLower.includes('update') || nameLower.includes('modify')) {
      return 'Data Modification';
    }
    
    if (nameLower.includes('delete') || nameLower.includes('remove')) {
      return 'Data Deletion';
    }
    
    return 'Other';
  }

  assessComplexity(source) {
    if (!source) return 'Unknown';
    
    const lines = source.split('\n').length;
    const hasLoops = source.includes('LOOP') || source.includes('FOR');
    const hasConditionals = source.includes('IF') || source.includes('CASE');
    const hasSubqueries = source.includes('SELECT') && source.includes('FROM');
    
    if (lines > 50 || (hasLoops && hasConditionals && hasSubqueries)) {
      return 'High';
    } else if (lines > 20 || (hasConditionals && hasSubqueries)) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  assessRedundancy(name, source) {
    const nameLower = name.toLowerCase();
    
    // Check for obvious redundancies
    if (nameLower.includes('prep') || nameLower.includes('build') || 
        nameLower.includes('capacity') || nameLower.includes('finish')) {
      return 'HIGH - Phase management functions that may be consolidated';
    }
    
    // Check for similar naming patterns
    if (nameLower.includes('assign') && nameLower.includes('movement')) {
      return 'MEDIUM - May overlap with other assignment functions';
    }
    
    if (nameLower.includes('sync') && nameLower.includes('movement')) {
      return 'MEDIUM - May overlap with other sync functions';
    }
    
    if (nameLower.includes('validate') || nameLower.includes('ensure')) {
      return 'LOW - Validation functions are typically necessary';
    }
    
    return 'LOW - Appears to serve unique purpose';
  }

  groupAndAnalyzeFunctions(analysis) {
    console.log('📊 Function Analysis Results:\n');
    
    // Group by purpose
    const grouped = {};
    analysis.forEach(func => {
      if (!grouped[func.purpose]) {
        grouped[func.purpose] = [];
      }
      grouped[func.purpose].push(func);
    });

    // Display analysis by group
    Object.entries(grouped).forEach(([purpose, funcs]) => {
      console.log(`\n${purpose}:`);
      console.log('─'.repeat(purpose.length + 1));
      
      funcs.forEach(func => {
        const redundancyIcon = func.potentialRedundancy.includes('HIGH') ? '🔴' : 
                              func.potentialRedundancy.includes('MEDIUM') ? '🟡' : '🟢';
        
        console.log(`${redundancyIcon} ${func.name}`);
        console.log(`   Purpose: ${func.purpose}`);
        console.log(`   Complexity: ${func.complexity}`);
        console.log(`   Redundancy: ${func.potentialRedundancy}`);
        console.log(`   Args: ${func.arguments || 'None'}`);
        console.log(`   Returns: ${func.return_type || 'void'}`);
        console.log(`   Source Length: ${func.source_length} chars`);
        console.log('');
      });
    });

    // Identify specific candidates for removal
    this.identifyRemovalCandidates(analysis);
  }

  identifyRemovalCandidates(analysis) {
    console.log('\n🗑️  Functions Recommended for Removal:\n');
    
    const candidates = analysis.filter(f => 
      f.potentialRedundancy.includes('HIGH') || 
      f.potentialRedundancy.includes('MEDIUM')
    );

    if (candidates.length === 0) {
      console.log('✅ No obvious candidates for removal found.');
      return;
    }

    candidates.forEach(func => {
      console.log(`🔴 ${func.name}`);
      console.log(`   Reason: ${func.potentialRedundancy}`);
      console.log(`   Purpose: ${func.purpose}`);
      console.log(`   Complexity: ${func.complexity}`);
      console.log('');
    });

    // Provide consolidation recommendations
    this.provideConsolidationRecommendations(candidates);
  }

  provideConsolidationRecommendations(candidates) {
    console.log('\n💡 Consolidation Recommendations:\n');
    
    // Phase management consolidation
    const phaseFunctions = candidates.filter(f => 
      f.purpose.includes('Phase Management')
    );
    
    if (phaseFunctions.length > 0) {
      console.log('🔄 Phase Management Functions:');
      console.log('   Consider consolidating these into a single function:');
      phaseFunctions.forEach(f => console.log(`   - ${f.name}`));
      console.log('   Suggested replacement: create_phase_workout(phase_type, profile_id, assessment_results)');
      console.log('');
    }

    // Assignment consolidation
    const assignmentFunctions = candidates.filter(f => 
      f.purpose.includes('Assignment')
    );
    
    if (assignmentFunctions.length > 0) {
      console.log('🔄 Assignment Functions:');
      console.log('   Consider consolidating these into a single function:');
      assignmentFunctions.forEach(f => console.log(`   - ${f.name}`));
      console.log('   Suggested replacement: assign_movements_to_workout(workout_id, movement_criteria)');
      console.log('');
    }

    // Sync consolidation
    const syncFunctions = candidates.filter(f => 
      f.purpose.includes('Synchronization')
    );
    
    if (syncFunctions.length > 0) {
      console.log('🔄 Synchronization Functions:');
      console.log('   Consider consolidating these into a single function:');
      syncFunctions.forEach(f => console.log(`   - ${f.name}`));
      console.log('   Suggested replacement: sync_movement_library()');
      console.log('');
    }
  }

  async checkFunctionDependencies() {
    try {
      console.log('\n🔗 Checking Function Dependencies...\n');
      
      // Check if any functions are referenced in triggers or other functions
      const dependencyQuery = `
        SELECT DISTINCT
          p.proname as function_name,
          COUNT(t.tgname) as trigger_references,
          COUNT(DISTINCT f.proname) as function_references
        FROM pg_proc p
        LEFT JOIN pg_trigger t ON t.tgfoid = p.oid
        LEFT JOIN pg_proc f ON f.prosrc LIKE '%' || p.proname || '%'
        WHERE p.pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        AND p.prolang = 12
        GROUP BY p.proname, p.oid
        ORDER BY function_name;
      `;

      const dependencies = await this.client.query(dependencyQuery);
      
      console.log('Function Dependencies:');
      console.log('─'.repeat(50));
      
      dependencies.rows.forEach(row => {
        const icon = row.trigger_references > 0 || row.function_references > 0 ? '🔗' : '🔓';
        console.log(`${icon} ${row.function_name}`);
        console.log(`   Trigger references: ${row.trigger_references}`);
        console.log(`   Function references: ${row.function_references}`);
        console.log('');
      });

    } catch (error) {
      console.error('❌ Error checking dependencies:', error.message);
    }
  }

  async explore() {
    try {
      await this.analyzeFunctionUsage();
      await this.checkFunctionDependencies();
    } catch (error) {
      console.error('❌ Error during exploration:', error.message);
    }
  }
}

async function main() {
  const analyzer = new FunctionUsageAnalyzer();
  
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
