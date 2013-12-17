 declare @DefaultGroupID int,@NoCommGroupID int
 select @DefaultGroupID=GroupID 
 from CommGroup with (nolock)
 where GroupName='Default'
 
 select @NoCommGroupID=GroupID 
 from CommGroup with (nolock)
 where GroupName='NoCommission'
 
 Update ai
    Set ai.GroupID=@DefaultGroupID
 from AffInfo ai with (rowlock,updlock)
    inner join AffDetail ad with (nolock) on ad.AffID=ai.AffID and ai.GroupID <> @NoCommGroupID
 where ai.[Status]='Approved' 