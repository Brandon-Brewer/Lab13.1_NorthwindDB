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
	,DATEDIFF(dd,stat21dt,getdate()) as daysinprocess
	,CASE WHEN DATEDIFF(dd,stat21dt,getdate()) >= 90 THEN 1 ELSE 0 END AS '90 Day or older Flag' 
	,Escalation.StatusDescription 'Escalation Current Status'
	,CASE WHEN (PB.ProductBucket LIKE '%Conv%' AND PD.Product LIKE '%J%') THEN 1 ELSE 0 END AS 'Non-Agency Flg'

INTO #StartingPop

FROM QLODS..LKWD LKWD
       INNER JOIN QLODS..StatusDim SD ON LKWD.CurrentStatusID = SD.StatusID
       INNER JOIN QLODS..LoanPurposeDim LPD ON LKWD.LoanPurposeID = LPD.LoanPurposeID
       INNER JOIN QLODS.DBO.ProductDim PD ON LKWD.ProductID = PD.ProductID
       INNER JOIN Reporting.DBO.vwProductBuckets PB ON PB.ProductID = LKWD.ProductID
       INNER JOIN QLODS.DBO.LoanChannelGroupDim LCG ON LCG.LoanChannelGroupID = LKWD.LoanChannelGroupID
       
	   OUTER APPLY (

              SELECT TOP 1 SD3.StatusDescription

              FROM QLODS..LKWDTrackingItemFact LTIF3
                     INNER JOIN QLODS..LKWDTrackingItemStatusDim SD3 ON LTIF3.StatusID = SD3.StatusID 

              WHERE LTIF3.LoanNumber = LKWD.LoanNumber 
                     AND LTIF3.TrackingItemID = 7126 --TI 7631 Escalation Requested: Underwriting Review Needed 

              ORDER BY LTIF3.StatusDateTime DESC

       )Escalation 

WHERE LKWD.ReverseFlg = 0
       AND LKWD.DeleteFlg = 0 
       AND LKWD.ClosingID IS NULL --Haven't Closed
       AND LKWD.FalloutID IS NULL --Haven't Fallen Out
	   AND SD.StatusKey IN (33,35) --In process 
                           
                           
--------------------------------------------------------------------                     
IF OBJECT_ID('tempdb..#SusReason','U') IS NOT NULL
       DROP TABLE #SusReason

SELECT SP.*

INTO #PIPE

FROM #StartingPop SP

WHERE ISNULL(SP.[Escalation Current Status],'NULL') <> 'Confirmed'
      AND ISNULL(SP.LoanChannel,'NULL') NOT IN ('QLMS','Schwab')
      AND SP.[Non-Agency Flg] = 0       




------------------------
Select P.LoanNumber
	, SRD.ReasonText
	, SRDD.ReasonDetailText
	, COUNT(*) 'Suspenses'
FROM #PIPE P
       Inner Join QLODS..LKWDTransFact LTF ON LTF.LoanNumber = P.LoanNumber
       Inner Join QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
       Inner Join QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
       Inner Join QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID
              Where LTF.EventtypeID = 2 -- Status Change
                     AND LTF.StatusID = 117 -- Suspense
                           Group By P.LoanNumber, SRD.ReasonText, SRDD.ReasonDetailText
                                  Having COUNT(*) >= 3