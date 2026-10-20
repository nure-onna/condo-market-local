# Condo Market Local

Marketplace acadêmico para moradores de um condomínio, desenvolvido em Flutter para **Android e web**. Esta versão funciona sem servidor: contas, anúncios, perfis, imagens e conversas ficam no dispositivo ou no navegador em que foram criados.

A abertura, o login e a página inicial usam a identidade visual e os banners do material `CondoMarket.zip`. A página inicial oferece busca, filtro por categorias, carrossel e acesso aos anúncios.

## Demonstração

O aplicativo cria uma conta local de teste ao iniciar. Os campos de login já vêm preenchidos:

- **E-mail:** `teste@teste.com`
- **Senha:** `teste1234`

Você pode cadastrar outras contas no mesmo dispositivo. Para testar uma conversa, publique um anúncio em uma conta, saia e abra o anúncio pela outra. O vendedor responde pela aba **Mensagens**.

## Executar

Instale o [Flutter](https://docs.flutter.dev/get-started/install) e execute na raiz do projeto:

```sh
flutter pub get
flutter analyze
flutter test
```

Para abrir no navegador:

```sh
flutter run -d chrome --web-port 7357
```

Para executar no Android, instale também o Android SDK e conecte um aparelho ou inicie um emulador:

```sh
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

Para gerar arquivos de distribuição:

```sh
flutter build web
flutter build apk
```

A versão web pode ser hospedada como site estático. A pasta gerada é `build/web/`; não existe API para configurar. O APK gerado pelo comando acima fica em `build/app/outputs/flutter-apk/`.

## Como os dados funcionam

O armazenamento usa `shared_preferences` para guardar um JSON local. As senhas usam PBKDF2-HMAC-SHA256 com sal aleatório. As imagens selecionadas são convertidas em base64 e limitadas a 2 MB por imagem.

Os dados **não são sincronizados** entre dispositivos, navegadores ou origens web. O e-mail serve apenas como identificador local; não há envio de mensagens nem recuperação de senha por e-mail. Limpar os dados do app ou do navegador pode apagar os registros. O login separa as contas da demonstração, mas não substitui a proteção do dispositivo contra acesso aos arquivos locais.

## Estrutura

- `lib/modelos/`: produtos, categorias, perfis e conversas.
- `lib/servicos/`: autenticação, perfil e persistência local.
- `lib/telas/`: login, anúncios, detalhes, perfil e mensagens.
- `assets/`: logotipos e banners.
- `android/` e `web/`: configurações das duas plataformas suportadas.
- `test/`: testes de armazenamento e fluxos da interface.

As funções próprias usam nomes descritivos em português. Métodos exigidos pelo Flutter, como `build`, `initState` e `dispose`, mantêm os nomes do framework.

## Origem do projeto

Esta versão é uma adaptação do projeto acadêmico [Condo-Market](https://github.com/nure-onna/Condo-Market), cujo histórico inicial registra André como autor. A adaptação substituiu o backend por armazenamento local, reorganizou o código em português, limitou as plataformas a Android e web e integrou o visual fornecido para a versão final. O histórico Git original é preservado para mostrar a origem e a evolução do trabalho.
