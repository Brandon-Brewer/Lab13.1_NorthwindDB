SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Today DATETIME = GETDATE()
DECLARE @TodayID INT = YEAR(@Today)*10000 + MONTH(@Today)*100 + DAY(@Today)
DECLARE @TodayTmID INT = DATEPART(HOUR,@Today)*3600 + DATEPART(MINUTE,@Today)*60 + DATEPART(SECOND,@Today) + 1

IF OBJECT_ID('tempdb..#Stat20','U') IS NOT NULL
       DROP TABLE #Stat20

SELECT 
	LK.LoanNumber
	, Pilot						= CASE WHEN TICSF.StatusID < 100 THEN 1 ELSE 0 END
	, LK.CreateDtID
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
	, LK.Stat41ID
	, LK.Stat41TmID
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
				AND TIF.StatusDtID >= s20.CreateDtID
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
				AND TIF.StatusDtID >= s20.CreateDtID
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
				AND TIF.StatusDtID >= s20.CreateDtID
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


IF OBJECT_ID('tempdb..#Population','U') IS NOT NULL
	DROP TABLE #Population

SELECT Q.LoanNumber
	, Pilot					= Q.NewPilot
	, [Stat 20 Date]		= DATEADD(SECOND, Q.Stat20TmID-1, CONVERT(VARCHAR(10), Q.Stat20ID, 112))
	, [Stat 41 Date]		= DATEADD(SECOND, Q.Stat41TmID-1, CONVERT(VARCHAR(10), Q.Stat41ID, 112))
INTO #Population
FROM #Qual
Q


IF OBJECT_ID('tempdb..#Touches','U') IS NOT NULL
	DROP TABLE #Touches

SELECT P.LoanNumber
	, P.Pilot
	, P.[Stat 20 Date]
	, P.[Stat 41 Date]
	, [AMP Session Date]				= SF.StartDt
	, [Session Duration]				= SF.SessionDuration
	, [Team Member Common ID]			= SF.AccessedByCommonId
	, [Team Member]						= EM.FullNameFirstLast
	, [Team]							= CASE WHEN DD.Division LIKE '%Underwriting%' OR DD.Division LIKE '%UW%' OR JTD.JobTitle LIKE '%Underwr%' THEN 'Underwriting'
											WHEN DD.Division LIKE '%Vendor%' THEN 'Vendor'
											WHEN DD.Division LIKE '%Closing%' THEN 'Closing'
											WHEN DD.Division LIKE '%Comm%'  OR DD.Division LIKE '%Client Exp%' OR DD.Division LIKE '%CR%' THEN 'Communications/Client Relations'
											WHEN DD.Division LIKE '%Amaze%' THEN 'Audit/Training'
											WHEN JTD.JobTitle LIKE '%Bank%' THEN 'Banking'
											WHEN DD.Division LIKE 'TS%' THEN 'Title Source'
											ELSE 'Other' END
	, [Division]						= DD.Division
	, [Job Group]						= JTG.[Job Title Group]
	, [Job Title]						= JTD.JobTitle
	, [Last on Day by Team Member]		= CASE WHEN ROW_NUMBER() OVER(PARTITION BY P.LoanNumber, SF.AccessedByCommonID, SF.StartDtId
																		ORDER BY SF.StartDt DESC, SF.EndDt DESC) = 1 THEN 1
												ELSE 0 END
	, [Team Member Flg]					= CASE WHEN JTD.JobTitle LIKE '%TL%' OR JTD.JobTitle LIKE '%DIR%' OR JTD.JobTitle LIKE '%DVP%' OR JTD.JobTitle LIKE '%VP%' THEN 0 ELSE 1 END
	, [In Ops]							= CASE WHEN SF.StartDt >= P.[Stat 20 Date] AND (SF.StartDt < P.[Stat 41 Date] OR P.[Stat 41 Date] IS NULL) THEN 1 ELSE 0 END
INTO #Touches
FROM #Population
P
LEFT JOIN BILoan.Loan.SessionFact
SF (NOLOCK)			ON P.LoanNumber = SF.LoanNumber
					AND SF.SessionDuration > 0
LEFT JOIN BICommon.TeamMember.DivisionBridge
DB (NOLOCK)			ON SF.AccessedByCommonId = DB.CommonID
					AND SF.StartDtID BETWEEN DB.ActiveStartDtID AND DB.ActiveEndDtID
LEFT JOIN BICommon.TeamMember.DivisionDim
DD (NOLOCK)			ON DB.DivisionID = DD.DivisionID
LEFT JOIN BICommon.TeamMember.JobTitleBridge
JTB (NOLOCK)		ON SF.AccessedByCommonId = JTB.CommonID
					AND SF.StartDtID BETWEEN JTB.ActiveStartDtID AND JTB.ActiveEndDtID
LEFT JOIN BICommon.TeamMember.JobTitleDim
JTD (NOLOCK)		ON JTB.JobTitleID = JTD.JobTitleID
LEFT JOIN BISandboxWrite.dbo.MG_JobTitleGroups
JTG (NOLOCK)		ON JTG.[Job Title] = JTD.JobTitle
LEFT JOIN QLODS.dbo.EmployeeMaster
EM (NOLOCK)			ON SF.AccessedByCommonId = EM.CommonID

--DROP TABLE #ByJobGroup
--SELECT t.LoanNumber
--	, t.Pilot
--	, JobGroup			= t.Team
--	, DistinctTouches	= COUNT(CASE WHEN t.[Last on Day by Team Member] = 1 AND t.[In Ops] = 1 THEN t.[AMP Session Date] END)
--INTO #ByJobGroup
--FROM #Touches t
--GROUP BY t.LoanNUmber, t.Team, t.Pilot

--DROP TABLE #ByJobGroup2
--SELECT PVT.*
--INTO #ByJobGroup2
--FROM (
--		SELECT JobGroup
--			, LoanNumber
--			, Pilot
--			, DistinctTouches
--		FROM #ByJobGroup
--	) T
--PIVOT (
--			SUM(DistinctTouches) FOR JobGroup IN ([Underwriting], [Vendor], [Closing], [Communications/Client Relations], [Audit/Training], [Banking], [Title Source], [Other])
--	) PVT

--SELECT Pilot
--	, Banking				= AVG(1.0*[Banking])
--	, UW					= AVG(1.0*[Underwriting])
--	, CR					= AVG(1.0*[Communications/Client Relations])
--	, Vendor				= AVG(1.0*[Vendor])
--	, TitleSource			= AVG(1.0*[Title Source])
--	, Closing				= AVG(1.0*[Closing])
--	, AuditT				= AVG(1.0*[Audit/Training])
--	, Other					= AVG(1.0*[Other])
--FROM #ByJobGroup2
--R
--GROUP BY Pilot

SELECT t.LoanNumber
	, t.Pilot
	, t.[Team Member Common ID]
	, t.[Team Member]
	, t.Team
	, t.Division
	, t.[Job Group]
	, t.[Job Title]
	, t.[Team Member Flg]
	--, [Total Time in Loan]					= SUM(t.[Session Duration])
	--, [Total Loan Touches]					= COUNT(t.[AMP Session Date])
	--, [Average Time in Loan]				= AVG(t.[Session Duration])
	, [Total OPS Time in Loan]				= SUM(CASE WHEN t.[In Ops] = 1 THEN t.[Session Duration] END)
	--, [Total OPS Loan Touches]				= COUNT(CASE WHEN t.[In Ops] = 1 THEN t.[AMP Session Date] END)
	--, [Average OPS Time in Loan]			= AVG(CASE WHEN t.[In Ops] = 1 THEN t.[Session Duration] END) 
	--, [Total Distinct Loan Touches]			= COUNT(CASE WHEN t.[Last on Day by Team Member] = 1 THEN t.[AMP Session Date] END)
	, [Total Distinct OPS Loan Touches]		= COUNT(CASE WHEN t.[Last on Day by Team Member] = 1 AND t.[In Ops] = 1 THEN t.[AMP Session Date] END)

INTO #tmLoan
FROM #touches t
GROUP BY t.LoanNumber
	, t.Pilot
	, t.[Team Member Common ID]
	, t.[Team Member]
	, t.Team
	, t.Division
	, t.[Job Group]
	, t.[Job Title]
	, t.[Team Member Flg]



SELECT tml.Pilot
	, [TEAM]								= CASE WHEN GROUPING(tml.team) = 1 THEN 'All' ELSE ISNULL(tml.team, 'Unknown') END
	, [Division]							= CASE WHEN GROUPING(tml.division) = 1 THEN 'All' ELSE ISNULL(tml.division, 'Unknown') END
	, [Job Title]							= CASE WHEN GROUPING(tml.[Job Title]) = 1 THEN 'All' ELSE ISNULL(tml.[Job Title], 'Unknown') END
	, [Team Member flg]						= CASE WHEN GROUPING(tml.[Team Member flg]) = 1 THEN 'All' 
												WHEN tml.[Team Member Flg] = 1 THEN 'TM'
												WHEN tml.[Team Member Flg] = 0 THEN 'TL'
												ELSE 'Unknown' END
	, [Distinct Loans]						= COUNT(DISTINCT tml.LoanNumber)
	, [Team Members]						= COUNT(DISTINCT tml.[Team Member Common ID])
	--, [Total Loan Touches]					= SUM(tml.[Total Loan Touches])
	--, [Total Ops Loan Touches]				= SUM(tml.[Total OPS Loan Touches])
	--, [Total Distinct Loan Touches]			= SUM(tml.[Total Distinct Loan Touches])
	--, [Total Distinct OPS Loan Touches]		= SUM(tml.[Total Distinct OPS Loan Touches])
	--, [AVG Loan Touches]					= AVG(tml.[Total Loan Touches]*1.0)
	--, [AVG Ops Loan Touches]				= AVG(tml.[Total OPS Loan Touches]*1.0)
	--, [AVG Distinct Loan Touches]			= AVG(tml.[Total Distinct Loan Touches]*1.0)
	, [AVG Distinct OPS Loan Touches]		= SUM(tml.[Total Distinct OPS Loan Touches]*1.0)/COUNT(Distinct tml.LoanNumber)
	--, [Total Time in Loan]					= SUM(tml.[Total Time in Loan]/3600.0)
	, [AVG OPS Time in Loan]				= SUM(tml.[Total OPS Time in Loan]/3600.0)/COUNT(Distinct tml.LoanNumber)
	--, [AVG Session Length]					= SUM(tml.[Total Time in Loan]/60.0)*1.0/SUM(tml.[Total Loan Touches])	
	--, [AVG Ops Session Length]				= SUM(tml.[Total OPS Time in Loan]/60.0)*1.0/SUM(tml.[Total OPS Loan Touches])
		 
FROM #tmLoan tml

GROUP BY GROUPING SETS (
							(tml.Pilot), 
							(tml.Pilot, tml.team),
							(tml.Pilot, tml.team, tml.Division),
							(tml.Pilot, tml.team, tml.Division, tml.[Job Title], tml.[Team Member Flg])
						)


ORDER BY  tml.Pilot
	, CASE WHEN GROUPING(tml.team) = 1 THEN 'A1' ELSE 'z' END
	, CASE WHEN GROUPING(tml.division) = 1 THEN 'A1' ELSE 'z' END
	, CASE WHEN GROUPING(tml.[Job Title]) = 1 THEN 'A1' ELSE 'z' END
	, CASE WHEN GROUPING(tml.[Team Member flg]) = 1 THEN 'A1' 
												ELSE 'z' END
	, tml.Team, tml.Division, tml.[Job Title], tml.[Team Member Flg]

