USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_CommGroupIns]
	@UserId int,
	@GroupId int =-1 Output,
	@GroupName nvarchar(100),
	@Description nvarchar(100),
	@SportIDList varchar(300),
	@DeductionList varchar(300),
	@DeductedPercentageList varchar(300),
	@TierList varchar(300),
	@MinAmountList varchar(500),
	@MaxAmountList varchar(500),
	@MinQMList varchar(500),
	@MaxQMList varchar(500),
	@CommissionList varchar(500),
	@IsApproved bit=0,  --used for approved a user with a private group
	@Password varchar(40)=null,
	@IP varchar(20),
	@MailOption bit = false OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT	
AS

/*
	Created: 20090719@DungTong
	Task: Add a new Commission Group
	DB: DBAFF12BET.Affiliate_12Bet
	Original:

	Revisions:
	
	Parameters:
		.@UserID: Administrator user id
		.@GroupID:
			-1		: normal group
			>1000	: Special Setting for Affiliate that has AffID=@GroupID
		.@GroupName The name of this Group
		.@Description : description for this group
		.@SportIDList: list of sportID separated by semi colon
		.@DeductionList: List of Deduction Setting for above Sport List.                   
		.@DeductedPercentageList: List of Deducted Percentage
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
	
	--Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@UserID,
		@funcname='[CommissionGroup]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
	
	if(@ErrMsg<>'')
	  return

	if (@GroupId>1000)
	begin
		if(exists (select 1 from CommGroup (nolock) where GroupID=@GroupID and IsDeleted=0))
		begin
			select @ErrCode=101,@ErrMsg='The group ID=' +  cast(@GroupId as varchar(10)) + ' is already existed. Please check.'    
			return
		end
		else if(@IsApproved=0 and not exists (select 1 from AffInfo (nolock) where AffID=@GroupID and status='approved'))
		begin
			select @ErrCode = 102, @ErrMsg = 'Invalid Group ID. Please check.'
			return	
		end
		else if(@IsApproved=1 and not exists (select 1 from AffInfo (nolock) where AffID=@GroupID and status in ('disapproved','pending')))
		begin
			select @ErrCode = 103, @ErrMsg = 'Invalid Group ID. Please check.'
			return	
		end 
	end	

	if(@GroupName is null or LTRIM(RTRIM(@GroupName))='')
	begin
		select @ErrCode = 10030, @ErrMsg = 'Group name is empty. Please choose a name!'
		return
	end

	
	if (@GroupID=-1 and exists (select 1 from CommGroup where GroupName = @GroupName  and IsDeleted=0))
	begin
		select @ErrCode = 10031, @ErrMsg = 'Group name existed. Please choose another name!'
		return
	end

	declare @Identity int 
	
	select @Identity = max(GroupID) from CommGroup (nolock) where GroupID < 1000 
	
	if(@Identity is null)
		 select @Identity=100        
	
	if(@Identity = 999 and (@GroupID<0 or @GroupID is null))
	begin
		select @ErrCode = 102, @ErrMsg = 'There is no room for a new Group! Please contact to administrator '
		return
	end

	Begin transaction

	if(@GroupID<=0)
	begin		
		set @GroupID=@Identity + 1
	end	

	insert into CommGroup([GroupID],[GroupName], [CreatedDate], [Creator], [IsDeleted], [Description])
	values(@GroupID,@GroupName, current_timestamp, @UserId, 0, @Description)	  

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'Error! Insert Group unsuccessfully!', @ErrCode = 10031
		return
	END
	
	--Insert Deduction Setting
	if(len(@DeductionList)>0)
	begin
		Insert into DeductionSetting(GroupID,DeductionID,DeductedPercentage)
		select @GroupID,cast(t.val as tinyint),cast(p.val as float)
		from dbo.strsplit(@DeductionList, ',') t
			inner join dbo.strsplit(@DeductedPercentageList, ',') p on p.rank=t.rank    
			inner join DeductionType d with (nolock) on d.DTypeID=cast(t.val as tinyint)			 
		
		IF @@Rowcount<>(select count(1) from dbo.strsplit(@DeductionList, ',')) or @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			
			Select @ErrMsg = N'Error! Insert Deduction Setting unsuccessfully!', @ErrCode = 10032
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
					ROLLBACK TRANSACTION
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
						Insert into GroupSetting(GroupID,SportType,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
						values (@GroupID,@SportID,@i,@MinAmount,@MaxAmount,@MinQM,@MaxQM,@Commission)
						--Neu khong dong nao duoc insert thi Rollback <=> @@ROWCOUNT<>1 
						if(@@ROWCOUNT<>1)
						begin
							ROLLBACK TRANSACTION
							Select @ErrMsg = N'There was an error when inserting tier setting.', @ErrCode = 10037
							return		
						end 	
					end
					else
					begin
						ROLLBACK TRANSACTION
						Select @ErrMsg = N'Error! Invalid Setting Data(SportType=' + cast(@SportID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!', @ErrCode = 10037
						return		
					end  
				
					--Increase @i by 1 
					select @i=@i + 1                                   
				end --end inner while
							 
				select @rank=min(rank) from dbo.strsplit(@SportIDList, ';') where rank>@rank
			END TRY
			BEGIN CATCH
				ROLLBACK TRANSACTION
				Select @ErrMsg = ERROR_MESSAGE(), @ErrCode = 10034
				return	
			END CATCH
		end --end outer while
	end --end if
	else ---Invalid Setting Data
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'Error! Invalid Setting Data (SportIDList) !', @ErrCode = 10033
		return	
	end 			
	
	--Approved user if @IsApproved=1
	if(@IsApproved=1 and @GroupID>1000)
	begin
		exec dbo.[Aff_AffiliateUpdStatus]
			@AffID =@GroupID,
			@UserID =@UserId,
			@Status ='approved',	
			@Password=@Password,  
			@GroupID =@GroupID, 
			@IP =@IP, 
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
	   
		if(@ErrCode<>0)
		begin
			ROLLBACK TRANSACTION
			return
		end		
		
		Select @MailOption = MailOption From AffDetail with(nolock) where AffId = @GroupID-- Get relevant Email Format
	end
	else if(@GroupID>1000) --Assign Group for Affiliate if GroupID>1000
	begin
		update AffInfo with (rowlock,updlock)
		set GroupID=@GroupID
		where AffID=@GroupID
		
		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			Select @ErrMsg = N'Error! Assign group for Affiliate unsuccessfully!', @ErrCode = 10042
			return
		END
	end

	COMMIT TRANSACTION
	
	 --Write the log 
	DECLARE @LogData nvarchar(4000), @AffID int, @SPName varchar(100)
	
	if (@GroupID>1000)
	  select @AffID=@GroupID
	else
	  select @AffID=0  
	
	SELECT @LogData = N'Add a commission group.GroupID=' + dbo.Aff_ToString(@GroupID)
					  + '\n GroupName=' + dbo.Aff_ToString(@GroupName)
					  + '\n Description=' + dbo.Aff_ToString(@Description)
					  + '\n SportIDList=' + dbo.Aff_ToString(@SportIDList)
					  + '\n DeductionList=' + dbo.Aff_ToString(@DeductionList)
					   + '\n DeductedPercentageList=' + dbo.Aff_ToString(@DeductedPercentageList)
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
GRANT EXECUTE ON [dbo].[Aff_CommGroupIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupIns] TO [vnteam]
GO