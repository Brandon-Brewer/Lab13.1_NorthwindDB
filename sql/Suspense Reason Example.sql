SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT ltf.LoanNumber
, SRD.ReasonText
, SRDD.ReasonDetailText

FROM QLODS..LKWDTransFact ltf
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = ltf.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
	INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID

WHERE ltf.StatusID = 117
	AND ltf.EventTypeID = 2
	AND ltf.RollBackFlg = 0
	AND ltf.DeleteFlg = 0

ORDER BY ltf.TransDtID