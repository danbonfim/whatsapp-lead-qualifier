#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE evolution;
    CREATE DATABASE n8n;
    CREATE DATABASE supabase;
    
    GRANT ALL PRIVILEGES ON DATABASE evolution TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE supabase TO $POSTGRES_USER;
    
    \c supabase
    
    -- Criar extensões necessárias
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOSQL

echo "Databases criados com sucesso!"
