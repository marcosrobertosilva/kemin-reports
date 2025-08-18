SELECT 
    f.[Item number],
    im.[Item name],
    f.[Facility],
    im.[Item type],
    im.[Make/buy code],
    iwagg.[Safety Stock],
    SUM(f.[On-hand balance for inspection -facility]) AS [On-hand inspect],
    iwagg.[On-hand approved],
    iwagg.[Reorder point],
    MAX(im.[User-defined field 5 - item]) AS [User-defined field 5 - item],
    ISNULL(col.[Past & next 30 days orders], 0) AS [Past & next 30 days orders],
    (SUM(f.[On-hand balance - facility]) - ISNULL(col.[Past & next 30 days orders], 0)) AS [OH - Orders Available],
    COUNT(DISTINCT(woh.[Manufacturing order number])) AS [MO's next 30 days],
    ROUND(ISNULL(ap.[12 months AVG Sales], 0), 0) AS [12 months AVG Sales],
    ROUND(ISNULL(
    CASE 
        WHEN ROUND(ISNULL(ap.[12 months AVG Sales], 0), 0) = 0 THEN NULL
        ELSE SUM(f.[On-hand balance - facility]) / ROUND(ISNULL(ap.[12 months AVG Sales], 0), 0)
    END,
    0
    ), 1) AS [Months of Stock],
    ROUND(ISNULL(
    CASE 
        WHEN ROUND(ISNULL(ap.[12 months AVG Sales], 0), 0) = 0 THEN NULL
        ELSE SUM(f.[On-hand balance - facility]) / (ROUND(ISNULL(ap.[12 months AVG Sales], 0), 0) / 30.0)
    END,
    0
    ), 0) AS [Days of Stock],
    ROUND(ISNULL(MAX(fc.[Avg Forecast Next 7 Months]), 0), 0) AS [Avg Forecast Next 7 Months]
    
FROM [PRD_Staging].[m3].[V_ItemFacility] f
LEFT JOIN [PRD_Staging].[m3].[V_ItemMaster] im
    ON f.[Item number] = im.[Item number]
LEFT JOIN (
    SELECT
        [Item number],
        [Facility],
        SUM([On-hand balance approved]) AS [On-hand approved],
        SUM([Safety stock]) AS [Safety Stock],
        MAX([Reorder point]) AS [Reorder point]
    FROM [PRD_Staging].[m3].[V_ItemWarehouse]
    GROUP BY [Item number], [Facility]
) iwagg
    ON f.[Item number] = iwagg.[Item number]
    AND f.[Facility] = iwagg.[Facility]
LEFT JOIN (
    SELECT
        [Facility],
        [Item number],
        SUM([Ordered quantity - basic U/M]) AS [Past & next 30 days orders]
    FROM [PRD_Staging].[m3].[V_CustomerOrderLines]
    GROUP BY [Item number], [Facility]
) col
    ON f.[Item number] = col.[Item number]
    AND f.[Facility] = col.[Facility]
LEFT JOIN [PRD_Staging].[m3].[V_WorkOrderHead] woh
    ON f.[Item number] = woh.[Item number]
    AND f.[Facility] = woh.[Facility]
LEFT JOIN (
    SELECT 
        [Facility],
        [Item number],
        AVG(CAST([Manufactured quantity] AS FLOAT)) AS [12 months AVG Sales]
    FROM [PRD_Staging].[m3].[V_WorkOrderHead]
    WHERE [Actual finish date (ISO format)] >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY [Facility], [Item number]
) ap
    ON f.[Item number] = ap.[Item number]
    AND f.[Facility] = ap.[Facility]
LEFT JOIN (
    SELECT 
        [Item number],
        AVG(CAST([Manual forecast] AS FLOAT)) AS [Avg Forecast Next 7 Months]
    FROM [PRD_Staging].[m3].[V_Forecasting]
    WHERE CAST([Period] AS INT) BETWEEN CAST(FORMAT(GETDATE(), 'yyyyMM') AS INT)
                                     AND CAST(FORMAT(DATEADD(MONTH, 6, GETDATE()), 'yyyyMM') AS INT)
    GROUP BY [Item number]
) fc
    ON f.[Item number] = fc.[Item number]

GROUP BY 
    f.[Item number],
    im.[Item name],
    f.[Facility],
    im.[Item type],
    im.[Make/buy code],
    iwagg.[Safety Stock],
    iwagg.[On-hand approved],
    iwagg.[Reorder point],
    col.[Past & next 30 days orders],
    ap.[12 months AVG Sales]