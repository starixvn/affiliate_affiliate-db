ALTER Procedure [dbo].[AffAdmin_Con_GroupPolicySel]
	@Groupid int
AS 
/*DB03.BODB02 --> DB052.Affiliate_MYM*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
-- 20151113@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
SET NOCOUNT ON

declare @IsIT bit
DECLARE @LicenseeID INT

SELECT @IsIT = CASE WHEN GroupName LIKE 'Aff_IT_Dept' THEN 1 ELSE 0 END 
	, @LicenseeID = LicenseeID
FROM dbo.AffAdmin_f_GroupInfo_Select(@GroupID,'')

DECLARE @FuncList TABLE (FunctionID INT, LicenseeID INT, FunctionName NVARCHAR(50), FunctionNote NVARCHAR(2000), FunctionDesc NVARCHAR(50), FunctionRender TINYINT, 
						CreateDate DATETIME, ModifyDate DATETIME, DisplayOrder TINYINT, Creator INT, ParentID INT, Filenames VARCHAR(2000))

INSERT INTO @FuncList (FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames)
SELECT FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames
FROM dbo.AffAdmin_f_FunctionInfo_Select('', @LicenseeID)

Declare @Tmp table(createdate smalldatetime, modifydate smalldatetime, gpolicy tinyint, groupid int
					, funcid int, groupname nvarchar(50), funcname nvarchar(50), funcdesc nvarchar(50)
					, parentid int, subfuncCount int, DisplayOrder int
					)

Insert into @Tmp
SELECT gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.FunctionID,gi.groupname,fi.functionname
	,fi.functiondesc,fi.parentid ,count(fip.functionid) as SubFuncCount,fi.DisplayOrder
FROM dbo.AffAdmin_f_GroupPolicy_Select(@GroupID,'') gp
	INNER JOIN AffAdmin_f_GroupInfo_Select('','') gi on gp.groupid=gi.groupid  
	INNER JOIN @FuncList fi on gp.FunctionID=fi.FunctionId 
	left join @FuncList fip on fi.FunctionID = fip.ParentID and fip.parentid <> fip.functionid
group by gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.FunctionID,gi.groupname,fi.functionname
	,fi.functiondesc,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid,count(fip.functionid) DESC, fi.DisplayOrder


If (@IsIT = 0)
Begin
	delete @Tmp
	where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp



