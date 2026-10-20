import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:condo_market_local/telas/tela_principal.dart';
import 'servicos/armazenamento_local.dart';

import 'package:condo_market_local/telas/autenticacao/tela_autenticacao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ArmazenamentoLocal.instancia.carregarDadosLocais();
    await ArmazenamentoLocal.instancia.prepararContaDeTeste();
    runApp(const MyApp());
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Não foi possível abrir os dados locais. Reinicie o aplicativo.\n'
              'Seus dados não foram apagados.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Condo Market',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      home: const TelaDeAbertura(),
    );
  }
}

class TelaDeAbertura extends StatefulWidget {
  const TelaDeAbertura({super.key});

  @override
  State<TelaDeAbertura> createState() => _EstadoTelaDeAbertura();
}

class _EstadoTelaDeAbertura extends State<TelaDeAbertura> {
  bool _pronto = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _pronto = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pronto) return const AuthGate();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 230,
              height: 230,
              child: Image.asset('assets/logo_condo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(minHeight: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final armazenamento = ArmazenamentoLocal.instancia;
    return ListenableBuilder(
      listenable: armazenamento,
      builder: (context, _) => armazenamento.usuarioAtualId == null
          ? const LoginScreen()
          : HomePage(key: ValueKey(armazenamento.usuarioAtualId)),
    );
  }
}
