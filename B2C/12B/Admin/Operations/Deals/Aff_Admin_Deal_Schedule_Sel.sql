/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_Deal_Schedule_Sel
AS
/*
      Created: 20250702@Lewis
      Task: Admin - Operation - Deal - Get schedule dropdown list for deal 
      DB: DBAFF12B-Affiliate_12B

      Revisions:
          - 20250702@Lewis: Init [RedmineID: #283530]
*/
BEGIN
    SET NOCOUNT ON;
    
    SELECT s.ScheduleID      AS ScheduleID,
           s.ScheduleName    AS ScheduleName
    FROM dbo.Schedule s WITH (NOLOCK)
    ORDER BY s.ScheduleID;
END;
GO
