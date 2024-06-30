package com.example.demo.controller;

import java.util.Date;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.model.ItemPedido;
import com.example.demo.model.MovimentacaoEstoque;
import com.example.demo.model.Pedido;
import com.example.demo.model.Produto;
import com.example.demo.repository.MovimentacaoEstoqueRepository;
import com.example.demo.repository.PedidoRepository;
import com.example.demo.repository.ProdutoRepository;

@RestController
@RequestMapping("/api/pedidos")
public class PedidoController {

    @Autowired
    private PedidoRepository pedidoRepository;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private MovimentacaoEstoqueRepository movimentacaoEstoqueRepository;

    @PostMapping
    public ResponseEntity<Pedido> createPedido(@RequestBody Pedido pedido) {
        // Defina a data da compra
        pedido.setDataCompra(new Date());

        // Salve o pedido para obter o ID gerado
        Pedido savedPedido = pedidoRepository.save(pedido);

        boolean pedidoCompleto = true;

        // Processar itens do pedido
        for (ItemPedido item : savedPedido.getItensPedido()) {
            Produto produto = produtoRepository.findById(item.getProduto().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Produto not found with id " + item.getProduto().getId()));

            // Atualiza o ItemPedido com as informações do Produto
            if (produto.getPreco() == null) {
                throw new ResourceNotFoundException("Produto with id " + produto.getId() + " does not have a price.");
            }
            item.setPreco(produto.getPreco());
            item.setPedido(savedPedido); // Associar o item ao pedido salvo

            MovimentacaoEstoque movimentacao = new MovimentacaoEstoque();
            movimentacao.setPedido(savedPedido); // Use o pedido salvo
            movimentacao.setProduto(produto);
            movimentacao.setQuantidadeRequisitada(item.getQuantidade());
            movimentacao.setValorTotalItem(item.getQuantidade() * produto.getPreco());

            // Verifique se há estoque suficiente
            if (produto.getEstoque() >= item.getQuantidade()) {
                produto.setEstoque(produto.getEstoque() - item.getQuantidade());
                movimentacao.setEstoqueSuficiente(true);
            } else {
                pedidoCompleto = false;
                movimentacao.setEstoqueSuficiente(false);
            }

            // Salve a movimentação de estoque
            movimentacaoEstoqueRepository.save(movimentacao);
        }

        // Atualiza o status do pedido após processar todos os itens
        savedPedido.setStatus(pedidoCompleto ? "COMPLETO" : "INCOMPLETO");
        Pedido updatedPedido = pedidoRepository.save(savedPedido); // Salve o pedido novamente para atualizar o status

        return ResponseEntity.ok(updatedPedido);
    }
}
