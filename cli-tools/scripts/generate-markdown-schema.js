#!/usr/bin/env node

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class MarkdownSchemaGenerator {
  constructor() {
    this.schemaDir = path.join(__dirname, '..', 'extracted-schema');
    this.outputDir = path.join(__dirname, '..', 'extracted-schema');
  }

  async findLatestSchemaDir() {
    const dirs = await fs.readdir(this.schemaDir);
    const schemaDirs = dirs.filter(dir => dir.startsWith('schema-'));
    if (schemaDirs.length === 0) {
      throw new Error('No schema extraction found. Please run extract-schema.js first.');
    }
    // Sort by timestamp and get the latest
    schemaDirs.sort().reverse();
    return path.join(this.schemaDir, schemaDirs[0]);
  }

  async loadJsonFile(filePath) {
    const content = await fs.readFile(filePath, 'utf8');
    return JSON.parse(content);
  }

  formatDataType(column) {
    let type = column.data_type;
    
    if (column.character_maximum_length) {
      type += `(${column.character_maximum_length})`;
    } else if (column.numeric_precision && column.numeric_scale) {
      type += `(${column.numeric_precision},${column.numeric_scale})`;
    }
    
    return type;
  }

  formatColumnConstraints(column) {
    const constraints = [];
    
    if (column.is_nullable === 'NO') {
      constraints.push('NOT NULL');
    }
    
    if (column.column_default) {
      constraints.push(`DEFAULT ${column.column_default}`);
    }
    
    return constraints.join(' ');
  }

    generateTablesSection(tables) {
    let markdown = '# Database Tables\n\n';
    markdown += `This section documents all ${Object.keys(tables).length} tables in the database schema.\n\n`;
    
    const tableNames = Object.keys(tables).sort();
    
    for (const tableName of tableNames) {
      const table = tables[tableName];
      
      markdown += `## Table: \`${tableName}\`\n\n`;
      markdown += `**Table Type:** ${table.table_type}\n\n`;
      markdown += `**Total Columns:** ${table.columns.length}\n\n`;
      
      if (table.columns.length === 0) {
        markdown += '*No columns found in this table*\n\n';
        continue;
      }
      
      markdown += '### Column Details\n\n';
      markdown += '| Column Name | Data Type | Is Nullable | Default Value | Column Description | Ordinal Position |\n';
      markdown += '|-------------|-----------|-------------|---------------|-------------------|------------------|\n';
      
      for (const column of table.columns) {
        const type = this.formatDataType(column);
        const nullable = column.is_nullable === 'YES' ? 'YES' : 'NO';
        const defaultValue = column.column_default || 'NULL';
        const description = column.description || 'No description available';
        const position = column.ordinal_position;
        
        markdown += `| \`${column.column_name}\` | \`${type}\` | ${nullable} | \`${defaultValue}\` | ${description} | ${position} |\n`;
      }
      
      markdown += '\n### Column Type Details\n\n';
      
      for (const column of table.columns) {
        markdown += `#### Column: \`${column.column_name}\`\n\n`;
        markdown += `- **Data Type:** \`${column.data_type}\`\n`;
        markdown += `- **Is Nullable:** ${column.is_nullable === 'YES' ? 'YES' : 'NO'}\n`;
        markdown += `- **Default Value:** ${column.column_default || 'NULL'}\n`;
        markdown += `- **Ordinal Position:** ${column.ordinal_position}\n`;
        
        if (column.character_maximum_length) {
          markdown += `- **Character Maximum Length:** ${column.character_maximum_length}\n`;
        }
        
        if (column.numeric_precision) {
          markdown += `- **Numeric Precision:** ${column.numeric_precision}\n`;
        }
        
        if (column.numeric_scale) {
          markdown += `- **Numeric Scale:** ${column.numeric_scale}\n`;
        }
        
        if (column.description) {
          markdown += `- **Description:** ${column.description}\n`;
        }
        
        markdown += '\n';
      }
      
      markdown += '---\n\n';
    }
    
    return markdown;
  }

    generateForeignKeysSection(foreignKeys) {
    let markdown = '# Foreign Key Relationships\n\n';
    markdown += `This section documents all ${foreignKeys.length} foreign key relationships in the database schema.\n\n`;
    
    if (foreignKeys.length === 0) {
      markdown += '*No foreign key relationships found in the database*\n\n';
      return markdown;
    }
    
    markdown += '## Summary Table\n\n';
    markdown += '| Table Name | Column Name | References Table.Column | On Update Rule | On Delete Rule |\n';
    markdown += '|------------|-------------|------------------------|----------------|----------------|\n';
    
    for (const fk of foreignKeys) {
      markdown += `| \`${fk.table_name}\` | \`${fk.column_name}\` | \`${fk.foreign_table_name}.${fk.foreign_column_name}\` | \`${fk.update_rule}\` | \`${fk.delete_rule}\` |\n`;
    }
    
    markdown += '\n## Detailed Foreign Key Information\n\n';
    
    // Group foreign keys by table
    const fksByTable = {};
    for (const fk of foreignKeys) {
      if (!fksByTable[fk.table_name]) {
        fksByTable[fk.table_name] = [];
      }
      fksByTable[fk.table_name].push(fk);
    }
    
    for (const tableName of Object.keys(fksByTable).sort()) {
      markdown += `### Table: \`${tableName}\`\n\n`;
      markdown += `**Total Foreign Keys:** ${fksByTable[tableName].length}\n\n`;
      
      for (const fk of fksByTable[tableName]) {
        markdown += `#### Foreign Key: \`${fk.constraint_name}\`\n\n`;
        markdown += `- **Source Table:** \`${fk.table_name}\`\n`;
        markdown += `- **Source Column:** \`${fk.column_name}\`\n`;
        markdown += `- **Referenced Table:** \`${fk.foreign_table_name}\`\n`;
        markdown += `- **Referenced Column:** \`${fk.foreign_column_name}\`\n`;
        markdown += `- **Constraint Name:** \`${fk.constraint_name}\`\n`;
        markdown += `- **On Update Rule:** \`${fk.update_rule}\`\n`;
        markdown += `- **On Delete Rule:** \`${fk.delete_rule}\`\n\n`;
        
        // Explain the rules
        markdown += `**Rule Explanation:**\n`;
        if (fk.update_rule === 'NO ACTION') {
          markdown += `- **Update Rule:** NO ACTION - Prevents updates to the referenced column if it would violate the foreign key constraint\n`;
        } else if (fk.update_rule === 'CASCADE') {
          markdown += `- **Update Rule:** CASCADE - Automatically updates the foreign key column when the referenced column is updated\n`;
        } else if (fk.update_rule === 'SET NULL') {
          markdown += `- **Update Rule:** SET NULL - Sets the foreign key column to NULL when the referenced column is updated\n`;
        } else if (fk.update_rule === 'SET DEFAULT') {
          markdown += `- **Update Rule:** SET DEFAULT - Sets the foreign key column to its default value when the referenced column is updated\n`;
        }
        
        if (fk.delete_rule === 'NO ACTION') {
          markdown += `- **Delete Rule:** NO ACTION - Prevents deletion of the referenced row if it would violate the foreign key constraint\n`;
        } else if (fk.delete_rule === 'CASCADE') {
          markdown += `- **Delete Rule:** CASCADE - Automatically deletes the foreign key row when the referenced row is deleted\n`;
        } else if (fk.delete_rule === 'SET NULL') {
          markdown += `- **Delete Rule:** SET NULL - Sets the foreign key column to NULL when the referenced row is deleted\n`;
        } else if (fk.delete_rule === 'SET DEFAULT') {
          markdown += `- **Delete Rule:** SET DEFAULT - Sets the foreign key column to its default value when the referenced row is deleted\n`;
        }
        
        markdown += '\n';
      }
      
      markdown += '---\n\n';
    }
    
    return markdown;
  }

    generateIndexesSection(indexes) {
    let markdown = '# Database Indexes\n\n';
    markdown += `This section documents all ${indexes.length} indexes in the database schema.\n\n`;
    
    if (indexes.length === 0) {
      markdown += '*No indexes found in the database*\n\n';
      return markdown;
    }
    
    // Group indexes by table
    const indexesByTable = {};
    for (const index of indexes) {
      if (!indexesByTable[index.table_name]) {
        indexesByTable[index.table_name] = [];
      }
      indexesByTable[index.table_name].push(index);
    }
    
    // Summary table
    markdown += '## Summary by Table\n\n';
    markdown += '| Table Name | Total Indexes | Primary Keys | Unique Indexes | Regular Indexes |\n';
    markdown += '|------------|---------------|--------------|----------------|-----------------|\n';
    
    for (const tableName of Object.keys(indexesByTable).sort()) {
      const tableIndexes = indexesByTable[tableName];
      const primaryKeys = tableIndexes.filter(idx => idx.is_primary).length;
      const uniqueIndexes = tableIndexes.filter(idx => idx.is_unique && !idx.is_primary).length;
      const regularIndexes = tableIndexes.filter(idx => !idx.is_unique && !idx.is_primary).length;
      
      markdown += `| \`${tableName}\` | ${tableIndexes.length} | ${primaryKeys} | ${uniqueIndexes} | ${regularIndexes} |\n`;
    }
    
    markdown += '\n## Detailed Index Information\n\n';
    
    for (const tableName of Object.keys(indexesByTable).sort()) {
      const tableIndexes = indexesByTable[tableName];
      
      markdown += `### Table: \`${tableName}\`\n\n`;
      markdown += `**Total Indexes:** ${tableIndexes.length}\n\n`;
      
      // Group indexes by name (composite indexes)
      const indexesByName = {};
      for (const index of tableIndexes) {
        if (!indexesByName[index.index_name]) {
          indexesByName[index.index_name] = [];
        }
        indexesByName[index.index_name].push(index);
      }
      
      for (const indexName of Object.keys(indexesByName).sort()) {
        const indexColumns = indexesByName[indexName];
        const firstIndex = indexColumns[0];
        
        markdown += `#### Index: \`${indexName}\`\n\n`;
        
        const type = [];
        if (firstIndex.is_primary) type.push('PRIMARY KEY');
        if (firstIndex.is_unique) type.push('UNIQUE');
        if (type.length === 0) type.push('REGULAR INDEX');
        
        markdown += `- **Index Name:** \`${indexName}\`\n`;
        markdown += `- **Index Type:** ${type.join(', ')}\n`;
        markdown += `- **Index Definition:** \`${firstIndex.index_definition}\`\n`;
        markdown += `- **Columns:** ${indexColumns.map(col => `\`${col.column_name}\``).join(', ')}\n`;
        markdown += `- **Total Columns:** ${indexColumns.length}\n\n`;
        
        if (indexColumns.length > 1) {
          markdown += `**Composite Index Details:**\n`;
          for (let i = 0; i < indexColumns.length; i++) {
            markdown += `- **Column ${i + 1}:** \`${indexColumns[i].column_name}\`\n`;
          }
          markdown += '\n';
        }
      }
      
      markdown += '---\n\n';
    }
    
    return markdown;
  }

  generateRLSPoliciesSection(rlsPolicies) {
    let markdown = '# Row Level Security (RLS) Policies\n\n';
    markdown += `This section documents all ${rlsPolicies.length} Row Level Security policies in the database schema.\n\n`;
    markdown += `Row Level Security (RLS) is a security feature that restricts which rows users can access in database tables. Each policy defines specific conditions that must be met for users to perform operations on table rows.\n\n`;
    
    if (rlsPolicies.length === 0) {
      markdown += '*No RLS policies found in the database*\n\n';
      return markdown;
    }
    
    // Group policies by table
    const policiesByTable = {};
    for (const policy of rlsPolicies) {
      if (!policiesByTable[policy.tablename]) {
        policiesByTable[policy.tablename] = [];
      }
      policiesByTable[policy.tablename].push(policy);
    }
    
    // Summary table
    markdown += '## Summary by Table\n\n';
    markdown += '| Table Name | Total Policies | SELECT Policies | INSERT Policies | UPDATE Policies | DELETE Policies | ALL Policies |\n';
    markdown += '|------------|----------------|-----------------|-----------------|-----------------|-----------------|--------------|\n';
    
    for (const tableName of Object.keys(policiesByTable).sort()) {
      const tablePolicies = policiesByTable[tableName];
      const selectPolicies = tablePolicies.filter(p => p.cmd === 'SELECT').length;
      const insertPolicies = tablePolicies.filter(p => p.cmd === 'INSERT').length;
      const updatePolicies = tablePolicies.filter(p => p.cmd === 'UPDATE').length;
      const deletePolicies = tablePolicies.filter(p => p.cmd === 'DELETE').length;
      const allPolicies = tablePolicies.filter(p => p.cmd === 'ALL').length;
      
      markdown += `| \`${tableName}\` | ${tablePolicies.length} | ${selectPolicies} | ${insertPolicies} | ${updatePolicies} | ${deletePolicies} | ${allPolicies} |\n`;
    }
    
    markdown += '\n## Detailed Policy Information\n\n';
    
    for (const tableName of Object.keys(policiesByTable).sort()) {
      const tablePolicies = policiesByTable[tableName];
      
      markdown += `### Table: \`${tableName}\`\n\n`;
      markdown += `**Total RLS Policies:** ${tablePolicies.length}\n\n`;
      
      for (const policy of tablePolicies) {
        markdown += `#### Policy: \`${policy.policyname}\`\n\n`;
        markdown += `- **Policy Name:** \`${policy.policyname}\`\n`;
        markdown += `- **Schema Name:** \`${policy.schemaname}\`\n`;
        markdown += `- **Table Name:** \`${policy.tablename}\`\n`;
        markdown += `- **Target Roles:** ${policy.roles.replace(/[{}]/g, '')}\n`;
        markdown += `- **Commands:** \`${policy.cmd}\`\n`;
        markdown += `- **Permissive:** ${policy.permissive}\n\n`;
        
        // Explain the command
        markdown += `**Command Explanation:**\n`;
        if (policy.cmd === 'ALL') {
          markdown += `- **ALL:** This policy applies to SELECT, INSERT, UPDATE, and DELETE operations\n`;
        } else if (policy.cmd === 'SELECT') {
          markdown += `- **SELECT:** This policy controls which rows can be read from the table\n`;
        } else if (policy.cmd === 'INSERT') {
          markdown += `- **INSERT:** This policy controls which rows can be inserted into the table\n`;
        } else if (policy.cmd === 'UPDATE') {
          markdown += `- **UPDATE:** This policy controls which rows can be updated in the table\n`;
        } else if (policy.cmd === 'DELETE') {
          markdown += `- **DELETE:** This policy controls which rows can be deleted from the table\n`;
        }
        
        // Explain the roles
        markdown += `**Role Explanation:**\n`;
        const roles = policy.roles.replace(/[{}]/g, '').split(',');
        for (const role of roles) {
          if (role === 'authenticated') {
            markdown += `- **authenticated:** Users who have successfully authenticated with the system\n`;
          } else if (role === 'service_role') {
            markdown += `- **service_role:** Internal service role with elevated privileges\n`;
          } else if (role === 'anon') {
            markdown += `- **anon:** Anonymous users who have not authenticated\n`;
          } else {
            markdown += `- **${role}:** Custom role\n`;
          }
        }
        
        if (policy.qual) {
          markdown += `\n**Using Expression:**\n`;
          markdown += `\`\`\`sql\n${policy.qual}\n\`\`\`\n\n`;
          markdown += `**Expression Explanation:** This condition must be true for the user to access rows during SELECT, UPDATE, or DELETE operations.\n\n`;
        }
        
        if (policy.with_check) {
          markdown += `**With Check Expression:**\n`;
          markdown += `\`\`\`sql\n${policy.with_check}\n\`\`\`\n\n`;
          markdown += `**Expression Explanation:** This condition must be true for the user to insert or update rows.\n\n`;
        }
        
        markdown += '---\n\n';
      }
    }
    
    return markdown;
  }

  generateFunctionsSection(functions) {
    let markdown = '# Database Functions\n\n';
    
    if (functions.length === 0) {
      markdown += '*No functions found*\n\n';
      return markdown;
    }
    
    for (const func of functions) {
      markdown += `## Function: \`${func.function_name}\`\n\n`;
      markdown += `- **Schema:** \`${func.schema_name}\`\n`;
      markdown += `- **Arguments:** \`${func.arguments}\`\n`;
      markdown += `- **Return Type:** \`${func.return_type}\`\n\n`;
      
      if (func.function_definition) {
        markdown += '**Definition:**\n';
        markdown += '```sql\n';
        markdown += func.function_definition;
        markdown += '\n```\n\n';
      }
    }
    
    return markdown;
  }

  generateTriggersSection(triggers) {
    let markdown = '# Database Triggers\n\n';
    
    if (triggers.length === 0) {
      markdown += '*No triggers found*\n\n';
      return markdown;
    }
    
    for (const trigger of triggers) {
      markdown += `## Trigger: \`${trigger.trigger_name}\`\n\n`;
      markdown += `- **Table:** \`${trigger.table_name}\`\n`;
      markdown += `- **Function:** \`${trigger.function_name}\`\n`;
      markdown += `- **Enabled:** ${trigger.enabled === 'O' ? 'Yes' : 'No'}\n`;
      markdown += `- **Type:** \`${trigger.trigger_type}\`\n\n`;
      
      if (trigger.trigger_definition) {
        markdown += '**Definition:**\n';
        markdown += '```sql\n';
        markdown += trigger.trigger_definition;
        markdown += '\n```\n\n';
      }
    }
    
    return markdown;
  }

  generateViewsSection(views) {
    let markdown = '# Database Views\n\n';
    
    if (views.length === 0) {
      markdown += '*No views found*\n\n';
      return markdown;
    }
    
    for (const view of views) {
      markdown += `## View: \`${view.table_name}\`\n\n`;
      
      if (view.view_definition) {
        markdown += '**Definition:**\n';
        markdown += '```sql\n';
        markdown += view.view_definition;
        markdown += '\n```\n\n';
      }
    }
    
    return markdown;
  }

  generateExtensionsSection(extensions) {
    let markdown = '# PostgreSQL Extensions\n\n';
    
    if (extensions.length === 0) {
      markdown += '*No extensions found*\n\n';
      return markdown;
    }
    
    markdown += '| Extension | Version |\n';
    markdown += '|-----------|---------|\n';
    
    for (const ext of extensions) {
      markdown += `| \`${ext.extension_name}\` | \`${ext.version}\` |\n`;
    }
    
    markdown += '\n';
    return markdown;
  }

  generateSequencesSection(sequences) {
    let markdown = '# Database Sequences\n\n';
    
    if (sequences.length === 0) {
      markdown += '*No sequences found*\n\n';
      return markdown;
    }
    
         markdown += '| Sequence Name | Data Type | Start Value | Minimum Value | Maximum Value | Increment | Cycles |\n';
     markdown += '|---------------|-----------|-------------|---------------|---------------|-----------|--------|\n';
    
         for (const seq of sequences) {
       const cycle = seq.cycle_option === 'YES' ? 'YES' : 'NO';
       markdown += `| \`${seq.sequence_name}\` | \`${seq.data_type}\` | \`${seq.start_value}\` | \`${seq.minimum_value}\` | \`${seq.maximum_value}\` | \`${seq.increment}\` | ${cycle} |\n`;
     }
    
    markdown += '\n';
    return markdown;
  }

  generateGrantsSection(grants) {
    let markdown = '# Database Grants\n\n';
    
    if (grants.length === 0) {
      markdown += '*No grants found*\n\n';
      return markdown;
    }
    
    // Group grants by table
    const grantsByTable = {};
    for (const grant of grants) {
      if (!grantsByTable[grant.table_name]) {
        grantsByTable[grant.table_name] = [];
      }
      grantsByTable[grant.table_name].push(grant);
    }
    
    for (const tableName of Object.keys(grantsByTable).sort()) {
      markdown += `## Table: \`${tableName}\`\n\n`;
      
             markdown += '| Grantee Role | Privilege Type | Is Grantable |\n';
       markdown += '|--------------|----------------|--------------|\n';
      
             for (const grant of grantsByTable[tableName]) {
         const grantable = grant.is_grantable === 'YES' ? 'YES' : 'NO';
         markdown += `| \`${grant.grantee}\` | \`${grant.privilege_type}\` | ${grantable} |\n`;
       }
      
      markdown += '\n';
    }
    
    return markdown;
  }

  async generateMarkdown() {
    try {
      const schemaDir = await this.findLatestSchemaDir();
      console.log(`📁 Using schema from: ${schemaDir}`);
      
      // Load all JSON files
      const [
        summary,
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
        this.loadJsonFile(path.join(schemaDir, 'summary.json')),
        this.loadJsonFile(path.join(schemaDir, 'tables.json')),
        this.loadJsonFile(path.join(schemaDir, 'indexes.json')),
        this.loadJsonFile(path.join(schemaDir, 'foreign_keys.json')),
        this.loadJsonFile(path.join(schemaDir, 'rls_policies.json')),
        this.loadJsonFile(path.join(schemaDir, 'functions.json')),
        this.loadJsonFile(path.join(schemaDir, 'triggers.json')),
        this.loadJsonFile(path.join(schemaDir, 'views.json')),
        this.loadJsonFile(path.join(schemaDir, 'extensions.json')),
        this.loadJsonFile(path.join(schemaDir, 'sequences.json')),
        this.loadJsonFile(path.join(schemaDir, 'grants.json'))
      ]);
      
      // Generate markdown content
      let markdown = `# Supabase Database Schema Documentation\n\n`;
      markdown += `**Extracted on:** ${summary.extraction_date}\n\n`;
      markdown += `**Database:** ${summary.database_url}\n\n`;
      
      markdown += `## Summary\n\n`;
      markdown += `| Component | Count |\n`;
      markdown += `|-----------|-------|\n`;
      markdown += `| Tables | ${summary.summary.tables} |\n`;
      markdown += `| Indexes | ${summary.summary.indexes} |\n`;
      markdown += `| Foreign Keys | ${summary.summary.foreign_keys} |\n`;
      markdown += `| RLS Policies | ${summary.summary.rls_policies} |\n`;
      markdown += `| Functions | ${summary.summary.functions} |\n`;
      markdown += `| Triggers | ${summary.summary.triggers} |\n`;
      markdown += `| Views | ${summary.summary.views} |\n`;
      markdown += `| Extensions | ${summary.summary.extensions} |\n`;
      markdown += `| Sequences | ${summary.summary.sequences} |\n`;
      markdown += `| Grants | ${summary.summary.grants} |\n\n`;
      
      markdown += `---\n\n`;
      
      // Add all sections
      markdown += this.generateTablesSection(tables);
      markdown += this.generateForeignKeysSection(foreignKeys);
      markdown += this.generateIndexesSection(indexes);
      markdown += this.generateRLSPoliciesSection(rlsPolicies);
      markdown += this.generateFunctionsSection(functions);
      markdown += this.generateTriggersSection(triggers);
      markdown += this.generateViewsSection(views);
      markdown += this.generateExtensionsSection(extensions);
      markdown += this.generateSequencesSection(sequences);
      markdown += this.generateGrantsSection(grants);
      
      // Save the markdown file
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const outputPath = path.join(this.outputDir, `database-schema-${timestamp}.md`);
      await fs.writeFile(outputPath, markdown);
      
      console.log(`✅ Markdown schema saved to: ${outputPath}`);
      return outputPath;
      
    } catch (error) {
      console.error('❌ Error generating markdown:', error);
      throw error;
    }
  }
}

// Main execution
async function main() {
  const generator = new MarkdownSchemaGenerator();
  
  try {
    await generator.generateMarkdown();
  } catch (error) {
    console.error('❌ Failed to generate markdown schema:', error.message);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
