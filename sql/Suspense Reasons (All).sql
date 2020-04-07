SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #sus
SELECT ltf.LoanNumber
INTO #sus
FROM QLODS..LKWDTransFact ltf
WHERE ltf.StatusID = 117
	AND ltf.EventTypeID = 2
	AND ltf.TransDtID BETWEEN 20170400 AND 20170717
	AND ltf.RollBackFlg = 0
	AND ltf.Deleteflg = 0
GROUP BY ltf.LoanNumber

--------------------------------------------------------
DROP TABLE IF EXISTS #bp
SELECT
  #sus.LoanNumber
, fSus.TransDtID
, fSus.ReasonText
, fSus.ReasonDetailText
INTO #bp
FROM #sus
	Outer Apply(
				SELECT TOP 1
					ltf.TransDtID
					, SRD.ReasonText
					, SRDD.ReasonDetailText
				FROM QLODS..LKWDTransFact ltf
					INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = ltf.ReasonGroupID
					INNER JOIN QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
					INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID
				WHERE ltf.LoanNumber = #sus.LoanNumber
					AND ltf.EventTypeID = 2
					AND ltf.StatusID = 117
					AND ltf.RollBackFlg = 0
					AND ltf.DeleteFlg = 0
				ORDER BY ltf.TransDtID ASC, ltf.TransTmID ASC
				)fSus

WHERE fSus.TransDtID BETWEEN 20170400 AND 20170717

--------------------------------------------------------------------
SELECT 
  #bp.LoanNumber
, lpd.LoanPurpose
, #bp.TransDtID
, #bp.ReasonText
, #bp.ReasonDetailText
FROM #bp
	INNER JOIN QLODS..LKWD L ON L.LoanNumber = #bp.LoanNumber
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
