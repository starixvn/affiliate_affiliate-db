 update AffInfo with (rowlock,updlock)
 set Email='test' + dbo.Aff_ToString(AffID) + '@test.com'