/****** Script for SelectTopNRows command from SSMS  ******/

DROP TABLE IF EXISTS #bp

SELECT ROW_NUMBER() OVER (Partition by ast.agentUserName ORDER BY ast.timeStamp) 'RN'
, astdim.Description, astdim.DisplayName , ast.*
INTO #bp

/*
  ast.agentEmployeeId
, ast.agentUserName
, DATEDIFF(second, MIN(ast.[timestamp]), MAX(ast.[timestamp])) 'total seconds'
, (DATEDIFF(second, MIN(ast.[timestamp]), MAX(ast.[timestamp])))/3600 'hours'
, (DATEDIFF(second, MIN(ast.[timestamp]), MAX(ast.[timestamp])))%3600/60 'minutes'
, (DATEDIFF(second, MIN(ast.[timestamp]), MAX(ast.[timestamp])))%60 'seconds'
*/
FROM [SRC].[chat].[AgentState] ast
	LEFT JOIN CTI.dbo.AgentStateLookup astdim ON astdim.AgentStateId = ast.agentStateId

WHERE 1=1
	AND ast.agentUserName = 'Charlynn Dillon'  
	AND ast.datekey = 20171205
	AND ast.agentStateId <> 0

ORDER BY ast.timestamp ASC

--GROUP BY	  ast.agentEmployeeId, ast.agentUserName



SELECT --#bp.agentStateId, bp2.agentStateId, #bp.timestamp, bp2.timestamp,
	--DATEDIFF(second, #bp.timestamp, bp2.timestamp)
	SUM(DATEDIFF(second, #bp.timestamp, bp2.timestamp))
FROM #bp
	LEFT JOIN #bp bp2 ON (bp2.RN - 1) = #bp.RN
WHERE #bp.agentStateId <> 0
--(CONCAT(#bp.agentStateId, bp2.agentStateId) <> '04'
	--OR CONCAT(#bp.agentStateId, bp2.agentStateId) <> '00')



--SELECT * FROM #bp