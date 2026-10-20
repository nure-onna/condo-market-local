import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:condo_market_local/modelos/produto.dart';
import 'package:condo_market_local/telas/conversas/tela_conversa.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;
  final String sellerId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.sellerId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _armazenamento = ArmazenamentoLocal.instancia;
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarProduto();
  }

  Future<void> _carregarProduto() async {
    try {
      final response = _armazenamento.carregarProduto(widget.productId);
      if (!mounted) return;

      setState(() {
        _product = response == null ? null : Product.aPartirDeJson(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar os detalhes do produto.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Produto')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Produto')),
        body: const Center(child: Text('Produto não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_product!.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              color: Colors.grey[200],
              child:
                  _product!.imageUrl != null && _product!.imageUrl!.isNotEmpty
                  ? Image.memory(
                      base64Decode(_product!.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product!.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'R\$ ${_product!.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descrição:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _product!.userId == _armazenamento.usuarioAtualId
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  productId: _product!.id,
                                  sellerId: _product!.userId,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      _product!.userId == _armazenamento.usuarioAtualId
                          ? 'Este anúncio é seu'
                          : 'Iniciar conversa local',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
