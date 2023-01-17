/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="1" isNested="1"></info>*/  
CREATE FUNCTION [dbo].[Aff_f_IP_GetCountryCode]  
(  
 @IP VARCHAR(45)  
)  
RETURNS  VARCHAR(10)
/*  
 Created by: Malcolm  
 Date: 20220809  
 Task: Get IP Info   
 DB: DBAFF12BET/Affiliate_12BET  
  
 Revisions:   
  - 20220809@Malcolm: Get country code from IP [RedmineID: #176390]
  - 20220919@Eddie  : Alter function from 'f_IP_GetCountryCode' [RedmineID: #176390]
*/  
BEGIN
 DECLARE @Country_code VARCHAR(10), @IPFull VARCHAR(45), @IPvX TINYINT  
 DECLARE @v4IPKey TINYINT, @v4IPLong BIGINT, @v6KeyValue BINARY(2), @v6IPValue BINARY(16)  
  
 SELECT @IPFull  = fip.FullForm,  
   @IPVx  = CASE WHEN LEFT(@IPFull,24) = '00000000000000000000FFFF' THEN 4 ELSE 6 END,  
   @v4IPKey    = CASE @IPvX WHEN 4 THEN CONVERT(TINYINT, CONVERT(BINARY(1), SUBSTRING(@IPFull,25,2), 2)) END,  
   @v4IPLong   = CASE @IPvX WHEN 4 THEN CONVERT(BIGINT , CONVERT(BINARY(4), SUBSTRING(@IPFull,25,8), 2)) END,  
   @v6KeyValue = CASE @IPvX WHEN 6 THEN CONVERT(BINARY(2) , LEFT(@IPFull,4), 2) END,  
   @v6IPValue  = CASE @IPvX WHEN 6 THEN CONVERT(BINARY(16), @IPFull, 2) END  
 FROM dbo.f_IP_FullForm (@IP) fip  
  
 IF @IPVx = 4  
 BEGIN
  SELECT @Country_code = countrySHORT  
  FROM ipTable_mini WITH (NOLOCK)  
  WHERE ipKey = @v4IPKey  
   AND @v4IPLong BETWEEN ipFrom AND ipTo  
 END  
 ELSE IF @IPVx = 6  
 BEGIN  
  SELECT @Country_code = iptable.country_code --AS countrySHORT  
   FROM  
    dbo.KeyMap_IPv6_DB3 km WITH (NOLOCK)  
    INNER JOIN dbo.IPv6_DB3 iptable WITH (NOLOCK) ON km.ipKey = iptable.ipKey  
   WHERE  
    km.KeyValue = @v6KeyValue AND @v6IPValue BETWEEN iptable.ipFROM AND iptable.ipTO  
 END  
  
 RETURN @Country_code
END  
  