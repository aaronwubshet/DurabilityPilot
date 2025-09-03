import { createClient } from '@supabase/supabase-js';

// Configuration
const supabaseUrl = 'https://atvnjpwmydhqbxjgczti.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFub24iLCJpYXQiOjE3NTQ0NTUxMTAsImV4cCI6MjA3MDAzMTExMH0.9EAsCCf9kC5GreyOXJv0b0K4zH08jT14jaG-omzf2ww';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkDatabase() {
  try {
    console.log('🔍 Checking database tables...\n');

    // Check user_programs
    console.log('📋 Checking user_programs table...');
    const { data: userPrograms, error: upError } = await supabase
      .from('user_programs')
      .select('*');
    
    if (upError) {
      console.log('❌ Error querying user_programs:', upError);
    } else {
      console.log('✅ user_programs found:', userPrograms?.length || 0);
      if (userPrograms?.length > 0) {
        console.log('Sample:', userPrograms[0]);
      }
    }

    // Check user_workouts
    console.log('\n📋 Checking user_workouts table...');
    const { data: userWorkouts, error: uwError } = await supabase
      .from('user_workouts')
      .select('*');
    
    if (uwError) {
      console.log('❌ Error querying user_workouts:', uwError);
    } else {
      console.log('✅ user_workouts found:', userWorkouts?.length || 0);
      if (userWorkouts?.length > 0) {
        console.log('Sample:', userWorkouts[0]);
      }
    }

    // Check profiles - first try to get all columns
    console.log('\n📋 Checking profiles table...');
    const { data: profiles, error: pError } = await supabase
      .from('profiles')
      .select('*')
      .limit(1);
    
    if (pError) {
      console.log('❌ Error querying profiles:', pError);
    } else {
      console.log('✅ profiles found:', profiles?.length || 0);
      if (profiles?.length > 0) {
        console.log('Sample profile structure:', Object.keys(profiles[0]));
        console.log('Sample profile data:', profiles[0]);
      }
    }

    // Check programs
    console.log('\n📋 Checking programs table...');
    const { data: programs, error: progError } = await supabase
      .from('programs')
      .select('*');
    
    if (progError) {
      console.log('❌ Error querying programs:', progError);
    } else {
      console.log('✅ programs found:', programs?.length || 0);
      if (programs?.length > 0) {
        console.log('Sample:', programs[0]);
      }
    }

    // Check if we can query user_programs with a specific user
    if (profiles?.length > 0) {
      const userId = profiles[0].id;
      console.log(`\n🔍 Testing user_programs query for user: ${userId}`);
      
      const { data: userProg, error: testError } = await supabase
        .from('user_programs')
        .select('*')
        .eq('user_id', userId);
      
      if (testError) {
        console.log('❌ Error testing user_programs query:', testError);
      } else {
        console.log('✅ user_programs query successful, found:', userProg?.length || 0);
      }
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkDatabase();
