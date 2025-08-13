#!/usr/bin/env node

import pkg from 'pg';
const { Client } = pkg;
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Database connection configuration
const DB_CONFIG = {
  connectionString: 'postgresql://postgres:DNgp0mt3CutQkehw@db.atvnjpwmydhqbxjgczti.supabase.co:5432/postgres',
  ssl: {
    rejectUnauthorized: false
  }
};

class SchemaExtractor {
  constructor() {
    this.client = new Client(DB_CONFIG);
    this.outputDir = path.join(__dirname, '..', 'extracted-schema');
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

  async ensureOutputDir() {
    try {
      await fs.mkdir(this.outputDir, { recursive: true });
    } catch (error) {
      if (error.code !== 'EEXIST') {
        throw error;
      }
    }
  }

  async extractTables() {
    console.log('📋 Extracting table schemas...');
    
    const query = `
      SELECT 
        t.table_name,
        t.table_type,
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale,
        c.ordinal_position,
        pgd.description as column_description
      FROM information_schema.tables t
      LEFT JOIN information_schema.columns c ON t.table_name = c.table_name
      LEFT JOIN pg_catalog.pg_statio_all_tables st ON t.table_name = st.relname
      LEFT JOIN pg_catalog.pg_description pgd ON pgd.objoid = st.relid AND pgd.objsubid = c.ordinal_position
      WHERE t.table_schema = 'public'
        AND t.table_type = 'BASE TABLE'
      ORDER BY t.table_name, c.ordinal_position;
    `;

    const result = await this.client.query(query);
    
    const tables = {};
    result.rows.forEach(row => {
      if (!tables[row.table_name]) {
        tables[row.table_name] = {
          table_name: row.table_name,
          table_type: row.table_type,
          columns: []
        };
      }
      
      if (row.column_name) {
        tables[row.table_name].columns.push({
          column_name: row.column_name,
          data_type: row.data_type,
          is_nullable: row.is_nullable,
          column_default: row.column_default,
          character_maximum_length: row.character_maximum_length,
          numeric_precision: row.numeric_precision,
          numeric_scale: row.numeric_scale,
          ordinal_position: row.ordinal_position,
          description: row.column_description
        });
      }
    });

    return tables;
  }

  async extractIndexes() {
    console.log('🔍 Extracting indexes...');
    
    const query = `
      SELECT 
        t.relname as table_name,
        i.relname as index_name,
        a.attname as column_name,
        ix.indisunique as is_unique,
        ix.indisprimary as is_primary,
        pg_get_indexdef(ix.indexrelid) as index_definition
      FROM pg_class t
      JOIN pg_index ix ON t.oid = ix.indrelid
      JOIN pg_class i ON ix.indexrelid = i.oid
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
      WHERE t.relkind = 'r'
        AND t.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
      ORDER BY t.relname, i.relname, a.attnum;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractForeignKeys() {
    console.log('🔗 Extracting foreign keys...');
    
    const query = `
      SELECT 
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        tc.constraint_name,
        rc.update_rule,
        rc.delete_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      JOIN information_schema.referential_constraints AS rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
      ORDER BY tc.table_name, kcu.column_name;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractRLSPolicies() {
    console.log('🔒 Extracting RLS policies...');
    
    const query = `
      SELECT 
        schemaname,
        tablename,
        policyname,
        permissive,
        roles,
        cmd,
        qual,
        with_check
      FROM pg_policies
      WHERE schemaname = 'public'
      ORDER BY tablename, policyname;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractFunctions() {
    console.log('⚙️ Extracting functions...');
    
    const query = `
      SELECT 
        n.nspname as schema_name,
        p.proname as function_name,
        pg_get_function_arguments(p.oid) as arguments,
        pg_get_function_result(p.oid) as return_type,
        pg_get_functiondef(p.oid) as function_definition,
        p.prosrc as source_code
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
      ORDER BY p.proname;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractTriggers() {
    console.log('⚡ Extracting triggers...');
    
    const query = `
      SELECT 
        t.tgname as trigger_name,
        c.relname as table_name,
        p.proname as function_name,
        t.tgenabled as enabled,
        t.tgtype as trigger_type,
        pg_get_triggerdef(t.oid) as trigger_definition
      FROM pg_trigger t
      JOIN pg_class c ON t.tgrelid = c.oid
      JOIN pg_proc p ON t.tgfoid = p.oid
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE n.nspname = 'public'
        AND NOT t.tgisinternal
      ORDER BY c.relname, t.tgname;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractViews() {
    console.log('👁️ Extracting views...');
    
    const query = `
      SELECT 
        table_name,
        view_definition
      FROM information_schema.views
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractExtensions() {
    console.log('📦 Extracting extensions...');
    
    const query = `
      SELECT 
        extname as extension_name,
        extversion as version
      FROM pg_extension
      ORDER BY extname;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractSequences() {
    console.log('🔢 Extracting sequences...');
    
    const query = `
      SELECT 
        sequence_name,
        data_type,
        start_value,
        minimum_value,
        maximum_value,
        increment,
        cycle_option
      FROM information_schema.sequences
      WHERE sequence_schema = 'public'
      ORDER BY sequence_name;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async extractGrants() {
    console.log('🔑 Extracting grants...');
    
    const query = `
      SELECT 
        grantee,
        table_catalog,
        table_schema,
        table_name,
        privilege_type,
        is_grantable
      FROM information_schema.role_table_grants
      WHERE table_schema = 'public'
      ORDER BY table_name, grantee, privilege_type;
    `;

    const result = await this.client.query(query);
    return result.rows;
  }

  async generateSQLSchema(tables, indexes, foreignKeys, sequences) {
    console.log('📝 Generating SQL schema...');
    
    let sql = '-- Generated Supabase Schema\n';
    sql += '-- Extracted on: ' + new Date().toISOString() + '\n\n';
    
    // Create sequences
    for (const seq of sequences) {
      sql += `CREATE SEQUENCE IF NOT EXISTS ${seq.sequence_name};\n`;
    }
    sql += '\n';
    
    // Create tables
    for (const tableName in tables) {
      const table = tables[tableName];
      sql += `-- Table: ${tableName}\n`;
      sql += `CREATE TABLE IF NOT EXISTS ${tableName} (\n`;
      
      const columns = table.columns.map(col => {
        let def = `  ${col.column_name} ${col.data_type}`;
        if (col.character_maximum_length) {
          def += `(${col.character_maximum_length})`;
        }
        if (col.numeric_precision && col.numeric_scale) {
          def += `(${col.numeric_precision},${col.numeric_scale})`;
        }
        if (col.column_default) {
          def += ` DEFAULT ${col.column_default}`;
        }
        if (col.is_nullable === 'NO') {
          def += ' NOT NULL';
        }
        return def;
      });
      
      sql += columns.join(',\n') + '\n);\n\n';
    }
    
    // Add foreign keys
    for (const fk of foreignKeys) {
      sql += `ALTER TABLE ${fk.table_name} ADD CONSTRAINT ${fk.constraint_name} `;
      sql += `FOREIGN KEY (${fk.column_name}) REFERENCES ${fk.foreign_table_name}(${fk.foreign_column_name}) `;
      sql += `ON UPDATE ${fk.update_rule} ON DELETE ${fk.delete_rule};\n`;
    }
    sql += '\n';
    
    return sql;
  }

  async saveToFiles(data) {
    console.log('💾 Saving extracted data to files...');
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const baseDir = path.join(this.outputDir, `schema-${timestamp}`);
    await fs.mkdir(baseDir, { recursive: true });
    
    // Save individual JSON files
    const files = [
      { name: 'tables.json', data: data.tables },
      { name: 'indexes.json', data: data.indexes },
      { name: 'foreign_keys.json', data: data.foreignKeys },
      { name: 'rls_policies.json', data: data.rlsPolicies },
      { name: 'functions.json', data: data.functions },
      { name: 'triggers.json', data: data.triggers },
      { name: 'views.json', data: data.views },
      { name: 'extensions.json', data: data.extensions },
      { name: 'sequences.json', data: data.sequences },
      { name: 'grants.json', data: data.grants }
    ];
    
    for (const file of files) {
      const filePath = path.join(baseDir, file.name);
      await fs.writeFile(filePath, JSON.stringify(file.data, null, 2));
      console.log(`  ✅ Saved ${file.name}`);
    }
    
    // Save SQL schema
    const sqlPath = path.join(baseDir, 'schema.sql');
    await fs.writeFile(sqlPath, data.sqlSchema);
    console.log(`  ✅ Saved schema.sql`);
    
    // Save summary report
    const summary = {
      extraction_date: new Date().toISOString(),
      database_url: DB_CONFIG.connectionString.replace(/\/\/.*@/, '//***:***@'),
      summary: {
        tables: Object.keys(data.tables).length,
        indexes: data.indexes.length,
        foreign_keys: data.foreignKeys.length,
        rls_policies: data.rlsPolicies.length,
        functions: data.functions.length,
        triggers: data.triggers.length,
        views: data.views.length,
        extensions: data.extensions.length,
        sequences: data.sequences.length,
        grants: data.grants.length
      }
    };
    
    const summaryPath = path.join(baseDir, 'summary.json');
    await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2));
    console.log(`  ✅ Saved summary.json`);
    
    console.log(`\n📁 All files saved to: ${baseDir}`);
    return baseDir;
  }

  async extract() {
    try {
      await this.connect();
      await this.ensureOutputDir();
      
      console.log('🚀 Starting Supabase schema extraction...\n');
      
      const [
        tables,
        indexes,
        foreignKeys,
        rlsPolicies,
        functions,
        triggers,
        views,
        extensions,
        sequences,
        grants
      ] = await Promise.all([
        this.extractTables(),
        this.extractIndexes(),
        this.extractForeignKeys(),
        this.extractRLSPolicies(),
        this.extractFunctions(),
        this.extractTriggers(),
        this.extractViews(),
        this.extractExtensions(),
        this.extractSequences(),
        this.extractGrants()
      ]);
      
      const sqlSchema = await this.generateSQLSchema(tables, indexes, foreignKeys, sequences);
      
      const data = {
        tables,
        indexes,
        foreignKeys,
        rlsPolicies,
        functions,
        triggers,
        views,
        extensions,
        sequences,
        grants,
        sqlSchema
      };
      
      const outputDir = await this.saveToFiles(data);
      
      console.log('\n🎉 Schema extraction completed successfully!');
      console.log(`📊 Summary:`);
      console.log(`  - Tables: ${Object.keys(tables).length}`);
      console.log(`  - RLS Policies: ${rlsPolicies.length}`);
      console.log(`  - Functions: ${functions.length}`);
      console.log(`  - Indexes: ${indexes.length}`);
      console.log(`  - Foreign Keys: ${foreignKeys.length}`);
      console.log(`  - Views: ${views.length}`);
      console.log(`  - Extensions: ${extensions.length}`);
      
      return outputDir;
      
    } catch (error) {
      console.error('❌ Error during schema extraction:', error);
      throw error;
    } finally {
      await this.disconnect();
    }
  }
}

// Main execution
async function main() {
  const extractor = new SchemaExtractor();
  
  try {
    await extractor.extract();
  } catch (error) {
    console.error('❌ Failed to extract schema:', error.message);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
