-- ==========================================
-- PROJECT ECHO: CORE INFRASTRUCTURE SCHEMA
-- PostgreSQL 17 + PostGIS 3.5
-- ==========================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS postgis;
-- Note: uuid_generate_v7() often requires pg_uuidv7 or a custom function.
-- For local dev, we will use a fallback or ensure the extension is available.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; 

-- 2. Global Enums
CREATE TYPE user_role AS ENUM (
    'STUDENT', 
    'SANITATION_WORKER', 
    'ELECTRICIAN', 
    'SECURITY',
    'ADMIN' -- Added ADMIN back as it was in our previous logic
);

CREATE TYPE report_status AS ENUM (
    'LOGGED', 
    'ACTION_REQUIRED', 
    'DISPATCHED', 
    'RESOLVED'
);

-- 3. Unified Identity Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Fallback to random if v7 isn't loaded
    university_id VARCHAR(50) UNIQUE NOT NULL, 
    pin_hash VARCHAR(255), -- Nullable for OAuth users
    auth_provider VARCHAR(50) NOT NULL DEFAULT 'LOCAL', -- E.g., 'LOCAL', 'GOOGLE'
    provider_id VARCHAR(255), -- E.g., Google Sub ID
    role user_role NOT NULL DEFAULT 'STUDENT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. The "Super App" Telemetry Table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    status report_status NOT NULL DEFAULT 'LOGGED',
    
    -- Geospatial boundary enforcement
    location_geom geometry(Point, 4326) NOT NULL, 
    
    -- Ephemeral blob storage reference
    image_url VARCHAR(512),
    
    -- Modularity engine for custom departmental payloads
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,  
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 5. Read-Only Campus Resources (For QR Routing)
CREATE TABLE campus_resources (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    resource_type VARCHAR(50) NOT NULL, 
    target_url VARCHAR(512) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Enterprise Indexes
CREATE INDEX idx_reports_location ON reports USING GIST (location_geom);
CREATE INDEX idx_reports_metadata ON reports USING GIN (metadata);
CREATE INDEX idx_reports_reporter_id ON reports (reporter_id);
