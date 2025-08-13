#!/usr/bin/env node

import { Command } from 'commander';
import { PlanScoringService } from '../src/plan-scoring-service.js';
import { validateConfig, logger } from '../src/config.js';

const program = new Command();

program
  .name('compute-plan-scores')
  .description('CLI tool for computing training plan scores using Supabase Edge Functions')
  .version('1.0.0');

// Single plan scoring
program
  .command('single')
  .description('Compute scores for a single training plan')
  .requiredOption('-p, --plan-id <id>', 'Plan ID to compute scores for')
  .requiredOption('-u, --user-id <id>', 'User ID')
  .option('-v, --verbose', 'Enable verbose logging')
  .action(async (options) => {
    try {
      validateConfig();
      
      if (options.verbose) {
        process.env.LOG_LEVEL = 'debug';
      }
      
      const scoringService = new PlanScoringService();
      const scores = await scoringService.computePlanScores(options.planId, options.userId);
      
      console.log('\n📊 Plan Scores Computed:');
      console.log(JSON.stringify(scores, null, 2));
      
    } catch (error) {
      logger.error(`Failed to compute plan scores: ${error.message}`);
      process.exit(1);
    }
  });

// Batch plan scoring
program
  .command('batch')
  .description('Compute scores for multiple training plans')
  .requiredOption('-p, --plan-ids <ids>', 'Comma-separated list of plan IDs')
  .requiredOption('-u, --user-id <id>', 'User ID')
  .option('-v, --verbose', 'Enable verbose logging')
  .action(async (options) => {
    try {
      validateConfig();
      
      if (options.verbose) {
        process.env.LOG_LEVEL = 'debug';
      }
      
      const planIds = options.planIds.split(',').map(id => id.trim());
      const scoringService = new PlanScoringService();
      const results = await scoringService.computePlanScoresBatch(planIds, options.userId);
      
      console.log('\n📊 Batch Plan Scores Computed:');
      console.log(`Processed ${results.length} plans`);
      console.log(JSON.stringify(results, null, 2));
      
    } catch (error) {
      logger.error(`Failed to compute batch plan scores: ${error.message}`);
      process.exit(1);
    }
  });

// Test system
program
  .command('test')
  .description('Test the plan scoring system connectivity')
  .option('-v, --verbose', 'Enable verbose logging')
  .action(async (options) => {
    try {
      validateConfig();
      
      if (options.verbose) {
        process.env.LOG_LEVEL = 'debug';
      }
      
      const scoringService = new PlanScoringService();
      const testResults = await scoringService.testScoringSystem();
      
      console.log('\n🧪 System Test Results:');
      console.log(JSON.stringify(testResults, null, 2));
      
    } catch (error) {
      logger.error(`System test failed: ${error.message}`);
      process.exit(1);
    }
  });

// Get analytics
program
  .command('analytics')
  .description('Get plan scoring analytics')
  .option('-f, --filters <json>', 'JSON string of filters to apply')
  .option('-v, --verbose', 'Enable verbose logging')
  .action(async (options) => {
    try {
      validateConfig();
      
      if (options.verbose) {
        process.env.LOG_LEVEL = 'debug';
      }
      
      const filters = options.filters ? JSON.parse(options.filters) : {};
      const scoringService = new PlanScoringService();
      const analytics = await scoringService.getPlanScoringAnalytics(filters);
      
      console.log('\n📈 Plan Scoring Analytics:');
      console.log(JSON.stringify(analytics, null, 2));
      
    } catch (error) {
      logger.error(`Failed to get analytics: ${error.message}`);
      process.exit(1);
    }
  });

// List atomic movements
program
  .command('movements')
  .description('List atomic movements in the library')
  .option('-v, --verbose', 'Enable verbose logging')
  .action(async (options) => {
    try {
      validateConfig();
      
      if (options.verbose) {
        process.env.LOG_LEVEL = 'debug';
      }
      
      const scoringService = new PlanScoringService();
      const movements = await scoringService.getAtomicMovements();
      
      console.log('\n🏃‍♂️ Atomic Movements Library:');
      movements.forEach((movement, index) => {
        console.log(`${index + 1}. ${movement.name}`);
        console.log(`   Joints: ${movement.joints?.join(', ') || 'N/A'}`);
        console.log(`   Muscles: ${movement.muscles?.join(', ') || 'N/A'}`);
        console.log(`   Supermetrics: ${movement.supermetrics?.join(', ') || 'N/A'}`);
        console.log('');
      });
      
    } catch (error) {
      logger.error(`Failed to fetch movements: ${error.message}`);
      process.exit(1);
    }
  });

// Parse command line arguments
program.parse();

