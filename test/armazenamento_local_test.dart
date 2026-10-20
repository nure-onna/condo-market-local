import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';

Map<String, dynamic> criarAnuncio({String titulo = 'Mesa'}) => {
  'title': titulo,
  'description': 'Mesa de madeira',
  'price': 80.5,
  'image_url': base64Encode([1, 2, 3]),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ArmazenamentoLocal armazenamento;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    armazenamento = ArmazenamentoLocal();
    await armazenamento.carregarDadosLocais();
  });
  tearDown(() => armazenamento.dispose());

  test(
    'Conta de teste é criada sem abrir sessão e continua disponível',
    () async {
      await armazenamento.prepararContaDeTeste();
      expect(armazenamento.usuarioAtualId, isNull);
      final reaberto = ArmazenamentoLocal();
      await reaberto.carregarDadosLocais();
      await reaberto.prepararContaDeTeste();
      await reaberto.autenticarUsuario('teste@teste.com', 'teste1234');
      final usuarioId = reaberto.usuarioAtualId!;
      expect(reaberto.carregarPerfil(usuarioId)!['email'], 'teste@teste.com');
      await reaberto.prepararContaDeTeste();
      expect(reaberto.usuarioAtualId, usuarioId);
      reaberto.dispose();
    },
  );

  test(
    'Contas, sessão, perfil e imagem persistem sem senha em texto puro',
    () async {
      await armazenamento.cadastrarUsuario(' ANA@teste.com ', 'senha123');
      final id = armazenamento.usuarioAtualId!;
      await armazenamento.salvarPerfil('Ana Silva', base64Encode([4, 5, 6]));
      await armazenamento.salvarProduto(criarAnuncio());
      final reaberto = ArmazenamentoLocal();
      await reaberto.carregarDadosLocais();
      expect(reaberto.usuarioAtualId, id);
      expect(reaberto.carregarPerfil(id)!['username'], 'Ana Silva');
      expect(
        reaberto.carregarPerfil(id)!['avatar_url'],
        base64Encode([4, 5, 6]),
      );
      expect(
        reaberto.listarProdutos().single['image_url'],
        base64Encode([1, 2, 3]),
      );
      final preferencias = await SharedPreferences.getInstance();
      expect(
        preferencias.getString(ArmazenamentoLocal.chaveDados),
        isNot(contains('senha123')),
      );
      await reaberto.encerrarSessao();
      await reaberto.carregarDadosLocais();
      expect(reaberto.usuarioAtualId, isNull);
      await reaberto.autenticarUsuario('ANA@teste.com', 'senha123');
      expect(reaberto.usuarioAtualId, id);
      reaberto.dispose();
    },
  );

  test('Valida cadastro, duplicidade e credenciais', () async {
    await expectLater(
      armazenamento.cadastrarUsuario('invalido', 'senha123'),
      throwsArgumentError,
    );
    await expectLater(
      armazenamento.cadastrarUsuario('a@teste.com', '123'),
      throwsArgumentError,
    );
    await armazenamento.cadastrarUsuario('a@teste.com', 'senha123');
    await expectLater(
      armazenamento.cadastrarUsuario('A@teste.com', 'senha456'),
      throwsStateError,
    );
    await armazenamento.encerrarSessao();
    await expectLater(
      armazenamento.autenticarUsuario('a@teste.com', 'errada'),
      throwsStateError,
    );
    expect(armazenamento.usuarioAtualId, isNull);
  });

  test(
    'Atualiza anúncio, restringe edição e mantém IDs após exclusões',
    () async {
      await armazenamento.cadastrarUsuario('ana@teste.com', 'senha123');
      await armazenamento.salvarProduto(criarAnuncio());
      final id = armazenamento.listarProdutos().single['id'] as int;
      await armazenamento.salvarProduto(
        criarAnuncio(titulo: 'Cadeira'),
        id: id,
      );
      expect(armazenamento.carregarProduto(id)!['title'], 'Cadeira');
      await armazenamento.cadastrarUsuario('bia@teste.com', 'senha123');
      await expectLater(
        armazenamento.salvarProduto(criarAnuncio(), id: id),
        throwsStateError,
      );
      await expectLater(armazenamento.excluirProduto(id), throwsStateError);
      await armazenamento.autenticarUsuario('ana@teste.com', 'senha123');
      await armazenamento.excluirProduto(id);
      await armazenamento.salvarProduto(criarAnuncio());
      expect(armazenamento.listarProdutos().single['id'], greaterThan(id));
      await expectLater(
        armazenamento.salvarProduto({...criarAnuncio(), 'price': -1}),
        throwsArgumentError,
      );
      expect(armazenamento.listarProdutos(), hasLength(1));
    },
  );

  test(
    'Conversa local permite resposta do vendedor e isola terceiros',
    () async {
      await armazenamento.cadastrarUsuario('vendedor@teste.com', 'senha123');
      final vendedor = armazenamento.usuarioAtualId!;
      await armazenamento.salvarProduto(criarAnuncio());
      final produto = armazenamento.listarProdutos().single['id'] as int;
      await expectLater(
        armazenamento.obterOuCriarConversa(produto, vendedor),
        throwsStateError,
      );
      await armazenamento.cadastrarUsuario('comprador@teste.com', 'senha123');
      final conversa = await armazenamento.obterOuCriarConversa(
        produto,
        vendedor,
      );
      expect(
        await armazenamento.obterOuCriarConversa(produto, vendedor),
        conversa,
      );
      await armazenamento.enviarMensagem(conversa, 'Disponível?');
      await armazenamento.autenticarUsuario('vendedor@teste.com', 'senha123');
      expect(armazenamento.listarConversas().single['id'], conversa);
      await armazenamento.enviarMensagem(conversa, 'Sim!');
      await armazenamento.carregarDadosLocais();
      expect(armazenamento.listarMensagens(conversa).map((m) => m['message']), [
        'Disponível?',
        'Sim!',
      ]);
      await armazenamento.cadastrarUsuario('terceiro@teste.com', 'senha123');
      expect(armazenamento.listarConversas(), isEmpty);
      expect(() => armazenamento.listarMensagens(conversa), throwsStateError);
      await expectLater(
        armazenamento.enviarMensagem(conversa, 'Intruso'),
        throwsStateError,
      );
      await armazenamento.autenticarUsuario('vendedor@teste.com', 'senha123');
      await armazenamento.excluirProduto(produto);
      expect(armazenamento.listarConversas(), isEmpty);
    },
  );

  test(
    'Observadores recebem estado inicial e anúncios salvos em sequência',
    () async {
      await armazenamento.cadastrarUsuario('ana@teste.com', 'senha123');
      final eventos = <int>[];
      final assinatura = armazenamento
          .observarAlteracoesDosDados(armazenamento.listarProdutos)
          .listen((produtos) => eventos.add(produtos.length));
      await Future<void>.delayed(Duration.zero);
      await Future.wait([
        armazenamento.salvarProduto(criarAnuncio(titulo: 'Mesa')),
        armazenamento.salvarProduto(criarAnuncio(titulo: 'Cadeira')),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(eventos, [0, 1, 2]);
      await assinatura.cancel();
      await armazenamento.carregarDadosLocais();
      expect(armazenamento.listarProdutos(), hasLength(2));
    },
  );
}
