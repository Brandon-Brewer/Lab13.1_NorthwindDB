/********
Need AvayaRona (or total Rona) from cude to get Answer Rate
	Currently only including CTIRona
********/

DROP TABLE IF EXISTS #bp

SELECT  
  EM.FullNameFirstLast 	
, COUNT(CASE WHEN cod.CallDesc = 'CONNECTED' AND cf.calldirectionid = 2 THEN 1 END) AS Answered
, COUNT(CASE WHEN cod.CallDesc = 'MISSED OPPORTUNITY' AND cf.calldirectionid = 2 THEN 1 END) AS MissedOpp
, COUNT(CASE WHEN cod.CallDesc = 'RONA' AND cf.calldirectionid = 2 THEN 1 END) AS CTIRONA
INTO #bp

FROM BICallData.dbo.CallFact cf
	LEFT JOIN QLODS.dbo.EmployeeMaster em WITH (NOLOCK) ON cf.CallEmployeeID = em.EmployeeDimID 
	LEFT JOIN BICallData.dbo.CalloutcomeDim cod WITH (NOLOCK) ON cf.CallOutComeID = cod.CallOutcomeID

WHERE CF.CallFromPhoneNumberID <> 31999
	AND CF.startdateid = 20171211
	AND em.OpsDirector IN ('Jason Halliday', 'Ryan Meyers')
  
GROUP BY em.FullNameFirstLast


SELECT 
  #bp.*
, CAST(100.0*(#bp.Answered) / NULLIF((#bp.Answered + #bp.MissedOpp + #bp.CTIRONA), 0) AS numeric(9,2)) 'Answer Rate'
FROM #bp
ORDER BY #bp.FullNameFirstLast