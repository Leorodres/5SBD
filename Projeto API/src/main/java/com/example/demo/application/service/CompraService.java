package com.example.demo.application.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.domain.model.Compra;
import com.example.demo.domain.model.Pedido;
import com.example.demo.domain.model.Produto;
import com.example.demo.domain.repository.CompraRepository;
import com.example.demo.domain.repository.PedidoRepository;
import com.example.demo.domain.repository.ProdutoRepository;

@Service
public class CompraService {

    @Autowired
    private CompraRepository compraRepository;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private PedidoRepository pedidoRepository;

    @Transactional
    public Compra createCompra(Compra compra) {
        Produto produto = produtoRepository.findBySku(compra.getProduto().getSku())
                .orElseThrow(() -> new RuntimeException("Produto não encontrado"));

        produto.setEstoque(produto.getEstoque() + compra.getQuantidadeRequisitada());
        produtoRepository.save(produto);

        List<Compra> movimentacoesPendentes = compraRepository.findByProdutoAndEstoqueSuficienteFalse(produto);
        for (Compra mov : movimentacoesPendentes) {
            if (produto.getEstoque() >= mov.getQuantidadeRequisitada()) {
                mov.setEstoqueSuficiente(true);
                compraRepository.save(mov);

                Pedido pedido = mov.getPedido();
                pedido.setStatus("COMPLETO");
                pedidoRepository.save(pedido);
            }
        }

        return compraRepository.save(compra);
    }
}

