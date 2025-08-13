import fetch from 'node-fetch';
import { Config, logger } from './config.js';

/**
 * Client for interacting with Supabase Edge Functions
 */
export class EdgeFunctionClient {
  constructor(apiKey = Config.supabaseAnonKey) {
    this.baseURL = Config.edgeFunctionURL;
    this.apiKey = apiKey;
  }

  /**
   * Make a request to an edge function
   */
  async callFunction(functionName, data = {}, options = {}) {
    const url = `${this.baseURL}/${functionName}`;
    
    const requestOptions = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
        ...options.headers
      },
      body: JSON.stringify(data)
    };

    logger.debug(`Calling edge function: ${functionName}`);
    logger.debug(`Request data: ${JSON.stringify(data, null, 2)}`);

    try {
      const response = await fetch(url, requestOptions);
      const responseText = await response.text();
      
      logger.debug(`Response status: ${response.status}`);
      logger.debug(`Response body: ${responseText}`);

      if (!response.ok) {
        throw new Error(`Edge function error: ${response.status} - ${responseText}`);
      }

      // Try to parse JSON response
      try {
        return JSON.parse(responseText);
      } catch (parseError) {
        // If not JSON, return the text
        return { data: responseText };
      }
    } catch (error) {
      logger.error(`Failed to call edge function ${functionName}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Compute scores for a training plan
   */
  async computePlanScores(planData) {
    return this.callFunction('compute-plan-scores', {
      plan: planData
    });
  }

  /**
   * Compute scores for multiple plans in batch
   */
  async computePlanScoresBatch(plans) {
    return this.callFunction('compute-plan-scores-batch', {
      plans: plans
    });
  }

  /**
   * Get plan scoring analytics
   */
  async getPlanScoringAnalytics(filters = {}) {
    return this.callFunction('plan-scoring-analytics', {
      filters: filters
    });
  }

  /**
   * Test edge function connectivity
   */
  async testConnection() {
    try {
      const result = await this.callFunction('health-check', {});
      logger.info('✅ Edge function connection successful');
      return result;
    } catch (error) {
      logger.error('❌ Edge function connection failed');
      throw error;
    }
  }
}

/**
 * Retry wrapper for edge function calls
 */
export async function withRetry(operation, maxAttempts = Config.retryAttempts) {
  let lastError;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      logger.warn(`Attempt ${attempt}/${maxAttempts} failed: ${error.message}`);
      
      if (attempt < maxAttempts) {
        // Exponential backoff
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 10000);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  
  throw lastError;
}

/**
 * Batch processing utility for large datasets
 */
export async function processBatch(items, batchSize = Config.batchSize, processor) {
  const results = [];
  
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    logger.info(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(items.length / batchSize)}`);
    
    const batchResults = await processor(batch);
    results.push(...batchResults);
    
    // Small delay between batches to avoid overwhelming the API
    if (i + batchSize < items.length) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  
  return results;
}

