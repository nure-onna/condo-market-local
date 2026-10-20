import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ArmazenamentoLocal extends ChangeNotifier {
  static final instancia = ArmazenamentoLocal();
  static const chaveDados = 'condo_market.dados.v1';
  static const emailContaTeste = 'teste@teste.com';
  static const senhaContaTeste = 'teste1234';

  late SharedPreferences _preferencias;
  Map<String, dynamic> _dados = {};
  Future<void> _fila = Future.value();

  String? get usuarioAtualId => _dados['usuario_atual'] as String?;

  Future<void> carregarDadosLocais() async {
    _preferencias = await SharedPreferences.getInstance();
    final salvo = _preferencias.getString(chaveDados);
    _dados = salvo == null
        ? {
            'usuarios': <dynamic>[],
            'profiles': <dynamic>[],
            'products': <dynamic>[],
            'chat_sessions': <dynamic>[],
            'chat_messages': <dynamic>[],
            'sequencias': <String, dynamic>{},
            'usuario_atual': null,
          }
        : Map<String, dynamic>.from(jsonDecode(salvo) as Map);
    notifyListeners();
  }

  List<Map<String, dynamic>> _obterRegistrosDaTabela(String tabela) =>
      (_dados[tabela] as List).cast<Map<String, dynamic>>();

  Future<T> _persistirAlteracao<T>(T Function() alterar) {
    final tarefa = _fila.then((_) async {
      final anterior = jsonEncode(_dados);
      try {
        final resultado = alterar();
        if (!await _preferencias.setString(chaveDados, jsonEncode(_dados))) {
          throw StateError(
            'Não foi possível salvar os dados neste dispositivo.',
          );
        }
        notifyListeners();
        return resultado;
      } catch (_) {
        _dados = Map<String, dynamic>.from(jsonDecode(anterior) as Map);
        rethrow;
      }
    });
    _fila = tarefa.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return tarefa;
  }

  int _gerarProximoIdentificador(String tabela) {
    final sequencias = _dados['sequencias'] as Map<String, dynamic>;
    final proximo = (sequencias[tabela] as int? ?? 0) + 1;
    sequencias[tabela] = proximo;
    return proximo;
  }

  String _obterUsuarioAutenticado() {
    final id = usuarioAtualId;
    if (id == null) throw StateError('Entre em uma conta local primeiro.');
    return id;
  }

  Future<String> _calcularResumoDaSenha(String senha, String sal) async {
    final chave =
        await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 210000,
          bits: 256,
        ).deriveKey(
          secretKey: SecretKey(utf8.encode(senha)),
          nonce: base64Decode(sal),
        );
    return base64Encode(await chave.extractBytes());
  }

  Future<void> prepararContaDeTeste() async {
    if (_obterRegistrosDaTabela(
      'usuarios',
    ).any((usuario) => usuario['email'] == emailContaTeste)) {
      return;
    }
    await _criarUsuarioLocal(
      emailContaTeste,
      senhaContaTeste,
      autenticarAposCadastro: false,
    );
  }

  Future<void> cadastrarUsuario(String email, String senha) =>
      _criarUsuarioLocal(email, senha, autenticarAposCadastro: true);

  Future<void> _criarUsuarioLocal(
    String email,
    String senha, {
    required bool autenticarAposCadastro,
  }) async {
    final endereco = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(endereco)) {
      throw ArgumentError('Informe um e-mail válido.');
    }
    if (senha.length < 6) {
      throw ArgumentError('Use uma senha com pelo menos 6 caracteres.');
    }
    final aleatorio = Random.secure();
    final sal = base64Encode(List.generate(16, (_) => aleatorio.nextInt(256)));
    final resumo = await _calcularResumoDaSenha(senha, sal);
    await _persistirAlteracao(() {
      if (_obterRegistrosDaTabela(
        'usuarios',
      ).any((u) => u['email'] == endereco)) {
        throw StateError('Este e-mail já possui uma conta neste dispositivo.');
      }
      final id = const Uuid().v4();
      _dados['usuarios'].add({
        'id': id,
        'email': endereco,
        'sal': sal,
        'resumo_senha': resumo,
      });
      _dados['profiles'].add({
        'id': id,
        'email': endereco,
        'username': endereco.split('@').first,
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (autenticarAposCadastro) {
        _dados['usuario_atual'] = id;
      }
    });
  }

  Future<void> autenticarUsuario(String email, String senha) async {
    final contas = _obterRegistrosDaTabela(
      'usuarios',
    ).where((u) => u['email'] == email.trim().toLowerCase());
    if (contas.isEmpty) throw StateError('E-mail ou senha incorretos.');
    final conta = contas.first;
    final resumo = await _calcularResumoDaSenha(senha, conta['sal'] as String);
    if (resumo != conta['resumo_senha']) {
      throw StateError('E-mail ou senha incorretos.');
    }
    await _persistirAlteracao(() {
      _dados['usuario_atual'] = conta['id'];
    });
  }

  Future<void> encerrarSessao() => _persistirAlteracao(() {
    _dados['usuario_atual'] = null;
  });

  Map<String, dynamic>? carregarPerfil(String id) {
    final perfis = _obterRegistrosDaTabela(
      'profiles',
    ).where((p) => p['id'] == id);
    return perfis.isEmpty ? null : Map.of(perfis.first);
  }

  Future<void> salvarPerfil(String nome, String? imagem) =>
      _persistirAlteracao(() {
        final perfil = _obterRegistrosDaTabela(
          'profiles',
        ).firstWhere((p) => p['id'] == _obterUsuarioAutenticado());
        if (nome.trim().isEmpty) throw ArgumentError('Informe seu nome.');
        perfil['username'] = nome.trim();
        perfil['avatar_url'] = imagem;
      });

  List<Map<String, dynamic>> listarProdutos({String? usuarioId}) {
    final produtos = _obterRegistrosDaTabela('products')
        .where((p) => usuarioId == null || p['user_id'] == usuarioId)
        .map((p) => Map<String, dynamic>.of(p))
        .toList();
    produtos.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    return produtos;
  }

  Map<String, dynamic>? carregarProduto(int id) {
    final produtos = _obterRegistrosDaTabela(
      'products',
    ).where((p) => p['id'] == id);
    return produtos.isEmpty ? null : Map.of(produtos.first);
  }

  Future<void> salvarProduto(Map<String, dynamic> valores, {int? id}) =>
      _persistirAlteracao(() {
        final usuario = _obterUsuarioAutenticado();
        final preco = valores['price'] as num;
        if (!preco.isFinite ||
            preco < 0 ||
            (valores['title'] as String).trim().isEmpty ||
            (valores['description'] as String).trim().isEmpty) {
          throw ArgumentError('Preencha título, descrição e um preço válido.');
        }
        if (id == null) {
          _dados['products'].add({
            ...valores,
            'id': _gerarProximoIdentificador('products'),
            'user_id': usuario,
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          final produto = _obterRegistrosDaTabela(
            'products',
          ).firstWhere((p) => p['id'] == id && p['user_id'] == usuario);
          produto.addAll({...valores, 'user_id': usuario});
        }
      });

  Future<void> excluirProduto(int id) => _persistirAlteracao(() {
    final usuario = _obterUsuarioAutenticado();
    if (!_obterRegistrosDaTabela(
      'products',
    ).any((p) => p['id'] == id && p['user_id'] == usuario)) {
      throw StateError('Este anúncio não pertence à sua conta.');
    }
    final conversas = _obterRegistrosDaTabela(
      'chat_sessions',
    ).where((c) => c['product_id'] == id).map((c) => c['id']).toSet();
    (_dados['chat_messages'] as List).removeWhere(
      (m) => conversas.contains(m['chat_id']),
    );
    (_dados['chat_sessions'] as List).removeWhere((c) => c['product_id'] == id);
    (_dados['products'] as List).removeWhere((p) => p['id'] == id);
  });

  List<Map<String, dynamic>> listarConversas() =>
      _obterRegistrosDaTabela('chat_sessions')
          .where(
            (c) =>
                c['seller_id'] == usuarioAtualId ||
                c['buyer_id'] == usuarioAtualId,
          )
          .map((c) => Map<String, dynamic>.of(c))
          .toList()
          .reversed
          .toList();

  Future<int> obterOuCriarConversa(int produtoId, String vendedorId) =>
      _persistirAlteracao(() {
        final usuario = _obterUsuarioAutenticado();
        if (usuario == vendedorId) {
          throw StateError('Abra uma conversa recebida na aba Mensagens.');
        }
        final produto = carregarProduto(produtoId);
        if (produto == null || produto['user_id'] != vendedorId) {
          throw StateError('Anúncio indisponível.');
        }
        final existentes = _obterRegistrosDaTabela('chat_sessions').where(
          (c) => c['product_id'] == produtoId && c['buyer_id'] == usuario,
        );
        if (existentes.isNotEmpty) return existentes.first['id'] as int;
        final id = _gerarProximoIdentificador('chat_sessions');
        _dados['chat_sessions'].add({
          'id': id,
          'product_id': produtoId,
          'seller_id': vendedorId,
          'buyer_id': usuario,
          'created_at': DateTime.now().toIso8601String(),
        });
        return id;
      });

  void _validarParticipacaoNaConversa(int conversaId) {
    if (!listarConversas().any((c) => c['id'] == conversaId)) {
      throw StateError('Conversa indisponível para esta conta.');
    }
  }

  List<Map<String, dynamic>> listarMensagens(int conversaId) {
    _validarParticipacaoNaConversa(conversaId);
    return _obterRegistrosDaTabela('chat_messages')
        .where((m) => m['chat_id'] == conversaId)
        .map((m) => Map<String, dynamic>.of(m))
        .toList();
  }

  Future<void> enviarMensagem(int conversaId, String texto) =>
      _persistirAlteracao(() {
        _validarParticipacaoNaConversa(conversaId);
        if (texto.trim().isEmpty) return;
        _dados['chat_messages'].add({
          'id': _gerarProximoIdentificador('chat_messages'),
          'chat_id': conversaId,
          'sender_id': _obterUsuarioAutenticado(),
          'message': texto.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      });

  Stream<List<Map<String, dynamic>>> observarAlteracoesDosDados(
    List<Map<String, dynamic>> Function() consultar,
  ) {
    late StreamController<List<Map<String, dynamic>>> controlador;
    void emitirDadosAtualizados() {
      try {
        controlador.add(consultar());
      } catch (erro, pilha) {
        controlador.addError(erro, pilha);
      }
    }

    controlador = StreamController(
      onListen: () {
        addListener(emitirDadosAtualizados);
        emitirDadosAtualizados();
      },
      onCancel: () => removeListener(emitirDadosAtualizados),
    );
    return controlador.stream;
  }
}
