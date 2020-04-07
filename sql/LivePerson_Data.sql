SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT
  CONVERT(VARCHAR(8), ast.[timestamp], 112) 'DateID'
, ast.agentEmployeeId
, ast.agentUserName
, ast.agentStateId
, ast.[timestamp]
, ROW_NUMBER() OVER (Partition by ast.agentEmployeeId, ast.datekey ORDER BY ast.[timeStamp]) 'RN'
INTO #bp
FROM [SRC].[chat].[AgentState] ast
WHERE 1=1
	AND ast.agentStateId <> 0
	AND ast.datekey BETWEEN 20171205 AND 20171206

/***********************************************************************************************
***********************************************************************************************/
DROP TABLE IF EXISTS #results
SELECT
  #bp.DateID
, #bp.agentEmployeeId
, #bp.agentUserName
, #bp.agentStateId
, SUM(DATEDIFF(second, #bp.timestamp, bp2.timestamp)) 'Seconds'
INTO #results
FROM #bp
	LEFT JOIN #bp bp2 ON (bp2.RN - 1) = #bp.RN
		AND #bp.agentEmployeeId = bp2.agentEmployeeId
		AND #bp.dateID = bp2.dateID
GROUP BY #bp.dateID, #bp.agentEmployeeId, #bp.agentUserName, #bp.agentStateId
HAVING SUM(DATEDIFF(second, #bp.timestamp, bp2.timestamp)) > 0

/***********************************************************************************************
***********************************************************************************************/
SELECT
  #results.dateID
, #results.agentEmployeeId 'CommonID'
, #results.agentUserName 'Agent'
, SUM(CASE WHEN #results.agentStateId <> 1 THEN #results.Seconds ELSE 0 END) 'Logged In Time'
, SUM(CASE WHEN #results.agentStateID = 2 THEN #results.Seconds ELSE 0 END) 'Online Time'
FROM #results
GROUP BY #results.DateID, #results.agentEmployeeId, #results.agentUserName
ORDER BY #results.dateID, #results.agentUserName