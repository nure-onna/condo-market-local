import 'package:flutter/material.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';
import 'package:condo_market_local/modelos/mensagem.dart';

class ChatScreen extends StatefulWidget {
  final int productId;
  final int? conversaId;
  final String sellerId;

  const ChatScreen({
    super.key,
    required this.productId,
    this.conversaId,
    required this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _armazenamento = ArmazenamentoLocal.instancia;
  int? _chatId;
  String? _erro;
  bool _enviando = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _carregarOuCriarConversa();
  }

  Future<void> _carregarOuCriarConversa() async {
    _currentUserId = _armazenamento.usuarioAtualId;
    try {
      final id =
          widget.conversaId ??
          await _armazenamento.obterOuCriarConversa(
            widget.productId,
            widget.sellerId,
          );
      _armazenamento.listarMensagens(id);
      if (mounted) setState(() => _chatId = id);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro.toString());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensagem() async {
    if (_messageController.text.trim().isEmpty ||
        _chatId == null ||
        _enviando) {
      return;
    }
    final texto = _messageController.text;
    setState(() => _enviando = true);
    try {
      await _armazenamento.enviarMensagem(_chatId!, texto);
      if (!mounted) return;
      if (_messageController.text == texto) _messageController.clear();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar mensagem: $erro')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversa local')),
        body: Center(child: Text(_erro!)),
      );
    }
    if (_chatId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversa local'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Simulação local: troque de conta neste dispositivo para responder. Não há envio pela internet.',
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _armazenamento.observarAlteracoesDosDados(
                () => _armazenamento.listarMensagens(_chatId!),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Inicie a conversa...'));
                }

                final messages = snapshot.data!
                    .map((data) => ChatMessage.aPartirDeJson(data))
                    .toList();

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe
                                ? const Radius.circular(16)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _enviando ? null : _enviarMensagem,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
