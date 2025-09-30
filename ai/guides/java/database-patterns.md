# Database Patterns Guide

A focused guide for database design patterns and best practices for Java applications.

*Extracted from: [Spotify Database Best Practices](https://backstage.spotify.net/docs/default/component/backend/coding/data-storage/)*

## Essential Database Columns

**Always add `created_at` and `updated_at` timestamps** - marked as "very high ROI" practice:

- Use database triggers for automatic `updated_at` maintenance
- Essential for debugging and data lifecycle understanding

**Consider `updated_by`** for audit trails in sensitive data scenarios.

## Primary Keys & Foreign Keys

- **Always use Primary Keys**: Prefer UUID over sequential IDs
- **Never use free-form strings as Foreign Keys**: Use structured IDs instead
- Avoid user-populated fields as foreign keys (performance and error-prone)

## Data Integrity Patterns

**Soft Delete vs Hard Delete**: Use `deleted_at` timestamps for audit trails

```sql
-- All queries need: WHERE deleted_at IS NULL
SELECT * FROM users WHERE deleted_at IS NULL AND active = true;
```

**CHECK Constraints** for enum validation:

```sql
item VARCHAR(50) NOT NULL CHECK (item IN ('ALBUM', 'ARTIST', 'GENRE'))
```

## Performance & Query Patterns

- **Always use WHERE clauses** to avoid table scans: `SELECT * FROM audio_file WHERE audio_file_id = 1;`
- **Use LIMIT for testing** new queries before removing limits
- **Talk Mission soft delete pattern** - always join with `users` table to filter deleted users

## Tools & Migration

- **Use Liquibase** for database migrations and change tracking
- **Use jdbi-extras** with Primary/Replica setup across regions
- **Consider BigQuery exports** for analytics and data science queries

*Reference: [Database Tools](https://backstage.spotify.net/docs/default/component/backend/coding/data-storage/#tools)*

## Schema Change Coding Requirements

**MySQL DDL Safety** - always include `ALGORITHM=INPLACE, LOCK=NONE` parameters

**Character Set Standards** - use `utf8mb4_general_ci` for new tables

**DEFINER Requirements** - set DEFINER to `'anchor-routine'@'localhost'` for views and procedures

## Connection & Library Preferences

**Connection Pooling** - prefer Hikari over dbcp2

**JDBI-extras Library** - use for SQL operations in Java with Primary/Replica setup

**Database Selection** for new projects:
- **Prefer PostgreSQL** over MySQL for new services
- **Use CloudSQL** for relational data (< 30TB, < 1000 queries/s)
- **Consider BigTable** only for massive datasets (> 1TB, > 1000 queries/s)

## Database Review Checklist

When reviewing code that includes database changes:

**Schema Design:**
- [ ] Tables include `created_at` and `updated_at` timestamps
- [ ] Primary keys use UUID or structured IDs (not user-provided strings)
- [ ] Foreign keys reference proper primary keys, not free-form strings
- [ ] Soft delete pattern used where audit trails are needed
- [ ] CHECK constraints used for enum validation

**Query Performance:**
- [ ] All queries include WHERE clauses (no table scans)
- [ ] Queries joining with users table to filter deleted users
- [ ] LIMIT used during query development and testing

**Schema Changes:**
- [ ] DDL statements include `ALGORITHM=INPLACE, LOCK=NONE`
- [ ] Character set specified as `utf8mb4_general_ci` for new tables
- [ ] DEFINER set to `'anchor-routine'@'localhost'` for views/procedures
- [ ] Liquibase migrations present for schema changes

**Connection & Libraries:**
- [ ] Hikari connection pool used (not dbcp2)
- [ ] JDBI-extras library used for database operations
- [ ] PostgreSQL chosen over MySQL for new services (where applicable)