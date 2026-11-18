<p align="center">
  <img src="assets/icon/icon.png" width="120" alt="Ícone do manuook">
</p>

<h1 align="center">Manuook</h1>

<p align="center">
  Sua estante pessoal com todos os livros que você já leu: capa, título e a sua nota.
</p>

---

## O que o app faz

- **Busca de livros com capa**: digite o título, o autor ou o ISBN e escolha o livro. A capa, o título e o autor vêm preenchidos.
- **Nota de 0 a 5 estrelas, de 0,1 em 0,1**: toque ou deslize o dedo sobre as estrelas. Elas se preenchem na fração exata (ex.: 3,7).
- **Capas rápidas**: as capas ficam guardadas no celular e são carregadas já no tamanho da tela, então a estante abre com elas prontas, mesmo sem internet.
- **5 estrelas especial**: quando o livro recebe 5 estrelas, aparece a opção *5 estrelas especial*. As estrelas ficam **azuis** e a capa ganha um brilho azul na estante.
- **Organização por período**:
  - livros lidos até 2026 ficam todos juntos em **"Lidos antes de 2027"**
  - a partir de **2027**, cada livro fica no **mês** em que foi lido (ex.: *Março de 2027*)
- **Resumo no topo**: total de livros, nota média e quantidade de especiais (a partir de 2027 mostra também quantos livros você leu no ano).
- **Ordenação**: mais recentes, maior nota ou título.
- **Configurações** (ícone de engrenagem):
  - modo **Claro**, **Noturno** ou igual ao **Sistema**
  - **cor do app** entre 12 opções (padrão: verde escuro)
- **Backup**: nas Configurações, *Copiar backup* copia todos os livros como texto e *Importar backup* restaura. Serve também para levar os livros para a versão iOS.
- **Adicionar manualmente**: se o livro não aparecer na busca, dá para cadastrar à mão e colar o link de uma capa.

Os dados ficam salvos no próprio celular.

## APIs de livros

O app usa duas APIs públicas e gratuitas, sem precisar de chave:

| API | Uso |
|---|---|
| [Google Books API](https://developers.google.com/books) | Busca principal, boa cobertura de edições brasileiras |
| [Open Library](https://openlibrary.org/developers/api) | Busca complementar e capas em alta resolução (`covers.openlibrary.org`) |

As duas são consultadas ao mesmo tempo e os resultados repetidos são juntados.

## Baixar o APK

Cada push no `main` gera um APK pelo GitHub Actions:

1. Abra a aba **[Releases](../../releases)** do repositório.
2. Baixe o `manuook.apk` da versão mais recente.
3. No Android, permita a instalação de fontes desconhecidas e instale.

O APK é sempre assinado com a mesma chave (`keystore/manuook.jks`), então as versões novas instalam **por cima** da antiga sem apagar seus livros.

## Estrutura do projeto

```
lib/
├── main.dart                  # ponto de entrada
├── theme.dart                 # tema (claro/noturno) a partir da cor escolhida
├── models/book.dart           # modelo do livro (nota, especial, mês de leitura)
├── services/
│   ├── book_api.dart          # Google Books + Open Library
│   ├── book_store.dart        # armazenamento local e backup
│   └── app_settings.dart      # tema claro/noturno e cor do app
├── screens/
│   ├── home_screen.dart       # estante separada por mês
│   ├── search_screen.dart     # busca de livros
│   ├── book_edit_screen.dart  # nota, estrelas e mês de leitura
│   └── settings_screen.dart   # configurações
└── widgets/
    ├── stars.dart             # estrelas fracionadas (0,1) e azul especial
    └── cover.dart             # capa com cache
```

A pasta `android/` não fica no repositório: ela é gerada pelo `flutter create` no GitHub Actions.

## Rodar localmente

```bash
flutter create --org com.gabestk --project-name manuook --platforms=android .
flutter pub get
dart run flutter_launcher_icons
flutter run
```

> No Android, confirme que `android/app/src/main/AndroidManifest.xml` tem a permissão `android.permission.INTERNET` (o workflow adiciona automaticamente).

## Próximos passos

- [ ] Versão iOS

## Tecnologias

Flutter · Dart · `shared_preferences` · `cached_network_image` · `http`
