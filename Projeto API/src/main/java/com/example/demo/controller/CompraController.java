package com.example.demo.controller;

import com.example.demo.application.service.CompraService;
import com.example.demo.domain.model.MovimentacaoEstoque;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/compra")
public class CompraController {

    @Autowired
    private CompraService compraService;

    @PostMapping
    public MovimentacaoEstoque createCompra(@RequestBody MovimentacaoEstoque compra) {
        return compraService.createCompra(compra);
    }
}
