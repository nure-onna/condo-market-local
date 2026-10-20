import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:condo_market_local/modelos/produto.dart';
import 'package:condo_market_local/modelos/categoria.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';
import 'package:image_picker/image_picker.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _armazenamento = ArmazenamentoLocal.instancia;
  final _imagePicker = ImagePicker();
  String? _imagemSelecionada;
  String? _imageUrl;
  bool _isSaving = false;
  final Set<String> _categoriasSelecionadas = {};

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _titleController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _imageUrl = widget.product!.imageUrl;
      _categoriasSelecionadas.addAll(widget.product!.categorias);
    }
  }

  Future<void> _selecionarImagemDaGaleria() async {
    try {
      final arquivo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 2 * 1024 * 1024) {
        throw StateError('Escolha uma imagem com até 2 MB.');
      }
      setState(() => _imagemSelecionada = base64Encode(bytes));
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a imagem: $erro')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final produto = Product(
        id: widget.product?.id ?? -1,
        userId: _armazenamento.usuarioAtualId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.replaceAll(',', '.')),
        imageUrl: _imagemSelecionada ?? _imageUrl,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        categorias: _categoriasSelecionadas.toList(),
        emDestaque: widget.product?.emDestaque ?? false,
      );
      await _armazenamento.salvarProduto(
        produto.converterParaJson(),
        id: widget.product?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anúncio salvo neste dispositivo.')),
      );
      Navigator.of(context).pop();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar anúncio: $erro')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Adicionar Anúncio' : 'Editar Anúncio',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _selecionarImagemDaGaleria,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Center(
                    child: _imagemSelecionada != null
                        ? Image.memory(
                            base64Decode(_imagemSelecionada!),
                            fit: BoxFit.cover,
                          )
                        : _imageUrl != null
                        ? Image.memory(
                            base64Decode(_imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Selecionar Imagem',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título do Anúncio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descrição do Produto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Preço',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um preço';
                  }
                  final preco = double.tryParse(value.replaceAll(',', '.'));
                  if (preco == null || !preco.isFinite || preco < 0) {
                    return 'Por favor, insira um preço válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Categorias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categoriasDisponiveis.map((categoria) {
                  return FilterChip(
                    label: Text(categoria.nome),
                    avatar: Icon(categoria.icone, size: 18),
                    selected: _categoriasSelecionadas.contains(
                      categoria.identificador,
                    ),
                    onSelected: (selecionada) {
                      setState(() {
                        if (selecionada) {
                          _categoriasSelecionadas.add(categoria.identificador);
                        } else {
                          _categoriasSelecionadas.remove(
                            categoria.identificador,
                          );
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _salvarProduto,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.product == null
                            ? 'Publicar Anúncio'
                            : 'Salvar Alterações',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
