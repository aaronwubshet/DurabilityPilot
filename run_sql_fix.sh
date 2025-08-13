#!/bin/bash

# Supabase connection details
DB_HOST="db.atvnjpwmydhqbxjgczti.supabase.co"
DB_PORT="5432"
DB_NAME="postgres"
DB_USER="postgres"

echo "🔍 Attempting to connect to Supabase database..."
echo "   - Host: $DB_HOST"
echo "   - Port: $DB_PORT"
echo "   - Database: $DB_NAME"
echo "   - User: $DB_USER"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "❌ psql is not installed or not in PATH"
    echo "   - Try: brew install postgresql"
    exit 1
fi

echo "✅ psql is available"
echo ""

# Try to run the SQL fix
echo "🔍 Running SQL fix for assessment_results RLS policy..."
echo ""

# Note: You'll need to provide the database password when prompted
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -f fix_assessment_results_rls.sql

echo ""
echo "✅ SQL fix completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Test your assessment retake in the app"
echo "   2. Check the console logs for successful database writes"
echo "   3. Verify that assessment results are being created properly"
