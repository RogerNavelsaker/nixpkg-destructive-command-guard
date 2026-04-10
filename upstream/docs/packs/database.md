# Database Packs

This document describes packs in the `database` category.

## Packs in this Category

- [PostgreSQL](#databasepostgresql)
- [MySQL/MariaDB](#databasemysql)
- [MongoDB](#databasemongodb)
- [Redis](#databaseredis)
- [SQLite](#databasesqlite)
- [Supabase](#databasesupabase)

---

## PostgreSQL

**Pack ID:** `database.postgresql`

Protects against destructive PostgreSQL operations like DROP DATABASE, TRUNCATE, and dropdb

### Keywords

Commands containing these keywords are checked against this pack:

- `psql`
- `dropdb`
- `DROP`
- `TRUNCATE`
- `pg_dump`
- `postgres`
- `DELETE`
- `delete`
- `drop`
- `truncate`

### Safe Patterns (Allowed)

These patterns match safe commands that are always allowed:

| Pattern Name | Pattern |
|--------------|----------|
| `pg-dump-no-clean` | `pg_dump\s+(?!.*--clean)(?!.*-c\b)` |
| `psql-dry-run` | `psql\s+.*--dry-run` |
| `select-query` | `(?i)^\s*SELECT\s+` |

### Destructive Patterns (Blocked)

These patterns match potentially destructive commands:

| Pattern Name | Reason | Severity |
|--------------|--------|----------|
| `drop-database` | DROP DATABASE permanently deletes the entire database (even with IF EXISTS). Verify and back up first. | high |
| `drop-table` | DROP TABLE permanently deletes the table (even with IF EXISTS). Verify and back up first. | high |
| `drop-schema` | DROP SCHEMA permanently deletes the schema and all its objects (even with IF EXISTS). | high |
| `truncate-table` | TRUNCATE permanently deletes all rows without logging individual deletions. | high |
| `delete-without-where` | DELETE without WHERE clause deletes ALL rows. Add a WHERE clause or use TRUNCATE intentionally. | high |
| `dropdb-cli` | dropdb permanently deletes the entire database. Verify the database name carefully. | high |
| `pg-dump-clean` | pg_dump --clean drops objects before creating them. This can be destructive on restore. | high |

### Allowlist Guidance

To allowlist a specific rule from this pack, add to your allowlist:

```toml
[[allow]]
rule = "database.postgresql:<pattern-name>"
reason = "Your reason here"
```

To allowlist all rules from this pack (use with caution):

```toml
[[allow]]
rule = "database.postgresql:*"
reason = "Your reason here"
risk_acknowledged = true
```

---

## MySQL/MariaDB

**Pack ID:** `database.mysql`

MySQL/MariaDB guard

### Keywords

Commands containing these keywords are checked against this pack:

- `mysql`
- `DROP`

### Allowlist Guidance

To allowlist a specific rule from this pack, add to your allowlist:

```toml
[[allow]]
rule = "database.mysql:<pattern-name>"
reason = "Your reason here"
```

To allowlist all rules from this pack (use with caution):

```toml
[[allow]]
rule = "database.mysql:*"
reason = "Your reason here"
risk_acknowledged = true
```

---

## MongoDB

**Pack ID:** `database.mongodb`

Protects against destructive MongoDB operations like dropDatabase, dropCollection, and remove without criteria

### Keywords

Commands containing these keywords are checked against this pack:

- `mongo`
- `mongosh`
- `dropDatabase`
- `dropCollection`
- `deleteMany`

### Safe Patterns (Allowed)

These patterns match safe commands that are always allowed:

| Pattern Name | Pattern |
|--------------|----------|
| `mongo-find` | `\.find\s*\(` |
| `mongo-count` | `\.count(?:Documents)?\s*\(` |
| `mongo-aggregate` | `\.aggregate\s*\(` |
| `mongodump-no-drop` | `mongodump\s+(?!.*--drop)` |
| `mongo-explain` | `\.explain\s*\(` |

### Destructive Patterns (Blocked)

These patterns match potentially destructive commands:

| Pattern Name | Reason | Severity |
|--------------|--------|----------|
| `drop-database` | dropDatabase permanently deletes the entire database. | high |
| `drop-collection` | drop/dropCollection permanently deletes the collection. | high |
| `delete-all` | remove({}) or deleteMany({}) deletes ALL documents. Add filter criteria. | high |
| `mongorestore-drop` | mongorestore --drop deletes existing data before restoring. | high |
| `collection-drop` | collection.drop() permanently deletes the collection. | high |

### Allowlist Guidance

To allowlist a specific rule from this pack, add to your allowlist:

```toml
[[allow]]
rule = "database.mongodb:<pattern-name>"
reason = "Your reason here"
```

To allowlist all rules from this pack (use with caution):

```toml
[[allow]]
rule = "database.mongodb:*"
reason = "Your reason here"
risk_acknowledged = true
```

---

## Redis

**Pack ID:** `database.redis`

Protects against destructive Redis operations like FLUSHALL, FLUSHDB, and mass key deletion

### Keywords

Commands containing these keywords are checked against this pack:

- `redis`
- `FLUSHALL`
- `FLUSHDB`
- `DEBUG`

### Safe Patterns (Allowed)

These patterns match safe commands that are always allowed:

| Pattern Name | Pattern |
|--------------|----------|
| `redis-get` | `(?i)\b(?:GET\|MGET)\b` |
| `redis-scan` | `(?i)\bSCAN\b` |
| `redis-info` | `(?i)\bINFO\b` |
| `redis-keys` | `(?i)\bKEYS\b` |
| `redis-dbsize` | `(?i)\bDBSIZE\b` |

### Destructive Patterns (Blocked)

These patterns match potentially destructive commands:

| Pattern Name | Reason | Severity |
|--------------|--------|----------|
| `flushall` | FLUSHALL permanently deletes ALL keys in ALL databases. | high |
| `flushdb` | FLUSHDB permanently deletes ALL keys in the current database. | high |
| `debug-crash` | DEBUG SEGFAULT/CRASH will crash the Redis server. | high |
| `debug-sleep` | DEBUG SLEEP blocks the Redis server and can cause availability issues. | high |
| `shutdown` | SHUTDOWN stops the Redis server. Use carefully. | high |
| `config-dangerous` | CONFIG SET for dir/dbfilename/slaveof can be used for security attacks. | high |

### Allowlist Guidance

To allowlist a specific rule from this pack, add to your allowlist:

```toml
[[allow]]
rule = "database.redis:<pattern-name>"
reason = "Your reason here"
```

To allowlist all rules from this pack (use with caution):

```toml
[[allow]]
rule = "database.redis:*"
reason = "Your reason here"
risk_acknowledged = true
```

---

## SQLite

**Pack ID:** `database.sqlite`

Protects against destructive SQLite operations like DROP TABLE, DELETE without WHERE, and accidental data loss

### Keywords

Commands containing these keywords are checked against this pack:

- `sqlite`
- `sqlite3`
- `DROP`
- `TRUNCATE`
- `DELETE`

### Safe Patterns (Allowed)

These patterns match safe commands that are always allowed:

| Pattern Name | Pattern |
|--------------|----------|
| `select-query` | `(?i)^\s*SELECT\s+` |
| `dot-schema` | `\.schema` |
| `dot-tables` | `\.tables` |
| `dot-dump` | `\.dump` |
| `dot-backup` | `\.backup` |
| `explain` | `(?i)^\s*EXPLAIN\s+` |

### Destructive Patterns (Blocked)

These patterns match potentially destructive commands:

| Pattern Name | Reason | Severity |
|--------------|--------|----------|
| `drop-table` | DROP TABLE permanently deletes the table (even with IF EXISTS). Verify it is intended. | high |
| `delete-without-where` | DELETE without WHERE deletes ALL rows. Add a WHERE clause. | high |
| `vacuum-into` | VACUUM INTO overwrites the target file if it exists. | high |
| `sqlite3-stdin` | Running SQL from file could contain destructive commands. Review the file first. | high |

### Allowlist Guidance

To allowlist a specific rule from this pack, add to your allowlist:

```toml
[[allow]]
rule = "database.sqlite:<pattern-name>"
reason = "Your reason here"
```

To allowlist all rules from this pack (use with caution):

```toml
[[allow]]
rule = "database.sqlite:*"
reason = "Your reason here"
risk_acknowledged = true
```

---

## `database.supabase`

**Pack ID:** `database.supabase`

Protects against destructive Supabase CLI operations including database resets, migration rollbacks, function/secret/storage deletion, project removal, and infrastructure changes

### Keywords

Commands containing these keywords are checked against this pack:

- `supabase`
- `db reset`
- `db push`
- `migration repair`
- `migration down`
- `migration squash`
- `functions delete`
- `secrets unset`
- `storage rm`
- `projects delete`
- `orgs delete`
- `branches delete`
- `domains delete`
- `vanity-subdomains`
- `sso remove`
- `network-restrictions`
- `config push`
- `stop --no-backup`

### Safe Patterns (Allowed)

These patterns match safe commands that are always allowed:

| Pattern Name | Pattern |
|--------------|----------|
| `supabase-db-diff` | `supabase\s+db\s+diff` |
| `supabase-db-lint` | `supabase\s+db\s+lint` |
| `supabase-db-dump` | `supabase\s+db\s+dump` |
| `supabase-db-shell-safe` | `(?i)supabase\s+db\s+shell\s*$` |
| `supabase-inspect-db` | `supabase\s+inspect\s+db` |
| `supabase-status` | `supabase\s+status` |
| `supabase-start` | `supabase\s+start` |
| `supabase-services` | `supabase\s+services` |
| `supabase-gen-types` | `supabase\s+gen\s+types` |
| `supabase-test-db` | `supabase\s+test\s+db` |
| `supabase-migration-list` | `supabase\s+migration\s+list` |
| `supabase-migration-new` | `supabase\s+migration\s+new` |
| `supabase-migration-fetch` | `supabase\s+migration\s+fetch` |
| `supabase-db-push-dry-run` | `supabase\s+db\s+push\b.*--dry-run` |
| `supabase-functions-list` | `supabase\s+functions\s+list` |
| `supabase-functions-serve` | `supabase\s+functions\s+serve` |
| `supabase-functions-download` | `supabase\s+functions\s+download` |
| `supabase-functions-new` | `supabase\s+functions\s+new` |
| `supabase-secrets-list` | `supabase\s+secrets\s+list` |
| `supabase-storage-ls` | `supabase\s+storage\s+ls` |
| `supabase-projects-list` | `supabase\s+projects\s+list` |
| `supabase-orgs-list` | `supabase\s+orgs\s+list` |
| `supabase-branches-list` | `supabase\s+branches\s+list` |
| `supabase-branches-get` | `supabase\s+branches\s+get` |
| `supabase-domains-get` | `supabase\s+domains\s+get` |
| `supabase-domains-reverify` | `supabase\s+domains\s+reverify` |
| `supabase-vanity-subdomains-get` | `supabase\s+vanity-subdomains\s+get` |
| `supabase-vanity-subdomains-check` | `supabase\s+vanity-subdomains\s+check-availability` |
| `supabase-sso-list` | `supabase\s+sso\s+list` |
| `supabase-sso-show` | `supabase\s+sso\s+show` |
| `supabase-sso-info` | `supabase\s+sso\s+info` |
| `supabase-network-restrictions-get` | `supabase\s+network-restrictions\s+get` |
| `supabase-network-bans-get` | `supabase\s+network-bans\s+get` |
| `supabase-ssl-enforcement-get` | `supabase\s+ssl-enforcement\s+get` |
| `supabase-postgres-config-get` | `supabase\s+postgres-config\s+get` |

### Destructive Patterns (Blocked)

These patterns match potentially destructive commands:

| Pattern Name | Reason | Severity |
|--------------|--------|----------|
| `supabase-db-reset` | supabase db reset drops and recreates the entire database. All data will be lost. | critical |
| `supabase-db-push` | supabase db push applies migrations to the remote database. Use --dry-run to preview first. | critical |
| `supabase-db-shell-destructive` | supabase db shell with destructive SQL (DROP/TRUNCATE/DELETE/ALTER). Verify the command carefully. | high |
| `supabase-migration-repair` | supabase migration repair modifies the migration history. This can cause drift between schema and migrations. | critical |
| `supabase-migration-down` | supabase migration down reverts applied migrations. Schema changes and associated data may be lost. | critical |
| `supabase-migration-squash` | supabase migration squash consolidates migrations and omits data manipulation statements (INSERT/UPDATE/DELETE). | high |
| `supabase-functions-delete` | supabase functions delete removes a deployed Edge Function. This causes immediate downtime for that function. | high |
| `supabase-storage-rm` | supabase storage rm deletes objects from storage. With --recursive, entire directories are removed. | high |
| `supabase-secrets-unset` | supabase secrets unset removes secrets from the project. Edge Functions depending on them will break immediately. | high |
| `supabase-projects-delete` | supabase projects delete permanently removes the entire Supabase project and all its data. | critical |
| `supabase-orgs-delete` | supabase orgs delete permanently removes the organization and may affect all projects within it. | high |
| `supabase-branches-delete` | supabase branches delete permanently removes a preview branch and its database. | high |
| `supabase-domains-delete` | supabase domains delete removes the custom domain configuration. Clients using the custom domain will lose access. | high |
| `supabase-vanity-subdomains-delete` | supabase vanity-subdomains delete removes the vanity subdomain. Clients using it will lose access. | high |
| `supabase-network-restrictions-update` | supabase network-restrictions update modifies allowed CIDR ranges. Misconfiguration can lock out all database connections. | high |
| `supabase-sso-remove` | supabase sso remove disconnects an SSO identity provider. All users authenticating via that provider will be locked out. | critical |
| `supabase-config-push` | supabase config push overwrites the remote project configuration with local config.toml settings. | high |
| `supabase-stop-no-backup` | supabase stop --no-backup stops the local stack and permanently deletes all data volumes. | high |

### Allowlist Guidance

To allowlist a specific rule from this pack, add to your allowlist:

```toml
[[allow]]
rule = "database.supabase:<pattern-name>"
reason = "Your reason here"
```

To allowlist all rules from this pack (use with caution):

```toml
[[allow]]
rule = "database.supabase:*"
reason = "Your reason here"
risk_acknowledged = true
```

---

