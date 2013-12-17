
declare @QualifiedMembers int ,
@CAQualifiedMembers int,
@Amount money, -- Amount with Marketing Fee included for Sportbook
@CAAmount  money, -- Amount with Marketing Fee included for Casino
@SPCommission float,
@HRCommission float,
@CACommission float

exec [dbo].[Aff_CalMonthlyEarning] 
@AffID =1300390,
@Month=03,
@Year =2012,
@QualifiedMembers  = @QualifiedMembers output,
@CAQualifiedMembers  = @CAQualifiedMembers output,
@Amount =@Amount OUTPUT, -- Amount with Marketing Fee included for Sportbook
@CAAmount   = @CAAmount OUTPUT, -- Amount with Marketing Fee included for Casino
@SPCommission =@SPCommission OUTPUT,
@HRCommission=@SPCommission OUTPUT,
@CACommission  = @CACommission OUTPUT

select  @QualifiedMembers as  QualifiedMembers,
@CAQualifiedMembers as CAQualifiedMembers,
@Amount as Amount, -- Amount with Marketing Fee included for Sportbook
@CAAmount as CAAmount, -- Amount with Marketing Fee included for Casino
@SPCommission as SPCommission,
@HRCommission as HRCommission,
@CACommission CACommission