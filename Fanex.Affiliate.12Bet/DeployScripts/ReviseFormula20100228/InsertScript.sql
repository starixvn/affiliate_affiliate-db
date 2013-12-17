update DeductionSetting with (rowlock,updlock)
set DeductedPercentage=0.05
where DeductionID=3

update DeductionSetting with (rowlock,updlock)
set DeductedPercentage=0.5
where DeductionID=4