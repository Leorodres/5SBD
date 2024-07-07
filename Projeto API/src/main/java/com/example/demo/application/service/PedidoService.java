package com.example.demo.application.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.demo.domain.model.Cliente;
import com.example.demo.domain.model.ItemPedido;
import com.example.demo.domain.model.MovimentacaoEstoque;
import com.example.demo.domain.model.Pedido;
import com.example.demo.domain.model.Produto;
import com.example.demo.domain.repository.ClienteRepository;
import com.example.demo.domain.repository.ItemPedidoRepository;
import com.example.demo.domain.repository.MovimentacaoEstoqueRepository;
import com.example.demo.domain.repository.PedidoRepository;
import com.example.demo.domain.repository.ProdutoRepository;

@Service
public class PedidoService {

    @Autowired
    private PedidoRepository pedidoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private ItemPedidoRepository itemPedidoRepository;

    @Autowired
    private MovimentacaoEstoqueRepository movimentacaoEstoqueRepository;

    public Pedido createPedido(Pedido pedido) {
        Cliente cliente = clienteRepository.findByCpf(pedido.getCliente().getCpf())
                .orElseGet(() -> clienteRepository.save(pedido.getCliente()));
        pedido.setCliente(cliente);

        Pedido pedidoSalvo = pedidoRepository.save(pedido);

        for (ItemPedido item : pedido.getItensPedido()) {
            Produto produto = produtoRepository.findBySku(item.getProduto().getSku())
                    .orElseGet(() -> {
                        Produto novoProduto = item.getProduto();
                        novoProduto.setEstoque(10);
                        return produtoRepository.save(novoProduto);
                    });

            item.setProduto(produto);
            item.setPedido(pedidoSalvo);
            item.setPreco(produto.getPreco() * item.getQuantidade());

            if (produto.getEstoque() < item.getQuantidade()) {
                MovimentacaoEstoque movimentacaoEstoque = new MovimentacaoEstoque();
                movimentacaoEstoque.setPedido(pedidoSalvo);
                movimentacaoEstoque.setProduto(produto);
                movimentacaoEstoque.setQuantidadeRequisitada(item.getQuantidade());
                movimentacaoEstoque.setValorTotalItem(item.getPreco());
                movimentacaoEstoque.setEstoqueSuficiente(false);
                movimentacaoEstoqueRepository.save(movimentacaoEstoque);
            } else {
                produto.setEstoque(produto.getEstoque() - item.getQuantidade());
                produtoRepository.save(produto);
            }

            itemPedidoRepository.save(item);
        }
        boolean isEstoqueSuficiente = pedido.getItensPedido().stream()
                .allMatch(item -> item.getProduto().getEstoque() >= item.getQuantidade());

        pedidoSalvo.setStatus(isEstoqueSuficiente ? "COMPLETO" : "INCOMPLETO");

        return pedidoRepository.save(pedidoSalvo);
    }
}
