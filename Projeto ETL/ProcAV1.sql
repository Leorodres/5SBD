USE [AV1BANCO];
GO

CREATE TABLE Cliente (
    email VARCHAR(255) NOT NULL,
    nome VARCHAR(255),
    cpf VARCHAR(14),
    telefone VARCHAR(20),
    CONSTRAINT PK_Cliente PRIMARY KEY (email)
);

-- Criando as tabelas de destino
CREATE TABLE Pedido (
    codigoPedido INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    dataPedido DATE NOT NULL,
    nomeDestinatario VARCHAR(255),
    enderecoEntrega1 VARCHAR(255),
    enderecoEntrega2 VARCHAR(255),
    enderecoEntrega3 VARCHAR(255),
    cidadeEntrega VARCHAR(255),
    estadoEntrega VARCHAR(255),
    cepEntrega VARCHAR(20),
    paisEntrega VARCHAR(255),
    numeroIOSS VARCHAR(50),
    CONSTRAINT PK_Pedido PRIMARY KEY (codigoPedido),
    CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (email) REFERENCES Cliente (email)
);

CREATE TABLE ItemPedido (
    codigoPedido INT NOT NULL,
    nomeProduto VARCHAR(255) NOT NULL,
    idItemPedido INT NOT NULL,
    qtd INT NOT NULL,
    valor DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_ItemPedido PRIMARY KEY (codigoPedido, nomeProduto),
    CONSTRAINT FK_ItemPedido_Pedido FOREIGN KEY (codigoPedido) REFERENCES Pedido (codigoPedido)
);

CREATE TABLE Produto (
    sku VARCHAR(50) NOT NULL,
    nomeProduto VARCHAR(255) NOT NULL,
    valor DECIMAL(18,2) NOT NULL,
    saldoEstoque INT DEFAULT 0,
    CONSTRAINT PK_Produto PRIMARY KEY (sku),
    CONSTRAINT UQ_Produto_nomeProduto UNIQUE (nomeProduto)
);

CREATE TABLE Compras (
    codigoPedido INT NOT NULL,
    nomeProduto VARCHAR(255) NOT NULL,
    qtdComprada INT NOT NULL,
    CONSTRAINT PK_Compras PRIMARY KEY (codigoPedido, nomeProduto),
    CONSTRAINT FK_Compras_ItemPedido FOREIGN KEY (codigoPedido, nomeProduto) REFERENCES ItemPedido (codigoPedido, nomeProduto)
);

-- Criando a tabela de movimentação de estoque
CREATE TABLE MovimentacaoEstoque (
    idMovimento INT IDENTITY(1,1) PRIMARY KEY,
    codigoPedido INT NOT NULL,
    nomeComprador VARCHAR(255) NOT NULL,
    total DECIMAL(18,2) NOT NULL,
    pedidoCompleto BIT NOT NULL,
    dataMovimento DATETIME DEFAULT GETDATE()
);

-- Atualizando a definição da tabela Produto
ALTER TABLE Produto
    ADD CONSTRAINT CHK_SaldoEstoque_NaoNegativo CHECK (saldoEstoque >= 0);

GO

USE [AV1BANCO];
GO

CREATE PROCEDURE [dbo].[SepararDadosPedido]
AS
BEGIN
    -- Inserindo dados na tabela Cliente
    INSERT INTO Cliente (email, nome, cpf, telefone)
    SELECT DISTINCT [buyer-email], [buyer-name], cpf, [buyer-phone-number]
    FROM carga
    WHERE [buyer-email] NOT IN (SELECT email FROM Cliente);

    -- Inserindo dados na tabela Pedido
    INSERT INTO Pedido (codigoPedido, email, dataPedido, nomeDestinatario, enderecoEntrega1, enderecoEntrega2, enderecoEntrega3, cidadeEntrega, estadoEntrega, cepEntrega, paisEntrega, numeroIOSS)
    SELECT DISTINCT [order-id], [buyer-email], CONVERT(DATE, [purchase-date]) AS dataPedido, 
           [recipient-name], [ship-address-1], [ship-address-2], [ship-address-3], [ship-city], [ship-state], [ship-postal-code], [ship-country], [ioss-number]
    FROM carga;

    -- Inserindo dados na tabela Produto
    INSERT INTO Produto (sku, nomeProduto, valor, saldoEstoque)
    SELECT DISTINCT sku, [product-name], CONVERT(DECIMAL(18, 2), [item-price]) AS valor, 5 AS saldoEstoque
    FROM carga
    WHERE sku NOT IN (SELECT sku FROM Produto);

    -- Inserindo dados na tabela ItemPedido
    INSERT INTO ItemPedido (codigoPedido, nomeProduto, idItemPedido, qtd, valor)
    SELECT [order-id], [product-name], [order-item-id], [quantity-purchased], CONVERT(DECIMAL(18, 2), [item-price])
    FROM carga;

    -- Variáveis para controle
    DECLARE @codigoPedido INT
    DECLARE @nomeProduto VARCHAR(255)
    DECLARE @qtd INT
    DECLARE @saldoEstoque INT
    DECLARE @pedidoCompleto BIT
    DECLARE @totalPedido DECIMAL(18,2)
    DECLARE @totalValor DECIMAL(18,2)

    -- Cursor para percorrer os pedidos
    DECLARE pedidoCursor CURSOR FOR
    SELECT DISTINCT [order-id]
    FROM carga
    ORDER BY [order-id];

    -- Abrindo o cursor
    OPEN pedidoCursor;

    -- Loop para percorrer os pedidos
    FETCH NEXT FROM pedidoCursor INTO @codigoPedido;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Inicializando variáveis para este pedido
        SET @totalPedido = 0;
        SET @totalValor = 0;
        SET @pedidoCompleto = 1;

        -- Cursor para percorrer os itens do pedido atual
        DECLARE itemCursor CURSOR FOR
        SELECT nomeProduto, qtd
        FROM ItemPedido
        WHERE codigoPedido = @codigoPedido
        ORDER BY nomeProduto;

        -- Abrindo o cursor
        OPEN itemCursor;

        -- Loop para percorrer os itens do pedido atual
        FETCH NEXT FROM itemCursor INTO @nomeProduto, @qtd;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Obtendo o saldo de estoque do produto
            SELECT @saldoEstoque = saldoEstoque
            FROM Produto
            WHERE nomeProduto = @nomeProduto;

            -- Verificando se há saldo suficiente no estoque
            IF @saldoEstoque < @qtd
            BEGIN
                SET @pedidoCompleto = 0;

                -- Registrando produtos em falta na tabela de compras
                INSERT INTO Compras (codigoPedido, nomeProduto, qtdComprada)
                VALUES (@codigoPedido, @nomeProduto, @qtd);
            END
            ELSE
            BEGIN
                -- Atualizando o saldo de estoque
                UPDATE Produto
                SET saldoEstoque = saldoEstoque - @qtd
                WHERE nomeProduto = @nomeProduto;

                -- Atualizando o total do pedido
                SET @totalPedido = @totalPedido + @qtd;

                -- Somando o valor do produto ao total
                SET @totalValor = @totalValor + (SELECT valor FROM Produto WHERE nomeProduto = @nomeProduto) * @qtd;
            END

            -- Próximo item do pedido
            FETCH NEXT FROM itemCursor INTO @nomeProduto, @qtd;
        END;

        -- Fechando o cursor dos itens do pedido
        CLOSE itemCursor;
        DEALLOCATE itemCursor;

        -- Inserindo na tabela MovimentacaoEstoque para este pedido
        INSERT INTO MovimentacaoEstoque (codigoPedido, nomeComprador, total, pedidoCompleto, dataMovimento)
        VALUES (@codigoPedido, (SELECT nome FROM Cliente WHERE email = (SELECT email FROM Pedido WHERE codigoPedido = @codigoPedido)), @totalValor, @pedidoCompleto, GETDATE());

        -- Próximo pedido
        FETCH NEXT FROM pedidoCursor INTO @codigoPedido;
    END;

    -- Fechando o cursor dos pedidos
    CLOSE pedidoCursor;
    DEALLOCATE pedidoCursor;

    -- Ordenando a tabela MovimentacaoEstoque
    WITH CTE AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY pedidoCompleto ORDER BY pedidoCompleto DESC) AS RowNumber
        FROM MovimentacaoEstoque
    )
    UPDATE CTE
    SET pedidoCompleto = 1
    WHERE RowNumber = 1;

	-- Limpar a tabela carga
    DELETE FROM carga;

END;

