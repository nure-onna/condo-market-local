import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';
import 'package:condo_market_local/servicos/servico_perfil.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _armazenamento = ArmazenamentoLocal.instancia;
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _currentUserId;
  String? _imagemSelecionada;
  String? _initialAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _armazenamento.usuarioAtualId;
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);
    final profile = await _userService.carregarPerfil(_currentUserId!);
    if (!mounted) return;
    if (profile != null) {
      _usernameController.text = profile.username;
      _initialAvatarUrl = profile.avatarUrl;
    }
    setState(() => _isLoading = false);
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
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _userService.salvarPerfil(
        userId: _currentUserId!,
        username: _usernameController.text.trim(),
        avatarUrl: _imagemSelecionada ?? _initialAvatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil salvo neste dispositivo.')),
      );
      Navigator.of(context).pop();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar perfil: $erro')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Usuário não logado.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selecionarImagemDaGaleria,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _imagemSelecionada != null
                            ? MemoryImage(base64Decode(_imagemSelecionada!))
                            : _initialAvatarUrl != null
                            ? MemoryImage(base64Decode(_initialAvatarUrl!))
                            : null,
                        child:
                            _imagemSelecionada == null &&
                                _initialAvatarUrl == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nome de Usuário',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um nome de usuário';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Salvar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
