set nocount on

--***************Loans aging 75 days or more with the Title and Appraisal cleared**************
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#StartingPop','U') IS NOT NULL
       DROP TABLE #StartingPop

SELECT LKWD.LoanNumber
,SD.StatusFullDesc 'Current Status'
,LPD.LoanPurpose 
,PD.Product 
,PB.ProductBucket
,LCG.FriendlyName 'LoanChannel'
,LKWD.Stat21Dt
--,LKWD.IsNewYorkCemaFlg 'CEMA Flg'
--,LKWD.SubordinationFlg
,DATEDIFF(dd,stat21dt,getdate()) as daysinprocess
,CASE WHEN DATEDIFF(dd,stat21dt,getdate()) >= 60 THEN 1 ELSE 0 END AS '60 Day or older Flag' --Changed to 75 from 90 days
--,EM.FullNameFirstLast 'Underwriter Assigned' 
--,EM.Jobtitle
--,EM.OpsDirector 
,Appraisal.StatusDescription 'Appraisal Current Status'
,Title.StatusDescription 'Title Current Status'
,Escalation.StatusDescription 'Escalation Current Status'
,CASE WHEN (PB.ProductBucket LIKE '%Conv%' AND PD.Product LIKE '%J%') THEN 1 ELSE 0 END AS 'Non-Agency Flg'
--,DATEADD(DAY,90,CAST(Stat21Dt AS Date)) '90DayDt'
, [Underwriter] = [und].[Preferredname] + ' ' + [und].[Preferredlastname]
, [Underwriter FSO] = [undFSO].[Preferredname] + ' ' + [undFSO].[Preferredlastname]
, 'Loan Underwriter Escalation' = [Loan Underwriter Escalation_FullNameFirstLast]
, 'Loan Underwriter FSO Escalation' = [Loan Underwriter FSO Escalation_FullNameFirstLast]
, lkwd.LockExpireDt
, [gd].[State] 


INTO #StartingPop
FROM QLODS..LKWD LKWD
       INNER JOIN QLODS..StatusDim SD ON LKWD.CurrentStatusID = SD.StatusID
       INNER JOIN QLODS..LoanPurposeDim LPD ON LKWD.LoanPurposeID = LPD.LoanPurposeID
       INNER JOIN QLODS.DBO.ProductDim PD ON LKWD.ProductID = PD.ProductID
       INNER JOIN Reporting.DBO.vwProductBuckets PB ON PB.ProductID = LKWD.ProductID
       INNER JOIN QLODS.DBO.LoanChannelGroupDim LCG ON LCG.LoanChannelGroupID = LKWD.LoanChannelGroupID
       --INNER JOIN QLODS..EmployeeMaster EM ON LKWD.LoanUnderwriterID = EM.EmployeeDimID 
    LEFT JOIN QLODS.dbo.LKWDCapitalMarkets AS lcap WITH(NOLOCK) ON lcap.LoanNumber = LKWD.LoanNumber   
    LEFT JOIN QLODS.dbo.GeographyDim AS gd WITH(NOLOCK) ON gd.GeographyID = CASE WHEN LKWD.PropertyGeographyID = -1 THEN ISNULL(lcap.GeographyID,-1) ELSE LKWD.PropertyGeographyID END   
 
       OUTER APPLY (

              SELECT TOP 1 SD.StatusDescription

              FROM QLODS..LKWDTrackingItemFact LTIF 
                     INNER JOIN QLODS..LKWDTrackingItemStatusDim SD ON LTIF.StatusID = SD.StatusID 

              WHERE LTIF.LoanNumber = LKWD.LoanNumber 
                     AND LTIF.TrackingItemID = 161 --TI 327 *Appraisal
                           --AND SD.StatusID = 67 

              ORDER BY LTIF.StatusDateTime DESC


       )Appraisal 

              OUTER APPLY (

              SELECT TOP 1 SD2.StatusDescription

              FROM QLODS..LKWDTrackingItemFact LTIF2
                     INNER JOIN QLODS..LKWDTrackingItemStatusDim SD2 ON LTIF2.StatusID = SD2.StatusID 

              WHERE LTIF2.LoanNumber = LKWD.LoanNumber 
                     AND LTIF2.TrackingItemID = 2133 --TI 1374 Title needs to be Reviewed
                           --AND SD2.StatusID = 67 

              ORDER BY LTIF2.StatusDateTime DESC

       )Title

       
       OUTER APPLY (

              SELECT TOP 1 SD3.StatusDescription

              FROM QLODS..LKWDTrackingItemFact LTIF3
                     INNER JOIN QLODS..LKWDTrackingItemStatusDim SD3 ON LTIF3.StatusID = SD3.StatusID 

              WHERE LTIF3.LoanNumber = LKWD.LoanNumber 
                     AND LTIF3.TrackingItemID = 7126 --TI 7631 Escalation Requested: Underwriting Review Needed 
                           --AND SD2.StatusID = 67 

              ORDER BY LTIF3.StatusDateTime DESC

       )Escalation 





OUTER APPLY  (   
   SELECT TOP 1 *   
   FROM QLODS..EmployeeMaster em (NOLOCK)   
   WHERE LKWD.LoanUnderwriterID = em.EmployeeDimID   
    ) und

OUTER APPLY  (   
   SELECT TOP 1 *   
   FROM QLODS..EmployeeMaster em (NOLOCK)   
   WHERE lkwd.LoanUnderwriterFinalSignOffID = em.EmployeeDimID   
    ) undFSO 


 

OUTER APPLY  (--CNA Dimensional
    SELECT  TOP 1   --Add new contact types here (name and id) and below in the PIVOT, then add ref in view SELECT
      'Loan Underwriter FSO Escalation_FullNameFirstLast'           = [Loan Underwriter FSO Escalation_FullNameFirstLast]
     , 'Loan Underwriter Escalation_FullNameFirstLast'               = [Loan Underwriter Escalation_FullNameFirstLast]
     
    FROM (
      SELECT 
       'cname' = ContactType + '_' + Attributes
       , AttributeValue
      FROM BILoan.Contact.ContactTypeDim ctd
       CROSS APPLY (
         SELECT TOP 1
           em.FullNameFirstLast
           ,'CommonID'             = CAST(tm.CommonID AS VARCHAR(61))
         FROM [BILoan].[Contact].[InternalLoanContactFact] f
         JOIN BICommon.TeamMember.TeamMemberDim 
         tm      ON tm.TeamMemberID = f.TeamMemberDimID
         JOIN QLODS.dbo.EmployeeMaster 
         em      ON em.CommonID = tm.CommonID
         WHERE f.LoanNumber = LKWD.LoanNumber 
           AND f.EndDateID = 21990101  --still open
           AND f.RemovedContactFlg = 0
           AND f.ContactTypeDimID = ctd.ContactTypeDimID
      ) contact
      UNPIVOT 
       (
        AttributeValue FOR Attributes IN (FullNameFirstLast, CommonID)--add more attributes here and below
       )
      PVP
     ) up
     PIVOT (
      MAX(AttributeValue) --will be only one
      FOR cname
      IN (--Add new contact types here and above in the Outer Apply SELECT, then add ref in view SELECT
         [Loan Underwriter FSO Escalation_FullNameFirstLast]       , [Loan Underwriter FSO Escalation_CommonID]
        , [Loan Underwriter Escalation_FullNameFirstLast]       , [Loan Underwriter Escalation_CommonID]
        
       )
     ) contactT
    ) cnad --CNA Dimensional


WHERE LKWD.ReverseFlg = 0
       AND LKWD.DeleteFlg = 0 
              AND DATEDIFF(dd,stat21dt,getdate()) >= 60 --60 Days.  Was 90 days, changed to 75 days, changed to 60 days. 
                     AND LKWD.ClosingID IS NULL --Haven't Closed
                           AND LKWD.FalloutID IS NULL --Haven't Fallen Out
                                  AND SD.StatusKey IN (33,35) --In process 
                           
                           
--------------------------------------------------------------------                     
IF OBJECT_ID('tempdb..#SuspenseCount','U') IS NOT NULL
       DROP TABLE #SuspenseCount

SELECT SUS.LoanNumber
       , MAX(SUS.SuspenseNumber) AS SuspenseCount
       --, MAX(CASE WHEN SUS.SuspenseNumber = 4 THEN SUS.TransDtID END) AS FourthSuspenseDtID
INTO #SuspenseCount
FROM (
              SELECT SP.LoanNumber
                     , LTF.TransDtID
                     , LTF.TransTmID
                     , SuspenseNumber           = CASE WHEN LTF.TransDtID IS NULL THEN 0
                                                                           ELSE ROW_NUMBER() OVER(PARTITION BY SP.LoanNumber ORDER BY LTF.TransDtID ASC, LTF.TransTmID ASC)
                                                                           END
              
              FROM #StartingPop SP
                        LEFT JOIN QLODS..LKWDTransFact LTF ON SP.LoanNumber = LTF.LoanNumber
                                  AND LTF.EventTypeID = 2 --StatusChange
                                  AND LTF.DeleteFlg = 0
                                  AND LTF.StatusID = 117 -- Status 33: Suspended
       ) SUS
GROUP BY SUS.LoanNumber

----------------------------------------------------------           
IF OBJECT_ID('tempdb..#Final','U') IS NOT NULL
       DROP TABLE #Final

SELECT SP.*
,SC.SuspenseCount
--,SC.FourthSuspenseDtID
, case when TICF.LoanNumber is null then 'FALSE' else 'TRUE' end as 'SCUpdated?'
 
INTO #Final
FROM #StartingPop SP
       LEFT JOIN #SuspenseCount SC ON SP.LoanNumber = SC.LoanNumber
    LEFT JOIN  qlods..TrackingItemCurrentStatusFact TICF on TICF.loannumber = SP.loannumber 
         and TICF.TrackingItemID = 884 --Suspense Condition - Provide detail* 
         and TICF.statusid in (28,30) --28 = Used Recommended Solution, 30 Used My Own Solution 


WHERE 
--SC.SuspenseCount >= 4
           ISNULL(SP.[Escalation Current Status],'NULL') <> 'Confirmed'
              AND ISNULL(SP.LoanChannel,'NULL') NOT IN ('QLMS','Schwab')
                     AND SP.[Non-Agency Flg] = 0       
       AND SP.[Appraisal Current Status] LIKE '%Cleared%'
              AND SP.[Title Current Status] LIKE '%Cleared%'

------------------------
SELECT *
FROM #Final
ORDER BY daysinprocess desc