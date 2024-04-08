USE [LEODB]
GO

-- Criando as tabelas de destino
CREATE TABLE Pedido (
    codigoPedido INT NOT NULL,
    dataPedido DATE NOT NULL,
    CONSTRAINT PK_Pedido PRIMARY KEY (codigoPedido)
);

CREATE TABLE Cliente (
    email VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (email)
);

CREATE TABLE ItemPedido (
    codigoPedido INT NOT NULL,
    qtd INT NOT NULL,
    nomeProduto VARCHAR(255) NOT NULL,
    valor DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_ItemPedido PRIMARY KEY (codigoPedido, nomeProduto),
    CONSTRAINT FK_ItemPedido_Pedido FOREIGN KEY (codigoPedido) REFERENCES Pedido (codigoPedido)
);

CREATE TABLE Produto (
    nomeProduto VARCHAR(255) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    valor DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_Produto PRIMARY KEY (nomeProduto)
);

GO

-- Procedure para separar os dados
CREATE PROCEDURE [dbo].[SepararDadosPedido]

AS

BEGIN

    -- Inserindo dados na tabela Pedido
    INSERT INTO Pedido (codigoPedido, dataPedido)
    SELECT codigoPedido, CONVERT(DATE, dataPedido)
    FROM carga;

    -- Inserindo dados na tabela Cliente
    INSERT INTO Cliente (email)
    SELECT DISTINCT email
    FROM carga;

    -- Inserindo dados na tabela ItemPedido e Produto
    DECLARE @codigoPedido INT, @qtd INT, @nomeProduto VARCHAR(255), @valor DECIMAL(18,2), @sku VARCHAR(50)

    WHILE EXISTS (SELECT * FROM carga)
    BEGIN
        SELECT TOP 1 @codigoPedido = codigoPedido, @qtd = qtd, @nomeProduto = nomeProduto, @valor = valor, @sku = sku
        FROM carga

        INSERT INTO ItemPedido (codigoPedido, qtd, nomeProduto, valor)
        VALUES (@codigoPedido, @qtd, @nomeProduto, @valor)

        IF NOT EXISTS (SELECT * FROM Produto WHERE nomeProduto = @nomeProduto)
        BEGIN
            INSERT INTO Produto (nomeProduto, sku, valor)
            VALUES (@nomeProduto, @sku, @valor)
        END

        DELETE FROM carga
        WHERE codigoPedido = @codigoPedido
    END

END
GO

-- Executando a procedure
EXEC [dbo].[SepararDadosPedido]
GO
