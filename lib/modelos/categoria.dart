import 'package:flutter/material.dart';

class Categoria {
  final String identificador;
  final IconData icone;
  final String nome;

  const Categoria(this.identificador, this.icone, this.nome);
}

const categoriasDisponiveis = <Categoria>[
  Categoria('moveis', Icons.weekend, 'Móveis'),
  Categoria('autos', Icons.directions_car_filled, 'Autos'),
  Categoria('eletronicos', Icons.devices_other, 'Eletrônicos'),
  Categoria('smartphones', Icons.smartphone, 'Smartphones'),
  Categoria('servicos', Icons.build, 'Serviços'),
  Categoria('casa', Icons.chair_alt, 'Casa'),
  Categoria('esportes', Icons.sports_soccer, 'Esportes'),
  Categoria('moda', Icons.checkroom, 'Moda'),
  Categoria('outros', Icons.more_horiz, 'Outros'),
];
