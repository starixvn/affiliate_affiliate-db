/* Extract object dependency pairs */

SELECT DISTINCT
    referencing_schema_name,
    referencing_entity_name,
    referenced_schema_name,
    referenced_entity_name
    FROM (
        SELECT DISTINCT
            referencing_schema_name = OBJECT_SCHEMA_NAME (d.referencing_id),
            referencing_entity_name = OBJECT_NAME(d.referencing_id),
            referenced_schema_name = OBJECT_SCHEMA_NAME (d.referenced_id),
            referenced_entity_name = OBJECT_NAME(d.referenced_id)
        FROM sys.sql_expression_dependencies d
        JOIN sys.objects o ON o.object_id = d.referencing_id
        WHERE o.type IN ('P','V','FN','IF','TF')
    ) AS dependencies
    WHERE referencing_entity_name NOT LIKE '%_UAT1%'
    AND referencing_entity_name NOT LIKE '%_UAT2%'
    AND referencing_entity_name NOT LIKE '%_UAT3%'
    AND referencing_entity_name NOT LIKE '%_UAT4%'
    AND referencing_entity_name NOT LIKE '%_xpre%'
    AND referencing_entity_name NOT LIKE '%_xtest%'
    AND referencing_entity_name NOT LIKE '%_Sally%'
;
