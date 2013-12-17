ALTER Procedure [dbo].[AffAdmin_AffiliateSelLog]
	@AffID INT = NULL, 
	@LogType INT = NULL,
	@DateFrom DATETIME = '2000-01-01',
	@DateTo DATETIME = '2020-01-01',
	@PageIndex INT =1,
	@PageSize INT = 20,
	@TotalPage INT = 0 OUTPUT,
	@RowCount INT = 0 OUTPUT
AS
/*
	Created: 20100423@Jacob
	Task : Get all log type
	DB: DB052.Affiliate_MYM
	Revisions:
		- 20100423@Jacob initialize
		
	Param's Explanation:

*/
SET NOCOUNT ON;

select @DateFrom=convert(varchar(10),@DateFrom,120)
select @DateTo=dateadd(s,-1,dateadd(d,1,@DateTo)) 

IF (@PageSize<=0) SET @PageSize = 20;


WITH UserLogs AS
(
	SELECT TOP(@PageIndex*@PageSize) ROW_NUMBER() OVER (ORDER BY [RefNo] desc, [LoggedDate] DESC) AS Row
		   , L.[RefNo]
		  ,L.[TypeID]
		  ,L.[AffID]
		  ,C.[UserName]
		  ,L.[Creator]
		  ,L.[LoggedDate]
		  ,L.[SPName]
		  ,L.[Details]
		  ,L.[IP]
		  ,T.[TypeName]
		  ,T.[Description]	
		   FROM [dbo].[UserLog] L WITH(NOLOCK) 
				INNER JOIN [dbo].[AffInfo]AS C WITH(NOLOCK) ON C.AffID = L.[AffID]
				INNER JOIN [dbo].[LogType] T WITH(NOLOCK) 
					ON (T.[TypeID]=L.[TypeID] AND (ISNULL(@LogType,0) = 0 OR T.[TypeID] = ISNULL(@LogType,0)))
		   WHERE L.[AffID]=ISNULL(@AffID,0)		   
				AND L.[LoggedDate] BETWEEN ISNULL(@DateFrom,'2000-01-01') AND ISNULL(@DateTo,GETDATE())	
)

SELECT   [Row]
		  , [RefNo]
		  ,[TypeID]
		  ,[AffID]
		  ,[UserName]
		  ,[Creator]
		  ,[LoggedDate]
		  ,[SPName]
		  ,[Details]
		  ,[IP]
		  ,[TypeName]
		  ,[Description]	
FROM UserLogs
WHERE  Row BETWEEN (@PageIndex-1)*@PageSize + 1 AND @PageIndex*@PageSize

SELECT @RowCount=COUNT(L.[RefNo])
FROM [dbo].[UserLog] L WITH(NOLOCK)
WHERE (ISNULL(@LogType,0) = 0 OR L.[TypeID] = ISNULL(@LogType,0))
	AND L.[AffID]=ISNULL(@AffID,0)		   
	AND L.[LoggedDate] BETWEEN ISNULL(@DateFrom,'2000-01-01') AND ISNULL(@DateTo,GETDATE())			
			
IF (@RowCount % @PageSize = 0) SET @TotalPage = (@RowCount / @PageSize);
ELSE SET @TotalPage = (@RowCount / @PageSize) + 1;



