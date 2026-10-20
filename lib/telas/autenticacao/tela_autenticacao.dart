import 'package:flutter/material.dart';
import 'package:condo_market_local/servicos/servico_autenticacao.dart';
import 'package:condo_market_local/servicos/armazenamento_local.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController(
    text: ArmazenamentoLocal.emailContaTeste,
  );
  final _passwordController = TextEditingController(
    text: ArmazenamentoLocal.senhaContaTeste,
  );
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _entrarOuCadastrarUsuario() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authService.autenticarUsuario(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.cadastrarUsuario(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _FundoComLogotipos(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/logo_condo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _entrarOuCadastrarUsuario,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(_isLogin ? 'Entrar' : 'Cadastrar'),
                          ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                      child: Text(
                        _isLogin
                            ? 'Não tem uma conta? Crie uma aqui!'
                            : 'Já tem uma conta? Faça login aqui!',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Contas e dados ficam apenas neste dispositivo.\n'
                      'O e-mail é usado como identificação local.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FundoComLogotipos extends StatelessWidget {
  const _FundoComLogotipos();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) => Stack(
        children: List.generate(18, (indice) {
          final largura = limites.maxWidth;
          final altura = limites.maxHeight;
          return Positioned(
            left: (indice * 137.0 + 23) % largura,
            top: (indice * 179.0 + 31) % altura,
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(
                'assets/logo.png',
                width: 10.0 + (indice % 4) * 4,
                height: 10.0 + (indice % 4) * 4,
              ),
            ),
          );
        }),
      ),
    );
  }
}
