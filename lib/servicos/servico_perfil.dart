import '../modelos/perfil.dart';
import 'armazenamento_local.dart';

class UserService {
  Future<Profile?> carregarPerfil(String usuarioId) async {
    final dados = ArmazenamentoLocal.instancia.carregarPerfil(usuarioId);
    return dados == null ? null : Profile.aPartirDeJson(dados);
  }

  Future<void> salvarPerfil({
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    final armazenamento = ArmazenamentoLocal.instancia;
    if (userId != armazenamento.usuarioAtualId) {
      throw StateError('Você só pode editar seu próprio perfil.');
    }
    final perfil = armazenamento.carregarPerfil(userId)!;
    await armazenamento.salvarPerfil(
      username ?? perfil['username'] as String,
      avatarUrl,
    );
  }
}
