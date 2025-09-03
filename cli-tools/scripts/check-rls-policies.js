import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

class RLSPolicyChecker {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL || 'https://atvnjpwmydhqbxjgczti.supabase.co',
      process.env.SUPABASE_SERVICE_ROLE_KEY || 'DNgp0mt3CutQkehw'
    );
  }

  async checkAllRLSPolicies() {
    console.log('🔒 Checking RLS Policies on All Tables...\n');
    
    try {
      // Get all tables with RLS enabled
      const { data: tables, error: tablesError } = await this.supabase
        .from('information_schema.tables')
        .select('table_name, table_schema')
        .eq('table_schema', 'public')
        .eq('table_type', 'BASE TABLE');

      if (tablesError) {
        console.error('❌ Error fetching tables:', tablesError);
        return;
      }

      console.log(`📊 Found ${tables.length} tables in public schema\n`);

      for (const table of tables) {
        await this.checkTableRLS(table.table_name);
      }

      // Check specific tables that should have RLS
      await this.checkCriticalTablesRLS();
      
    } catch (error) {
      console.error('❌ Error checking RLS policies:', error);
    }
  }

  async checkTableRLS(tableName) {
    try {
      // Check if RLS is enabled
      const { data: rlsStatus, error: rlsError } = await this.supabase
        .rpc('check_rls_enabled', { table_name: tableName });

      if (rlsError) {
        // Try alternative method
        const { data: policies, error: policiesError } = await this.supabase
          .from('pg_policies')
          .select('*')
          .eq('tablename', tableName);

        if (policiesError) {
          console.log(`⚠️  ${tableName}: Could not check RLS status`);
          return;
        }

        if (policies.length === 0) {
          console.log(`❌ ${tableName}: RLS enabled but NO POLICIES found`);
        } else {
          console.log(`✅ ${tableName}: RLS enabled with ${policies.length} policies`);
          await this.showTablePolicies(tableName, policies);
        }
      } else {
        if (rlsStatus) {
          console.log(`✅ ${tableName}: RLS enabled`);
          await this.showTablePolicies(tableName);
        } else {
          console.log(`❌ ${tableName}: RLS NOT enabled`);
        }
      }
    } catch (error) {
      console.log(`⚠️  ${tableName}: Error checking RLS - ${error.message}`);
    }
  }

  async showTablePolicies(tableName, policies = null) {
    try {
      if (!policies) {
        const { data: fetchedPolicies, error: policiesError } = await this.supabase
          .from('pg_policies')
          .select('*')
          .eq('tablename', tableName);

        if (policiesError) {
          console.log(`    └─ Could not fetch policies: ${policiesError.message}`);
          return;
        }
        policies = fetchedPolicies;
      }

      if (policies.length === 0) {
        console.log(`    └─ No policies found`);
        return;
      }

      for (const policy of policies) {
        console.log(`    └─ Policy: ${policy.policyname}`);
        console.log(`       └─ Roles: ${policy.roles.join(', ')}`);
        console.log(`       └─ Command: ${policy.cmd}`);
        console.log(`       └─ Qual: ${policy.qual || 'N/A'}`);
        console.log(`       └─ With Check: ${policy.with_check || 'N/A'}`);
      }
    } catch (error) {
      console.log(`    └─ Error fetching policies: ${error.message}`);
    }
  }

  async checkCriticalTablesRLS() {
    console.log('\n🔍 Checking Critical Tables RLS Status...\n');
    
    const criticalTables = [
      'profiles',
      'assessment_results',
      'assessments',
      'movements',
      'movement_blocks',
      'movement_block_items',
      'programs',
      'user_programs',
      'user_workouts',
      'user_workout_blocks',
      'user_block_items',
      'user_set_logs'
    ];

    for (const tableName of criticalTables) {
      await this.checkTableRLS(tableName);
    }
  }

  async checkUserAccessPatterns() {
    console.log('\n👤 Checking User Access Patterns...\n');
    
    try {
      // Check if authenticated users can access their own data
      const { data: policies, error } = await this.supabase
        .from('pg_policies')
        .select('*')
        .ilike('qual', '%auth.uid%');

      if (error) {
        console.log('⚠️  Could not check user access patterns');
        return;
      }

      console.log(`Found ${policies.length} policies using auth.uid:`);
      for (const policy of policies) {
        console.log(`  └─ ${policy.tablename}.${policy.policyname}: ${policy.qual}`);
      }
    } catch (error) {
      console.log('⚠️  Error checking user access patterns:', error.message);
    }
  }

  async checkRolePermissions() {
    console.log('\n🔑 Checking Role Permissions...\n');
    
    try {
      // Check what roles exist and their permissions
      const { data: roles, error } = await this.supabase
        .rpc('get_role_permissions');

      if (error) {
        console.log('⚠️  Could not check role permissions');
        return;
      }

      console.log('Role permissions:', roles);
    } catch (error) {
      console.log('⚠️  Error checking role permissions:', error.message);
    }
  }

  async generateRLSRecommendations() {
    console.log('\n💡 RLS Policy Recommendations...\n');
    
    const recommendations = [
      '✅ Ensure all user data tables have RLS enabled',
      '✅ Use auth.uid() in policies to restrict access to user\'s own data',
      '✅ Consider using row-level security for sensitive data',
      '✅ Test policies with different user roles',
      '✅ Ensure service role can bypass RLS when needed',
      '✅ Use appropriate policy commands (SELECT, INSERT, UPDATE, DELETE)',
      '✅ Consider using WITH CHECK clauses for INSERT/UPDATE policies'
    ];

    recommendations.forEach(rec => console.log(rec));
  }

  async run() {
    console.log('🚀 Starting RLS Policy Check...\n');
    
    await this.checkAllRLSPolicies();
    await this.checkUserAccessPatterns();
    await this.checkRolePermissions();
    await this.generateRLSRecommendations();
    
    console.log('\n✨ RLS Policy Check Complete!');
  }
}

// Run the checker
async function main() {
  const checker = new RLSPolicyChecker();
  await checker.run();
}

main().catch(console.error);
