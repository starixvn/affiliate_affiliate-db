ALTER PROCEDURE [Aff_MemberListSel]
	@AffUsername nvarchar(50) = null,
	@Username nvarchar(30) = null,    
	@IBCUserName nvarchar(50) = null,
	@PageSize int=50,
	@PageIndex int=1 OUTPUT,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
	Created: 20090701@VinhTrinh	
	DB: DB052.Affiliate_12Bet

	Revisions:		
			   -20100112@Peter : 	Shorting the page by CreatedDate . Request from Fan	
*/
SET NOCOUNT ON
declare @AffID int, @CurrDate smalldatetime

If @AffUsername is not null
Begin
	select @AffID = AffId from AffInfo with (nolock) where Username = @AffUsername
End

select @CurrDate = dateadd(d, 0, (datediff(d, 0, current_timestamp)))

select @Username = '%' + isnull(@Username, '') + '%', @IBCUserName = '%' + isnull(@IBCUserName, '') + '%'

select @NRows = count(1)
from MemberInfo m with (nolock)
	inner join AffInfo a with(nolock) on m.AffID = a.AffID
where (case 
			when @AffID is null then 1 
			else 
				case when @AffID = a.AffID then 1 else 0 end
			end
		) = 1
	and m.Username like @Username
	and IBCUserName like @IBCUserName
	and m.IsRemoved=0
	
if(isnull(@NRows,0)=0) return	
   
DECLARE @RowStart int, @RowEnd int

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex=(case when @PageIndex > @TotalPages then @TotalPages else @PageIndex end),
	   @RowStart = @PageSize * (@PageIndex-1) + 1, @RowEnd = @RowStart + @PageSize - 1
		 

DECLARE @TempMember TABLE(IBCCustId int PRIMARY KEY, UserName nvarchar(30), IBCUserName nvarchar(50), Currency int, FirstName nvarchar(50), LastName nvarchar(50), CreatedDate datetime, AffId int, AffUserName nvarchar(30)) 

insert into @TempMember
select m.IBCCustId, m.UserName, m.IBCUserName, m.Currency, m.FirstName, m.LastName, m.CreatedDate, m.AffID, m.AffUserName as AffUserName
from
	(select ROW_NUMBER() OVER(ORDER BY m.CreatedDate desc) AS TheCount,
		m.IBCCustID, m.UserName, m.IBCUserName, m.Currency as Currency, m.FirstName, m.LastName, m.CreatedDate, m.AffID, af.UserName as AffUserName
	from MemberInfo m with (nolock)
		INNER JOIN AffInfo af with (nolock) on m.AffID = af.AffId
	where (case 
			when @AffID is null then 1 
			else 
				case when @AffID = af.AffID then 1 else 0 end
			end
			) = 1
		and m.Username like @Username
		and m.IBCUserName like @IBCUserName
		and m.IsRemoved = 0
	)m
where m.TheCount between @RowStart and @RowEnd


SELECT UserName, t.IBCCustID, IBCUserName, FirstName, LastName, CreatedDate, CurrBalance, AffUserName
FROM @TempMember m
	LEFT JOIN (
		SELECT m.IBCCustID, 
		isnull(sum(case when ruben = 1 then (winlost-abs(actual_stake) + playercomm)*isnull(e.actualrate2,1) else 0 end), 0) as CurrBalance	
		FROM @TempMember m
			LEFT JOIN bodb02.dbo.bettrans b with(nolock) on b.CustID = m.IbcCustID		
			LEFT JOIN exchange e with(nolock) on e.exchangeid=m.currency 
												 and e.UpdatedTime=(
																	 select max(e1.UpdatedTime) 
																	 from Exchange e1 with (nolock) 
																	 where e1.ExchangeID=e.ExchangeID and UpdatedTime<=b.winlostdate
																   ) 
							 
		GROUP BY m.IBCCustID
	) t on m.IBCCustId = t.IBCCustID
order by CreatedDate desc

GO
GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberListSel] TO [vnteam]