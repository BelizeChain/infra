-- BelizeChain PostgreSQL Initialization Script

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Compliance and KYC data
CREATE TABLE IF NOT EXISTS kyc_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id VARCHAR(66) NOT NULL UNIQUE,
    kyc_level SMALLINT NOT NULL DEFAULT 0,
    verification_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE,
    verifier_id VARCHAR(66),
    document_hash VARCHAR(66),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kyc_account ON kyc_verifications(account_id);
CREATE INDEX idx_kyc_level ON kyc_verifications(kyc_level);

-- Transaction monitoring for compliance
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    block_number BIGINT NOT NULL,
    extrinsic_index INT NOT NULL,
    from_address VARCHAR(66) NOT NULL,
    to_address VARCHAR(66),
    amount NUMERIC(36, 12) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tx_from ON transactions(from_address);
CREATE INDEX idx_tx_to ON transactions(to_address);
CREATE INDEX idx_tx_block ON transactions(block_number);
CREATE INDEX idx_tx_timestamp ON transactions(timestamp);

-- Quantum job tracking
CREATE TABLE IF NOT EXISTS quantum_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id VARCHAR(66) NOT NULL UNIQUE,
    submitter VARCHAR(66) NOT NULL,
    backend VARCHAR(50) NOT NULL,
    circuit_hash VARCHAR(66) NOT NULL,
    num_qubits SMALLINT NOT NULL,
    circuit_depth INT NOT NULL,
    num_shots INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    result_hash VARCHAR(66),
    accuracy SMALLINT,
    submitted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quantum_submitter ON quantum_jobs(submitter);
CREATE INDEX idx_quantum_status ON quantum_jobs(status);
CREATE INDEX idx_quantum_backend ON quantum_jobs(backend);

-- Federated learning contributions
CREATE TABLE IF NOT EXISTS fl_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    validator VARCHAR(66) NOT NULL,
    round_number INT NOT NULL,
    model_hash VARCHAR(66) NOT NULL,
    quality_score SMALLINT CHECK (quality_score >= 0 AND quality_score <= 100),
    timeliness_score SMALLINT CHECK (timeliness_score >= 0 AND timeliness_score <= 100),
    honesty_score SMALLINT CHECK (honesty_score >= 0 AND honesty_score <= 100),
    submitted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fl_validator ON fl_contributions(validator);
CREATE INDEX idx_fl_round ON fl_contributions(round_number);

-- Explorer search cache
CREATE TABLE IF NOT EXISTS search_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    search_type VARCHAR(20) NOT NULL,
    search_term VARCHAR(255) NOT NULL,
    result JSONB NOT NULL,
    cached_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_search_type_term ON search_cache(search_type, search_term);
CREATE INDEX idx_search_expires ON search_cache(expires_at);

-- Create update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to kyc_verifications
CREATE TRIGGER update_kyc_verifications_updated_at
    BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO belizechain;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO belizechain;

-- Insert test data for development
INSERT INTO kyc_verifications (account_id, kyc_level, verification_date, expiry_date) VALUES
    ('5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY', 2, NOW(), NOW() + INTERVAL '1 year'),
    ('5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty', 3, NOW(), NOW() + INTERVAL '2 years')
ON CONFLICT (account_id) DO NOTHING;

-- Analyze tables for query optimization
ANALYZE kyc_verifications;
ANALYZE transactions;
ANALYZE quantum_jobs;
ANALYZE fl_contributions;
ANALYZE search_cache;
