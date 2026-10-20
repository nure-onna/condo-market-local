import 'armazenamento_local.dart';

class AuthService {
  Future<void> autenticarUsuario({
    required String email,
    required String password,
  }) => ArmazenamentoLocal.instancia.autenticarUsuario(email, password);

  Future<void> cadastrarUsuario({
    required String email,
    required String password,
  }) => ArmazenamentoLocal.instancia.cadastrarUsuario(email, password);

  Future<void> encerrarSessao() =>
      ArmazenamentoLocal.instancia.encerrarSessao();
}
