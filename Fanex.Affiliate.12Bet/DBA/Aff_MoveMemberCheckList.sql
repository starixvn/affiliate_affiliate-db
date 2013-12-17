 /*Case 1: Member is under Agent 01 (walk in member)
 --Update AgentID, AffiliateID from Deposit_DB.dbo.Customer
 --Update Setting Super,Master,Agent for this member from bodb02 (Check Replication)
 --Insert this member into MemberInfo under Affiliate xyz
 -- Calculate Daily transaction for this Affiliate for the month.*/
 
 /*Case 2: Member is under Agent02 but under another Affiliate
 --Update AffiliateID from Deposit_DB.dbo.Customer
 -- Update 
 
 */
 --Tasks : move walk in member sbuckley63 under 12BETAFF3711
 /*
 dba_getpt '12BETGBP02'
 Select * from AffInfo (nolock) where username='12BETAFF3711'
 Select * from Deposit_Customer (nolock) where username='sbuckley63'
 */
 use [Deposit_Customer]
 
 update Deposit_Customer with (rowlock,updlock)
 set --IBCAgentID=860383,
	 Affiliate=92030783	 
where username='sbuckley63'	 

exec  [dbo].[Aff_CustomerInsMember]
	@IbcCustID =3653473,
	@AffID =92030783,
	@Username ='sbuckley63',
	@IBCUsername ='12BETGBP012143',
	@DepositCustID =136092,
	@FirstName ='Steve',
	@LastName='Buckley',
	@Currency =12,
	@Recommend =836215,
	@Email ='sbuckley63@googlemail.com'

GO
/*
 Check this member user is created since 18 Feb 2011
 Select creatdate,* from Customer (nolock) where custid=3653473
*/
exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='18 Feb 2011',
	@AffId =92030783
	 
exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='19 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='20 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='21 Feb 2011',
	@AffId =92030783
	
exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='22 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='23 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='24 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='25 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='26 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='27 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='28 Feb 2011',
	@AffId =92030783

exec [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate ='1 Mar 2011',
	@AffId =92030783

	
	 