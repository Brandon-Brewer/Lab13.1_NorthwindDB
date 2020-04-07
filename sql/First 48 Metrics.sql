SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Today DATETIME = GETDATE()
DECLARE @TodayID INT = YEAR(@Today)*10000 + MONTH(@Today)*100 + DAY(@Today)
DECLARE @TodayTmID INT = DATEPART(HOUR,@Today)*3600 + DATEPART(MINUTE,@Today)*60 + DATEPART(SECOND,@Today) + 1

IF OBJECT_ID('tempdb..#Stat20','U') IS NOT NULL
       DROP TABLE #Stat20

SELECT 
	LK.LoanNumber
	, Pilot						= CASE WHEN TICSF.StatusID < 100 THEN 1 ELSE 0 END
	, LK.Stat20ID
	, LK.Stat20TmID
	, LK.Stat21ID
	, LK.Stat21TmID
	, LK.Stat33ID
	, LK.Stat33TmID
	, LK.Stat35ID
	, LK.Stat35TmID
	, LK.Stat40ID
	, LK.Stat40TmID
	, LK.ClosingDt
	, LK.FalloutDt
	, LK.FalloutReasonText1
	, LK.FalloutReasonText2
	, LK.FalloutReasonText3
	, LTF.LTV
	, LTF.DTI
	, LTF.QualFICO
	, LTF.LoanAmount
	, PB.ProductDescription
	, PB.ProductBucket
	, PB.Jumboflg
	, LoanChannel				= LCG.FriendlyName
	, LoanPurpose				= CASE WHEN LK.LoanPurposeID = 7 THEN 'Refinance'
									ELSE 'Purchase' END
	, EmployeeLoanFlg
	, SelfEmployflg
	, ReverseFlg
	, [STATE]
INTO #Stat20
FROM QLODS.dbo.LKWD 
LK (NOLOCK)
INNER JOIN QLODS.dbo.LKWDTransFact
LTF (NOLOCK)		ON LTF.LoanNumber = LK.LoanNumber
					AND LTF.TransDtID = LK.Stat20ID
					AND LTF.TransTmID = LK.Stat20TmID
					AND LTF.EventtypeID = 2
					AND LTF.StatusID = 119 --status 20
LEFT JOIN Reporting.dbo.vwProductBuckets 
PB (NOLOCK)			ON PB.ProductID = LTF.ProductID
LEFT JOIN QLODS.dbo.LoanChannelGroupDim
LCG (NOLOCK)		ON LCG.LoanChannelGroupID = LTF.LoanChannelGroupID 
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)		ON LK.LoanNumber = TICSF.LoanNumber
					AND TICSF.TrackingItemID = 7405
LEFT JOIN QLODS.dbo.GeographyDim
GD (NOLOCK)			ON LK.PropertyGeographyID = GD.GeographyID
WHERE LK.Stat20ID >= 20170301
AND LK.DeleteFlg = 0
AND LTF.LoanPurposeID = 7
AND LK.ReverseFlg = 0


IF OBJECT_ID('tempdb..#Qual','U') IS NOT NULL
       DROP TABLE #Qual

SELECT s20.*
	, PilotStartDate = TI7405.StatusDateTime
	, FolderIncompleteDate = TI1727.StatusDateTime
	, NewPilot = CASE WHEN TI1727.StatusDateTime <= TI7405.StatusDateTime THEN 0 ELSE Pilot END
INTO #Qual
FROM #Stat20
s20
OUTER APPLY (
				SELECT TOP 1
					TIF.StatusDateTime
				FROM QLODS.dbo.LKWDTrackingItemFact
				TIF (NOLOCK)
				WHERE TIF.LoanNumber = s20.LoanNumber
				AND TIF.Trackingitemid = 7405
				AND TIF.DeleteFlg = 0
				AND TIF.StatusID = 11
				ORDER BY TIF.StatusDtID ASC, TIF.StatusTmID ASC
			) TI7405
OUTER APPLY (
				SELECT TOP 1
					TIF.StatusDateTime
				FROM QLODS.dbo.LKWDTrackingItemFact
				TIF (NOLOCK) 
				WHERE TIF.Loannumber = s20.LoanNumber
				AND TIF.trackingitemid = 7364 --TI 8107 Appraisal First Pilot
				AND TIF.Deleteflg = 0
				AND TIF.StatusID = 11
				ORDER BY TIF.StatusDtID DESC
					, TIF.StatustmID DESC
			) TI8107
OUTER APPLY (
				SELECT TOP 1
					TIF.StatusDateTime
				FROM QLODS.dbo.LKWDTrackingItemFact
				TIF (NOLOCK)
				INNER JOIN QLODS..TrackingItemCurrentStatusFact 
				ticsf (NOLOCK) ON ticsf.LoanNumber = TIF.LoanNumber
					AND ticsf.TrackingItemID = TIF.TrackingItemID
					AND ticsf.TrackingSeqNum = TIF.TrackingSeqNum
				WHERE TIF.Loannumber = s20.LoanNumber
				AND TIF.trackingitemid = 2485 --TI 1727 Folder Incomplete
				AND TIF.StatusID = 11 --outstanding
				AND TIF.Deleteflg = 0
				ORDER BY TIF.StatusDtID ASC
					, TIF.StatustmID ASC
			) TI1727
WHERE (
	(
		S20.ProductBucket = 'Conventional'
		AND TI8107.StatusDateTime IS NULL
		AND S20.JumboFlg = 0
		AND S20.ProductDescription NOT LIKE '%home possible%'
		AND S20.ProductDescription NOT LIKE '%fred%'
		AND S20.EmployeeLoanFlg = 0
		AND S20.SelfEmployflg = 0
		AND S20.[STATE] <> 'KY'
		AND S20.LoanChannel NOT LIKE '%schwab%'
		AND S20.LoanChannel NOT LIKE '%cadillac%'
		AND (
				REPLACE(S20.LoanChannel,' ','') NOT LIKE '%ssharp%'
				OR REPLACE(S20.LoanChannel,' ','') NOT LIKE '%SameServicerHarp%'
			)
		AND (	
				Pilot = 0
				OR TI1727.StatusDateTime <= TI7405.StatusDateTime
			)
	)
	OR Pilot = 1 
)
AND (
		s20.Stat21ID IS NOT NULL
		OR TI1727.StatusDateTime IS NOT NULL
	)	


--SELECT DISTINCT TIC.LoanNumber
--FROM QLODS.dbo.LKWDTrackingItemFact
--TIC (NOLOCK)
--INNER JOIN QLODS.dbo.LKWD
--LK (NOLOCK)			ON TIC.LoanNumber = LK.LoanNumber
--					AND LK.LoanPurposeID = 7
--					AND LK.DeleteFlg = 0
--WHERE TIC.TrackingItemID = 4893  -- TI 5234	Income Specialist Review Required
--AND TIC.StatusID = 11
--AND TIC.DeleteFlg = 0
--AND StatusDtID >= 20170301
--AND StatusSeqNum = 1

--SELECT StatusID
--	, COUNT(LoanNumber)
--FROM QLODS.dbo.TrackingItemCurrentStatusFact
--WHERE TrackingItemID = 4893
--GROUP BY StatusID


IF OBJECT_ID('tempdb..#ClientReady','U') IS NOT NULL
       DROP TABLE #ClientReady

SELECT 
	Q.*
	, CurrentlyClientReady			= CASE WHEN TICSF.StatusID < 100 THEN 1 ELSE 0 END
	, FirstClientReadyDtID			= FCR.StatusDtID
	, FirstClientReadyTmID			= FCR.StatusTmID
	, LastClientReadyDtID			= LCR.StatusDtID
	, LastClientReadyTmID			= LCR.StatusTmID
INTO #ClientReady
FROM #Qual
Q
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TICSF (NOLOCK)		ON TICSF.LoanNumber = Q.LoanNumber
					AND TICSF.TrackingITemID = 5659
OUTER APPLY (
                SELECT TOP 1 TIF.StatusDtID
					, TIF.StatusTmID
                FROM QLODS.dbo.LKWDTrackingItemFact
                TIF (NOLOCK)
                WHERE TIF.LoanNumber = Q.LoanNumber
                AND TIF.TrackingItemID = 5659 -- All Client Conditions Cleared
                AND TIF.StatusID = 67
                AND TIF.DeleteFlg = 0
                ORDER BY TIF.StatusDtID ASC
                        , TIF.StatusTmID ASC
            ) FCR
OUTER APPLY (
                SELECT TOP 1 TIF2.StatusDtID
					, TIF2.StatusTmID
                FROM QLODS.dbo.LKWDTrackingItemFact
                TIF2 (NOLOCK)
                WHERE TIF2.LoanNumber = Q.LoanNumber
                AND TIF2.TrackingItemID = 5659 -- All Client Conditions Cleared
                AND TIF2.StatusID = 67
                AND TIF2.DeleteFlg = 0
                ORDER BY TIF2.StatusDtID DESC
                        , TIF2.StatusTmID DESC
            ) LCR


IF OBJECT_ID('tempdb..#Stat21','U') IS NOT NULL
	DROP TABLE #Stat21

SELECT
	Q.*
    , FirstStat21ID		= FS.TransDtID
    , FirstStat21TmID	= FS.TransTmID
INTO #Stat21
FROM #ClientReady Q
OUTER APPLY (
				SELECT TOP 1 TransDtID
						, TransTmID
				FROM QLODS.dbo.LKWDTransFact
				LTF (NOLOCK)
				WHERE LTF.LoanNumber = Q.LoanNumber
				AND LTF.EventTypeID = 2
				AND LTF.StatusID = 76  -- Put StatusID From StatusDim here, ex. StatusID = 76 is Stat 21
				AND LTF.DeleteFlg = 0
				ORDER BY LTF.TransDtID ASC
						, LTF.TransTmID ASC
			) FS


IF OBJECT_ID('tempdb..#Stat33','U') IS NOT NULL
	DROP TABLE #Stat33

SELECT
	Q.*
    , FirstStat33ID		= FS.TransDtID
    , FirstStat33TmID	= FS.TransTmID
INTO #Stat33
FROM #Stat21
Q
OUTER APPLY (
				SELECT TOP 1 TransDtID
						, TransTmID
				FROM QLODS.dbo.LKWDTransFact
				LTF (NOLOCK)
				WHERE LTF.LoanNumber = Q.LoanNumber
				AND LTF.EventTypeID = 2
				AND LTF.StatusID = 117 -- Stat 33
				AND LTF.DeleteFlg = 0
				ORDER BY LTF.TransDtID ASC
						, LTF.TransTmID ASC
			) FS


IF OBJECT_ID('tempdb..#Stat35','U') IS NOT NULL
	DROP TABLE #Stat35

SELECT
	Q.*
    , FirstStat35ID		= FS.TransDtID
    , FirstStat35TmID	= FS.TransTmID
INTO #Stat35
FROM #Stat33
Q
OUTER APPLY (
				SELECT TOP 1 TransDtID
						, TransTmID
				FROM QLODS.dbo.LKWDTransFact
				LTF (NOLOCK)
				WHERE LTF.LoanNumber = Q.LoanNumber
				AND LTF.EventTypeID = 2
				AND LTF.StatusID = 83 -- Stat 35
				AND LTF.DeleteFlg = 0
				ORDER BY LTF.TransDtID ASC
						, LTF.TransTmID ASC
			) FS


IF OBJECT_ID('tempdb..#Stat40','U') IS NOT NULL
	DROP TABLE #Stat40

SELECT
	Q.*
    , FirstStat40ID		= FS.TransDtID
    , FirstStat40TmID	= FS.TransTmID
INTO #Stat40
FROM #Stat35
Q
OUTER APPLY (
				SELECT TOP 1 TransDtID
						, TransTmID
				FROM QLODS.dbo.LKWDTransFact
				LTF (NOLOCK)
				WHERE LTF.LoanNumber = Q.LoanNumber
				AND LTF.EventTypeID = 2
				AND LTF.StatusID = 181 -- Stat 35
				AND LTF.DeleteFlg = 0
				ORDER BY LTF.TransDtID ASC
						, LTF.TransTmID ASC
			) FS


IF OBJECT_ID('tempdb..#RFSOP','U') IS NOT NULL
	DROP TABLE #RFSOP

SELECT S40.*
	, RFSOPDtID			= ISNULL(FirstRFSOP.StatusDtID, S40.FirstStat40ID)
	, RFSOPTmID			= ISNULL(FirstRFSOP.StatusTmID, S40.FirstStat40TmID)
INTO #RFSOP
FROM #Stat40
S40
OUTER APPLY (
				SELECT TOP 1 TIF.StatusDtID
					, TIF.StatusTmID
				FROM QLODS.dbo.LKWDTrackingItemFact
				TIF (NOLOCK)
				WHERE TIF.LoanNumber = S40.LoanNumber 
				AND TIF.TrackingItemID = 4432 -- TI 4626 Loan is Ready for Final Signoff Pending Action FSO Hotlist
				AND TIF.DeleteFlg = 0
				AND TIF.StatusID = 11
				ORDER BY TIF.StatusDtID ASC
					, TIF.StatusTmID ASC
			) FirstRFSOP


IF OBJECT_ID('tempdb..#Suspense','U') IS NOT NULL
	DROP TABLE #Suspense

SELECT R.LoanNumber
	, SuspensePre35				= SUM(CASE WHEN TIF.TransDtID < R.FirstStat35ID THEN 1
										WHEN TIF.TransDtID = R.FirstStat35ID AND TIF.TransTmID < R.FirstStat35TmID THEN 1
										ELSE 0 END)
	, SuspensePost35			= SUM(CASE WHEN TIF.TransDtID > R.FirstStat35ID THEN 1
										WHEN TIF.TransDtID = R.FirstStat35ID AND TIF.TransTmID > R.FirstStat35TmID AND SRD.ReasonID NOT IN (2,3) THEN 1
										ELSE 0 END)
	, SuspensePost35Excl		= SUM(CASE WHEN TIF.TransDtID > R.FirstStat35ID AND SRD.ReasonID NOT IN (2,3) THEN 1
										WHEN TIF.TransDtID = R.FirstStat35ID AND TIF.TransTmID > R.FirstStat35TmID AND SRD.ReasonID NOT IN (2,3) THEN 1
										ELSE 0 END)
	, SuspensePreRFSOP			= SUM(CASE WHEN TIF.TransDtID < R.RFSOPDtID THEN 1
										WHEN TIF.TransDtID = R.RFSOPDtID AND TIF.TransTmID < R.RFSOPTmID THEN 1
										ELSE 0 END)
	, SuspensePostRFSOP			= SUM(CASE WHEN TIF.TransDtID > R.RFSOPDtID THEN 1
										WHEN TIF.TransDtID = R.RFSOPDtID AND TIF.TransTmID > R.RFSOPTmID THEN 1
										ELSE 0 END)
	, TotalSuspense				= COUNT(TIF.TransDtID)
	, TotalTimeInSuspense		= SUM(DATEDIFF(SECOND,DATEADD(SECOND, TIF.TransTmID-1, CONVERT(VARCHAR(MAX),CAST(TIF.TransDtID AS VARCHAR(10)),112))
															, DATEADD(SECOND, ISNULL(Nxt.TransTmID,@TodayTmID)-1, CONVERT(VARCHAR(MAX),CAST(ISNULL(Nxt.TransDtID,@TodayID) AS VARCHAR(10)),112)))/3600.0)
INTO #Suspense
FROM #RFSOP
R
LEFT JOIN QLODS.dbo.LKWDTransFact
TIF (NOLOCK)		ON R.LoanNumber = TIF.LoanNumber
					AND TIF.StatusID = 117
					AND TIF.DeleteFlg = 0
					AND TIF.EventTypeID = 2
OUTER APPLY (
				SELECT TOP 1 TIF2.TransDtID
					, TIF2.TransTmID
				FROM QLODS.dbo.LKWDTransFact
				TIF2 (NOLOCK)
				WHERE TIF2.LoanNumber = TIF.LoanNumber
				AND TIF2.EventTypeID = 2
				AND TIF2.DeleteFlg = 0
				AND TIF2.TransDtID >= TIF.TransDtID
				AND CASE WHEN TIF2.TransDtID = TIF.TransDtID AND TIF2.TransTmID <= TIF.TransTmID THEN 0
						ELSE 1 END = 1
				ORDER BY TIF2.TransDtID ASC
					, TIF2.TransTmID ASC
			) Nxt
LEFT JOIN QLODS.dbo.LKWDStatusReasonGroupBridge 
SRGB (NOLOCK)			ON TIF.ReasonGroupID = SRGB.ReasonGroupID
LEFT JOIN QLODS.dbo.LKWDStatusReasonDim 
SRD (NOLOCK)			ON SRGB.ReasonID = SRD.ReasonID
GROUP BY R.LoanNumber

IF OBJECT_ID('tempdb..#LRT','U') IS NOT NULL
	DROP TABLE #LRT

SELECT R.*
	, S.SuspensePre35
	, S.SuspensePost35
	, S.SuspensePost35Excl
	, S.SuspensePreRFSOP
	, S.SuspensePostRFSOP
	, S.TotalSuspense
	, S.TotalTimeInSuspense
	, WentToLRT						= CASE WHEN TIF.LoanNumber IS NOT NULL THEN 1 ELSE 0 END
INTO #LRT
FROM #RFSOP
R
LEFT JOIN #Suspense
S					ON R.LoanNumber = S.LoanNumber
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TIF (NOLOCK)		ON TIF.LoanNumber = R.LoanNumber
					AND TIF.TrackingItemID = 7411
					AND TIF.StatusID < 100


IF OBJECT_ID('tempdb..#AppSpec','U') IS NOT NULL
	DROP TABLE #AppSpec

SELECT L.*
	, WentToAppSpec					= CASE WHEN TIF.LoanNumber IS NOT NULL THEN 1 ELSE 0 END
INTO #AppSpec
FROM #LRT
L
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TIF (NOLOCK)		ON TIF.LoanNumber = L.LoanNumber
					AND TIF.TrackingItemID = 7409
					AND TIF.StatusID < 100


IF OBJECT_ID('tempdb..#PreFSORev','U') IS NOT NULL
	DROP TABLE #PreFSORev

SELECT A.*
	, WentToPreFSO					= CASE WHEN TIF.LoanNumber IS NOT NULL THEN 1 ELSE 0 END
INTO #PreFSORev
FROM #AppSpec
A
LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact
TIF (NOLOCK)		ON TIF.LoanNumber = A.LoanNumber
					AND TIF.TrackingItemID = 7409
					AND TIF.StatusID < 100


IF OBJECT_ID('tempdb..#Touches','U') IS NOT NULL
	DROP TABLE #Touches

SELECT P.LoanNumber
	, JobGroup			= ISNULL(CASE WHEN DD.Division LIKE '%Underwriting%' OR DD.Division LIKE '%UW%' OR JobTitle LIKE '%Underwr%' THEN 'Underwriting'
									WHEN DD.Division LIKE '%Vendor%' THEN 'Vendor'
									WHEN DD.Division LIKE '%Closing%' THEN 'Closing'
									WHEN DD.Division LIKE '%Comm%'  OR DD.Division LIKE '%Client Exp%' OR DD.Division LIKE '%CR%' THEN 'Communications/Client Relations'
									WHEN DD.Division LIKE '%Amaze%' THEN 'Audit/Training'
									WHEN JTD.JobTitle LIKE '%Bank%' THEN 'Banking'
									WHEN DD.Division LIKE 'TS%' THEN 'Title Source'
									ELSE 'Other' END, 'Total')
	, LoanTouches		= COUNT(SF.SessionFactID)
	, DistinctTouches	= COUNT(DISTINCT SF.AccessedbyCommonID+' '+SF.StartDtID)
	, TimeInLoan		= SUM(SF.SessionDuration/3600.0)
INTO #Touches
FROM #PreFSORev
P
LEFT JOIN BILoan.Loan.SessionFact
SF (NOLOCK)		ON P.LoanNumber = SF.LoanNumber
				AND SF.StartDtID BETWEEN P.Stat20ID AND ISNULL(P.Stat40ID,@TodayID)
				AND CASE WHEN SF.StartDtID = P.Stat20ID AND SF.StartTmID < P.Stat20TmID THEN 0
						WHEN SF.StartDtID = ISNULL(P.Stat40ID,@TodayID) AND SF.StartTmID > ISNULL(P.Stat40TmID,@TodayTmID) THEN 0
						ELSE 1 END = 1
				AND SF.SessionDuration > 0
LEFT JOIN BICommon.TeamMember.DivisionBridge
DB (NOLOCK)			ON SF.AccessedByCommonId = DB.CommonID
					AND SF.StartDtID BETWEEN DB.ActiveStartDtID AND DB.ActiveEndDtID
LEFT JOIN BICommon.TeamMember.DivisionDim
DD (NOLOCK)			ON DB.DivisionID = DD.DivisionID
LEFT JOIN BICommon.TeamMember.JobTitleBridge
JTB (NOLOCK)			ON SF.AccessedByCommonId = JTB.CommonID
					AND SF.StartDtID BETWEEN JTB.ActiveStartDtID AND JTB.ActiveEndDtID
LEFT JOIN BICommon.TeamMember.JobTitleDim
JTD (NOLOCK)			ON JTB.JobTitleID = JTD.JobTitleID
GROUP BY GROUPING SETS (
							(
								P.LoanNumber
								, CASE WHEN DD.Division LIKE '%Underwriting%' OR DD.Division LIKE '%UW%' OR JobTitle LIKE '%Underwr%' THEN 'Underwriting'
									WHEN DD.Division LIKE '%Vendor%' THEN 'Vendor'
									WHEN DD.Division LIKE '%Closing%' THEN 'Closing'
									WHEN DD.Division LIKE '%Comm%'  OR DD.Division LIKE '%Client Exp%' OR DD.Division LIKE '%CR%' THEN 'Communications/Client Relations'
									WHEN DD.Division LIKE '%Amaze%' THEN 'Audit/Training'
									WHEN JTD.JobTitle LIKE '%Bank%' THEN 'Banking'
									WHEN DD.Division LIKE 'TS%' THEN 'Title Source'
									ELSE 'Other' END
							), (P.LoanNumber)
						)


IF OBJECT_ID('tempdb..#ByJobGroup','U') IS NOT NULL
	DROP TABLE #ByJobGroup

SELECT PVT.*
INTO #ByJobGroup
FROM (
		SELECT LoanNumber
			, JobGroup
			, DistinctTouches
		FROM #Touches
	) T
PIVOT (
			SUM(DistinctTouches) FOR JobGroup IN ([Underwriting], [Vendor], [Closing], [Communications/Client Relations], [Audit/Training], [Banking], [Title Source], [Other])
	) PVT

IF OBJECT_ID('tempdb..#DenialReasons','U') IS NOT NULL
	DROP TABLE #DenialReasons

SELECT P.LoanNumber
	, DRF.DenialReasonDimID
	, DenialReasonNumber				= 'Denial Reason '+CONVERT(VARCHAR,DRF.DenialReasonRank)
INTO #DenialReasons
FROM #PreFSORev
P
LEFT JOIN BILoan.Loan.DenialFact
DF (NOLOCK)			ON P.LoanNumber = DF.LoanNumber
					AND DF.DenialEndDateId = 21991231
LEFT JOIN BILoan.Loan.DenialReasonFact
DRF (NOLOCK)		ON DF.DenialFactId = DRF.DenialFactId


IF OBJECT_ID('tempdb..#DenialPvt','U') IS NOT NULL
	DROP TABLE #DenialPvt

SELECT PVT.*
INTO #DenialPvt
FROM #DenialReasons
PIVOT (
			MAX(DenialReasonDimID) FOR DenialReasonNumber IN ([Denial Reason 1], [Denial Reason 2], [Denial Reason 3])
	) PVT

IF OBJECT_ID('tempdb..#DenialDim','U') IS NOT NULL
	DROP TABLE #DenialDim

SELECT D.LoanNumber
	, DenialReason1			= DRD1.DenialReasonDescription
	, DenialReason2			= DRD2.DenialReasonDescription
	, DenialReason3			= DRD3.DenialReasonDescription
	, ANAFallout			= CASE WHEN 'Approved/Client Does Not Accept' IN (DRD1.DenialCategoryDescription, DRD2.DenialCategoryDescription, DRD3.DenialCategoryDescription) THEN 1
								ELSE 0 END
	, CollateralFallout		= CASE WHEN 'Assets' IN (DRD1.DenialCategoryDescription, DRD2.DenialCategoryDescription, DRD3.DenialCategoryDescription) THEN 1
								ELSE 0 END
INTO #DenialDim
FROM #DenialPvt
D
LEFT JOIN BILoan.Loan.DenialReasonDim
DRD1 (NOLOCK)			ON D.[Denial Reason 1] = DRD1.DenialReasonDimId
LEFT JOIN BILoan.Loan.DenialReasonDim
DRD2 (NOLOCK)			ON D.[Denial Reason 2] = DRD2.DenialReasonDimId
LEFT JOIN BILoan.Loan.DenialReasonDim
DRD3 (NOLOCK)			ON D.[Denial Reason 3] = DRD3.DenialReasonDimId

IF OBJECT_ID('tempdb..#SpecTIStats','U') IS NOT NULL
	DROP TABLE #SpecTIStats

SELECT P.LoanNumber
	, HelpRequested		= COUNT(DISTINCT CASE WHEN TIF.StatusID = 127 THEN P.LoanNumber END)
	, Problem			= COUNT(DISTINCT CASE WHEN TIF.StatusID = 49 THEN P.LoanNumber END)
INTO #SpecTIStats
FROM #PreFSORev
P
INNER JOIN QLODS.dbo.LKWDTrackingItemFact
TIF (NOLOCK)			ON P.LoanNumber= TIF.LoanNumber
						AND TIF.DeleteFlg = 0
INNER JOIN QLODS.dbo.LKWDTrackingItemDim
TID (NOLOCK)			ON TIF.TrackingItemID = TID.TrackingItemID
INNER JOIN QLODS.dbo.LKWD
LK (NOLOCK)				ON TIF.LoanNumber = LK.LoanNumber
						AND LK.DeleteFlg = 0
						AND LK.ReverseFlg = 0
WHERE TID.TrackingItem IN (8153,8154,8155,8156)
AND TIF.StatusID IN (49,127) --Problem, Help Requested
GROUP BY P.LoanNumber

IF OBJECT_ID('tempdb..#WeekOf','U') IS NOT NULL
	DROP TABLE #WeekOf

SELECT P.LoanNumber
	, WeekOf		= DD.[DayName]
INTO #WeekOf
FROM #PreFSORev
P
OUTER APPLY (
				SELECT TOP 1 D.[DayName]
				FROM QLODS.dbo.DateDim
				D
				WHERE D.DateID BETWEEN 20170301 AND @TodayID
				AND D.DateID <= P.Stat20ID
				AND D.DayOfWeekKey = 4
				ORDER BY D.DateID DESC
			) DD


IF OBJECT_ID('tempdb..#RawData','U') IS NOT NULL
	DROP TABLE #RawData

SELECT P.LoanNumber
	, P.LoanPurpose
	, P.LoanChannel
	, P.ProductBucket
	, P.LTV
	, P.DTI
	, P.QualFICO
	, P.LoanAmount
	, Pilot = p.NewPilot
	, S.HelpRequested
	, S.Problem
	, W.WeekOf
	, Stat20Date					= DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
	, p.FolderIncompleteDate
	, FirstStat21Date				= DATEADD(SECOND, P.FirstStat21TmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstStat21ID AS VARCHAR(10)),112))
	, Stat21Date					= DATEADD(SECOND, P.Stat21TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat21ID AS VARCHAR(10)),112))
	, FirstStat33Date				= DATEADD(SECOND, P.FirstStat33TmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstStat33ID AS VARCHAR(10)),112))
	, Stat33Date					= DATEADD(SECOND, P.Stat33TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat33ID AS VARCHAR(10)),112))
	, FirstStat35Date				= DATEADD(SECOND, P.FirstStat35TmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstStat35ID AS VARCHAR(10)),112))
	, Stat35Date					= DATEADD(SECOND, P.Stat35TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat35ID AS VARCHAR(10)),112))
	, CurrentlyClientReady
	, FirstClientReady				= DATEADD(SECOND, P.FirstClientReadyTmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstClientReadyDtID AS VARCHAR(10)),112))
	, LastClientReady				= DATEADD(SECOND, P.LastClientReadyTmID-1, CONVERT(VARCHAR(MAX),CAST(P.LastClientReadyDtID AS VARCHAR(10)),112))
	, RFSOPDate						= DATEADD(SECOND, P.RFSOPTmID-1, CONVERT(VARCHAR(MAX),CAST(P.RFSOPDtID AS VARCHAR(10)),112))
	, FirstStat40Date				= DATEADD(SECOND, P.FirstStat40TmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstStat40ID AS VARCHAR(10)),112))
	, Stat40Date					= DATEADD(SECOND, P.Stat40TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat40ID AS VARCHAR(10)),112))
	, [20 - 21 TT]					= DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
													, DATEADD(SECOND, P.Stat21TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat21ID AS VARCHAR(10)),112)))/3600.0
	, [20 - First 33 or 35 TT]		= CASE WHEN FirstStat35ID IS NOT NULL AND FirstStat33ID IS NOT NULL
												AND DATEADD(SECOND, P.FirstStat35TmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstStat35ID AS VARCHAR(10)),112)) <= 
													DATEADD(SECOND, P.FirstStat33TmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstStat33ID AS VARCHAR(10)),112))
										THEN DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
															, DATEADD(SECOND, P.Stat35TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat35ID AS VARCHAR(10)),112)))/3600.0

										WHEN FirstStat35ID IS NOT NULL AND FirstStat33ID IS NULL
										THEN DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
															, DATEADD(SECOND, P.Stat35TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat35ID AS VARCHAR(10)),112)))/3600.0
										
										WHEN FirstStat35ID IS NULL AND FirstStat33ID IS NOT NULL
										THEN DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
															, DATEADD(SECOND, P.Stat33TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat33ID AS VARCHAR(10)),112)))/3600.0

										ELSE DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
															, DATEADD(SECOND, P.Stat33TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat33ID AS VARCHAR(10)),112)))/3600.0
										END
	, [20 - First Client Ready TT]	= DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
												, DATEADD(SECOND, P.FirstClientReadyTmID-1, CONVERT(VARCHAR(MAX),CAST(P.FirstClientReadyDtID AS VARCHAR(10)),112)))/3600.0
	, [20 - 40 TT]					= DATEDIFF(SECOND, DATEADD(SECOND, P.Stat20TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat20ID AS VARCHAR(10)),112))
													, DATEADD(SECOND, P.Stat40TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat40ID AS VARCHAR(10)),112)))/3600.0
	, [21 - 40 TT]					= DATEDIFF(SECOND, DATEADD(SECOND, P.Stat21TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat21ID AS VARCHAR(10)),112))
													, DATEADD(SECOND, P.Stat40TmID-1, CONVERT(VARCHAR(MAX),CAST(P.Stat40ID AS VARCHAR(10)),112)))/3600.0
	, FalloutDt
	, ClosingDt
	, D.ANAFallout
	, D.CollateralFallout
	, D.DenialReason1
	, D.DenialReason2
	, D.DenialReason3
	, WentToLRT
	, WentToAppSpec
	, WentToPreFSO
	, SuspensePre35
	, SuspensePost35
	, SuspensePost35Excl
	, SuspensePreRFSOP
	, SuspensePostRFSOP
	, TotalTimeInSuspense
	, T.LoanTouches
	, T.DistinctTouches
	, T.TimeInLoan
	, B.[Banking]
	, B.[Underwriting]
	, B.[Communications/Client Relations]
	, B.[Vendor]
	, B.[Title Source]
	, B.[Closing]
	, B.[Audit/Training]
	, B.[Other]
INTO #RawData
FROM #PreFSORev
P
LEFT JOIN #Touches
T		ON P.LoanNumber = T.LoanNumber
		AND T.JobGroup = 'Total'
LEFT JOIN #ByJobGroup
B		ON p.LoanNumber = B.LoanNumber
LEFT JOIN #DenialDim
D		ON P.LoanNumber = D.LoanNumber
LEFT JOIN #SpecTIStats
S		ON P.LoanNumber = S.LoanNumber
LEFT JOIN #WeekOf
W		ON P.LoanNumber = W.LoanNumber


SELECT Pilot
	, WeekOf		= CASE WHEN GROUPING(WeekOf) > 0 THEN 'Total' ELSE WeekOf END
	, Loans			= COUNT(LoanNumber)
	, LTV			= AVG(CONVERT(FLOAT,LTV))
	, DTI			= AVG(CONVERT(FLOAT,DTI))
	, FICO			= AVG(CONVERT(FLOAT,QualFICO))
	, LoanAmount	= AVG(CONVERT(FLOAT,LoanAmount))
FROM #RawData
R
GROUP BY GROUPING SETS (
							(
								Pilot
								, WeekOf
							),(Pilot)
						)

SELECT Pilot
	, WeekOf				= CASE WHEN GROUPING(WeekOf) > 0 THEN 'Total' ELSE WeekOf END
	, Loans					= COUNT(LoanNumber)
	, LoansTo21				= COUNT(CASE WHEN Stat21Date IS NOT NULL THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, [20-21]				= AVG([20 - 21 TT])
	, LoansTo33or35			= COUNT(CASE WHEN Stat33Date IS NOT NULL OR Stat35Date IS NOT NULL THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, [20-33/35]			= AVG([20 - First 33 or 35 TT])
	, LoansToCR				= COUNT(CASE WHEN FirstClientReady IS NOT NULL THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, InCR					= COUNT(CASE WHEN CurrentlyClientReady = 1 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, [20-CR]				= AVG([20 - First Client Ready TT])
	, LoansTo40				= COUNT(CASE WHEN Stat40Date IS NOT NULL THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, [20-40]				= AVG([20 - 40 TT])
	, [21-40]				= AVG([21 - 40 TT])
FROM #RawData
R
GROUP BY GROUPING SETS (
							(
								Pilot
								, WeekOf
							),(Pilot)
						)


SELECT Pilot
	, WeekOf				= CASE WHEN GROUPING(WeekOf) > 0 THEN 'Total' ELSE WeekOf END
	, Loans					= COUNT(LoanNumber)
	, Total					= AVG(1.0*LoanTouches)
	, DistinctTs			= AVG(1.0*DistinctTouches)
	, TimeINL				= AVG(1.0*TimeInLoan)
	, Banking				= AVG(1.0*[Banking])
	, UW					= AVG(1.0*[Underwriting])
	, CR					= AVG(1.0*[Communications/Client Relations])
	, Vendor				= AVG(1.0*[Vendor])
	, TitleSource			= AVG(1.0*[Title Source])
	, Closing				= AVG(1.0*[Closing])
	, AuditT				= AVG(1.0*[Audit/Training])
	, Other					= AVG(1.0*[Other])
FROM #RawData
R
GROUP BY GROUPING SETS (
							(
								Pilot
								, WeekOf
							),(Pilot)
						)

SELECT Pilot
	, WeekOf				= CASE WHEN GROUPING(WeekOf) <> 0 THEN 'Total' ELSE WeekOf END
	, Loans					= COUNT(LoanNumber)
	, FolderIncomplete		= COUNT(CASE WHEN FolderIncompleteDate IS NOT NULL THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, SuspensePre35			= COUNT(CASE WHEN SuspensePre35 > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, SuspensePost35		= COUNT(CASE WHEN SuspensePost35 > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, SuspensePost35Excl	= COUNT(CASE WHEN SuspensePost35Excl > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, SuspensePreRFSOP		= COUNT(CASE WHEN SuspensePreRFSOP > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, LRT					= COUNT(CASE WHEN WentToLRT > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, AppSpec				= COUNT(CASE WHEN WentToAppSpec > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, HelpRequested			= COUNT(CASE WHEN HelpRequested > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, Problem				= COUNT(CASE WHEN Problem > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, Fallout				= COUNT(CASE WHEN FalloutDt > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, ANAFallout			= COUNT(CASE WHEN ANAFallout > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
	, CollateralFallout		= COUNT(CASE WHEN CollateralFallout > 0 THEN LoanNumber END)*1.0/COUNT(LoanNumber)
FROM #RawData
R
GROUP BY GROUPING SETS (
							(
								Pilot
								, WeekOf
							),(Pilot)
						)

SELECT *
FROM #RawData

-- Client Conditions
/* CROSS APPLY(select ltif.TrackingItemID
 ,ltid.TrackingItemDesc
 ,ltid.TrackingItem
 ,ltid.Category
 ,min(ltif.StatusDtID) StatusDtID
 ,sum(case when ltisd.Statusdescription like '%prob%' then 1 
 else 0 
 end) ProbCount
 ,sum(case when ltisd.StatusID = 36 then 1 
 else 0 
 end) RRCount
 from qlods..LKWDTrackingItemFact ltif with(nolock)
 join qlods..lkwdtrackingitemdim ltid with(nolock)
 on ltif.TrackingItemID = ltid.TrackingItemID
 and ltid.Category in ('Income', 'Property', 'Assets', 'Credit', 'Application/UW')
 and ltid.ConditionType in('Client Conditions')
 and ltid.trackingitemdesc not like '%fyi%' 
 left join qlods..LKWDTrackingItemStatusDim ltisd with(nolock)
 on ltif.StatusID = ltisd.StatusID
 and (ltisd.StatusDescription like '%prob%' or ltisd.StatusID = 36) /*Problem Statuses and Revision Requested*/
 where lkwd.LoanNumber = ltif.LoanNumber 
 group by ltif.LoanNumber
 ,ltif.TrackingItemID
 ,ltid.TrackingItemDesc
 ,ltid.TrackingItem
 ,ltid.Category
 ,ltif.TrackingSeqNum 
 ) ltif*/