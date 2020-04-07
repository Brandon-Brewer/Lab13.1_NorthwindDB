Set Transaction Isolation Level Read Uncommitted

Select
  lo.CreateDtID
, COUNT(*)			'LoanCount'
, dd.WeekendFlg
, [NetLeads]		= SUM(CASE WHEN lo.Stat9595DtID IS NULL THEN 1 ELSE 0 END)
FROM QLODS..LOLA lo (NOLOCK)
	INNER JOIN QLODS..DateDim dd (NOLOCK) ON dd.DateID = lo.CreateDtID
WHERE 1=1
	AND lo.CreateDtID BETWEEN 20161200 AND 20161299
	AND lo.LoanPurposeID = 7 --Refi
	AND lo.DeleteFlg = 0
GROUP BY lo.CreateDtID, dd.WeekendFlg
ORDER BY lo.CreateDtID




Select
  COUNT(*)
, [setup]	= SUM(CASE WHEN lo.Stat20DtID = lo.AllocatedDtID THEN 1 ELSE 0 END)
, [pct]		= AVG(CASE WHEN lo.Stat20DtID = lo.AllocatedDtID THEN 1.0 ELSE 0.0 END)
FROM QLODS..LOLA lo (NOLOCK)
WHERE 1=1
	AND lo.AllocatedDtID BETWEEN 20170300 AND 20170399
	AND lo.DeleteFlg = 0





Select
  lcgd.FriendlyName
, COUNT(*) 'Credit Pull Count'
FROM QLODS..LOLA lo (NOLOCK)
	INNER JOIN QLODS..DateDim dd (NOLOCK) ON dd.DateID = lo.FirstCreditPullDtID
	INNER JOIN QLODS..LoanChannelGroupDim lcgd (NOLOCK) ON lcgd.LoanChannelGroupID = lo.LoanChannelGroupID
WHERE 1=1
	AND dd.QuarterKey = 20164
	AND lo.DeleteFlg = 0
GROUP BY lcgd.FriendlyName
ORDER BY 2 DESC




SELECT
  lotf.TransDateTime
, lotf.UniqueStatusID
, sd.StatusFullDesc
, lotf.StatusSequence
FROM QLODS..LOLATransFact lotf (NOLOCK)
	INNER JOIN QLODS..StatusDim sd (NOLOCK) ON sd.StatusID = lotf.UniqueStatusID
WHERE lotf.JacketNumber = '3363493492'
ORDER BY lotf.TransDateTime




SELECT COUNT(DISTINCT lotf.JacketNumber)
FROM QLODS..LOLATransFact lotf (NOLOCK)
	INNER JOIN QLODS..LOLATransFact lotf2 (NOLOCK) lotf2.JackNumber = lotf.JackNumber
WHERE 1=1
	AND lotf.UniqueStatusID = 4089
	AND lotf.DateID BETWEEN 20160600 AND 20160699
--	AND lotf.StatusSequence = 1














