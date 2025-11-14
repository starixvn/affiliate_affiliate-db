# SQL Server Environment Reference

**Purpose**: Centralized environment configuration - server aliases, executors, and database mappings.

---

## 🖥️ Server Aliases

| Alias | Database | Test Environment | Production Environment |
|-------|----------|------------------|------------------------|
| **DBAFF12B** | Affiliate_12B | TESTDB053 | DR_DB05HA2G1L |
| **DBAFFN8B** | Affiliate_N8B | TESTDB053 | DR_DB05HA2G1L |
| **DBAFFYASHBET** | Affiliate_YashBet | TESTDB053 | DR_DB05HA2G1L |
| **DB12B** | bodb_12B | TESTDB053 | DR_DB05HA2G1L |
| **DBN8B** | bodb_N8B | TESTDB053 | DR_DB05HA2G1L |
| **DBYASHBET** | bodb_YashBet | TESTDB053 | DR_DB05HA2G1L |

**Format Convention**: `<ALIAS>-<DatabaseName>`

**Examples**:
- `DBAFF12B-Affiliate_12B`
- `DBAFFN8B-Affiliate_N8B`
- `DB12B-bodb_12B`

---

## 👤 Executor Accounts

### By Layer

| Layer | Executors | Usage |
|-------|-----------|-------|
| **Admin** | `wsv_afinet` | Admin-facing stored procedures |
| **User** | `wsv_afinet,wsv_afinetv` | User-facing stored procedures (dual for redundancy) |
| **API** | `wsv_afinet` | External API endpoints |
| **ClickStatistics** | `wsv_afinet` | Click tracking operations |
| **UserControl/Security** | `wsv_afinet` | Security and user control |
| **Task** | `wsv_afinet` | Scheduled SQL jobs |

### Functions

| Type | Attribute | Value |
|------|-----------|-------|
| **Standalone** | `executers` | `wsv_afinet,wsv_afinetv` |
| **Nested** | `executers` | `wsv_afinet,wsv_afinetv`<br>`isNested="1"` |

**Note**: Functions use `executers` (not `selecters`) in metadata.

---

## 🗂️ Database Relationships

### Affiliate Databases (DBAFF*)
- Store affiliate data, commission calculations, CPA lifecycle, reporting
- Main application databases for each brand

### Business Object Databases (DB*)
- Store player data, product info, game types, deposits, tags
- Shared reference data across affiliate platforms
- Cross-database queries common: `bodb_12B.dbo.DepositInfo`, `bodb_12B.dbo.Tag`

### Brand Segregation
Each brand maintains parallel structure:
```
12B/         → DBAFF12B-Affiliate_12B + DB12B-bodb_12B
N88/         → DBAFFN8B-Affiliate_N8B + DBN8B-bodb_N8B
YashBet/     → DBAFFYASHBET-Affiliate_YashBet + DBYASHBET-bodb_YashBet
```

---

## 🔧 Usage in Code

### Stored Procedure
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
```

### Function (Standalone)
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
```

### Function (Nested - called by other SPs/functions)
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
```

### Script (DDL/DML)
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
```

---

**Last Updated**: 2025-11-19  
**Owner**: DBA Team
