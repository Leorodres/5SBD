package com.example.demo.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.demo.domain.model.Pedido;

public interface PedidoRepository extends JpaRepository<Pedido, Long> {
}
