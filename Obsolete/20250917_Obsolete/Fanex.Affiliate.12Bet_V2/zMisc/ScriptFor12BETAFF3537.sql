 --Affiliate_12BET
 select * from AffInfo (nolock) where username='12BETAFF3537'
 
 --AffID=92030609
 
 --Move these customers from Affiliate 92030504(12BETAFF3432),92030412 (12BETAFF3340) to 92030609
 --(All members were created on this month so can move, otherwise will not)
 /*
	select username2,username,* from customer (nolock) where username2 like '%IRMN%'
 */
 
select * from MemberInfo(nolock)
where IBCCustID in (
3274427,
3283560,
3283563,
3309222,
3309223,
3309228,
3305498,
3309232,
3309238,
3291931

)

--update AffiliateID from MemberInfo 
update MemberInfo with (rowlock,updlock)
set IsRemoved=0,
    AffID=92030609	
where IBCCustID in (
3274427,
3283560,
3283563,
3309222,
3309223,
3309228,
3305498,
3309232,
3309238,
3291931

)
--Delete MemberDailyRemoved and MemberRemoval for related members

--USE DepositDB
--Update AffiliateID from Deposit_Customer

update Deposit_Customer with (rowlock,updlock)
set AffiliateID=92030609
IBCCustID in (
3274427,
3283560,
3283563,
3309222,
3309223,
3309228,
3305498,
3309232,
3309238,
3291931

)

