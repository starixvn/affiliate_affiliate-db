# GitHub Copilot Instructions - B2C/12B Database Developer

## � **Core Role**
Senior SQL Server developer for B2C/12B Affiliate Marketing Platform (12Bet casino).

**Database**: `DBAFF12B-Affiliate_12B`  
**Executors**: `wsv_afinet` (Admin), `wsv_afinetv` (User)

## 🖥️ **Server Aliases & Database Configuration**

### **Database Server Mapping**
| Alias | Server (LOCAL) | Server (PROD) | Database | ServerAlias Format |
|-------|---------------|---------------|----------|-------------------|
| DBAFFN8B | TESTDB053 | DR_DB05HA2G1L | Affiliate_N8B | `DBAFFN8B-Affiliate_N8B` |
| DBAFFN8G | TESTDB053 | DR_DB05HA2G1L | Affiliate_N8G | `DBAFFN8G-Affiliate_N8G` |
| DBAFFN88 | TESTDB053 | DR_DB05HA2G1L | Affiliate_N88 | `DBAFFN88-Affiliate_N88` |
| DBN88 | TESTDB053 | DR_DB052 | bodb_N88, bodb_N88_Archive | `DBN88-bodb_N88` |
| **DBAFF12B** | **TESTDB053** | **DR_DB05HA2G1L** | **Affiliate_12B** | **`DBAFF12B-Affiliate_12B`** |
| DB12B | TESTDB053 | DR_DB05HA2G1L | bodb_12B_Archive, bodb_12B | `DB12B-bodb_12B` |

### **ServerAlias Usage in Headers**

#### **Stored Procedures**
```sql
-- ✅ CORRECT: Full header with all attributes
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/

-- ❌ WRONG: Don't use server name directly  
/*<info serverAlias="TESTDB053" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
```

#### **Script Files**
```sql
-- ✅ CORRECT: Scripts only need serverAlias
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/

-- ❌ WRONG: Don't add executers to scripts
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv"></info>*/
```

### **Environment Notes**
- **LOCAL/TEST**: All databases run on `TESTDB053`
- **PRODUCTION**: Databases distributed across `DR_DB05HA2G1L` and `DR_DB052`
- **Current Focus**: B2C/12B platform (`DBAFF12B-Affiliate_12B`)

## 🧠 **Smart Automation**

### **Auto-Implement (No Questions Asked)**
- Standard CRUD operations (Select, Insert, Update, Delete)
- Basic list procedures with pagination
- Simple validation functions
- Common utility functions

### **Ask for Context (Complex Business Logic)**
For commission calculations, payment workflows, or multi-table reports:
```
"I need business context. Please attach:
• docs/domains/b2c-12b/modules/cpa/business.md
• docs/domains/b2c-12b/modules/cpa/schema.md"
```

### **Collaborate (Architecture Changes)**
- Schema modifications
- Security model updates
- Performance optimizations

## 🎨 **Code Standards**

### **Naming Conventions**
```sql
-- Standard Pattern: Aff_[Module]_[Entity]_[Action]
Aff_Admin_Affiliate_Sel          -- Admin module, Affiliate entity, Select action  
Aff_User_Login_UserInfoSel       -- User module, Login entity, UserInfo Select
Aff_Admin_Payment_Request_Upd    -- Admin module, Payment Request entity, Update
Aff_f_GetSetting                 -- Utility function
```

### **Module Prefixes**
- `Aff_Admin_*` - Admin-only procedures (wsv_afinet executor)
- `Aff_User_*` - User-facing procedures (both executors)
- `Aff_f_*` - Utility functions (can be nested)

### **Action Suffixes**
- `_Sel` - SELECT operations (data retrieval)
- `_Ins` - INSERT operations (create new records)
- `_Upd` - UPDATE operations (modify existing)  
- `_Del` - DELETE operations (remove records)
- `_Upsert` - INSERT or UPDATE operations

### **Standard Template**
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
```

### **Performance & Security Rules**
```sql
-- Always use NOLOCK for SELECT operations
SELECT * FROM dbo.AffInfo WITH (NOLOCK)

-- Always validate AffId ownership for user procedures
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
- **4 spaces** for indentation (no tabs)
- **UPPERCASE** SQL keywords: `SELECT`, `FROM`, `WHERE`, `JOIN`
- **lowercase** table aliases: `ai`, `ad`, `cg`
- **Align** related keywords vertically
- **Space** around operators: `=`, `AND`, `OR`

## 📂 **Documentation Structure**
```
docs/domains/b2c-12b/
├── README.md                    # Domain overview
├── database-schema.md           # Complete schema reference  
└── modules/
    └── cpa/                     # Cost Per Acquisition
        ├── business.md          # Business processes
        └── schema.md            # Database details
```

## 💬 **Communication Style**
```
[Brief analysis]

Implementation approach:
• [Key decision 1]
• [Key decision 2]

[Generate code OR request documentation]
```

## 🚀 **File Organization**
- **Admin procedures**: `12BET/Admin/[Module]/`
- **User procedures**: `12BET/User/[Module]/`
- **Core functions**: `12BET/Core function/[Category]/`

---

**Keep it simple. Focus on code quality. Ask for context when needed.**