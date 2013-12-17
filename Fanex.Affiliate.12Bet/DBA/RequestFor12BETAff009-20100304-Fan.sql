 /*
 Hi Peter
 
Please see below email if you can adjust 12BETAFF009 Feb2010 commission to 40%
 
Regards and Thanks
Fan

    -----Original Message-----
    From: Maggie Leow <leowmaggie@yahoo.com.sg>
    To: yang fan <Fan@pacificseainvests.com>
    Cc: jeff wong <jkmwo@hotmail.com>
    Date: Wed, 3 Mar 2010 16:49:27 +0800 (SGT)
    Subject: Fw: Fw: Fwd: Re: MSO issue

    Fan - pls talk to IT VN if they can adjust mso feb payout to 40%.
     
    Regards and thanks.
     
    From           :     Maggie Leow
    Skype         :      maggielah


    ----- Forwarded Message ----
    From: vivian chen <vivian2168@gmail.com>
    To: Maggie Leow <leowmaggie@yahoo.com.sg>
    Cc: peter tan choon soon <ptofjbmy@yahoo.com>; jeff wong <jkmwo@hotmail.com>
    Sent: Wednesday, 3 March 2010 4:47:31
    Subject: Re: Fw: Fwd: Re: MSO issue

    yes. please proceed.

    On Wed, Mar 3, 2010 at 4:14 PM, Maggie Leow < leowmaggie@yahoo.com.sg> wrote:

        Hi Vivian,

        MSO requested his commission to be fixed at 40% each month.

        If you have no objection we will adjust his payout to 40% in month Feb 2010.
         
        Regards and thanks.
         
        From           :     Maggie Leow
        Skype         :      maggielah


        ----- Forwarded Message ----
        From: Yang Fan <fan@pacificseainvests.com>
        To: "leowmaggie@yahoo.com.sg" <leowmaggie@yahoo.com.sg>
        Cc: "jkmwo@hotmail.com" <jkmwo@hotmail.com>
        Sent: Wednesday, 3 March 2010 1:38:36
        Subject: Fwd: Re: MSO issue

        Hi Maggie
         
        MSO wants fixed the rate to 40%, please advise.
         
        Regards and Thanks
        Fan

            -----Original Message-----
            From: "Yang Fan" <fan@pacificseainvests.com>
            To: "Maggie Leow" <leowmaggie@yahoo.com.sg>
            Cc: "jkmwo@hotmail.com" <jkmwo@hotmail.com>,
            Date: Mon, 01 Mar 2010 15:16:09 +0800
            Subject: Re: MSO issue

            Hi Maggie
             
            Jan2010 his Winlost is -$131,016.87 and his Total Qualified Active Players is 344, so we paid his rate is 40%.
            Please refer below table compare with Jan and Feb:
             
            Date 	Winlost 	Qualified players 	Rate 	Commission
            Jan2010 	-$131,016.87 	344 	40% 	$46,443.44
            Feb2010 	-$95,729.65 	326 	30% 	$25,928.87

             
            Regards and Thanks
            Fan

                -----Original Message-----
                From: Maggie Leow <leowmaggie@yahoo.com.sg>
                To: fan@pacificseainvests.com
                Cc: "jkmwo@hotmail.com" <jkmwo@hotmail.com>
                Date: Mon, 1 Mar 2010 14:47:32 +0800 (SGT)
                Subject: Re: MSO issue

                what was the rate we paid him in Jan


                Regards and thanks.
                 
                From           :     Maggie Leow
                Skype         :      maggielah


                From: Yang Fan <fan@pacificseainvests.com>
                To: "leowmaggie@yahoo.com.sg" <leowmaggie@yahoo.com.sg>
                Cc: "jkmwo@hotmail.com" <jkmwo@hotmail.com>
                Sent: Monday, 1 March 2010 2:30:52
                Subject: MSO issue

                Hi MAggie
                 
                MSO asking why his Feb commission will become 30%, I was told him because our new system follow the new tier. His Feb Winlost is -$95,809.65, therefor his commission is only 30%.
                But he didnt accept this deal, he said that we have agreement before, his commission at least 40%, please advise how can I answer him.
                 
                Regards and Thanks
                Fan
                
 */
 ---Solution
 declare @groupid int
 
 select @groupid=groupid
 from CommGroupHistory (nolock)
 where GroupName='CommGroup40' and MonthDate='2010-02-28'
 
 Insert into DeductionSettingHistory (groupid,monthdate,DeductionID)
 select @groupid,'2010-02-28',2
 union all 
 select @groupid,'2010-02-28',3
 union all 
 select @groupid,'2010-02-28',4
 
 update AffGroupHistory with (rowlock,updlock)
 
 set groupid=@groupid
 
 where MonthDate='2010-02-28'
     and AffID=(select top(1) AffID from AffInfo (nolock) where username='12BETAFF009')
 
 