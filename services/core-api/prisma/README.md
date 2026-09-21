# Prisma Migrations

## Applying Migrations

When the PostgreSQL database is available, apply the migrations using:

```bash
# Start the database (from repo root)
docker compose up -d postgres

# Apply migrations
cd services/core-api
npx prisma db push

# Or manually apply the migration SQL
psql postgresql://yole:yole@localhost:5432/yole_core < prisma/migrations/20260916_init_ledger/migration.sql
```

## Database Connection

The database connection string is configured in `.env`:

```
DATABASE_URL="postgresql://yole:yole@localhost:5432/yole_core"
```

This corresponds to the PostgreSQL service defined in the root `docker-compose.yml`.

## Schema Updates

After modifying `schema.prisma`, create a new migration:

```bash
npx prisma migration plan --name <migration_name>
```

Note: The Prisma version installed uses the newer migration workflow. Consult Prisma documentation for the latest commands.
