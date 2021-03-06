-- This code is intended to create a report for client supplied document turn times.

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
Use BISandboxWrite
Go
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- The AdHocReportDateRange table holds int values of start and end dates
-- There is a table in the BISandboxWrite that stores DateIDs for my reporting
--DROP TABLE dbo.AdHocReportDateRange
--CREATE TABLE dbo.AdHocReportDateRange (
--ReportName VARCHAR(255) NULL,
--StartDateID INT NULL,
--EndDateID   INT NULL)
--INSERT INTO dbo.AdHocReportDateRange
--VALUES ('Client Documents', NULL, NULL)
UPDATE dbo.AdHocReportDateRange
SET 
	StartDateID = 20170501,
    EndDateID   = 20170531
WHERE 
	ReportName = 'Client Documents';

-- SELECT * FROM dbo.AdHocReportDateRange
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
DROP TABLE dbo.ClientDocuments, dbo.ClientDocsTrackingItemFact, dbo.ClientDocumentsOutApp;

/* This table is the rows of LKWDTrackingItemFact that have TrackingItemID=2903 (Tracking Item 2145, Documents received from client)
in status Cleared by Underwriter */
Create Table dbo.ClientDocsTrackingItemFact
      (
      LkwdTrackingItemFactID BigInt Not Null Primary Key Clustered,
      LoanNumber VarChar(15) Not Null,
      TrackingItemID int Not Null,
      StatusID int Not Null,
      PrevStatusID int,
      StatusDateTime DateTime Not Null,
      StatusDtID int Not Null,
      StatusUserID int Not Null
      );
      
-- This table 
Create Table dbo.ClientDocumentsOutApp
      (
      -- LoanNumber VarChar(15) Not Null Primary Key, -- not unique in above table
      ClientDocsTrackingItemFactID BigInt Not Null Primary Key Clustered,
      OutstandingStatusDateTime DateTime Not Null, 
	  OutstandingStatusDateID int not null
      );


-----------------------------------------------------------------------------
/* We grab the LKWDTrackingItemFact data where the Client Docs tracking item was Cleared by UW
 110k rows per month, 14 seconds on DWReadOnlyServer */
Insert Into dbo.ClientDocsTrackingItemFact
      (
      LkwdTrackingItemFactID, LoanNumber, TrackingItemID, 
      StatusID, PrevStatusID, StatusDateTime, StatusDtID, StatusUserID
      )
Select
      ltif.LkwdTrackingItemFactID, ltif.LoanNumber, ltif.TrackingItemID,
      ltif.StatusID, ltif.PrevStatusID, ltif.StatusDateTime, ltif.StatusDtID, ltif.StatusUserID
-- Into #dbo.ClientDocsTrackingItemFact
From
      dbo.AdHocReportDateRange dtRange With(nolock) --Contains the date range
      Join QLODS.dbo.LKWDTrackingItemFact ltif With(nolock)
            On ltif.StatusDtID between dtRange.StartDateID And dtRange.EndDateID
Where
      dtRange.ReportName = 'Client Documents'
      And ltif.TrackingItemID = 2903 -- #2145, Documents received from client
      And ltif.DeleteFlg = 0
      And ltif.StatusID = 67 --Cleared by UW
      And ltif.PrevStatusID != 67; --If we have a cleared followed by another cleared, the second one does not count.


/* ---------------------------------------------------------------------------
 We now get the datetime of the oldest Outstanding before each Cleared by UW.
 The way this is done may not be obvious right away.
 For each TI 2145 Cleared status we join the Outstandings that happened before it.
 These Outstandings must have a previous status of Cleared (or "-" Dash which means it's the first real status)
 Then we find the most recent (max) of those Outstandings. 
 This is now the slow step, as it can't filter by date.
 15 minutes */

Insert Into ClientDocumentsOutApp (ClientDocsTrackingItemFactID, OutstandingStatusDateTime, OutstandingStatusDateID)
Select
      -- ltif2.LoanNumber As LoanNumber,
      ltif.LkwdTrackingItemFactID,
      Max(ltif2.StatusDateTime) As OutstandingStatusDateTime , --Max means the most recent Oustanding before the Cleared
	  Max(ltif2.Statusdtid) As OutstandingStatusDateID --Max means the most recent Oustanding before the Cleared

From
      ClientDocsTrackingItemFact ltif With(nolock) --Contains dates only for Cleared
      Join QLODS.dbo.LKWDTrackingItemFact ltif2 With(nolock) 
            On ltif.LoanNumber = ltif2.LoanNumber
            And ltif2.StatusDateTime <= ltif.StatusDateTime --Must be an Outstanding before a Cleared
Where
      ltif2.TrackingItemID = 2903
      And ltif2.StatusID = 11 --Outstanding
      And ltif2.PrevStatusID in (1, 67) -- Previous status "-" or Cleared by UW
Group By ltif.LkwdTrackingItemFactID; -- ltif2.LoanNumber;


-----------------------------------------------------------------------------
-- Create the ClientDocuments table.
-- Each row of this table gives a turn time from oldest Outstanding to Cleared.
-- It also includes information on product, purpose, channel, and underwriter.

Declare @Start int = (Select StartDateID From dbo.AdHocReportDateRange Where ReportName = 'Client Documents');
Declare @End int = (Select EndDateID From dbo.AdHocReportDateRange Where ReportName = 'Client Documents');

SELECT 
      ltif.LoanNumber as LoanNumber
      , ltid.TrackingItem as TrackingItem
      , ltid.TrackingItemDesc as TrackingItemDesc
      , ltisd.StatusDescription as StatusDescription
      , ltif.PrevStatusID as PrevStatusID
      , ltif.StatusDateTime as StatusDateTime
      , ltif.StatusDtID as StatusDtID
      , lkwd.ComputedLoanAmount as LoanAmount
      , pd.ProductDescription as ProductDescription
      , pd.ProductBucket as ProductBucket
      , case when lpd.LoanPurpose like 'Refinance' then 'Refinance' else 'Purchase' end as RefiORPurchase
      , lcgd.FriendlyName as LoanChannel
      , case when lcgd.FriendlyName like 'Schwab' then 'Schwab' else
      case when lcgd.FriendlyName like 'QLMS' OR lcgd.FriendlyName like 'Correspondent' then 'QLMS' else
      case when lcgd.FriendlyName like '%ame Servicer%' then 'Howling Wolf' else 'Forward' end end end as ChannelBucket
      , ltif.StatusUserID as StatusUserID
      , em.CommonID as ClearedCommonID
      , em.FullNameFirstLast as ClearedUW
      , em.JobTitle as ClearedJobTitle
      , em.OpsDVP as ClearedOpsDVP
      , em.OpsDirector as ClearedOpsDirector
      , outapp.OutstandingStatusDateTime
      , outapp.OutstandingStatusDateID
      
	  , DATEDIFF(MINUTE, outapp.OutstandingStatusDateTime, ltif.StatusDateTime) as [Minutes]
      , DATEDIFF(MINUTE, outapp.OutstandingStatusDateTime, ltif.StatusDateTime) / 60.0 / 24.0 as [Calendar Days]
      ,[BISandboxWrite].[dbo].[fn_GetBusinessDaysByDateNoSundays](outapp.OutstandingStatusDateTime, ltif.StatusDateTime) as [Business Days]
	  ,DATEPART(dw,ltif.StatusDateTime) [DayOfWeek]-- sunday is 1 
	  ,case 
		when DATEPART(dw,ltif.StatusDateTime) = 1 
		then (DATEDIFF(MINUTE, outapp.OutstandingStatusDateTime, ltif.StatusDateTime) / 60.0 / 24.0 )
	    else [BISandboxWrite].[dbo].[fn_GetBusinessDaysByDateNoSundays](outapp.OutstandingStatusDateTime, ltif.StatusDateTime)
	  end as  [Days]

	  --, DATEDIFF(DAY, outapp.OutstandingStatusDateTime, ltif.StatusDateTime) as [DaysV2]
	  --, DD.BankHolidayFlg
	  --,dd.HolidayFlg
	  --,dd.DayOfWeekKey
	  --,case when (dd.DayOfWeekKey = 1 or 
  

	  , Associate.StatusDescription as [4744CurrentStatus]
      , case when Associate.StatusDescription like 'Outstanding' then 'Y' else 'N' end as AssociateFlag
INTO dbo.ClientDocuments
From 
      ClientDocsTrackingItemFact ltif with (nolock)
      Left Join ClientDocumentsOutApp outapp with (nolock) On ltif.LkwdTrackingItemFactID = outapp.ClientDocsTrackingItemFactID
      Join QLODS.dbo.LKWD lkwd with (nolock) ON lkwd.LoanNumber = ltif.LoanNumber
      Join Reporting.dbo.vwProductBuckets pd with (nolock) ON pd.ProductID = lkwd.ProductID
      Join QLODS.dbo.LoanPurposeDim lpd with (nolock) ON lpd.LoanPurposeID = lkwd.LoanPurposeID
      Join QLODS.dbo.LoanChannelGroupDim lcgd with (nolock) ON lcgd.LoanChannelGroupID = lkwd.LoanChannelGroupID
      Join QLODS.dbo.LKWDTrackingItemDim ltid with (nolock) ON ltif.TrackingItemID = ltid.TrackingItemID
      Join QLODS.dbo.EmployeeMaster em with (nolock) ON em.EmployeeDimID = ltif.StatusUserID
      Join QLODS.dbo.LKWDTrackingItemStatusDim ltisd with (nolock) ON ltisd.StatusID = ltif.StatusID
	  left join qlods..datedim DD on dd.DateID = ltif.StatusDtID
		
  --Get current status of tracking item 4744 (associate eligible loan)
  LEFT JOIN (Select LoanNumber, StatusDateTime, ltisd.StatusDescription as StatusDescription, TrackingItemID as TrackingItemID, StatusDtId, TrackingSeqNum,
                ROW_NUMBER() OVER (PARTITION BY ltif.LoanNumber ORDER BY TrackingSeqNum DESC, ltif.StatusDateTime DESC) as [Rank]
              FROM QLODS.dbo.LKWDTrackingItemFact as ltif WITH(NOLOCK)
                INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim as ltisd WITH (NOLOCK)
                  ON ltif.StatusID = ltisd.StatusID
              WHERE ltif.TrackingItemID = 4476 AND StatusDtID between @Start and @End
             ) as Associate
    on lkwd.LoanNumber = Associate.LoanNumber
Where
      lkwd.DeleteFlg = 0
      And pd.ProductBucket not like 'ORM'
      And (Associate.Rank = 1 OR Associate.Rank is NULL);

select * from dbo.ClientDocuments

--select Reporting.dbo.fn_getbusinessdays('2017-04-02 9:34:00.00', '2017-04-01 11:19:00.00') 
--select getdate()
--SELECT DATEPART(dw,GETDATE()) -- sunday is 1 

-- Update the table with the UW assigned to the loan.
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Update the table with the UW assigned to the loan.

ALTER TABLE dbo.ClientDocuments
Add AssignedOpsDirector varchar(255) NULL,
AssignedOpsDVP varchar(255) NULL,
AssignedUW varchar(255) NULL,
AssignedCommonID int NULL,
FullUW int NULL,
AssociateUW int NULL;

UPDATE dbo.ClientDocuments
Set AssociateUW = em.CommonID
FROM dbo.ClientDocuments cd
INNER JOIN QLODS.dbo.LKWD lkwd
  ON lkwd.LoanNumber = cd.LoanNumber
INNER JOIN QLODS.dbo.EmployeeMaster em
  ON lkwd.AssociateUnderwriterID = em.EmployeeDimID

UPDATE dbo.ClientDocuments 
Set FullUW = em.CommonID
FROM dbo.ClientDocuments cd
INNER JOIN QLODS.dbo.LKWD lkwd
  ON lkwd.LoanNumber = cd.LoanNumber
Left JOIN QLODS.dbo.EmployeeMaster em
  ON lkwd.LoanUnderwriterID = em.EmployeeDimID
  
UPDATE dbo.ClientDocuments
Set AssignedCommonID = case when FullUW IS NOT NULL AND FullUW <> 1 then FullUW else AssociateUW end
FROM dbo.ClientDocuments

UPDATE dbo.ClientDocuments 
Set AssignedOpsDVP = em.OpsDVP,
AssignedOpsDirector = em.OpsDirector,
AssignedUW = em.FullNameFirstLast
FROM BISandBoxWrite.dbo.ClientDocuments cd
  INNER JOIN QLODS.dbo.EmployeeMaster em
    ON cd.AssignedCommonID = em.CommonID


select *
from dbo.ClientDocuments


Drop Table dbo.ClientDocsTrackingItemFact, dbo.ClientDocumentsOutApp;





/* STEP FOUR FROM CONTINUITY GUIDE

DROP FUNCTION dbo.medianproduct
DROP FUNCTION dbo.medianchannel
DROP FUNCTION dbo.medianpurpose
DROP FUNCTION dbo.medianAssigned
DROP FUNCTION dbo.medianCleared
DROP FUNCTION dbo.medianAssignedDirector
DROP FUNCTION dbo.medianClearedDirector
DROP FUNCTION dbo.medianAssignedDVP
DROP FUNCTION dbo.medianClearedDVP
DROP FUNCTION dbo.median
*/

/*
CREATE FUNCTION dbo.medianproduct (@rop varchar(9), @pb varchar(255), @af varchar(255), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @rop like cd.RefiORPurchase
            AND @pb like cd.ProductBucket
            AND @af like cd.AssociateFlag
            AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @rop like cd.RefiORPurchase
            AND @pb like cd.ProductBucket
            AND @af like cd.AssociateFlag
            AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianchannel (@rop varchar(9), @cb varchar(255), @af varchar(255), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @rop like cd.RefiORPurchase
            AND @cb like cd.ChannelBucket
            AND @af like cd.AssociateFlag
            AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @rop like cd.RefiORPurchase
            AND @cb like cd.ChannelBucket
            AND @af like cd.AssociateFlag
            AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianpurpose (@rop varchar(9), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @rop like cd.RefiORPurchase
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @rop like cd.RefiORPurchase
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianAssigned (@UW varchar(32), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.AssignedUW
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.AssignedUW
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianCleared (@UW varchar(32), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.ClearedUW
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.ClearedUW
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianAssignedDirector (@UW varchar(32), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.AssignedOpsDirector
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.AssignedOpsDirector
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianClearedDirector (@UW varchar(32), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.ClearedOpsDirector
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.ClearedOpsDirector
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianAssignedDVP (@UW varchar(32), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.AssignedOpsDVP
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.AssignedOpsDVP
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.medianClearedDVP (@UW varchar(32), @Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.ClearedOpsDVP
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where @UW like cd.ClearedOpsDVP
          AND cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

CREATE FUNCTION dbo.median (@Quartile int, @StartDate int, @EndDate int)
  RETURNS float
  as
  Begin
  RETURN
  (
    Select (      
      (Select Top 1 A.[Days]
       From   
         (Select  Top (@Quartile*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days
         ) As A
       Order By A.Days DESC
      ) 
      + 
      (Select Top 1 A.Days
       From 
         (Select  Top ((4-@Quartile)*25) Percent cd.Days
          From    dbo.ClientDocuments cd
          Where cd.StatusDtID between @StartDate and @EndDate
          Order By cd.Days DESC
         ) As A
       Order By A.Days Asc
      )
    ) / 2 
  ) 
end

GO
*/

-------------------------------------------------------------------------
select *
from dbo.ClientDocuments cd
-------------------------------------------------------------------------

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
USE BISandboxWrite

--DECLARE @Start int = (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents');
--DECLARE @End int = (SELECT EndDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents');

------------------------Assigned Underwriter-----------------------------------------
SELECT cd.AssignedOpsDVP, cd.AssignedOpsDirector, cd.AssignedCommonID, cd.AssignedUW
, COUNT(Distinct cd.LoanNumber) as [Loan Count], COUNT (cd.LoanNumber) as [TI Count], AVG(cd.[Days]) as Average
--, dbo.medianUW(cd.Underwriter,1,@StartDate,@EndDate) as Quartile1
, dbo.medianAssigned(cd.AssignedUW,2
                     ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ) as Median
--, dbo.medianUW(cd.Underwriter,3,@StartDate,@EndDate) as Quartile3

FROM dbo.ClientDocuments cd

WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.AssignedOpsDVP, cd.AssignedOpsDirector, cd.AssignedUW, cd.AssignedCommonID
ORDER BY cd.AssignedOpsDVP, cd.AssignedOpsDirector, cd.AssignedUW, cd.AssignedCommonID

------------------------Cleared Underwriter-----------------------------------------
SELECT cd.ClearedOpsDVP, cd.ClearedOpsDirector, cd.ClearedCommonID, cd.ClearedUW
, COUNT(Distinct cd.LoanNumber) as [Loan Count], COUNT (cd.LoanNumber) as [TI Count], AVG(cd.[Days]) as Average
--, dbo.medianUW(cd.Underwriter,1,@StartDate,@EndDate) as Quartile1
, dbo.medianCleared(cd.ClearedUW,2
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Median
--, dbo.medianUW(cd.Underwriter,3,@StartDate,@EndDate) as Quartile3

FROM dbo.ClientDocuments cd

WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.ClearedOpsDVP, cd.ClearedOpsDirector, cd.ClearedUW, cd.ClearedCommonID
ORDER BY cd.ClearedOpsDVP, cd.ClearedOpsDirector, cd.ClearedUW, cd.ClearedCommonID

-----------------------Assigned Director------------------------------------------
SELECT cd.AssignedOpsDVP, cd.AssignedOpsDirector
, COUNT(Distinct cd.LoanNumber) as [Loan Count], COUNT (cd.LoanNumber) as [TI Count], AVG(cd.[Days]) as Average
--, dbo.medianUW(cd.Underwriter,1,@StartDate,@EndDate) as Quartile1
, dbo.medianAssignedDirector(cd.AssignedOpsDirector,2
                             ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                             ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                            ) as Median
--, dbo.medianUW(cd.Underwriter,3,@StartDate,@EndDate) as Quartile3

FROM dbo.ClientDocuments cd
WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.AssignedOpsDVP, cd.AssignedOpsDirector
ORDER BY cd.AssignedOpsDVP, cd.AssignedOpsDirector

-------------------------Cleared Director------------------------------------------------------------------------------
SELECT cd.ClearedOpsDVP, cd.ClearedOpsDirector
, COUNT(Distinct cd.LoanNumber) as [Loan Count], COUNT (cd.LoanNumber) as [TI Count], AVG(cd.[Days]) as Average
--, dbo.medianUW(cd.Underwriter,1,@StartDate,@EndDate) as Quartile1
, dbo.medianClearedDirector(cd.ClearedOpsDirector,2
                            ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                            ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                           ) as Median
--, dbo.medianUW(cd.Underwriter,3,@StartDate,@EndDate) as Quartile3

FROM dbo.ClientDocuments cd
WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.ClearedOpsDVP, cd.ClearedOpsDirector
ORDER BY cd.ClearedOpsDVP, cd.ClearedOpsDirector

--------------------------Assigned DVP-----------------------------------------------------------------------------
SELECT cd.AssignedOpsDVP
, COUNT(Distinct cd.LoanNumber) as [Loan Count], COUNT (cd.LoanNumber) as [TI Count], AVG(cd.[Days]) as Average
--, dbo.medianUW(cd.Underwriter,1,@StartDate,@EndDate) as Quartile1
, dbo.medianAssignedDVP(cd.AssignedOpsDVP,2
                        ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                        ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                       ) as Median
--, dbo.medianUW(cd.Underwriter,3,@StartDate,@EndDate) as Quartile3

FROM dbo.ClientDocuments cd
WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.AssignedOpsDVP
ORDER BY cd.AssignedOpsDVP

---------------------------Cleared DVP----------------------------------------------------------------------------
SELECT cd.ClearedOpsDVP
, COUNT(Distinct cd.LoanNumber) as [Loan Count], COUNT (cd.LoanNumber) as [TI Count], AVG(cd.[Days]) as Average
--, dbo.medianUW(cd.Underwriter,1,@StartDate,@EndDate) as Quartile1
, dbo.medianClearedDVP(cd.ClearedOpsDVP,2
                       ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                       ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                      ) as Median
--, dbo.medianUW(cd.Underwriter,3,@StartDate,@EndDate) as Quartile3

FROM dbo.ClientDocuments cd
WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.ClearedOpsDVP
ORDER BY cd.ClearedOpsDVP


---------------------------Total----------------------------------------------------------------------------
SELECT
COUNT(Distinct cd.LoanNumber) as [Loan Count]
, COUNT (cd.LoanNumber) as [TI Count]
, AVG(cd.[Days]) as Average
, dbo.median(1
             ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
             ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
            ) as Quartile1
, dbo.median(2
             ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
             ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
            ) as Median
, dbo.median(3
             ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
             ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
            ) as Quartile3

FROM dbo.ClientDocuments cd

WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between 
                    (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                     AND
                    (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')


---------------------------Purpose----------------------------------------------------------------------------
SELECT cd.RefiORPurchase
, COUNT(Distinct cd.LoanNumber) as [Loan Count]
, COUNT (cd.LoanNumber) as [TI Count]
, AVG(cd.[Days]) as Average
, dbo.medianpurpose(cd.RefiORPurchase,1
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Quartile1
, dbo.medianpurpose(cd.RefiORPurchase,2
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Median
, dbo.medianpurpose(cd.RefiORPurchase,3
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Quartile3

FROM dbo.ClientDocuments cd

WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between
                     (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                      AND
                     (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.RefiORPurchase
ORDER BY RefiORPurchase

------------------------Channels-----------------------------------------
SELECT cd.RefiORPurchase, cd.ChannelBucket, cd.AssociateFlag
, case when cd.AssociateFlag='Y' then 'Associate ' else 'Full ' end + cd.RefiORPurchase+' '+cd.ChannelBucket
, COUNT(Distinct cd.LoanNumber) as [Loan Count]
, COUNT(cd.LoanNumber) as [TI Count]
, AVG(cd.[Days]) as Average
, dbo.medianchannel(cd.RefiORPurchase, cd.ChannelBucket, cd.AssociateFlag,1
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Quartile1
, dbo.medianchannel(cd.RefiORPurchase, cd.ChannelBucket, cd.AssociateFlag,2
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Median
, dbo.medianchannel(cd.RefiORPurchase, cd.ChannelBucket, cd.AssociateFlag,3
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Quartile3

FROM dbo.ClientDocuments cd

WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between 
                     (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                      AND
                     (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.AssociateFlag, cd.RefiORPurchase, cd.ChannelBucket
ORDER BY cd.AssociateFlag, cd.RefiORPurchase, cd.ChannelBucket

------------------------Products-----------------------------------------
SELECT cd.RefiORPurchase, cd.ProductBucket, cd.AssociateFlag
, case when cd.AssociateFlag='Y' then 'Associate ' else 'Full ' end + cd.RefiORPurchase+' '+cd.ProductBucket
, COUNT(Distinct cd.LoanNumber) as [Loan Count]
, COUNT (cd.LoanNumber) as [TI Count]
, AVG(cd.[Days]) as Average
--Excel does not allow variables to be declared so these are start and end dates from a table.
, dbo.medianproduct(cd.RefiORPurchase, cd.ProductBucket, cd.AssociateFlag,1
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents') 
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Quartile1
, dbo.medianproduct(cd.RefiORPurchase, cd.ProductBucket, cd.AssociateFlag,2
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Median
, dbo.medianproduct(cd.RefiORPurchase, cd.ProductBucket, cd.AssociateFlag,3
                    ,(SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                    ,(SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                   ) as Quartile3

FROM dbo.ClientDocuments cd

WHERE                       --cd.RefiORPurchase = 'Purchase' AND cd.ProductBucket = 'VA'
cd.StatusDtID between 
                     (SELECT StartDateID FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')
                      AND
                     (SELECT  EndDateID  FROM dbo.AdHocReportDateRange WHERE ReportName = 'Client Documents')

GROUP BY cd.AssociateFlag, cd.RefiORPurchase, cd.ProductBucket
ORDER BY cd.AssociateFlag, cd.RefiORPurchase, cd.ProductBucket





