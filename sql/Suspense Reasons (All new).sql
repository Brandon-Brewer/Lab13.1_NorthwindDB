SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  L.LoanNumber
, lpd.LoanPurpose
, sus.TransDtID
, SRD.ReasonText
, SRDD.ReasonDetailText

FROM QLODS.dbo.LKWD L
	CROSS APPLY(
				SELECT TOP 1
					  ltf.ReasonGroupID
					, ltf.TransDtID
				FROM QLODS..LKWDTransFact ltf
				WHERE ltf.LoanNumber = L.LoanNumber
					AND ltf.EventTypeID = 2
					AND ltf.StatusID = 117
					AND ltf.RollBackFlg = 0
					AND ltf.DeleteFlg = 0
				ORDER BY ltf.TransDtID ASC, ltf.TransTmID ASC
				)sus
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = sus.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
	INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID

WHERE 1=1
	AND L.[1stStat33ID] BETWEEN 20170400 AND 20170717
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	