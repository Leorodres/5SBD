package com.example.demo.domain.repository;

import com.example.demo.domain.model.MovimentacaoEstoque;
import com.example.demo.domain.model.Produto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MovimentacaoEstoqueRepository extends JpaRepository<MovimentacaoEstoque, Long> {
    List<MovimentacaoEstoque> findByProdutoAndEstoqueSuficienteFalse(Produto produto);
}
