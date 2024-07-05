CREATE PROCEDURE [dbo].[AtualizarSaldoEstoque]
AS
BEGIN
    DECLARE @sku VARCHAR(50)
    DECLARE @nomeProduto VARCHAR(255)
    DECLARE @quantidade INT

    DECLARE cargaCursor CURSOR FOR
    SELECT sku, nomeProduto, qntComprada
    FROM cargaEstoque;

    OPEN cargaCursor;

    FETCH NEXT FROM cargaCursor INTO @sku, @nomeProduto, @quantidade;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE Produto
        SET saldoEstoque = saldoEstoque + @quantidade
        WHERE nomeProduto = @nomeProduto AND sku = @sku;

        FETCH NEXT FROM cargaCursor INTO @sku, @nomeProduto, @quantidade;
    END;

    CLOSE cargaCursor;
    DEALLOCATE cargaCursor;

    -- Ordenar a tabela Produto com base no saldoEstoque
    ;WITH CTE AS (
        SELECT *,
               ROW_NUMBER() OVER (ORDER BY saldoEstoque DESC) AS NumLinha
        FROM Produto
    )
    UPDATE Produto
    SET saldoEstoque = CTE.NumLinha
    FROM Produto
    INNER JOIN CTE ON Produto.sku = CTE.sku;

END;
