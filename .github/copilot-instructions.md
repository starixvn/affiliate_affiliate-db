### Stored Procedure Template
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
    
    BEGIN TRY
        -- Input validation
        IF @Param1 IS NULL OR @Param1 = ''
        BEGIN
            RAISERROR('Parameter @Param1 cannot be null or empty', 16, 1)
            RETURN
        END
        
        -- Main business logic
        SELECT ...
        FROM dbo.TableName WITH (NOLOCK)
        WHERE ...
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, ERROR_SEVERITY(), ERROR_STATE())
    END CATCH
END
GO

### Performance & Security
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

### Formatting
- 4 spaces indentation (no tabs)
- UPPERCASE SQL keywords: SELECT, FROM, WHERE, JOIN
- lowercase table aliases: ai, ad, cg
- Align related keywords vertically
- Space around operators: =, AND, OR

## 📂 Project Structure
docs/domains/b2c-12b/
├── README.md                    # Domain overview
├── database-schema.md           # Schema reference  
└── modules/
    └── cpa/                     # Cost Per Acquisition
        ├── business.md          # Business processes
        └── schema.md            # Database details

File Organization:
- Admin procedures: B2C/12B/Admin/[Module]/
- User procedures: B2C/12B/User/[Module]/
- Core functions: 12BET/Core function/[Category]/
- Scripts: Scripts/B2C/12B/Affliate_12B/[RedmineID]/

## 💬 Communication Style
[Brief analysis]

Implementation approach:
• [Key decision 1]
• [Key decision 2]

[Generate code OR request documentation]

---
Keep it simple. Focus on code quality. Ask for context when needed.