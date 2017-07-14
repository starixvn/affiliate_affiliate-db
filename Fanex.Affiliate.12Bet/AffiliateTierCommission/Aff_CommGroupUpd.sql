USE [Affiliate_12BET]
GO

ALTER PROCEDURE [Aff_CommGroupUpd]
	@UserId int,
	@GroupId int,
	@GroupName nvarchar(100),
	@Description nvarchar(100),
	@SportIDList varchar(300),
	@DeductionList xml,
	@TierList varchar(300),
	@MinAmountList varchar(500),
	@MaxAmountList varchar(500),
	@MinQMList varchar(500),
	@MaxQMList varchar(500),
	@CommissionList varchar(500),
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT	
AS

/*
	Created: 20090719@DungTong
	Task: update an existing Commission Group
	DB: DBAFF12BET.Affiliate_12Bet
	Original:

	Revisions:
		- 20121207@Johnny: 
			+ If update group does not have casino to group has casino -> update CasinoJoinedDate in AffInfo 
			+ If update group has casino to group hasn't casino 
				. do not update CasinoJoinedDate in AffInfo 
				. if there is affiliate in group has casino, do not allow update this group
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]

	Parameters:
		.@UserID: Administrator user id
		.@GroupID:
			-1		: normal group
			>1000	: Special Setting for Affiliate that has AffID=@GroupID
		.@GroupName The name of this Group
		.@Description : description for this group
		.@SportIDList: list of sportID separated by semi colon
		.@DeductionList: List of Deduction Setting for above Sport List.                   
		.@TierList: List of number of Tiers for each sport type separated by a semi colon
		.@MinAmountList: List of MinAmount for each tier (all sports)
		.@MaxAmountList: List of MaxAmount for each tier (all sports)
		.@MinQMList: List of MinQM for each tier (all sports)
		.@MaxQMList: List of MaxQM for each tier (all sports)
		.@CommissionList: List of Commission for each tier (all sports)
		.@IsApproved: 1 if we want to approved this aff and create a new group					  
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)
	
	--Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@UserID,
		@funcname='[CommissionGroup]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
	
	if(@ErrMsg<>'')
		return
	
	if (not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))
	begin
		select @ErrCode=101,@ErrMsg='The group ID=' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.'    
		return
	end

	if(@GroupName is null or LTRIM(RTRIM(@GroupName))='')
	begin
		select @ErrCode = 10030, @ErrMsg = 'Group name is empty. Please choose a name!'
		return
	end
	
	if (@GroupID<1000 and exists (select 1 from CommGroup where GroupID<>@GroupID and GroupName = @GroupName and IsDeleted=0))
	begin
		select @ErrCode = 10031, @ErrMsg = 'Group name existed. Please choose another name!'
		return
	end

	declare @DeductionSetting table(GroupID int,DeductionID tinyint,DeductedPercentage decimal(9,8),NextDeductedPercentage decimal(9,8))
	declare @GroupSetting table(GroupID int,SportType tinyint,TierID tinyint,MinAmount money,MaxAmount money,MinQM int,MaxQM int,Commission decimal(9,8))
	
	--Insert Deduction Setting
	IF (@DeductionList IS NOT NULL)
	begin
		INSERT INTO @DeductionSetting (GroupID, DeductionID, DeductedPercentage, NextDeductedPercentage)
		SELECT @GroupId, t.c.value('@id', 'tinyint'), t.c.value('@percent', 'decimal(9,8)'), t.c.value('@nextpercent', 'decimal(9,8)')
		FROM @DeductionList.nodes('/root/row') AS t(c)

		IF @@ERROR <> 0
		BEGIN
		
			Select @ErrMsg = N'Error! Invalid Deduction Setting!', @ErrCode = 10032
			return
		END
	end
	
	--Insert Tier Setting
	declare @rank int,@SportID int,@NTier int, @i int, @MinQM int, @MaxQM int,@PreMaxQM int
	declare @MinAmountArr varchar(500),@MaxAmountArr varchar(500),@MinQMArr varchar(500),@MaxQMArr varchar(500),@CommissionArr varchar(500)
	declare @MinAmount money,@MaxAmount money,@PreMaxAmount money
	declare @Commission decimal(9,8),@PreCommission decimal(9,8)	
	select @rank=min(rank) from dbo.strsplit(@SportIDList, ';')	       
	
	if @rank is not null
	begin
		while @rank is not null
		begin
			BEGIN TRY
				-- For each SportType
				select @SportID=cast(val as tinyint) from dbo.strsplit(@SportIDList, ';') where rank=@rank
				select @NTier=cast(val as tinyint) from dbo.strsplit(@TierList, ';') where rank=@rank
				select @MinAmountArr=val from dbo.strsplit(@MinAmountList, ';') where rank=@rank
				select @MaxAmountArr=val from dbo.strsplit(@MaxAmountList, ';') where rank=@rank
				select @MinQMArr=val from dbo.strsplit(@MinQMList, ';') where rank=@rank
				select @MaxQMArr=val from dbo.strsplit(@MaxQMList, ';') where rank=@rank
				select @CommissionArr=val from dbo.strsplit(@CommissionList, ';') where rank=@rank

				select @i=1
				
				if(@NTier<1)
				begin						       
					Select @ErrMsg = N'Error! Invalid Tier List!', @ErrCode = 10035
					return
				end
				
				if(@NTier>50)
				begin
					ROLLBACK TRANSACTION
					Select @ErrMsg = N'Oops, maximum of 50 tiers are allowed!', @ErrCode = 10085
					return
				end
							
				while @i<=@NTier
				begin
					-- For each Tier
					if(@i<>1) --Store previous setting to compare with current setting
					begin
						select @PreMaxAmount=@MaxAmount,										   
								@PreMaxQM=@MaxQM,
								@PreCommission=@Commission
							
					end

					select @MinAmount=cast(val as money) from dbo.strsplit(@MinAmountArr, ',') where rank=@i
					select @MaxAmount=cast(val as money) from dbo.strsplit(@MaxAmountArr, ',') where rank=@i
					select @MinQM=cast(val as int) from dbo.strsplit(@MinQMArr, ',') where rank=@i
					select @MaxQM=cast(val as int) from dbo.strsplit(@MaxQMArr, ',') where rank=@i
					select @Commission=cast(val as decimal(9,8)) from dbo.strsplit(@CommissionArr, '@') where rank=@i
															
					/*Kiem tra du lieu la hop le : 
								+ cac gia tri khong nho hon 0 
								+ min < max
								+ min sau = max truoc + 1 (@i>1)
								+ Commission sau > Commission truoc va khong duoc lon hon 1
								+ Neu la tier cuoi cung thi hai gia tri max phai la vo cuc
								+ Cac gia tri min, max khong duoc lon hon vo cuc
								+ Vo Cuc(MaxAmount)= 100000000000000
								+ Vo Cuc(MaxQM) =1000000000 
							
					*/							
						

					if(@MinAmount>=0 and @MaxAmount<=100000000000000 and @MinAmount<=@MaxAmount
										and @MinQM>=0 and @MaxQM<=1000000000 and @MinQM<=@MaxQM
										and (@Commission between 0 and 1)
										and (
											case when (@i=1 and @i<@NTier) then 1
													when (@NTier>1 and @i=@NTier and @MaxQM=1000000000 and @MaxAmount=100000000000000 and @MinAmount=@PreMaxAmount + 1 and @MinQM=@PreMaxQM + 1 and @Commission>= @PreCommission) then 1
													when (@NTier=1 and @i=@NTier and @MaxQM=1000000000 and @MaxAmount=100000000000000 and @MinQM=0 and @MinAmount=0) then 1
													when (@i>1 and @i<@NTier and @MinAmount=@PreMaxAmount + 1 and @MinQM=@PreMaxQM + 1 and @Commission>= @PreCommission) then 1
													else 0
												end     	  
										)=1
					)								  
					begin
						--Insert du lieu 
						Insert into @GroupSetting(GroupID,SportType,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
						values (@GroupID,@SportID,@i,@MinAmount,@MaxAmount,@MinQM,@MaxQM,@Commission)
						
						--Neu khong dong nao duoc insert thi thoat <=> @@ROWCOUNT<>1 
						if(@@ROWCOUNT<>1)
						begin								  
							Select @ErrMsg = N'There was an error when inserting tier setting.', @ErrCode = 10037
							return		
						end 	
					end
					else
					begin								
						Select @ErrMsg = N'Error! Invalid Setting Data(SportType=' + cast(@SportID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!', @ErrCode = 10037
						return		
					end  
						
					--Increase @i by 1 
					select @i=@i + 1                                   
				end --end inner while
						 
				select @rank=min(rank) from dbo.strsplit(@SportIDList, ';') where rank>@rank
			END TRY
			BEGIN CATCH						
				Select @ErrMsg = ERROR_MESSAGE(), @ErrCode = 10034
				return	
			END CATCH
				 
		end --end outer while
	end --end if
	else ---Invalid Setting Data
	begin	
		Select @ErrMsg = N'Error! Invalid Setting Data (SportIDList) !', @ErrCode = 10033
		return	
	end 			

	--Checking again
	if (not exists (select 1 from @GroupSetting))
	begin
		Select @ErrMsg = N'Error! Invalid Setting Data !', @ErrCode = 10039
		return	
	end

	Declare @IsCasino_Current bit, @IsCasino_NewGroup bit, @CasinoId int

	select @CasinoId = dbo.Aff_GetSportID('Casino')
			, @IsCasino_Current = 0
			, @IsCasino_NewGroup = 0
	
	If Exists (Select 1 from GroupSetting nolock where GroupId = @GroupId and SportType = @CasinoId)
		set @IsCasino_Current = 1

	If Exists(Select 1 from @GroupSetting where SportType = @CasinoId)
		set @IsCasino_NewGroup = 1

	Select @IsCasino_Current as currentstatus, @IsCasino_NewGroup as newstatus
	
	--from casino to non-casino: if exists aff in group ->not allow update group to non-casino
	If (@IsCasino_Current = 1  
		and @IsCasino_NewGroup = 0
		and Exists(select 1 from AffInfo nolock where GroupId = @GroupId))
	Begin
		Select @ErrMsg = N'Error! Do not allow update this group to non-casino group because this group has affilite(s)!', @ErrCode = 10099
		return	
	End

	--BEGIN TRANSACTIOn AFTER CHECKING VALID INPUT DATA
	BEGIN TRANSACTION  
	  
	Update CommGroup with (rowlock,updlock)
	set GroupName=@GroupName, 
		Description=@Description     
	where GroupID=@GroupID
   
	if(@@ERROR <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 10040
		return	
	end
	   
	delete DeductionSetting where GroupID=@GroupID
	
	if(@@ERROR <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 10041
		return	
	end
		
	insert into DeductionSetting(GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage)
	select ds.GroupID, ds.DeductionID, ds.DeductedPercentage, ds.NextDeductedPercentage
	FROM @DeductionSetting ds
		INNER JOIN DeductionType d WITH (NOLOCK) ON d.DTypeID = ds.DeductionID
	WHERE d.IsTest <= @isTest

	if(@@ERROR <> 0 OR @@ROWCOUNT <> (SELECT COUNT(1) FROM @DeductionSetting))
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 10042
		return	
	end 
   
	delete GroupSetting where GroupID=@GroupID
	
	if(@@ERROR <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 10043
		return	
	end

	Insert into GroupSetting(GroupID,SportType,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
	select GroupID,SportType,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission
	from @GroupSetting
   
	if(@@ERROR <> 0 or @@ROWCOUNT<> (select count(1) from @GroupSetting))
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 10044
		return	
	end

	--Decide whether update CasinoJoinedDate or not
	If (@IsCasino_NewGroup = 1)--From non-casino to casino group
	Begin
		Update AffInfo with(rowlock, updlock)
		Set CasinoJoinedDate = convert(varchar(10), current_timestamp, 120)
		where GroupId = @GroupId and CasinoJoinedDate is null
	End

	commit transaction
	 
	--Write the log 
	DECLARE @LogData nvarchar(4000), @AffID int,@SPName varchar(100)
	
	if (@GroupID>1000)
	  select @AffID=@GroupID
	else
	  select @AffID=0  
	
	SELECT @LogData = N'Update a commission group.GroupID=' + dbo.Aff_ToString(@GroupID)
					  + '\n GroupName=' + dbo.Aff_ToString(@GroupName)
					  + '\n Description=' + dbo.Aff_ToString(@Description)
					  + '\n SportIDList=' + dbo.Aff_ToString(@SportIDList)
					  + '\n DeductionList=' + CONVERT(NVARCHAR(MAX), @DeductionList)
					  + '\n TierList=' + dbo.Aff_ToString(@TierList)
					  + '\n MinAmountList=' + dbo.Aff_ToString(@MinAmountList)
					  + '\n MaxAmountList=' + dbo.Aff_ToString(@MaxAmountList)
					  + '\n MinQMList=' + dbo.Aff_ToString(@MinQMList)
					  + '\n MaxQMList=' + dbo.Aff_ToString(@MaxQMList)
					  + '\n CommissionList=' + dbo.Aff_ToString(@CommissionList)
	   
	SELECT @SPName=OBJECT_NAME(@@PROCID)
	
	EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserId,	
		@AffID=@AffID,
		@Typename= 'CommissionGroup',	
		@SPName=@SPName ,
		@IP =@IP,
		@Details=@LogData
END
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupUpd] TO [vnteam]
GO