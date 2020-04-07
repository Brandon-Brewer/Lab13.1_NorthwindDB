SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT
	  L.LoanNumber
	--, SRD.ReasonText
	--, SRDD.ReasonDetailText
	--, [After First 35 Flg]			= CASE WHEN ltf.TransDateTime > L.[1stStat35Dt] THEN 1 ELSE 0 END
	--, [Within First 10 days flg]	= CASE WHEN ltf.TransDateTime <= DATEADD(day, 10, L.Stat21Dt) THEN 1 ELSE 0 END
	--, [Within First 15 days flg]	= CASE WHEN ltf.TransDateTIme <= DATEADD(day, 15, L.Stat21Dt) THEN 1 ELSE 0 END

FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = L.LoanNumber
		AND ltf.EventTypeID = 2
		AND ltf.StatusID = 117
		AND ltf.RollBackFlg = 0
		AND ltf.DeleteFlg = 0
	--INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = ltf.ReasonGroupID
	--INNER JOIN QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
	--INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700






/********************************************************************************
Get the top Suspense reasons before and after CA
********************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	  L.LoanNumber
	, SRD.ReasonText
	--, SRDD.ReasonDetailText
	, [After 35 flg]	= CASE WHEN ltf.TransDateTime > L.[1stStat35Dt] THEN 1 ELSE 0 END

FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = L.LoanNumber
		AND ltf.EventTypeID = 2
		AND ltf.StatusID = 117
		AND ltf.RollBackFlg = 0
		AND ltf.DeleteFlg = 0
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = ltf.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
	--INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700
	AND L.[1stStat35ID] IS NOT NULL









/****************************************************************
This is to get suspense reason and time in suspense.
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #sus
SELECT DISTINCT
	  L.LoanNumber
INTO #sus
FROM QLODS..LKWD L
	LEFT JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = L.LoanNumber
		AND ltf.EventTypeID = 2
		AND ltf.StatusID = 117
		AND ltf.RollBackFlg = 0
		AND ltf.DeleteFlg = 0
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = ltf.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700
	AND SRDD.ReasonDetailText = 'Repairs/Appraisal'



DROP TABLE IF EXISTS #sus2
SELECT 
	  LTF.LoanNumber
	, LTF.StatusID
	, LTF.TransDateTime
	, ROW_NUMBER() OVER(PARTITION BY LTF.LoanNumber ORDER BY LTF.TransDtID, LTF.TransTmID) 'RN'
INTO #sus2
FROM #sus
	INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = #sus.LoanNumber
WHERE 1=1
	AND LTF.EventTypeID = 2
	AND LTF.DeleteFlg = 0
	AND LTF.RollBackFlg = 0
ORDER BY LTF.LoanNumber, LTF.TransDateTime


DROP TABLE IF EXISTS #sus3
SELECT
	s1.LoanNumber
	--, s1.StatusID
	--, s1.TransDateTime
	--, s2.StatusID
	--, s2.TransDateTime
	, [Time in Status]	= SUM(DATEDIFF(SECOND, s1.TransDateTime, s2.TransDateTime))/86400.0
INTO #sus3
FROM #sus2 s1
	LEFT JOIN #sus2 s2 ON s1.LoanNumber = s2.LoanNumber
		AND s1.RN = (s2.RN - 1)
WHERE s1.StatusID = 117
GROUP BY s1.LoanNumber

---Get Average-----
SELECT AVG(#sus3.[Time in Status])
FROM #sus3




