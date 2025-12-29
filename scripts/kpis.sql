
-- SQL – Creación de vw_SalesKPIs_Base


CREATE OR ALTER VIEW dbo.vw_SalesKPIs_Base
AS
WITH SalesByDate AS (
    SELECT
        OrderDate,
        SUM(SalesAmount) AS TotalSales,
        SUM(Quantity) AS TotalQuantity
    FROM dbo.vw_FactSales
    GROUP BY OrderDate
),
OrdersByDate AS (
    SELECT
        OrderDate,
        COUNT(DISTINCT OrderID) AS TotalOrders
    FROM dbo.vw_FactOrders
    GROUP BY OrderDate
)
SELECT
    d.[Date] AS KPI_Date,

    ISNULL(s.TotalSales, 0) AS TotalSales,
    ISNULL(s.TotalQuantity, 0) AS TotalQuantity,
    ISNULL(o.TotalOrders, 0) AS TotalOrders,

    CASE 
        WHEN o.TotalOrders = 0 THEN 0
        ELSE s.TotalSales * 1.0 / o.TotalOrders
    END AS AvgTicket

FROM dbo.vw_DimDate d
LEFT JOIN SalesByDate s
    ON s.OrderDate = d.[Date]
LEFT JOIN OrdersByDate o
    ON o.OrderDate = d.[Date];
GO

SELECT COUNT(*) FROM dbo.vw_SalesKPIs_Base;
SELECT COUNT(*) FROM dbo.vw_DimDate;


-- SQL – Creación de vw_DimCustomers_Analytics
CREATE OR ALTER VIEW dbo.vw_DimCustomers_Analytics
AS
WITH CustomerOrders AS (
    SELECT
        o.CustomerID,
        o.OrderID,
        o.OrderDate,
        SUM(fs.SalesAmount) AS OrderSales
    FROM Orders o
    JOIN dbo.vw_FactSales fs
        ON o.OrderID = fs.OrderID
    GROUP BY
        o.CustomerID,
        o.OrderID,
        o.OrderDate
),
CustomerAgg AS (
    SELECT
        CustomerID,
        MIN(OrderDate) AS FirstOrderDate,
        MAX(OrderDate) AS LastOrderDate,
        COUNT(DISTINCT OrderID) AS TotalOrders,
        SUM(OrderSales) AS TotalSales,
        AVG(OrderSales) AS AvgOrderValue
    FROM CustomerOrders
    GROUP BY CustomerID
),
GlobalAvg AS (
    SELECT AVG(TotalSales) AS AvgCustomerSales
    FROM CustomerAgg
)
SELECT
    c.CustomerID,
    c.CompanyName,

    ca.FirstOrderDate,
    ca.LastOrderDate,

    ISNULL(ca.TotalOrders, 0) AS TotalOrders,
    ISNULL(ca.TotalSales, 0) AS TotalSales,
    ISNULL(ca.AvgOrderValue, 0) AS AvgOrderValue,

    -- Antigüedad
    CASE 
        WHEN ca.FirstOrderDate IS NULL THEN 0
        ELSE DATEDIFF(YEAR, ca.FirstOrderDate, GETDATE())
    END AS CustomerTenureYears,

    -- Cliente activo
    CASE 
        WHEN ca.LastOrderDate >= DATEADD(MONTH, -12, CAST(GETDATE() AS date))
        THEN 1 ELSE 0
    END AS IsActiveCustomer,

    -- Segmentación
    CASE 
        WHEN ca.TotalSales >= ga.AvgCustomerSales THEN 'VIP'
        ELSE 'Regular'
    END AS CustomerSegment

FROM Customers c
LEFT JOIN CustomerAgg ca
    ON c.CustomerID = ca.CustomerID
CROSS JOIN GlobalAvg ga;
GO



SELECT COUNT(*) FROM dbo.vw_DimCustomers_Analytics;
SELECT COUNT(DISTINCT CustomerID) FROM Customers;



-- SQL – vw_ProductRankings

CREATE OR ALTER VIEW dbo.vw_ProductRankings
AS
SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    p.SupplierName,

    SUM(fs.SalesAmount) AS TotalSales,

    RANK() OVER (
        ORDER BY SUM(fs.SalesAmount) DESC
    ) AS SalesRank

FROM dbo.vw_FactSales fs
JOIN dbo.vw_DimProducts p
    ON fs.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    p.SupplierName;
GO


SELECT TOP 10 *
FROM dbo.vw_ProductRankings
ORDER BY SalesRank;


-- Debe coincidir
SELECT SUM(TotalSales) FROM dbo.vw_SalesKPIs_Base;
SELECT SUM(SalesAmount) FROM dbo.vw_FactSales;


