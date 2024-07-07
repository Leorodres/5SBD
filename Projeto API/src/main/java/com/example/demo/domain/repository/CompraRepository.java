package com.example.demo.domain.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.demo.domain.model.Compra;
import com.example.demo.domain.model.Produto;

public interface CompraRepository extends JpaRepository<Compra, Long> {
    List<Compra> findByProdutoAndEstoqueSuficienteFalse(Produto produto);
}
