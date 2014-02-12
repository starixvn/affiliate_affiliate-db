set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_PaymentRequestSelList]
    @Username			NVARCHAR(30)  = NULL,
    @Status				NVARCHAR(10)  = NULL,   
    @GetAll				bit = 0,
    @Currency			int = NULL,
    @Fromdate			DATETIME  = NULL,
    @Todate				DATETIME  = NULL,
	@PageSize			int=50,
	@PageIndex			int=1,
	@TotalPages			int=0 OUTPUT,
	@NRows				int=0 OUTPUT
AS 

/*
 Task : Get All Affiliate for a specific page
DB: 
Original: [Aff_BettransSelRequestPaymentList]
Revisions:   
	- 20130812@Joseph uncomment currency filters
Param's Explanation:
• @Username: Affiliate username need to search
• @Status : pending,Approved,disapproved
• @GetAll : Get all paymentrequest if @GetAll = 1
• @Fromdate :  default value=null :search all
• @Todate :  default value=null :search all
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search
• @NRows OUTPUT,--total of rows
 */
 SET NOCOUNT ON
DECLARE @RowStart int, @TransType int

select @TransType = 202 --payment request

select @Username= '%' + Coalesce(@Username, '') + '%' 

IF @GetAll = 1-- Search by Username or Search All
BEGIN
	Select @NRows=Count(1) 
	FROM     AffTrans b WITH (nolock)
		INNER JOIN AffInfo c WITH (nolock) ON b.AffId = c.AffId
	WHERE   TransType = @TransType
		AND c.Username like @Username
		and ISNULL(@Currency, c.Currency) = c.Currency
	
    if (isnull(@NRows,0)=0)
          return     
    select 	@TotalPages=ceiling (convert(float,@NRows,0)/@PageSize)
    select @RowStart=((@PageIndex-1)*@PageSize)

	Select Top(@PageSize) * 
	from
		(SELECT   
			RowID=ROW_NUMBER() OVER 
				(order by  CASE b.status
							WHEN 'Pending' THEN 1
							WHEN 'Approved' THEN 2
							WHEN 'Rejected' THEN 3
							ELSE 4
						END,transid desc),
			b.Transid,
			b.Transdate,
			b.AffId,
			b.Status,
			b.refId,             
			a.Username,
			e.Code as Currency,			
			abs(Amount) as amt,
			b.Completeddate,
			case when b.Status in ('Pending','Cancelled') and TransType=202 then a.UserName
                 when b.TransType=201  then 'System'				  
				  else admin.username
			end  as Creator
		FROM AffTrans b WITH (nolock)
			INNER JOIN AffInfo a WITH (nolock) ON b.AffId = a.AffId
			INNER join Exchange e with(nolock) on a.Currency = e.ExchangeID
			LEFT Join AdminUser admin on b.creator = admin.CustId
		WHERE TransType = @TransType--Payment request
			AND a.Username like @Username       
			and ISNULL(@Currency, a.Currency) = a.Currency              			 
		) A
	Where A.RowId > @RowStart
END
ELSE
BEGIN         
	Select @NRows=Count(1) 
    FROM     AffTrans b WITH (nolock)          
    WHERE    TransType = @TransType                         
             AND b.status = Coalesce(@Status,b.status)
			 AND b.TransDate between @fromdate and @todate

    select 	@TotalPages=ceiling (convert(float,isnull(@NRows,0))/@PageSize)
    if  (@TotalPages=0)
         return

	select @RowStart=((@PageIndex-1)*@PageSize)
		 
	Select Top(@PageSize) * 
	from
		(SELECT   
			RowID=ROW_NUMBER() OVER 
				(order by CASE b.status
							WHEN 'Pending' THEN 1
							WHEN 'Approved' THEN 2
							WHEN 'Rejected' THEN 3
							ELSE 4
						END, transid desc),
			b.transid,
			b.transdate,
			b.AffId,
			b.status,
			b.refId,             
			a.username,
			e.Code as Currency,			
			abs(Amount) as amt,
			b.completeddate,
			case when b.Status in ('Pending','Cancelled') and TransType=202 then a.UserName
                 when b.TransType=201  then 'System'				  
			      else admin.username
			end  as Creator
		FROM     AffTrans b WITH (nolock)
				 INNER JOIN AffInfo a WITH (nolock) ON b.AffId = a.AffId	 
				 inner join Exchange e with(nolock) on a.Currency = e.ExchangeID
				 LEFT JOIN AdminUser admin with (nolock) on admin.custid=b.creator
		WHERE    TransType = @TransType                         
				 AND b.status = Coalesce(@Status,b.status)
				 AND b.TransDate between @fromdate and @todate
		) A
	Where A.RowId > @RowStart
END


GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelList] TO [vnteam]
