package com.example.demo.application.service;

import com.example.demo.domain.model.*;
import com.example.demo.domain.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PedidoService {

    @Autowired
    private PedidoRepository pedidoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private MovimentacaoEstoqueRepository movimentacaoEstoqueRepository;

    public Pedido createPedido(Pedido pedido) {
        // Verificar se o cliente já está cadastrado
        Cliente cliente = clienteRepository.findByCpf(pedido.getCliente().getCpf())
                .orElseGet(() -> clienteRepository.save(pedido.getCliente()));

        // Verificar se os produtos estão cadastrados e criar pedido
        pedido.getItensPedido().forEach(item -> {
            Produto produto = produtoRepository.findBySku(item.getProduto().getSku())
                    .orElseGet(() -> {
                        Produto novoProduto = item.getProduto();
                        novoProduto.setEstoque(10);
                        return produtoRepository.save(novoProduto);
                    });
            item.setProduto(produto);

            if (produto.getEstoque() < item.getQuantidade()) {
                MovimentacaoEstoque movimentacaoEstoque = new MovimentacaoEstoque();
                movimentacaoEstoque.setPedido(pedido);
                movimentacaoEstoque.setProduto(produto);
                movimentacaoEstoque.setQuantidadeRequisitada(item.getQuantidade());
                movimentacaoEstoque.setEstoqueSuficiente(false);
                movimentacaoEstoqueRepository.save(movimentacaoEstoque);
            } else {
                produto.setEstoque(produto.getEstoque() - item.getQuantidade());
                produtoRepository.save(produto);
            }
        });

        pedido.setCliente(cliente);
        return pedidoRepository.save(pedido);
    }
}
