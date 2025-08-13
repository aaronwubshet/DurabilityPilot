import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
dotenv.config();

// Configuration object mirroring iOS app structure
export const Config = {
  // Supabase Configuration
  supabaseURL: process.env.SUPABASE_URL || 'https://atvnjpwmydhqbxjgczti.supabase.co',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NTUxMTAsImV4cCI6MjA3MDAzMTExMH0.9EAsCCf9kC5GreyOXJv0b0K4zH08jT14jaG-omzf2ww',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  
  // Edge Function Configuration
  edgeFunctionURL: process.env.EDGE_FUNCTION_URL || 'https://atvnjpwmydhqbxjgczti.supabase.co/functions/v1',
  
  // CLI Configuration
  logLevel: process.env.LOG_LEVEL || 'info',
  batchSize: parseInt(process.env.BATCH_SIZE) || 50,
  retryAttempts: parseInt(process.env.RETRY_ATTEMPTS) || 3,
  
  // Storage Configuration (matching iOS app)
  assessmentVideosBucket: 'assessment-videos',
  trainingPlanImagesBucket: 'training-plan-images',
  
  // App Version
  appVersion: '1.0.0'
};

// Create Supabase client instances
export const supabaseClient = createClient(Config.supabaseURL, Config.supabaseAnonKey);

export const supabaseServiceClient = Config.supabaseServiceRoleKey 
  ? createClient(Config.supabaseURL, Config.supabaseServiceRoleKey)
  : null;

// Validation
export function validateConfig() {
  const errors = [];
  
  if (!Config.supabaseURL) {
    errors.push('SUPABASE_URL is required');
  }
  
  if (!Config.supabaseAnonKey) {
    errors.push('SUPABASE_ANON_KEY is required');
  }
  
  if (!Config.supabaseServiceRoleKey) {
    console.warn('⚠️  SUPABASE_SERVICE_ROLE_KEY not provided - some operations may be limited');
  }
  
  if (errors.length > 0) {
    throw new Error(`Configuration errors: ${errors.join(', ')}`);
  }
  
  return true;
}

// Logger utility
export const logger = {
  info: (message) => {
    if (['info', 'debug'].includes(Config.logLevel)) {
      console.log(`ℹ️  ${message}`);
    }
  },
  warn: (message) => {
    if (['warn', 'info', 'debug'].includes(Config.logLevel)) {
      console.warn(`⚠️  ${message}`);
    }
  },
  error: (message) => {
    console.error(`❌ ${message}`);
  },
  debug: (message) => {
    if (Config.logLevel === 'debug') {
      console.debug(`🔍 ${message}`);
    }
  }
};

