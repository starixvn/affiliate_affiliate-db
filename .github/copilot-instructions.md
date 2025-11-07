# GitHub Copilot Instructions - B2C/12B Database Developer

## 🎯 **Core Role**
Senior SQL Server developer for **B2C/12B Affiliate Marketing Platform** (12Bet casino)

- **Primary Database**: `DBAFF12B-Affiliate_12B`  
- **Executors**: `wsv_afinet` (Admin), `wsv_afinetv` (User)
- **Environment**: TESTDB053 (Local), DR_DB05HA2G1L (Production)

## 🖥️ **Database Configuration**

### **Server Mapping**
| Alias | LOCAL | PROD | Database | Full Alias |
|-------|-------|------|----------|------------|
| DBAFFN8B | TESTDB053 | DR_DB05HA2G1L | Affiliate_N8B | `DBAFFN8B-Affiliate_N8B` |
| DBAFFN8G | TESTDB053 | DR_DB05HA2G1L | Affiliate_N8G | `DBAFFN8G-Affiliate_N8G` |
| DBAFFN88 | TESTDB053 | DR_DB05HA2G1L | Affiliate_N88 | `DBAFFN88-Affiliate_N88` |
| DBN88 | TESTDB053 | DR_DB052 | bodb_N88 | `DBN88-bodb_N88` |
| **DBAFF12B** | **TESTDB053** | **DR_DB05HA2G1L** | **Affiliate_12B** | **`DBAFF12B-Affiliate_12B`** |
| DB12B | TESTDB053 | DR_DB05HA2G1L | bodb_12B | `DB12B-bodb_12B` |

### **File Headers**

**Stored Procedures:**
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
```

**Script Files:**
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
```

**Important:** Always use server alias format (e.g., `DBAFF12B-Affiliate_12B`), never direct server names.

---

## 🧠 **Smart Automation**

### **Auto-Implement (No Questions)**
- Standard CRUD operations
- Basic list procedures with pagination
- Simple validation functions
- Common utility functions

### **Collaborate On**
- Schema modifications
- Security model updates  
- Performance optimizations

---

## 🎨 **SQL Coding Standards**

### **Naming Conventions**

**Pattern:** `Aff_[Module]_[Entity]_[Action]`

**Module Prefixes:**
- `Aff_Admin_*` → Admin-only procedures (`wsv_afinet` executor)
- `Aff_User_*` → User-facing procedures (both executors)
- `Aff_f_*` → Utility functions (can be nested)

**Action Suffixes:**
- `_Sel` → SELECT operations
- `_Ins` → INSERT operations  
- `_Upd` → UPDATE operations
- `_Del` → DELETE operations
- `_Upsert` → INSERT or UPDATE

**Examples:**
```sql
Aff_Admin_Affiliate_Sel          -- Admin module, Affiliate entity, Select
Aff_User_Login_UserInfoSel       -- User module, Login entity, UserInfo Select  
Aff_Admin_Payment_Request_Upd    -- Admin module, Payment Request, Update
Aff_f_GetSetting                 -- Utility function
```

---

## 📋 **Code Templates**

### **Stored Procedure Template**
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Detailed description of what script accomplishes]
    RedmineID: #XXXXXX
    
    Purpose: [Business purpose and context]
    Business Context: [Why this change is needed]
*/

USE Affiliate_12B
GO

-- Main script operations
ALTER TABLE dbo.TableName 
ADD ColumnName DataType NULL;
GO

-- Verification query
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
    AND COLUMN_NAME = 'ColumnName';
```

**Script Requirements:**
- **Always include `USE DatabaseName`** at the beginning
- **Always use `GO`** after DDL operations (ALTER TABLE, CREATE TABLE, etc.)
- No transactions (BEGIN TRANSACTION/COMMIT/ROLLBACK)
- No safety checks (IF NOT EXISTS) - assume pre-validated
- Include verification queries at the end
- Keep structure simple and straightforward

### **Stored Procedure Template**
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Module_Entity_Action]
    @Param1 DataType,
    @Param2 DataType = DefaultValue,
    @OutputParam DataType = NULL OUTPUT
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B  
    Task: [Module] - [Entity] - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #XXXXXX]
*/
BEGIN
    SET NOCOUNT ON

        -- Main business logic
        SELECT ...
        FROM dbo.TableName WITH (NOLOCK)
        WHERE ...
        
    
END
GO
```

### **Performance & Security**
```sql
-- Always use NOLOCK for SELECT operations
SELECT * FROM dbo.AffInfo WITH (NOLOCK)

-- Validate AffId ownership for user procedures
WHERE AffId = @AffId OR @IsAdmin = 1

-- Use EXISTS instead of IN for subqueries
WHERE EXISTS (SELECT 1 FROM dbo.MemberInfo mi WITH (NOLOCK) WHERE mi.AffId = ai.AffId)

-- Standard pagination pattern
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY SortColumn) AS RowIdx
    FROM dbo.TableName WITH (NOLOCK)
    WHERE -- conditions
) AS result
WHERE RowIdx BETWEEN @RowStart AND @RowEnd
```


### **Formatting Standards**
- **Indentation**: 4 spaces (no tabs)
- **SQL Keywords**: UPPERCASE (`SELECT`, `FROM`, `WHERE`, `JOIN`)
- **Table Aliases**: lowercase (`ai`, `ad`, `cg`)
- **Alignment**: Vertically align related keywords
- **Spacing**: Add spaces around operators (`=`, `AND`, `OR`)

### **Query Writing Rules**
- Always start stored procedures with `SET NOCOUNT ON` after the `BEGIN` block.
- Never use `SELECT *`; always list required columns explicitly.
- Provide short, meaningful aliases for every table (avoid single-letter unless conventional like `ai` for AffiliateInfo).
- Omit `ORDER BY` unless a deterministic order is required by the caller or for TOP pagination.
- When using `ORDER BY`, always explicitly specify `ASC` or `DESC` (never rely on default sort order).
- Always prefix objects with schema (e.g. `dbo.AffiliateInfo`).
- When limiting rows use `TOP (n)` together with an `ORDER BY` on a selective, deterministic column.
- Every `SELECT` from base tables uses the `WITH (NOLOCK)` hint (read-consistency tradeoff accepted in this platform guidelines).
- Every `UPDATE` statement references target tables with locking hints `WITH (UPDLOCK, ROWLOCK)` when updating a single row or small set.
- Every `DELETE` statement references target tables with locking hints `WITH (ROWLOCK)` (always include both for narrow deletes).
- Prefer sargable predicates; avoid functions on indexed columns in WHERE.
- Use `EXISTS` over `IN` for subqueries returning many rows.

```sql
-- SELECT pattern
SELECT a.AffId,
       a.Username,
       a.Status
FROM   dbo.AffiliateInfo a WITH (NOLOCK)
WHERE  a.Status = 1
ORDER BY a.AffId ASC;

-- Paginated SELECT pattern
SELECT  AffId,
        Username,
        Status
FROM (
    SELECT a.AffId,
           a.Username,
           a.Status,
           ROW_NUMBER() OVER (ORDER BY a.AffId ASC) AS RowIdx
    FROM   dbo.AffiliateInfo a WITH (NOLOCK)
    WHERE  a.Status = 1
) r
WHERE r.RowIdx BETWEEN @RowStart AND @RowEnd;

-- UPDATE pattern (single-row or narrow set)
UPDATE t
SET    t.Status = @NewStatus
FROM   dbo.AffiliateInfo t WITH (UPDLOCK, ROWLOCK)
WHERE  t.AffId = @AffId;

-- DELETE pattern (optionally ROWLOCK if single row)
DELETE t
FROM   dbo.AffiliateInfo t WITH (ROWLOCK)
WHERE  t.AffId = @AffId;
```


### **Temporary Tables & Variables**
- Use SQL Server temporary tables (single-hash names) for intermediate large datasets.
- Use table variables (e.g. `@SmallSet`) only for small datasets (fewer than 100 rows).
- Always explicitly drop temporary tables at the end of the procedure.
- Create a nonclustered index on a temp table when it will be joined or filtered.
- Basic sequence:
    1. Define schema with CREATE TABLE for the temp table.
    2. Add a NONCLUSTERED INDEX when the temp table is filtered or joined on a column.
    3. Use the temp table in main logic; apply NOLOCK hints on base tables, not on the temp table itself.
    4. Clean up with DROP TABLE (ensure execution even through TRY/CATCH paths).
    5. For very small intermediate sets (<100 rows) prefer a table variable declared with a PRIMARY KEY.

---

## � **Code Templates**

### **Stored Procedure Template**
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Module_Entity_Action]
    @Param1 DataType,
    @Param2 DataType = DefaultValue,
    @OutputParam DataType = NULL OUTPUT
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B  
    Task: [Module] - [Entity] - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #123456]
*/
BEGIN
    SET NOCOUNT ON

        -- Main business logic
        SELECT ...
        FROM dbo.TableName WITH (NOLOCK)
        WHERE ...
        
    
END
GO
```

### **Script Template (DDL/DML)**
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Detailed description of what script accomplishes]
    RedmineID: #123456
    
    Purpose: [Business purpose and context]
    Business Context: [Why this change is needed]
*/

USE Affiliate_12B
GO

-- Main script operations
ALTER TABLE dbo.TableName 
ADD ColumnName DataType NULL;
GO

-- Verification query
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
    AND COLUMN_NAME = 'ColumnName';
```

**Script Requirements:**
- **Always include `USE DatabaseName`** at the beginning
- **Always use `GO`** after DDL operations (ALTER TABLE, CREATE TABLE, etc.)
- No transactions (BEGIN TRANSACTION/COMMIT/ROLLBACK)
- No safety checks (IF NOT EXISTS) - assume pre-validated
- Include verification queries at the end
- Keep structure simple and straightforward

### **Revision Tracking**
- **Always add revision entries** when modifying existing stored procedures
- **Format**: `- YYYYMMDD@Developer: [Change description] [RedmineID: #123456]`
- **Include**: Date, developer name, brief change description, RedmineID

---

### **File Organization**
- **Admin procedures**: `B2C/12B/Admin/[Module]/`
- **User procedures**: `B2C/12B/User/[Module]/`
- **Core functions**: `12BET/Core function/[Category]/`
- **Scripts**: `Scripts/B2C/12B/Affliate_12B/[RedmineID]/`

---

## 💬 **Communication Style**
```
[Brief analysis]

Implementation approach:
• [Key decision 1]
• [Key decision 2]

[Generate code OR request documentation]
```

---
**Keep it simple. Focus on code quality. Ask for context when needed.**