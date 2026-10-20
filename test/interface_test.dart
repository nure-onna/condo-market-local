import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:condo_market_local/main.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';

Future<void> acionarGravacao(WidgetTester tester, Finder botao) async {
  await tester.runAsync(() async {
    final conclusao = Completer<void>();
    final armazenamento = ArmazenamentoLocal.instancia;
    void concluir() {
      if (!conclusao.isCompleted) conclusao.complete();
    }

    armazenamento.addListener(concluir);
    try {
      await tester.tap(botao);
      await conclusao.future;
    } finally {
      armazenamento.removeListener(concluir);
    }
  });
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ArmazenamentoLocal.instancia.carregarDadosLocais();
  });

  testWidgets('Abre login sem servidor e explica as contas locais', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    final campos = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(campos[0].controller!.text, 'teste@teste.com');
    expect(campos[1].controller!.text, 'teste1234');
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.textContaining('Contas e dados ficam apenas'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsNothing);
    await tester.tap(find.text('Não tem uma conta? Crie uma aqui!'));
    await tester.pump();
    expect(find.text('Cadastrar'), findsOneWidget);
  });

  testWidgets('Publica anúncio, atualiza feed, edita perfil e sai', (
    tester,
  ) async {
    await tester.pump();
    await tester.runAsync(() async {
      await ArmazenamentoLocal.instancia.cadastrarUsuario(
        'ana@teste.com',
        'senha123',
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Novidades perto de você'), findsOneWidget);
    expect(find.byIcon(Icons.image), findsWidgets);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Bicicleta');
    await tester.enterText(campos.at(1), 'Bicicleta usada em bom estado');
    await tester.enterText(campos.at(2), '150,50');
    await tester.ensureVisible(find.text('Publicar Anúncio'));
    await acionarGravacao(tester, find.text('Publicar Anúncio'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Bicicleta'), findsOneWidget);
    expect(find.text('R\$ 150.50'), findsOneWidget);
    await tester.tap(find.text('Mensagens'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anúncios'));
    await tester.pumpAndSettle();
    expect(find.text('Bicicleta'), findsOneWidget);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ana');
    await acionarGravacao(tester, find.text('Salvar Alterações'));
    await tester.pumpAndSettle();
    final armazenamento = ArmazenamentoLocal.instancia;
    expect(
      armazenamento.carregarPerfil(armazenamento.usuarioAtualId!)!['username'],
      'Ana',
    );
    await acionarGravacao(tester, find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
