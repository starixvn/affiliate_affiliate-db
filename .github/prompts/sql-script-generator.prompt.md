---
mode: 'agent'
tools: ['changes', 'codebase', 'editFiles', 'problems', 'execute_sql']
description: 'SQL script generator that follows company standards for metadata headers, documentation, and coding practices. Generates minimal, focused SQL scripts with standard headers based on user requirements only.'
---

# SQL Script Generator

Generate minimal SQL scripts following company standards with proper metadata headers and documentation blocks. **Generate only what the user specifically requests - no assumptions or extra features.**

## 📋 User Input Requirements

When generating a script, the user must provide:
- **Server Alias**: Target database server (e.g., DBAFFN88-Affiliate_N88, DBAFF12B-Affiliate_12B)
- **Task Description**: Brief description of what the script does
- **RedmineID**: Ticket/issue number (e.g., #12345)
- **User/Author**: Person creating the script
- **Script Requirements**: Specific SQL operations needed

## 📝 Script Naming Convention

Scripts are named using the format: `{YYYYMMDD}_{TaskDescription}.sql`

Examples:
- `20250903_UpdateUserPermissions.sql`
- `20250903_CreateCPATrackingTable.sql`
- `20250903_DeleteOldRecords.sql`

## 📋 Standard Script Format

### Required Headers
```sql
/*<info serverAlias="{UserProvidedServerAlias}"></info>*/
/*
    Created: {YYYYMMDD}@{UserProvidedAuthor}
    DB: {ExtractedFromServerAlias}
    Task: {UserProvidedTaskDescription} [RedmineID: {UserProvidedRedmineID}]
*/

-- Script body (only what user requests)
```

## 🛠️ Script Templates

### Data Modification Script
```sql
/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
    Created: 20250903@lewis.cao
    DB: DBAFFN88.Affiliate_N88
    Task: Update user status for affiliate system [RedmineID: #12345]
*/

UPDATE TableName 
SET ColumnName = 'NewValue'
WHERE Condition = 'Criteria';
```

### Schema Creation Script
```sql
/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
    Created: 20250903@lewis.cao
    DB: DBAFFN88.Affiliate_N88
    Task: Create new table for tracking [RedmineID: #12345]
*/

CREATE TABLE dbo.NewTableName (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETUTCDATE()
);
```

### Query Script
```sql
/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
    Created: 20250903@lewis.cao
    DB: DBAFFN88.Affiliate_N88
    Task: Generate monthly report data [RedmineID: #12345]
*/

SELECT 
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(Amount) AS TotalAmount
FROM Orders
WHERE OrderDate >= '2025-08-01'
GROUP BY CustomerID;
```

## ⚠️ Generation Rules

### DO Generate:
- Standard headers with user-provided information
- Appropriate filename following naming convention
- Only the SQL operations user specifically requests
- Clean, readable formatting

### DON'T Generate (unless explicitly requested):
- Verification queries
- Backup statements
- Error handling (TRY/CATCH)
- Performance optimizations (SET NOCOUNT ON)
- Indexes or constraints beyond user requirements
- Transaction wrappers
- Execution time tracking

## 🎯 Server Alias Mapping
- **Development**: `DBAFFN88-Affiliate_N88`
- **Production**: `DBAFF12B-Affiliate_12B`
- **Test**: `DBAFFT01-Affiliate_Test`

## ✅ Output Requirements

1. **Generate filename**: `{YYYYMMDD}_{TaskDescription}.sql`
2. **Include standard headers** with user-provided information
3. **Generate minimal script body** containing only requested operations
4. **Use consistent formatting** and proper SQL syntax
5. **No extra features** unless specifically requested by user

Generate SQL scripts that are deployment-ready, maintainable, and follow company standards while remaining minimal and focused on the specific user requirements.
