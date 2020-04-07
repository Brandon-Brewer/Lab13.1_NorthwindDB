/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  em.FullNameFirstLast
, cf.*

FROM BICallData.dbo.CallFact cf
	INNER JOIN QLODS.dbo.EmployeeMaster		em ON em.CommonID = cf.CallEmployeeCommonID

WHERE 1=1
	--AND cf.StartDateID BETWEEN 20170700 AND 20170916
	--AND (em.OpsDirector LIKE '%Jason Halliday%'
		--OR em.OpsDirector LIKE '%Ryan Meyers%')
	--AND (--cf.CallEmployeeCommonID =  2292569
	--	cf.CallToPhoneNumberID = 13333
		--OR cf.CallFromPhoneNumberID = 13333)
	AND cf.CallEmployeeCommonID = 2118976
	AND cf.StartDateID = 20170724

ORDER BY cf.StartDateTime