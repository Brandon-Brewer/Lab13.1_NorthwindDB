SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #hotlist
SELECT
  hotlist.PriorityListName
, listpriority.PriorityDescription
, lpm.*
, CASE WHEN lpm.EndDateTime IS NULL AND lpm.ListEndDateID IS NULL THEN GETDATE() ELSE lpm.EndDateTime END 'AdjEndDateTime'
, CASE WHEN listpriority.PriorityDescription LIKE '%Section%' THEN 1 ELSE 0 END 'SectionFlg'
, CASE WHEN listpriority.PriorityDescription LIKE '%Priority%' THEN 1 ELSE 0 END 'PriorityFlg'
, CASE WHEN listpriority.PriorityDescription LIKE '%Section%' THEN 'Section' ELSE 'Priority' END 'Section/Priority'
INTO #hotlist
FROM BILoan.dbo.LoanPriorityMovementFact lpm WITH (NOLOCK)
	LEFT JOIN BILoan.dbo.LoanPriorityListDim hotlist WITH (NOLOCK) ON hotlist.LoanPriorityListID = lpm.LoanPriorityListID
	LEFT JOIN BILoan.dbo.LoanPriorityDisplayDim listpriority WITH (NOLOCK) ON listpriority.LoanPriorityDisplayID = lpm.DisplayPriorityID
	LEFT JOIN QLODS.dbo.LKWD L WITH (NOLOCK) ON L.LoanNumber = lpm.LoanNumber
WHERE 1=1
	AND hotlist.PriorityListName = 'CCS'
	--AND listpriority.PriorityDescription NOT LIKE '%Section%'
	--AND lpm.EndDateTime IS NULL
	--AND lpm.ListEndDateID IS NULL
	--AND lpm.LoanNumber = '3417148792'
	--AND '2018-09-10 18:00:00.000' BETWEEN lpm.StartDateTime AND lpm.EndDateTime
ORDER BY lpm.StartDateTime



DROP TABLE IF EXISTS #dates
SELECT DATEADD(HOUR, 21, dd.[Date]) 'Date'  -- Timestamp at 9pm
INTO #dates
FROM QLODS.dbo.DateDim dd WITH (NOLOCK)
WHERE dd.DateID BETWEEN 20181201 AND 20190106



SELECT
  #dates.[Date]
, COUNT(DISTINCT #hotlist.EmployeeCommonID) 'TM Count'
, SUM(#hotlist.PriorityFlg) 'Priorities'
, SUM(#hotlist.SectionFlg) 'Sections'
, SUM(#hotlist.PriorityFlg) + SUM(#hotlist.SectionFlg) 'Total'
FROM #hotlist
	CROSS JOIN #dates
WHERE #dates.[Date] BETWEEN #hotlist.StartDateTime AND #hotlist.AdjEndDateTime
GROUP BY #dates.[Date]


