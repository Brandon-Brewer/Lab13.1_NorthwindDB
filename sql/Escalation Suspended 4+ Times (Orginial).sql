--********Report Loans Suspended 4 or more times*********--
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
,CASE WHEN DATEDIFF(dd,stat21dt,getdate()) >= 90 THEN 1 ELSE 0 END AS '90 Day or older Flag' 
--,EM.FullNameFirstLast 'Underwriter Assigned' 
--,EM.Jobtitle
--,EM.OpsDirector 
,Appraisal.StatusDescription 'Appraisal Current Status'
,Title.StatusDescription 'Title Current Status'
,Escalation.StatusDescription 'Escalation Current Status'
,CASE WHEN (PB.ProductBucket LIKE '%Conv%' AND PD.Product LIKE '%J%') THEN 1 ELSE 0 END AS 'Non-Agency Flg'
--,DATEADD(DAY,90,CAST(Stat21Dt AS Date)) '90DayDt'

INTO #StartingPop
FROM QLODS..LKWD LKWD
       INNER JOIN QLODS..StatusDim SD ON LKWD.CurrentStatusID = SD.StatusID
       INNER JOIN QLODS..LoanPurposeDim LPD ON LKWD.LoanPurposeID = LPD.LoanPurposeID
       INNER JOIN QLODS.DBO.ProductDim PD ON LKWD.ProductID = PD.ProductID
       INNER JOIN Reporting.DBO.vwProductBuckets PB ON PB.ProductID = LKWD.ProductID
       INNER JOIN QLODS.DBO.LoanChannelGroupDim LCG ON LCG.LoanChannelGroupID = LKWD.LoanChannelGroupID
       --INNER JOIN QLODS..EmployeeMaster EM ON LKWD.LoanUnderwriterID = EM.EmployeeDimID 

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

WHERE LKWD.ReverseFlg = 0
       AND LKWD.DeleteFlg = 0 
              --AND DATEDIFF(dd,stat21dt,getdate()) >= 90 --60 Days 
                     AND LKWD.ClosingID IS NULL --Haven't Closed
                           AND LKWD.FalloutID IS NULL --Haven't Fallen Out
                                  AND SD.StatusKey IN (33,35) --In process 
                           
                           
--------------------------------------------------------------------                     
IF OBJECT_ID('tempdb..#SuspenseCount','U') IS NOT NULL
       DROP TABLE #SuspenseCount

SELECT SUS.LoanNumber
       , MAX(SUS.SuspenseNumber) AS SuspenseCount
       , MAX(CASE WHEN SUS.SuspenseNumber = 4 THEN SUS.TransDtID END) AS FourthSuspenseDtID
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
,SC.FourthSuspenseDtID

INTO #Final
FROM #StartingPop SP
       LEFT JOIN #SuspenseCount SC ON SP.LoanNumber = SC.LoanNumber


WHERE 
SC.SuspenseCount >= 4
          AND ISNULL(SP.[Escalation Current Status],'NULL') <> 'Confirmed'
              AND ISNULL(SP.LoanChannel,'NULL') NOT IN ('QLMS','Schwab')
                     AND SP.[Non-Agency Flg] = 0       
       --AND SP.[Appraisal Current Status] LIKE '%Cleared%'
              --AND SP.[Title Current Status] LIKE '%Cleared%'

------------------------
SELECT *
FROM #Final
