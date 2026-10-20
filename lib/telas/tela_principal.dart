import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:condo_market_local/modelos/categoria.dart';
import 'package:condo_market_local/modelos/produto.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';
import 'package:condo_market_local/telas/produtos/tela_detalhes_produto.dart';
import 'package:condo_market_local/telas/produtos/formulario_produto.dart';
import 'package:condo_market_local/telas/perfil/tela_perfil.dart';
import 'package:condo_market_local/telas/conversas/tela_lista_conversas.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _FaixaDeCategoriasEBusca extends StatelessWidget {
  final String? categoriaSelecionada;
  final ValueChanged<String> aoSelecionarCategoria;
  final ValueChanged<String> aoPesquisar;

  const _FaixaDeCategoriasEBusca({
    required this.categoriaSelecionada,
    required this.aoSelecionarCategoria,
    required this.aoPesquisar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final categorias = SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoriasDisponiveis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, indice) {
          final categoria = categoriasDisponiveis[indice];
          final selecionada = categoria.identificador == categoriaSelecionada;
          return InkWell(
            onTap: () => aoSelecionarCategoria(categoria.identificador),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selecionada
                        ? cores.primary
                        : cores.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    categoria.icone,
                    color: selecionada ? Colors.white : cores.primary,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    categoria.nome,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    final busca = TextField(
      onChanged: aoPesquisar,
      decoration: InputDecoration(
        hintText: 'Buscar…',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: cores.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: LayoutBuilder(
        builder: (context, limites) {
          if (limites.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(child: categorias),
                const SizedBox(width: 12),
                SizedBox(width: 340, child: busca),
              ],
            );
          }
          return Column(
            children: [categorias, const SizedBox(height: 8), busca],
          );
        },
      ),
    );
  }
}

class _CarrosselDeBanners extends StatefulWidget {
  const _CarrosselDeBanners();

  @override
  State<_CarrosselDeBanners> createState() => _EstadoCarrosselDeBanners();
}

class _EstadoCarrosselDeBanners extends State<_CarrosselDeBanners> {
  int _indiceAtual = 0;
  final _controladorDePaginas = PageController();
  Timer? _temporizador;
  static const _imagens = [
    'assets/banners/condo-market-lancamento.png',
    'assets/banners/condo-market-seguranca.png',
    'assets/banners/condo-market-comunidade.png',
  ];
  static const _cores = [
    Color(0xFFFFE4EC),
    Color(0xFFE9F5FF),
    Color(0xFFFFEAF2),
  ];

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controladorDePaginas.hasClients) return;
      _controladorDePaginas.animateToPage(
        (_indiceAtual + 1) % _imagens.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controladorDePaginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, limites) {
            return SizedBox(
              height: (limites.maxWidth / 2.5).clamp(100, 180).toDouble(),
              child: PageView.builder(
                controller: _controladorDePaginas,
                itemCount: _imagens.length,
                onPageChanged: (indice) =>
                    setState(() => _indiceAtual = indice),
                itemBuilder: (context, indice) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: _cores[indice],
                    alignment: Alignment.center,
                    child: Image.asset(_imagens[indice], fit: BoxFit.contain),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_imagens.length, (indice) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: indice == _indiceAtual ? 18 : 10,
              height: 6,
              decoration: BoxDecoration(
                color: indice == _indiceAtual
                    ? cores.primary
                    : cores.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CartaoDeProduto extends StatelessWidget {
  final Product? produto;

  const _CartaoDeProduto({this.produto});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: produto == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(
                  productId: produto!.id,
                  sellerId: produto!.userId,
                ),
              ),
            ),
      child: Ink(
        decoration: BoxDecoration(
          color: cores.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cores.surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: produto?.imageUrl == null || produto!.imageUrl!.isEmpty
                    ? Container(
                        color: cores.surfaceContainerHighest,
                        child: const Icon(Icons.image, size: 40),
                      )
                    : Image.memory(
                        base64Decode(produto!.imageUrl!.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: produto == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          color: cores.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 12,
                          color: cores.surfaceContainerHighest,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                produto!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (produto!.emDestaque)
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${produto!.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: cores.primary,
                            fontWeight: FontWeight.w600,
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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _armazenamento = ArmazenamentoLocal.instancia;
  final _chaveScaffold = GlobalKey<ScaffoldState>();
  String? _categoriaSelecionada;
  String _pesquisa = '';

  void _selecionarCategoria(String identificador) {
    setState(() {
      _categoriaSelecionada = _categoriaSelecionada == identificador
          ? null
          : identificador;
    });
  }

  void _selecionarAba(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _chaveScaffold,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              centerTitle: true,
              leading: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => _chaveScaffold.currentState?.openDrawer(),
              ),
              title: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Sair',
                  icon: const Icon(Icons.logout),
                  onPressed: _armazenamento.encerrarSessao,
                ),
              ],
            )
          : null,
      drawer: _selectedIndex == 0
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Categorias',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(height: 1),
                    for (final categoria in categoriasDisponiveis)
                      ListTile(
                        leading: Icon(categoria.icone),
                        title: Text(categoria.nome),
                        selected:
                            _categoriaSelecionada == categoria.identificador,
                        onTap: () {
                          _selecionarCategoria(categoria.identificador);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: switch (_selectedIndex) {
        0 => _construirPaginaDeAnuncios(),
        1 => const ChatListScreen(),
        _ => const ProfileScreen(),
      },
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anúncios'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Mensagens',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _selecionarAba,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _construirPaginaDeAnuncios() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _armazenamento.observarAlteracoesDosDados(
        _armazenamento.listarProdutos,
      ),
      builder: (context, resultado) {
        final produtos =
            (resultado.data ?? const <Map<String, dynamic>>[])
                .map(Product.aPartirDeJson)
                .where((produto) {
                  final categoriaCorresponde =
                      _categoriaSelecionada == null ||
                      produto.categorias.contains(_categoriaSelecionada);
                  final busca = _pesquisa.toLowerCase();
                  return categoriaCorresponde &&
                      (produto.title.toLowerCase().contains(busca) ||
                          produto.description.toLowerCase().contains(busca));
                })
                .toList()
              ..sort(
                (primeiro, segundo) => (segundo.emDestaque ? 1 : 0).compareTo(
                  primeiro.emDestaque ? 1 : 0,
                ),
              );
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _FaixaDeCategoriasEBusca(
                categoriaSelecionada: _categoriaSelecionada,
                aoSelecionarCategoria: _selecionarCategoria,
                aoPesquisar: (texto) =>
                    setState(() => _pesquisa = texto.trim()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: _CarrosselDeBanners()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Novidades perto de você',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (resultado.hasError)
              SliverToBoxAdapter(
                child: Center(child: Text('Erro: ${resultado.error}')),
              )
            else if (resultado.connectionState == ConnectionState.waiting)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, indice) => _CartaoDeProduto(
                      produto: indice < produtos.length
                          ? produtos[indice]
                          : null,
                    ),
                    childCount: produtos.isEmpty ? 6 : produtos.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
