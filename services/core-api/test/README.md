# Testing Strategy

## Database Requirements

The LedgerService tests require a running PostgreSQL database. Tests use real database transactions and are NOT mocked.

### Running Tests Locally

1. **Start PostgreSQL with Docker Compose:**

```bash
# From repository root
docker compose up -d postgres

# Verify it's running
docker compose ps postgres
```

2. **Apply Database Migrations:**

```bash
cd services/core-api
npx prisma migrate dev
# or
npx prisma db push
```

3. **Run Tests:**

```bash
# Unit tests (including LedgerService)
pnpm test

# Specific test file
pnpm test -- ledger.service.spec.ts

# E2E tests
pnpm test:e2e
```

### Test Database Configuration

Connection string from `.env`:
```
DATABASE_URL="postgresql://yole:yole@localhost:5432/yole_core"
```

This matches the PostgreSQL service in `docker-compose.yml`:
- Host: localhost
- Port: 5432
- User: yole
- Password: yole
- Database: yole_core

### CI/CD Considerations

In CI environments, ensure PostgreSQL is available before running tests:

```yaml
# Example GitHub Actions
services:
  postgres:
    image: postgres:16
    env:
      POSTGRES_USER: yole
      POSTGRES_PASSWORD: yole
      POSTGRES_DB: yole_core
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### Without Docker

If Docker is unavailable, you can use a local PostgreSQL installation:

```bash
# Install PostgreSQL (Ubuntu/Debian)
sudo apt-get install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE USER yole WITH PASSWORD 'yole';
CREATE DATABASE yole_core OWNER yole;
\q

# Update .env if using different connection details
# Then run migrations and tests as above
```

## Test Coverage

### LedgerService Tests

1. **Balanced Transfer Test**: Verifies that posting a journal with balanced debits/credits updates wallet pocket balances correctly
2. **Idempotency Test**: Ensures duplicate idempotency keys return the same journal without double-posting
3. **Insufficient Funds Test**: Validates that transfers are rejected when available funds are insufficient

All tests use real PostgreSQL transactions to ensure production-grade reliability.
