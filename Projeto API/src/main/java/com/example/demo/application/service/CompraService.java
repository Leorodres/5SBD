package com.example.demo.application.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.demo.domain.model.MovimentacaoEstoque;
import com.example.demo.domain.model.Pedido;
import com.example.demo.domain.model.Produto;
import com.example.demo.domain.repository.MovimentacaoEstoqueRepository;
import com.example.demo.domain.repository.PedidoRepository;
import com.example.demo.domain.repository.ProdutoRepository;

@Service
public class CompraService {

    @Autowired
    private MovimentacaoEstoqueRepository movimentacaoEstoqueRepository;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private PedidoRepository pedidoRepository;

    public MovimentacaoEstoque createCompra(MovimentacaoEstoque compra) {
        Produto produto = produtoRepository.findBySku(compra.getProduto().getSku())
                .orElseThrow(() -> new RuntimeException("Produto não encontrado"));

        produto.setEstoque(produto.getEstoque() + compra.getQuantidadeRequisitada());
        produtoRepository.save(produto);

        // Verificar se alguma movimentação pendente pode ser completada
        movimentacaoEstoqueRepository.findByProdutoAndEstoqueSuficienteFalse(produto)
                .forEach(mov -> {
                    if (produto.getEstoque() >= mov.getQuantidadeRequisitada()) {
                        mov.setEstoqueSuficiente(true);
                        movimentacaoEstoqueRepository.save(mov);

                        Pedido pedido = mov.getPedido();
                        pedido.setStatus("COMPLETO");
                        pedidoRepository.save(pedido);
                    }
                });

        return compra;
    }
}
