/* Extract basic stored procedure metadata for catalog enrichment */
SELECT 
    p.name              AS ProcedureName,
    SCHEMA_NAME(p.schema_id) AS SchemaName,
    p.create_date,
    p.modify_date,
    CASE 
        WHEN p.name LIKE 'Aff_Admin_%' THEN 'Admin'
        WHEN p.name LIKE 'Aff_User_%' THEN 'User'
        WHEN p.name LIKE 'Aff_Con_%' THEN 'Security'
        WHEN p.name LIKE 'Aff_f_%' THEN 'Function'
        WHEN p.name LIKE 'Task_Aff_%' THEN 'Task'
        WHEN p.name LIKE 'Aff_API_%' THEN 'API'
        ELSE 'Core'
    END AS Layer,
    (SELECT COUNT(DISTINCT d.referenced_id)
        FROM sys.sql_expression_dependencies d
        WHERE d.referencing_id = p.object_id) AS DependencyCount
FROM sys.procedures p
WHERE p.name NOT LIKE '%_UAT%'
ORDER BY p.name ASC;

/* Next step (outside SQL):
   - Parse file headers to populate LastRev.
   - Join dependency detail for KeyDependencies (top N referenced objects).
*/
