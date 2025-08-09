SELECT 
    f.[Item number],
    im.[Item name],
    f.[Facility],
    im.[Item type],
    im.[Make/buy code],
    SUM(iw.[Safety stock]) AS [Safety Stock],
    SUM(f.[On-hand balance for inspection -facility]) AS [On-hand inspect],
    SUM(iw.[On-hand balance approved]) AS [On-hand approved],
    MAX(iw.[Reorder point]) AS [Reorder point],
    MAX(im.[User-defined field 5 - item]) AS [User-defined field 5 - item],
    SUM(iw.[Order quantity]) AS [Order quantity],
    (SUM(f.[On-hand balance - facility]) - SUM(iw.[Order quantity])) AS [OH - Orders Available],
    COUNT(DISTINCT(woh.[Manufacturing order number])) AS [MO's next 30 days],
    ROUND(ISNULL(ap.[Avg Monthly Production], 0), 0) AS [Avg Monthly Production],
    ROUND(ISNULL(
    CASE 
        WHEN ROUND(ISNULL(ap.[Avg Monthly Production], 0), 0) = 0 THEN NULL
        ELSE SUM(f.[On-hand balance - facility]) / ROUND(ISNULL(ap.[Avg Monthly Production], 0), 0)
    END,
    0
    ), 1) AS [Months of Stock],

    ROUND(ISNULL(
    CASE 
        WHEN ROUND(ISNULL(ap.[Avg Monthly Production], 0), 0) = 0 THEN NULL
        ELSE SUM(f.[On-hand balance - facility]) / (ROUND(ISNULL(ap.[Avg Monthly Production], 0), 0) / 30.0)
    END,
    0
    ), 0) AS [Days of Stock],

    ROUND(ISNULL(MAX(fc.[Avg Forecast Next 7 Months]), 0), 0) AS [Avg Forecast Next 7 Months]

FROM [PRD_Staging].[m3].[V_ItemFacility] f
LEFT JOIN [PRD_Staging].[m3].[V_ItemMaster] im
    ON f.[Item number] = im.[Item number]
LEFT JOIN [PRD_Staging].[m3].[V_ItemWarehouse] iw
    ON f.[Item number] = iw.[Item number]
    AND f.[Facility] = iw.[Facility]
LEFT JOIN [PRD_Staging].[m3].[V_WorkOrderHead] woh
    ON f.[Item number] = woh.[Item number]
    AND f.[Facility] = woh.[Facility]
LEFT JOIN (
    SELECT 
        [Facility],
        [Item number],
        AVG(CAST([Manufactured quantity] AS FLOAT)) AS [Avg Monthly Production]
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

-- WHERE f.[Facility] = 'NOA'
WHERE f.[Item number] = '018173-21-WW'
GROUP BY 
    f.[Item number],
    im.[Item name],
    f.[Facility],
    im.[Item type],
    im.[Make/buy code],
    ap.[Avg Monthly Production]