import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { Config, supabaseServiceClient, validateConfig, logger } from '../src/config.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function loadJson(filePath) {
  const content = await fs.readFile(filePath, 'utf8');
  return JSON.parse(content);
}

async function upsert(table, rows, conflictTarget = 'id') {
  if (!rows || rows.length === 0) return;
  const { error } = await supabaseServiceClient.from(table).upsert(rows, { onConflict: conflictTarget });
  if (error) throw error;
}

async function main() {
  validateConfig();
  if (!supabaseServiceClient) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is required to load seeds');
  }

  const baseDir = path.resolve(__dirname, '../..', 'schema_update_from_gpt/durability_system_package/seeds');

  logger.info('Loading library seeds...');

  // Load simple tables first
  const patternTypes = await loadJson(path.join(baseDir, 'pattern_types.json')).catch(() => []);
  await upsert('library.pattern_types', patternTypes);

  const patterns = await loadJson(path.join(baseDir, 'patterns.json')).catch(() => []);
  await upsert('library.patterns', patterns);

  const exercises = await loadJson(path.join(baseDir, 'exercises.json')).catch(() => []);
  await upsert('library.exercises', exercises);

  const tags = await loadJson(path.join(baseDir, 'tags.json')).catch(() => []);
  await upsert('library.tags', tags);

  const contexts = await loadJson(path.join(baseDir, 'contexts.json')).catch(() => []);
  await upsert('library.contexts', contexts);

  const metrics = await loadJson(path.join(baseDir, 'metrics.json')).catch(() => []);
  await upsert('library.metrics', metrics);

  const supermetrics = await loadJson(path.join(baseDir, 'supermetrics.json')).catch(() => []);
  await upsert('library.supermetrics', supermetrics);

  const injuries = await loadJson(path.join(baseDir, 'injuries.json')).catch(() => []);
  await upsert('library.injuries', injuries);

  // Junctions (if provided as arrays of { exercise_id, tag_id } etc.)
  const exerciseTags = await loadJson(path.join(baseDir, 'exercise_tags.json')).catch(() => []);
  if (exerciseTags.length) await upsert('library.exercise_tags', exerciseTags, 'exercise_id,tag_id');

  const contraindications = await loadJson(path.join(baseDir, 'exercise_contraindications.json')).catch(() => []);
  if (contraindications.length) await upsert('library.exercise_contraindications', contraindications, 'exercise_id,injury_id');

  const indications = await loadJson(path.join(baseDir, 'exercise_indications.json')).catch(() => []);
  if (indications.length) await upsert('library.exercise_indications', indications, 'exercise_id,injury_id');

  const superImpacts = await loadJson(path.join(baseDir, 'exercise_supermetric_impacts.json')).catch(() => []);
  if (superImpacts.length) await upsert('library.exercise_supermetric_impacts', superImpacts, 'exercise_id,supermetric_id');

  const exerciseSports = await loadJson(path.join(baseDir, 'exercise_sports.json')).catch(() => []);
  if (exerciseSports.length) await upsert('library.exercise_sports', exerciseSports, 'exercise_id,sport_id');

  logger.info('Refreshing movement_library materialized view...');
  const { error: rpcErr } = await supabaseServiceClient.rpc('refresh_movement_library');
  if (rpcErr) throw rpcErr;

  logger.info('Syncing into public.movements (optional)...');
  const { error: syncErr } = await supabaseServiceClient.rpc('sync_movements_from_library');
  if (syncErr) logger.warn(`sync_movements_from_library failed: ${syncErr.message}`);

  logger.info('Seed load complete.');
}

main().catch((err) => {
  logger.error(err.message || String(err));
  process.exit(1);
});


