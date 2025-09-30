ALTER PROCEDURE [dbo].[Aff_AdminNoteSel]	
	@AffID int,
	@NoteId int = null,
	@PageSize int = 50,
	@PageIndex int = 1,
	@TotalPages int = 0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: 20090122@TrangLe
Task : List Notes for Affiliate
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):
. @NoteId ID of note
. @AffID Affiliate ID
*/
SET NOCOUNT ON

--count nrows
select @NRows=count(1)
FROM AdminNotes N WITH (NOLOCK)	
where AffID = @AffID and
	(@NoteId is null or NoteId = @NoteId)

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	
SELECT [Noteid], [Note], [UpdatedDate], AffID, [Updatedby], UpdateName
from (
	SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY Updateddate desc) AS TheCount,
		[Noteid], [Note], [UpdatedDate], N.AffID, [Updatedby], U.username as UpdateName
	FROM AdminNotes N WITH (NOLOCK)
		INNER JOIN AdminUser U WITH (NOLOCK) ON U.CUSTID=N.UPDATEDBY
	WHERE AffID = @AffID and
		(@NoteId is null or NoteId = @NoteId)
	) x
where x.TheCount >= @RowStart



GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteSel] TO [vnteam]