Create PROCEDURE [Aff_CasinoHasData]	
	@Date smalldatetime,
	@HasCasinoData bit = 0 OUTPUT
AS  
/*
	Task : check casino data exists or not in previous month.
	Author : Johnny@20110801
	DB: DB052.Affiliate_12BET
	Original: [Aff_CasinoHasData]  
	Revisions
		-20120409@Johnny:
			+ link: http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320
*/
SET NOCOUNT ON  

Select @HasCasinoData = 0
select @Date = convert(varchar(10),@Date,120)

--Check Data whether Casino data import or not.
if exists(select 1 from MemberDaily nolock where winlostdate = @Date and sporttype = 3)
Begin
	Select @HasCasinoData = 1
End

GO
GRANT EXECUTE ON [dbo].[Aff_CasinoHasData] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CasinoHasData] TO [VNTeam]
  