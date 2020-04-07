DECLARE @State INT


/***** 1 *****/
/* Pull all loans in the First 48 Pilot, i.e. where Tracking item 8152 is not null */
IF OBJECT_ID('tempdb..#Pilot','U') IS NOT NULL
	DROP TABLE #Pilot

/* This part of the query waits 30 seconds if the database in DWReadOnlyServer is restoring for a seemless run */
SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT [Loan Number]								= TICSF.LoanNumber
	, [Current Status]								= SD.StatusFullDesc
	, [Current Status Date]							= LK.CurrStatDt
	, [Days in Current Status]						= DATEDIFF(SECOND, LK.CurrStatDt, GETDATE())/86400.0
	, [Status 21]									= LK.Stat21Dt
	, [Status 33]									= LK.Stat33Dt
	, [Status 35]									= LK.Stat35Dt
	, [Status 40]									= LK.Stat40Dt
	, [Status 41]									= LK.Stat41Dt
	, [Fallout Date]								= LK.FalloutDt
	, [Closing Date]								= LK.ClosingDt
	, [Pilot Indicator Revision Requested]			= CASE WHEN TICSF.StatusID = 11 THEN 'No' ELSE 'Yes' END -- Mark if Pilot is Revision Requested (resubmitted to folder)
	, [Inital Underwriter]							= EM.FullNameFirstLast
	, [IUW TL]										= EM.OpsTeamLeader
	, [IUW OD]										= EM.OpsDirector
	, [IUW DVP]										= EM.OpsDVP
	, [FSO Underwriter]								= EM2.FullNameFirstLast
	, [FSO TL]										= EM2.OpsTeamLeader
	, [FSO OD]										= EM2.OpsDirector
	, [FSO DVP]										= EM2.OpsDVP
	, [PIW]											= CASE WHEN LK.PIWFlg = 1 THEN 'Yes' ELSE 'No' END -- Mark if it's a PIW
INTO #Pilot
FROM QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)
INNER JOIN QLODS.dbo.LKWD
LK (NOLOCK)				ON TICSF.LoanNumber = LK.LoanNumber
						AND LK.DeleteFlg = 0
						AND LK.ReverseFlg = 0
LEFT JOIN QLODS.dbo.StatusDim
SD (NOLOCK)				ON LK.CurrentStatusID = SD.StatusID
LEFT JOIN QLODS.dbo.EmployeeMaster
EM (NOLOCK)				ON LK.LoanUnderwriterID = EM.EmployeeDimID
LEFT JOIN QLODS.dbo.EmployeeMaster
EM2 (NOLOCK)			ON LK.LoanUnderwriterFinalSignOffID = EM2.EmployeeDimID
WHERE TICSF.TrackingItemID = 7405 -- Pilot Tracking Item 8152
AND TICSF.StatusID <> 100 -- Not Cancelled



/***** 2 *****/
/* Pull all loans with an open appraisal */
IF OBJECT_ID('tempdb..#Appraisal','U') IS NOT NULL
	DROP TABLE #Appraisal

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END 

SELECT P.*
	, [Waiting On Appraisal?]						= CASE WHEN Appr.StatusID IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days Waiting on Appraisal]					= DATEDIFF(SECOND,Appr.StatusDateTime, GETDATE())/86400.0
INTO #Appraisal
FROM #Pilot
P
OUTER APPLY (
				SELECT TOP 1 TIC.StatusID
					, TIC.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TIC (NOLOCK)
				WHERE P.[Loan Number] = TIC.LoanNumber
				AND TIC.TrackingItemID = 327 -- *Appraisal
				AND TIC.StatusID IN (6,8,10,11,12,15,56,64) -- Ordered, Received by Vendor Mgmt, Assigned to Vendor, Outstanding, Waiting on Acceptable Docs/Info
																--, Under Review, Received, or Verified by Set-up
				ORDER BY TIC.StatusDateTime ASC
			) Appr


/***** 3 *****/
/* Pull all loans where Appraisal Review is Ready for Final Review */
IF OBJECT_ID('tempdb..#AppraisalReview','U') IS NOT NULL
	DROP TABLE #AppraisalReview

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT A.*
	, [Appraisal Review]							= CASE WHEN Appr.StatusID IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days in Appraisal Review]					= DATEDIFF(SECOND,Appr.StatusDateTime, GETDATE())/86400.0
INTO #AppraisalReview
FROM #Appraisal
A
OUTER APPLY (
				SELECT TOP 1 TIC.StatusID
					, TIC.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TIC (NOLOCK)
				WHERE A.[Loan Number] = TIC.LoanNumber
				AND TIC.TrackingItemID = 2175 -- Tracking Item 1416 Appraisal needs to be reviewed
				AND TIC.StatusID IN (318) -- Ready for Final Review
				ORDER BY TIC.StatusDateTime ASC
			) Appr

/***** 4 *****/
/* Pull current priority/section in FSO or IUW Hotlist */
IF OBJECT_ID('tempdb..#Hotlist','U') IS NOT NULL
	DROP TABLE #Hotlist

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'BILoan'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT A.*
	, Hotlist										= ISNULL(LPL.PriorityListName, ' ')
	, [Priority or Section]							= ISNULL(LPD.PriorityDescription, ' ')
	, [Days in Priority or Section]					= LPMF.[Days]
INTO #Hotlist
FROM #AppraisalReview
A
LEFT JOIN BILoan.dbo.LoanPriorityMovementFact_Current
LPMF (NOLOCK)			ON A.[Loan Number] = LPMF.LoanNumber
						AND LPMF.LoanPriorityListID IN (35,81)
LEFT JOIN BILoan.dbo.LoanPriorityDisplayDim
LPD (NOLOCK)			ON LPMF.DisplayPriorityID = LPD.LoanPriorityDisplayID
LEFT JOIN BILoan.dbo.LoanPriorityListDim
LPL (NOLOCK)			ON LPMF.LoanPriorityListID = LPL.LoanPriorityListID


/***** 5 *****/
/* Find loans currently in Tracking Item 5648 Outstanding */
IF OBJECT_ID('tempdb..#AgingIUWs','U') IS NOT NULL
	DROP TABLE #AgingIUWs

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT S.*
	, [Aging IUW]									= CASE WHEN TIC.StatusID IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [IUW Days Aging]								= DATEDIFF(SECOND,TIC.StatusDateTime, GETDATE())/86400.0
INTO #AgingIUWs
FROM #Hotlist
S
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TIC (NOLOCK)			ON S.[Loan Number] = TIC.LoanNumber
						AND TIC.TrackingItemID = 5298 -- 5648 Initial Underwrite Review
						AND TIC.StatusID = 11 -- Outstanding


/***** 6 *****/
/* Loans with DTRT Tracking Items < 125 */
IF OBJECT_ID('tempdb..#DTRT','U') IS NOT NULL
	DROP TABLE #DTRT

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT A.*
	, [DTRT/High Risk Loan]		= CASE WHEN DTRT.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [DTRT Days Aging]			= DATEDIFF(SECOND,DTRT.StatusDateTime, GETDATE())/86400.0
INTO #DTRT
FROM #AgingIUWs
A
OUTER APPLY (
				SELECT TOP 1 TIC.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TIC (NOLOCK)
				INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim
				TISD (NOLOCK)			ON TIC.StatusID = TISD.StatusID
										AND TISD.StatusCode <= 125 -- Less than 125 mirrior hotlist logic
				WHERE A.[Loan Number] = TIC.LoanNumber
				AND TIC.TrackingItemID IN (4333,6071) -- Two DTRT Tracking Items 4579 OFAC Hit has been identified or 6809 - CEI - Dispute Removal Form has been Emailed
				ORDER BY TIC.StatusDateTime ASC
			) DTRT


/***** 7 *****/
/* Loans where the First 48 Pilot Tracking Items are outstanding */
IF OBJECT_ID('tempdb..#SpecReviews','U') IS NOT NULL
	DROP TABLE #SpecReviews

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT D.[Loan Number]
	, ColumnPrefix						= LTRIM(RTRIM(REPLACE(TID.TrackingItemDesc,'First48 Pilot: ','')))
	, [Status]							= CONVERT(VARCHAR(MAX),TISD.StatusDescription)
	, [Days in Status]					= CONVERT(VARCHAR(MAX),TIC.StatusDateTime)
	, FirstTrackingItem					= ROW_NUMBER() OVER(PARTITION BY D.[Loan Number], TID.TrackingItemDesc ORDER BY TIC.StatusDateTime DESC)
INTO #SpecReviews
FROM #DTRT
D
INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TIC (NOLOCK)			ON D.[Loan Number] = TIC.LoanNumber
INNER JOIN QLODS.dbo.LKWDTrackingItemDim
TID (NOLOCK)			ON TIC.TrackingItemID = TID.TrackingItemID
INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim
TISD (NOLOCK)			ON TIC.StatusID = TISD.StatusID
WHERE TID.TrackingItem IN (8153, 8154, 8155, 8156, 8158) -- Pilot Tracking items minus Pre-FSO
AND TIC.StatusID IN (11,36,49,127) -- Not yet cleared


/***** 8 *****/
/* Pivot the tracking items so they are one per loan */
IF OBJECT_ID('tempdb..#AppSpecPivot','U') IS NOT NULL
	DROP TABLE #AppSpecPivot

SELECT P.*
INTO #AppSpecPivot
FROM (
		SELECT U.[Loan Number]
			, ColumnName			= U.ColumnPrefix+' '+U.ColumnName
			, U.ColumnValue
		FROM (
				SELECT S.[Loan Number]
					, S.ColumnPrefix
					, S.[Status]
					, S.[Days in Status]
				FROM #SpecReviews
				S
				WHERE FirstTrackingItem = 1
			) X1
		UNPIVOT (
					ColumnValue FOR ColumnName IN ([Status], [Days in Status])
				) U
	) X2
PIVOT (
		 MAX(ColumnValue) FOR ColumnName IN ([Asset Spec Review Status]
												, [Asset Spec Review Days in Status]
												, [Income Spec Review Status]
												, [Income Spec Review Days in Status]
												, [LRT Review Status]
												, [LRT Review Days in Status]
												, [Credit Spec Review Status]
												, [Credit Spec Review Days in Status]
												, [App Spec Review Status]
												, [App Spec Review Days in Status])
	) P


/***** 9 *****/
/* Add Pivoted App Spec info In */
IF OBJECT_ID('tempdb..#AppSpecAging','U') IS NOT NULL
	DROP TABLE #AppSpecAging

SELECT D.*
	, [Asset Spec Status]					= ISNULL(A.[Asset Spec Review Status],' ')
	, [Asset Spec Days in Status]			= DATEDIFF(SECOND,CONVERT(DATETIME, A.[Asset Spec Review Days in Status]),GETDATE())/86400.0
	, [Income Spec Status]					= ISNULL(A.[Income Spec Review Status],' ')
	, [Income Spec Days in Status]			= DATEDIFF(SECOND,CONVERT(DATETIME, A.[Income Spec Review Days in Status]),GETDATE())/86400.0
	, [LRT Status]							= ISNULL(A.[LRT Review Status],' ')
	, [LRT Days in Status]					= DATEDIFF(SECOND,CONVERT(DATETIME, A.[LRT Review Days in Status]),GETDATE())/86400.0
	, [Credit Spec Status]					= ISNULL(A.[Credit Spec Review Status],' ')
	, [Credit Spec Days in Status]			= DATEDIFF(SECOND,CONVERT(DATETIME, A.[Credit Spec Review Days in Status]),GETDATE())/86400.0
	, [App Spec Status]						= ISNULL(A.[App Spec Review Status],' ')
	, [App Spec Days in Status]				= DATEDIFF(SECOND,CONVERT(DATETIME, A.[App Spec Review Days in Status]),GETDATE())/86400.0
INTO #AppSpecAging
FROM #DTRT
D
LEFT JOIN #AppSpecPivot
A			ON D.[Loan Number] = A.[Loan Number]


/***** 10 *****/
/* Add in if PreFSO Tracking Item Status - look at ones that are outstanding first, then go by most recent, ignore cancelled */
IF OBJECT_ID('tempdb..#PreFSO','U') IS NOT NULL
	DROP TABLE #PreFSO

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT A.*
	, [Pre-FSO Review Status]			= ISNULL(PF.StatusDescription,' ')
	, [Days in Pre-FSO Status]			= DATEDIFF(SECOND,PF.StatusDateTime,GETDATE())/86400.0
INTO #PreFSO
FROM #AppSpecAging
A
OUTER APPLY (
				SELECT TOP 1 TISD.StatusDescription
					, TIC.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TIC (NOLOCK)
				LEFT JOIN QLODS.dbo.LKWDTrackingItemStatusDim
				TISD (NOLOCK)			ON TIC.StatusID = TISD.StatusID
				WHERE A.[Loan Number] = TIC.LoanNumber
				AND TIC.TrackingItemID = 7410 -- TI 8157
				ORDER BY CASE WHEN TIC.StatusID IN (11,36,49,127) THEN 1
							WHEN TISD.StatusDescription LIKE '%Cancel' THEN -1
							ELSE 0 END DESC
					, TIC.StatusDateTime ASC
			) PF


/***** 11 *****/
/* Is loan currently client ready? */
IF OBJECT_ID('tempdb..#ClientReady','U') IS NOT NULL
	DROP TABLE #ClientReady

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT P.*
	, [Client Ready]				= CASE WHEN TIC.LoanNumber IS NOT NULL THEN 'Yes' ELSE 'No' END
INTO #ClientReady
FROM #PreFSO
P
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TIC (NOLOCK)			ON P.[Loan Number] = TIC.LoanNumber
						AND TIC.TrackingItemID = 5659 -- TI 5957 All Client Conditins have been cleared
						AND TIC.StatusID = 67 -- Cleared by Underwriter


/***** 12 *****/
/* Open banker Clarification*/
IF OBJECT_ID('tempdb..#BCAging','U') IS NOT NULL
	DROP TABLE #BCAging

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT C.*
	, [Banker Clarification]		= CASE WHEN BC.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days Waiting for BC]			= DATEDIFF(SECOND,BC.StatusDateTime, GETDATE())/86400.0
	-- NUmber of BCs?
INTO #BCAging
FROM #ClientReady
C
OUTER APPLY (
				SELECT TOP 1 TIC.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TIC (NOLOCK)
				WHERE C.[Loan Number] = TIC.LoanNumber
				AND TIC.TrackingItemID = 4323 -- TI4583 Banker Clarification
				AND TIC.StatusID IN (11,366,15) -- Outstanding, SC Clarification Needed, Under Review
				ORDER BY TIC.StatusDateTime ASC
			) BC


/***** 13 *****/
/* Title Coordinator task not cleared */
IF OBJECT_ID('tempdb..#TCAging','U') IS NOT NULL
	DROP TABLE #TCAging

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT B.*
	, [Title Coorindator Action]		= CASE WHEN TC.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days Waiting for TC]				= DATEDIFF(SECOND,TC.StatusDateTime, GETDATE())/86400.0
INTO #TCAging
FROM #BCAging
B
OUTER APPLY (
				SELECT TOP 1 TIC.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TIC (NOLOCK)
				INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim
				TISD (NOLOCK)			ON TIC.StatusID = TISD.StatusID
										AND TISD.StatusCode <= 125	-- Less than Cleared by Underwriter (matches hotlist)
				WHERE B.[Loan Number] = TIC.LoanNumber
				-- Tracking Items come from "HL RTC Tracking Items for FSO UW" Pop-up Table
				AND TIC.TrackingItemID IN (5423,5420,5644,5655,5650,5646,6564,6604,6745,6743,6746,6741,6742,6838)
				ORDER BY TIC.StatusDateTime ASC
			) TC


/***** 14 *****/
/* Docs Received are waiting to be reviewed */
IF OBJECT_ID('tempdb..#DocsReceived','U') IS NOT NULL
	DROP TABLE #DocsReceived

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT T.*
	, [Waiting for Docs]			= CASE WHEN D.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days Waiting for Docs]		= DATEDIFF(SECOND, D.StatusDateTime, GETDATE())/86400.0
INTO #DocsReceived
FROM #TCAging
T
OUTER APPLY (
				SELECT TOP 1 TICSF.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TICSF (NOLOCK)
				WHERE T.[Loan Number] = TICSF.LoanNumber
				AND TICSF.TrackingItemID = 2903 -- Tracking item 2145 Document Received by Client
				AND TICSF.StatusID = 11 -- Outstanding
				ORDER BY TICSF.StatusDateTime ASC
			) D


/***** 15 *****/
/* Check how many LMBRUs there are */
IF OBJECT_ID('tempdb..#LMBRU','U') IS NOT NULL
	DROP TABLE #LMBRU

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT D.[Loan Number]
	, [LMBRUs]				= COUNT(TICSF.LoanNumber)
	, [Days with LMBRU]		= MAX(DATEDIFF(SECOND,TICSF.StatusDateTime, GETDATE())/86400.0)
INTO #LMBRU
FROM #DocsReceived
D
INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)			ON  D.[Loan Number] = TICSF.LoanNumber
						AND TICSF.TrackingItemID IN (
														-- Find all LMBRUs/Re-Underwrites
														SELECT TID.TrackingItemID
														FROM QLODS.dbo.LKWDTrackingItemDim
														TID (NOLOCK)
														WHERE TID.TrackingItemDesc LIKE '%Re_Under%'
														OR TID.TrackingItemDesc LIKE '%LMBRU%'
													)
						AND TICSF.StatusID = 11 -- Outstanding
GROUP BY D.[Loan Number]


/***** 16 *****/
/* Check how many Clent Conditions there are */
IF OBJECT_ID('tempdb..#ClientConditions','U') IS NOT NULL
	DROP TABLE #ClientConditions

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT D.[Loan Number]
	, [Days with Client Condition]		= MAX(DATEDIFF(SECOND,TICSF.StatusDateTime, GETDATE())/86400.0)
	, [Number of Client Conditions]		= COUNT(TICSF.LoanNumber)
INTO #ClientConditions
FROM #DocsReceived
D
INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)			ON  D.[Loan Number] = TICSF.LoanNumber
						AND TICSF.TrackingItemID IN (
														-- Find all client conditions
														SELECT TID.TrackingItemID
														FROM QLODS.dbo.LKWDTrackingItemDim
														TID (NOLOCK)
														WHERE TID.ConditionType ='Client Conditions'
													)
						AND TICSF.StatusID IN (49,56) -- Problem or Recieved
GROUP BY D.[Loan Number]


/***** 17 *****/
/* How man CA Conditions there are */
IF OBJECT_ID('tempdb..#CAConditions','U') IS NOT NULL
	DROP TABLE #CAConditions

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT D.[Loan Number]
	, [Days with CA Condition]			= MAX(DATEDIFF(SECOND,TICSF.StatusDateTime, GETDATE())/86400.0)
	, [Number of CA Conditions]			= COUNT(TICSF.LoanNumber)
INTO #CAConditions
FROM #DocsReceived
D
INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)			ON  D.[Loan Number] = TICSF.LoanNumber
						AND TICSF.TrackingItemID IN (
														-- Find all CA Conditions
														SELECT TID.TrackingItemID
														FROM QLODS.dbo.LKWDTrackingItemDim
														TID (NOLOCK)
														WHERE TID.ConditionType ='CA Conditions'
													)
						AND TICSF.StatusID = 11 -- Outstanding
GROUP BY D.[Loan Number]


/***** 18 *****/
/* How many CCS Actions are Problem or Received */
IF OBJECT_ID('tempdb..#CCSAction','U') IS NOT NULL
	DROP TABLE #CCSAction

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT D.[Loan Number]
	, [Days with CCS Action]		= MAX(DATEDIFF(SECOND,TICSF.StatusDateTime, GETDATE())/86400.0)
	, [Number of CCS Action]		= COUNT(TICSF.LoanNumber)
INTO #CCSAction
FROM #DocsReceived
D
INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)			ON  D.[Loan Number] = TICSF.LoanNumber
						AND TICSF.TrackingItemID IN (
														-- Find all CCS Actions
														SELECT TID.TrackingItemID
														FROM QLODS.dbo.LKWDTrackingItemDim
														TID (NOLOCK)
														WHERE TID.ConditionType ='CCS Action Conditions'
													)
						AND TICSF.StatusID IN (49,56) -- Problem or Received
GROUP BY D.[Loan Number]


/***** 19 *****/
/* Add all LMBRUs, Client Conditions, CA Conditions, and CCS Actions */
IF OBJECT_ID('tempdb..#AddConditions','U') IS NOT NULL
	DROP TABLE #AddConditions

SELECT D.*
	, [Number of Client Conditions]			= ISNULL(C.[Number of Client Conditions],0)
	, C.[Days with Client Condition]
	, [Number of CA Conditions]				= ISNULL(CA.[Number of CA Conditions],0)
	, CA.[Days with CA Condition]
	, [Number of CCS Actions]				= ISNULL(CCS.[Number of CCS Action],0)
	, CCS.[Days with CCS Action]
	, [Number of LMBRUs]					= ISNULL(L.[LMBRUs],0)
	, L.[Days with LMBRU]
INTO #AddConditions
FROM #DocsReceived
D
LEFT JOIN #ClientConditions
C			ON D.[Loan Number] = C.[Loan Number]
LEFT JOIN #CAConditions
CA			ON D.[Loan Number] = CA.[Loan Number]
LEFT JOIN #CCSAction
CCS			ON D.[Loan Number] = CCS.[Loan Number]
LEFT JOIN #LMBRU
L			ON D.[Loan Number] = L.[Loan Number]


/***** 20 *****/
/* In suspense and with a Credit UW */
IF OBJECT_ID('tempdb..#CreditSuspense','U') IS NOT NULL
	DROP TABLE #CreditSuspense

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT A.*
	, [Credit Suspense]					= CASE WHEN SUS.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days in Credit Suspense]			= DATEDIFF(SECOND, SUS.StatusDateTime, GETDATE())/86400.0
INTO #CreditSuspense
FROM #AddConditions
A
OUTER APPLY (
				SELECT TOP 1 TICSF.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TICSF (NOLOCK)
				WHERE A.[Loan Number] = TICSF.LoanNumber
				AND TICSF.TrackingItemID = 6102 -- TI 6816 Suspense Condition: Credit UW to Review
				AND TICSF.StatusID = 11 -- Outstanding
				ORDER BY TICSF.StatusDateTime ASC
			) SUS


/***** 21 *****/
/* In suspense and with a Collateral UW */
IF OBJECT_ID('tempdb..#CollateralSuspense','U') IS NOT NULL
	DROP TABLE #CollateralSuspense

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT C.*
	, [Collateral Suspense]					= CASE WHEN SUS.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days in Collateral Suspense]			= DATEDIFF(SECOND, SUS.StatusDateTime, GETDATE())/86400.0
INTO #CollateralSuspense
FROM #CreditSuspense
C
OUTER APPLY (
				SELECT TOP 1 TICSF.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TICSF (NOLOCK)
				WHERE C.[Loan Number] = TICSF.LoanNumber
				AND TICSF.TrackingItemID = 6103 -- 6817 Suspense Condition: Collateral UW to Reivew are Outstanding
				AND TICSF.StatusID = 11 -- Outstanding
				ORDER BY TICSF.StatusDateTime ASC
			) SUS


/***** 22 *****/
/* In suspense - check if a loan is with Credit UW or Collateral UW first, then default to regular suspense. */
IF OBJECT_ID('tempdb..#Suspense','U') IS NOT NULL
	DROP TABLE #Suspense
	
SELECT C.*
	-- WHere is it in suspense aging 
	, [Suspense Aging]			= CASE WHEN [Collateral Suspense] = 'Yes' THEN 'Yes'
										WHEN [Credit Suspense] = 'Yes' THEN 'Yes'
										WHEN [Current Status] LIKE '%33%' THEN 'Other'
										ELSE 'No' END
	-- Look at minimum of Credit/Collateral UW suspense date first, then default to days since stat 33
	, [Days In Suspense]		= CASE WHEN [Credit Suspense] = 'Yes' OR [Collateral Suspense] = 'Yes' THEN 
										CASE WHEN ISNULL([Days in Credit Suspense],0) > ISNULL([Days in Collateral Suspense],0) THEN [Days in Credit Suspense]
											ELSE [Days in Collateral Suspense]
											END
									WHEN [Current Status] LIKE '%33%' THEN [Days in Current Status] END
INTO #Suspense
FROM #CollateralSuspense
C


/***** 23 *****/
/* Fraud Prevention Review is outstanding */
IF OBJECT_ID('tempdb..#Fraud','U') IS NOT NULL
	DROP TABLE #Fraud

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT S.*
	, [Fraud Prevention Review]					= CASE WHEN F.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days in Fraud Prevention Review]			= DATEDIFF(SECOND, F.StatusDateTime, GETDATE())/86400.0
INTO #Fraud
FROM #Suspense
S
OUTER APPLY (
				SELECT TOP 1 TICSF.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TICSF (NOLOCK)
				WHERE S.[Loan Number] = TICSF.LoanNumber
				AND TICSF.TrackingItemID = 4397 -- TI 3548 Fraud Prevention Review
				AND TICSF.StatusID = 11 -- Outstanding
				ORDER BY TICSF.StatusDateTime ASC
			) F


/***** 24 *****/
/* Fraud Prevention Review is outstanding */
IF OBJECT_ID('tempdb..#FSOColl','U') IS NOT NULL
	DROP TABLE #FSOColl

SET @State = 1
WHILE @State > 0	BEGIN
						SELECT @State = t1.[State] FROM Sys.Databases t1 WHERE Name = 'QLODS'
						IF @State = 0 BREAK ELSE WAITFOR DELAY '00:00:30'
					END

SELECT F.*
	, [FSO Collateral Review]					= CASE WHEN FC.StatusDateTime IS NOT NULL THEN 'Yes' ELSE 'No' END
	, [Days in FSO Collateral Review]			= DATEDIFF(SECOND, FC.StatusDateTime, GETDATE())/86400.0
INTO #FSOColl
FROM #Fraud
F
OUTER APPLY (
				SELECT TOP 1 TICSF.StatusDateTime
				FROM QLODS.dbo.TrackingItemCurrentStatusFact
				TICSF (NOLOCK)
				WHERE F.[Loan Number] = TICSF.LoanNumber
				AND TICSF.TrackingItemID = 5387 -- TI 5752 FSO Collateral Needs Review
				AND TICSF.StatusID IN (11,49) -- Outstanding or Problem
				ORDER BY TICSF.StatusDateTime ASC
			) FC


/***** 24 *****/
/* Pull All Relevant Data */
IF OBJECT_ID('tempdb..#Final','U') IS NOT NULL
	DROP TABLE #Final

SELECT F.[Loan Number]
	, F.[Current Status]
	, F.[Current Status Date]
	, F.[Days in Current Status]
	, F.[DTRT/High Risk Loan]
	, F.[Appraisal Review]
	, F.PIW
	, F.[Waiting On Appraisal?]
	, F.[FSO Collateral Review]
	, F.[Title Coorindator Action]
	, [Section 122]									= CASE WHEN F.[Priority or Section] = 'Section 122: Pre-FSO Review Complete'
																AND (
																		F.[Number of LMBRUs] > 0
																		OR F.[Number of CA Conditions] > 0
																		OR F.[Number of Client Conditions] > 0
																		OR F.[Number of CCS Actions] > 0
																		OR [Credit Suspense] = 'Yes'
																	) THEN 'Yes'
														ELSE 'No' END
	, F.[Number of LMBRUs]
	, F.[Number of Client Conditions]
	, F.[Number of CCS Actions]
	, F.[Number of CA Conditions]
	, F.[Fraud Prevention Review]
	, F.[Suspense Aging]
	, F.[Credit Suspense]
	, F.[Collateral Suspense]
	, F.[Aging IUW]
	, F.[Pre-FSO Review Status]
	, F.[Client Ready]
	, F.[Banker Clarification]
	, F.[Waiting for Docs]
	, F.[Pilot Indicator Revision Requested]
	, [Spec Incomplete]								= CASE WHEN F.[Asset Spec Status] IS NOT NULL THEN 'Yes'
														WHEN F.[Income Spec Status] IS NOT NULL THEN 'Yes'
														WHEN F.[Credit Spec Status] IS NOT NULL THEN 'Yes'
														ELSE 'No' END
	, F.Hotlist
	, F.[Priority or Section]
	, F.[Days in Priority or Section]
	, F.[DTRT Days Aging]
	, F.[Days in Appraisal Review]
	, F.[Days Waiting on Appraisal]
	, F.[Days in FSO Collateral Review]
	, F.[Days Waiting for TC]
	, F.[Days in Fraud Prevention Review]
	, F.[Days in Credit Suspense]
	, F.[Days in Collateral Suspense]
	, F.[Days In Suspense]
	, F.[IUW Days Aging]
	, F.[Days in Pre-FSO Status]
	, F.[Days Waiting for BC]
	, F.[Days Waiting for Docs]
	, F.[Days with LMBRU]
	, F.[Days with Client Condition]
	, F.[Days with CCS Action]
	, F.[Days with CA Condition]
	, F.[Inital Underwriter]
	, F.[FSO Underwriter]
	, F.[IUW TL]
	, F.[IUW OD]
	, F.[IUW DVP]
	, F.[FSO TL]
	, F.[FSO OD]
	, F.[FSO DVP]
	, F.[LRT Status]
	, F.[LRT Days in Status]
	, F.[App Spec Status]
	, F.[App Spec Days in Status]
	, F.[Asset Spec Status]
	, F.[Asset Spec Days in Status]
	, F.[Income Spec Status]
	, F.[Income Spec Days in Status]
	, F.[Credit Spec Status]
	, F.[Credit Spec Days in Status]
	, F.[Status 21]
	, F.[Status 33]
	, F.[Status 35]
	, F.[Status 40]
	, F.[Status 41]
	, F.[Fallout Date]
	, F.[Closing Date]
INTO #Final
FROM #FSOColl
F

/* Pull all data */
SELECT *
FROM #Final
F
ORDER BY CONVERT(INT, LEFT(F.[Current Status],3)) ASC
	, F.[Days in Current Status] DESC

/* Pull DTRT Data */
SELECT F.[Loan Number]
	, F.[DTRT Days Aging]
	, F.[Current Status]
	, F.[Days in Current Status]
FROM #Final
F
WHERE F.[DTRT/High Risk Loan] = 'Yes'
ORDER BY F.[DTRT Days Aging] DESC
 

/* Pull Appraisal Review Data */
SELECT F.[Loan Number]
	, F.[Days in Appraisal Review]
	, F.[Current Status]
	, F.[Days in Current Status]
	, F.[Waiting On Appraisal?]
	, F.[Days Waiting on Appraisal]
	, F.PIW
FROM #Final
F
WHERE F.[Appraisal Review] = 'Yes'
ORDER BY F.[Days in Appraisal Review] DESC


/* Pull FSO Collateral Review*/
SELECT F.[Loan Number]
	, F.[Days In FSO Collateral Review]
	, F.[Current Status]
	, F.[Days in Current Status]
	, F.[FSO Underwriter]
	, F.[FSO TL]
	, F.[FSO OD]
	, F.[FSO DVP]
	, F.[Pre-FSO Review Status]
	, F.[Days in Pre-FSO Status]
	, F.[Collateral Suspense]
	, F.[Days in Collateral Suspense]
FROM #Final
F
WHERE F.[FSO Collateral Review] = 'Yes'
ORDER BY F.[Days in FSO Collateral Review] DESC

/* Pull TC*/
SELECT F.[Loan Number]
	, F.[Days Waiting for TC]
	, F.[Current Status]
	, F.[Days in Current Status]
FROM #Final
F
WHERE F.[Title Coorindator Action] = 'Yes'
ORDER BY F.[Days Waiting for TC] DESC

/* Section 122 */
SELECT F.[Loan Number]
	, F.[Days in Priority or Section]
	, F.[Current Status]
	, F.PIW
	, F.[Waiting On Appraisal?]
	, F.[Number of LMBRUs]
	, F.[Number of Client Conditions]
	, F.[Number of CA Conditions]
	, F.[Number of CCS Actions]
	, F.[Credit Suspense]
FROM #Final
F
WHERE F.[Section 122] = 'Yes'
ORDER BY [Days in Priority or Section] DESC


/* Aging IUW */
SELECT F.[Loan Number]
	, F.[IUW Days Aging]
	, F.[Current Status]
	, F.[Days in Current Status]
	, F.[Inital Underwriter]
	, F.[IUW TL]
	, F.[IUW OD]
	, F.[IUW DVP]
	, F.Hotlist
	, F.[Priority or Section]
	, F.[Days in Priority or Section]
	, F.[Pre-FSO Review Status]
	, F.[Client Ready]
	, F.[Waiting On Appraisal?]
	, F.[Number of LMBRUs]
	, F.[Waiting for Docs]
	, F.[Number of Client Conditions]
	, F.[Number of CA Conditions]
	, F.[Number of CCS Actions]
FROM #Final
F
WHERE F.[Aging IUW] = 'Yes'
ORDER BY [IUW Days Aging] DESC


/* Sitting in Stat 21 */
SELECT F.[Loan Number]
	, F.[Current Status]
	, F.[Days in Current Status]
	, F.[Inital Underwriter]
	, F.[IUW TL]
	, F.[IUW OD]
	, F.[IUW DVP]
	, F.[Pre-FSO Review Status]
	, F.[Aging IUW]
	, F.[Waiting On Appraisal?]
	, F.[Client Ready]
FROM #Final
F
WHERE F.[Current Status] LIKE '%21%'
AND (
		F.[Pre-FSO Review Status] IN ('Completed/Confirmed','Cleared by Underwriter')
		OR F.[Aging IUW] = 'No'
	)
ORDER BY [Days in Current Status] DESC


/* BC */
SELECT F.[Loan Number]
	, F.[Days Waiting for BC]
	, F.[Client Ready]
	, F.[Current Status]
	, F.[Days in Current Status]
FROM #Final
F
WHERE F.[Banker Clarification] = 'Yes'
ORDER BY [Days Waiting for BC] DESC


/* Suspense */
SELECT F.[Loan Number]
	, F.[Suspense Aging]
	, F.[Days In Suspense]
	, F.[Current Status]
	, F.[Current Status Date]
	, F.[Days in Current Status]
	, F.[Status 33]
	, F.[Status 35]
	, F.[Collateral Suspense]
	, F.[Days in Collateral Suspense]
	, F.[Credit Suspense]
	, F.[Days in Credit Suspense]
FROM #Final
F
WHERE F.[Suspense Aging] <> 'No'
ORDER BY F.[Suspense Aging] DESC
	, F.[Days In Suspense] DESC