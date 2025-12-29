use Northwind;

CREATE OR ALTER VIEW dbo.vw_FactSales
AS
WITH OrderLineTotals AS (
    SELECT
        od.OrderID,
        od.ProductID,
        od.Quantity,
        od.UnitPrice,
        od.Discount,
        -- Total por línea
        od.Quantity * od.UnitPrice * (1 - od.Discount) AS LineSalesAmount
    FROM [Order Details] od
),
OrderTotals AS (
    SELECT
        OrderID,
        SUM(LineSalesAmount) AS OrderSalesAmount
    FROM OrderLineTotals
    GROUP BY OrderID
)
SELECT
    o.OrderID,                              -- Degenerate dimension
    o.OrderDate,
    o.CustomerID,
    o.EmployeeID,
    olt.ProductID,
    o.ShipVia AS ShipperID,

    -- Métricas base
    olt.Quantity,
    olt.UnitPrice,
    olt.Discount,

    -- Ventas
    olt.LineSalesAmount AS SalesAmount,

    -- Freight prorrateado
    CASE 
        WHEN ot.OrderSalesAmount = 0 THEN 0
        ELSE o.Freight * (olt.LineSalesAmount / ot.OrderSalesAmount)
    END AS FreightAllocated

FROM Orders o
INNER JOIN OrderLineTotals olt
    ON o.OrderID = olt.OrderID
INNER JOIN OrderTotals ot
    ON o.OrderID = ot.OrderID;
GO

-- **************************************************


--  SQL – Creación de vw_FactOrders

CREATE OR ALTER VIEW dbo.vw_FactOrders
AS
SELECT
    fs.OrderID,
    MIN(fs.OrderDate) AS OrderDate,
    fs.CustomerID,
    fs.EmployeeID,
    fs.ShipperID,

    -- Métricas de pedido
    SUM(fs.SalesAmount) AS OrderSalesAmount,
    SUM(fs.Quantity) AS TotalQuantity,
    COUNT(*) AS LineCount,
    MAX(o.Freight) AS Freight,

    -- Ticket promedio por pedido
    SUM(fs.SalesAmount) / COUNT(*) AS TicketAverage

FROM dbo.vw_FactSales fs
JOIN Orders o
    ON fs.OrderID = o.OrderID
GROUP BY
    fs.OrderID,
    fs.CustomerID,
    fs.EmployeeID,
    fs.ShipperID;
GO

