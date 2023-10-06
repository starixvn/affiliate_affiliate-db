 Select 'DROP proc ' + name, * from sys.procedures (nolock)

SELECT b.name fncSchema, 'DROP FUNCTION ' + a.Name AS function_name, TYPE
FROM sys.objects a
INNER JOIN sys.schemas b
ON a.schema_id = b.schema_id
WHERE TYPE in ('FN', 'IF', 'TF')