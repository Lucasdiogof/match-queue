# Branding

A logo definitiva do FIFA Queue **ainda não existe** e não foi criada nesta
etapa. Nada no projeto depende de uma marca gráfica.

## O que existe hoje

- `BrandAssets` (`lib/core/design_system/branding/brand_assets.dart`) — único
  lugar do projeto que conhece nome, monograma e caminhos de asset da marca.
  Todos os caminhos são `null`.
- `BrandMark` — desenha um monograma `FQ` em quadrado arredondado enquanto
  `BrandAssets.logo` for `null`.
- `BrandWordmark` — renderiza o texto `FIFA Queue` enquanto
  `BrandAssets.wordmark` for `null`.
- `BrandLockup` — combinação dos dois.

Nenhum outro arquivo do app referencia a marca diretamente.

## Como trocar quando a identidade existir

1. Colocar os arquivos em `assets/brand/`.
2. Declarar a pasta em `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/brand/
```

3. Preencher os caminhos em `BrandAssets`:

```dart
static const String? logo = 'assets/brand/logo.png';
static const String? wordmark = 'assets/brand/wordmark.png';
static const String? appIcon = 'assets/brand/app_icon.png';
static const String? splashMark = 'assets/brand/splash.png';
```

`BrandMark` e `BrandWordmark` passam a usar as imagens automaticamente — não
há nenhuma outra alteração de código necessária.

## Ícones de loja

Ícones definitivos de App Store / Play Store não foram gerados. Quando a logo
existir, o caminho mais direto é adicionar `flutter_launcher_icons` como
`dev_dependency` apontando para `assets/brand/app_icon.png`.
