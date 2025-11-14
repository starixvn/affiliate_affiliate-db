# SQL Script Template

**Usage**: Copy-paste template when creating DDL/DML migration scripts.

**File Placement**: `Scripts/B2C/<Brand>/<RedmineID>/YYYYMMDD_<RedmineID>_<Description>.sql`

**Environment Reference**: See `sql-environment.md` for serverAlias.

---

## DDL Script Template (CREATE/ALTER)

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Detailed description of changes]
    RedmineID: #XXXXXX
*/

USE Affiliate_12B
GO

-- =============================================
-- Step 1: Create new table
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TableName')
BEGIN
    CREATE TABLE [dbo].[TableName]
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Column1 DATATYPE NOT NULL,
        Column2 DATATYPE NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedDate DATETIME NULL
    )
    
    PRINT 'Table [TableName] created successfully'
END
ELSE
BEGIN
    PRINT 'Table [TableName] already exists'
END
GO

-- =============================================
-- Step 2: Add indexes
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TableName_Column1')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TableName_Column1]
    ON [dbo].[TableName] ([Column1])
    INCLUDE ([Column2])
    
    PRINT 'Index [IX_TableName_Column1] created successfully'
END
GO

-- =============================================
-- Step 3: Add foreign keys (if needed)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TableName_RefTable')
BEGIN
    ALTER TABLE [dbo].[TableName]
    ADD CONSTRAINT [FK_TableName_RefTable]
    FOREIGN KEY ([Column1]) REFERENCES [dbo].[RefTable]([Id])
    
    PRINT 'Foreign key [FK_TableName_RefTable] created successfully'
END
GO
```

---

## DML Script Template (INSERT/UPDATE)

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Detailed description of data changes]
    RedmineID: #XXXXXX
*/

USE Affiliate_12B
GO

-- =============================================
-- Insert initial data
-- =============================================
BEGIN TRANSACTION

    -- Check if data already exists
    IF NOT EXISTS (SELECT 1 FROM dbo.TableName WHERE Id = 1)
    BEGIN
        INSERT INTO dbo.TableName (Column1, Column2, CreatedDate)
        VALUES
            ('Value1', 'Value2', GETDATE()),
            ('Value3', 'Value4', GETDATE())
        
        PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' row(s) inserted into TableName'
    END
    ELSE
    BEGIN
        PRINT 'Data already exists in TableName'
    END

COMMIT TRANSACTION
GO
```

---

## Column Addition Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Add new column [ColumnName] to [TableName]
    RedmineID: #XXXXXX
*/

USE Affiliate_12B
GO

-- =============================================
-- Add new column
-- =============================================
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.TableName') 
        AND name = 'NewColumn'
)
BEGIN
    ALTER TABLE [dbo].[TableName]
    ADD [NewColumn] DATATYPE NULL  -- Use NULL for existing data
    
    PRINT 'Column [NewColumn] added to [TableName]'
    
    -- Populate with default value if needed
    UPDATE dbo.TableName
    SET NewColumn = 'DefaultValue'
    WHERE NewColumn IS NULL
    
    PRINT 'Column [NewColumn] populated with default values'
    
    -- Make NOT NULL if required
    ALTER TABLE [dbo].[TableName]
    ALTER COLUMN [NewColumn] DATATYPE NOT NULL
    
    PRINT 'Column [NewColumn] set to NOT NULL'
END
ELSE
BEGIN
    PRINT 'Column [NewColumn] already exists in [TableName]'
END
GO
```

---

## SystemSettings Update Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Update system settings
    RedmineID: #XXXXXX
*/

USE Affiliate_12B
GO

-- =============================================
-- Update or Insert SystemSettings
-- =============================================
MERGE INTO dbo.SystemSettings AS target
USING (
    SELECT 'SettingName' AS SName, 'SettingValue' AS SValue, 'Description' AS Description
) AS source
ON target.SName = source.SName
WHEN MATCHED THEN
    UPDATE SET 
        target.SValue = source.SValue,
        target.Description = source.Description
WHEN NOT MATCHED THEN
    INSERT (SName, SValue, Description)
    VALUES (source.SName, source.SValue, source.Description);

PRINT 'SystemSettings updated'
GO
```

---

## Permission Grant Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Grant permissions for new objects
    RedmineID: #XXXXXX
*/

USE Affiliate_12B
GO

-- =============================================
-- Grant Execute permissions
-- =============================================
GRANT EXECUTE ON [dbo].[Aff_User_NewProcedure_Sel] TO [wsv_afinet]
GRANT EXECUTE ON [dbo].[Aff_User_NewProcedure_Sel] TO [wsv_afinetv]

PRINT 'Permissions granted successfully'
GO
```

---

## Rollback Script Template

**Always create a rollback script** for production deployments.

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: ROLLBACK - [Original Task Description]
    RedmineID: #XXXXXX
    
    ROLLBACK PROCEDURE:
    1. [Step 1]
    2. [Step 2]
*/

USE Affiliate_12B
GO

-- =============================================
-- Rollback: Drop new column
-- =============================================
IF EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.TableName') 
        AND name = 'NewColumn'
)
BEGIN
    ALTER TABLE [dbo].[TableName]
    DROP COLUMN [NewColumn]
    
    PRINT 'Column [NewColumn] dropped from [TableName]'
END
GO
```

---

## Best Practices

### File Naming
```
YYYYMMDD_RedmineID_Description.sql
20251119_242450_AddCPAQuotaColumn.sql
```

### Required Elements
- ✅ File header with serverAlias and RedmineID
- ✅ USE statement for correct database
- ✅ Idempotent checks (IF NOT EXISTS)
- ✅ Transaction wrapping for DML
- ✅ Print statements for execution feedback
- ✅ GO statements to separate batches

### Idempotent Patterns
```sql
-- Table exists check
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TableName')

-- Column exists check
IF NOT EXISTS (SELECT 1 FROM sys.columns 
               WHERE object_id = OBJECT_ID('dbo.TableName') 
               AND name = 'ColumnName')

-- Index exists check
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IndexName')

-- Data exists check
IF NOT EXISTS (SELECT 1 FROM dbo.TableName WHERE Condition)
```

---

**Last Updated**: 2025-11-19  
**Owner**: DBA Team
