import { EdgeFunctionClient, withRetry, processBatch } from './edge-function-client.js';
import { supabaseClient, logger } from './config.js';

/**
 * Service for computing and managing plan scores using atomic movements
 */
export class PlanScoringService {
  constructor() {
    this.edgeClient = new EdgeFunctionClient();
  }

  /**
   * Compute scores for a single training plan
   */
  async computePlanScores(planId, userId) {
    logger.info(`Computing scores for plan ${planId}`);
    
    try {
      // Fetch plan data from database
      const planData = await this.fetchPlanData(planId, userId);
      
      // Compute scores using edge function
      const scores = await withRetry(async () => {
        return await this.edgeClient.computePlanScores({
          planId,
          userId,
          movements: planData.movements,
          userProfile: planData.userProfile,
          assessmentResults: planData.assessmentResults
        });
      });
      
      // Store computed scores
      await this.storePlanScores(planId, scores);
      
      logger.info(`✅ Successfully computed scores for plan ${planId}`);
      return scores;
      
    } catch (error) {
      logger.error(`Failed to compute scores for plan ${planId}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Compute scores for multiple plans in batch
   */
  async computePlanScoresBatch(planIds, userId) {
    logger.info(`Computing scores for ${planIds.length} plans`);
    
    try {
      // Fetch all plan data
      const plansData = await Promise.all(
        planIds.map(planId => this.fetchPlanData(planId, userId))
      );
      
      // Process in batches
      const results = await processBatch(plansData, 10, async (batch) => {
        return await withRetry(async () => {
          return await this.edgeClient.computePlanScoresBatch({
            plans: batch
          });
        });
      });
      
      // Store all computed scores
      await Promise.all(
        results.map(result => this.storePlanScores(result.planId, result.scores))
      );
      
      logger.info(`✅ Successfully computed scores for ${planIds.length} plans`);
      return results;
      
    } catch (error) {
      logger.error(`Failed to compute batch scores: ${error.message}`);
      throw error;
    }
  }

  /**
   * Fetch plan data from database
   */
  async fetchPlanData(planId, userId) {
    logger.debug(`Fetching plan data for plan ${planId}`);
    
    try {
      // Fetch plan details
      const { data: plan, error: planError } = await supabaseClient
        .from('plans')
        .select('*')
        .eq('id', planId)
        .eq('user_id', userId)
        .single();
      
      if (planError) throw planError;
      
      // Fetch plan movements
      const { data: movements, error: movementsError } = await supabaseClient
        .from('plan_movements')
        .select('*')
        .eq('plan_id', planId);
      
      if (movementsError) throw movementsError;
      
      // Fetch user profile
      const { data: userProfile, error: profileError } = await supabaseClient
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
      
      if (profileError) throw profileError;
      
      // Fetch latest assessment results
      const { data: assessmentResults, error: assessmentError } = await supabaseClient
        .from('assessment_results')
        .select('*')
        .eq('profile_id', userId)
        .order('created_at', { ascending: false })
        .limit(10);
      
      if (assessmentError) throw assessmentError;
      
      return {
        plan,
        movements,
        userProfile,
        assessmentResults
      };
      
    } catch (error) {
      logger.error(`Failed to fetch plan data: ${error.message}`);
      throw error;
    }
  }

  /**
   * Store computed plan scores in database
   */
  async storePlanScores(planId, scores) {
    logger.debug(`Storing scores for plan ${planId}`);
    
    try {
      const { error } = await supabaseClient
        .from('plan_scores')
        .upsert({
          plan_id: planId,
          functional_strength_score: scores.functionalStrength,
          range_of_motion_score: scores.rangeOfMotion,
          flexibility_score: scores.flexibility,
          mobility_score: scores.mobility,
          aerobic_capacity_score: scores.aerobicCapacity,
          recovery_impact_score: scores.recoveryImpact,
          resilience_impact_score: scores.resilienceImpact,
          results_impact_score: scores.resultsImpact,
          computed_at: new Date().toISOString()
        });
      
      if (error) throw error;
      
      logger.debug(`✅ Stored scores for plan ${planId}`);
      
    } catch (error) {
      logger.error(`Failed to store plan scores: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get plan scoring analytics
   */
  async getPlanScoringAnalytics(filters = {}) {
    logger.info('Fetching plan scoring analytics');
    
    try {
      const analytics = await withRetry(async () => {
        return await this.edgeClient.getPlanScoringAnalytics(filters);
      });
      
      return analytics;
      
    } catch (error) {
      logger.error(`Failed to get analytics: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get atomic movement library data
   */
  async getAtomicMovements() {
    logger.debug('Fetching atomic movement library');
    
    try {
      const { data: movements, error } = await supabaseClient
        .from('atomic_movements')
        .select('*')
        .order('name');
      
      if (error) throw error;
      
      return movements;
      
    } catch (error) {
      logger.error(`Failed to fetch atomic movements: ${error.message}`);
      throw error;
    }
  }

  /**
   * Update atomic movement library
   */
  async updateAtomicMovement(movementId, movementData) {
    logger.info(`Updating atomic movement ${movementId}`);
    
    try {
      const { error } = await supabaseClient
        .from('atomic_movements')
        .update(movementData)
        .eq('id', movementId);
      
      if (error) throw error;
      
      logger.info(`✅ Updated atomic movement ${movementId}`);
      
    } catch (error) {
      logger.error(`Failed to update atomic movement: ${error.message}`);
      throw error;
    }
  }

  /**
   * Test the scoring system
   */
  async testScoringSystem() {
    logger.info('Testing plan scoring system');
    
    try {
      // Test edge function connectivity
      await this.edgeClient.testConnection();
      
      // Test database connectivity
      const movements = await this.getAtomicMovements();
      logger.info(`✅ Found ${movements.length} atomic movements`);
      
      return {
        edgeFunctionStatus: 'connected',
        databaseStatus: 'connected',
        movementsCount: movements.length
      };
      
    } catch (error) {
      logger.error(`Scoring system test failed: ${error.message}`);
      throw error;
    }
  }
}

