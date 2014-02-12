 CREATE PROCEDURE [dbo].[DOT_DEP_LicenseeInsCustomer]
	@SystemCustID int, -- CustID that stored in IBC's DB
	@TrackingID varchar(50), -- AffID & some others info
	@LicenseeID varchar(30), -- username or custid that get from licensee's DB
	@Currency int,
	@Recommend int, -- IBC's currency agent ID
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT	 
AS
/*  
	Created: Viet @ 22 Feb 2011
	Task : Add new customer
	DB: DB052.Affiliate_ZZun
*/ 
SET NOCOUNT ON

-----------
-- DO IT LATER
-----------
GO
GRANT EXECUTE ON [dbo].[DOT_DEP_LicenseeInsCustomer] TO [Dot_Member]
GO
GRANT VIEW DEFINITION ON [dbo].[DOT_DEP_LicenseeInsCustomer] TO [vnteam]