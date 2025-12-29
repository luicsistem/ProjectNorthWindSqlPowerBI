CREATE VIEW vw_VentasMensuales_MoM
AS
WITH VentasMensuales AS (
    SELECT
        YEAR(O.OrderDate) AS Anio,
        MONTH(O.OrderDate) AS Mes,
        SUM(
            OD.UnitPrice * OD.Quantity * (1 - OD.Discount)
        ) AS Ventas
    FROM Orders O
    JOIN [Order Details] OD
        ON O.OrderID = OD.OrderID
    GROUP BY
        YEAR(O.OrderDate),
        MONTH(O.OrderDate)
),
ComparacionMoM AS (
    SELECT
        Anio,
        Mes,
        Ventas,
        LAG(Ventas) OVER (ORDER BY Anio, Mes) AS Ventas_Mes_Anterior
    FROM VentasMensuales
)
SELECT
    Anio,
    Mes,
    Ventas,
    Ventas_Mes_Anterior,
    CASE
        WHEN Ventas_Mes_Anterior IS NULL OR Ventas_Mes_Anterior = 0
            THEN NULL
        ELSE
            ROUND(
                (Ventas - Ventas_Mes_Anterior) * 100.0 / Ventas_Mes_Anterior,
                2
            )
    END AS MoM_Porcentaje
FROM ComparacionMoM;
GO