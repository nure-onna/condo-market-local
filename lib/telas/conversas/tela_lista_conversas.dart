import 'package:flutter/material.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';
import 'package:condo_market_local/modelos/conversa.dart';
import 'package:condo_market_local/telas/conversas/tela_conversa.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _armazenamento = ArmazenamentoLocal.instancia;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _armazenamento.usuarioAtualId;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text('Faça login para ver suas conversas.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Conversas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _armazenamento.observarAlteracoesDosDados(
          _armazenamento.listarConversas,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Você ainda não tem conversas.'));
          }

          final sessions = snapshot.data!
              .map((data) => ChatSession.aPartirDeJson(data))
              .toList();

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final otherUserId = session.sellerId == _currentUserId
                  ? session.buyerId
                  : session.sellerId;

              return ListTile(
                title: Text('Conversa com o usuário: $otherUserId'),
                subtitle: Text('Produto ID: ${session.productId}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        productId: session.productId,
                        conversaId: session.id,
                        sellerId: session.sellerId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
