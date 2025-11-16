# JetWash Mobile (scaffold)

Este diretório contém um scaffold mínimo do app Flutter para o projeto JetWash Pro.

Pré-requisitos:
- Flutter SDK instalado (versão compatível com o `sdk` do `pubspec.yaml`).

Variáveis de ambiente (para integração com Supabase):

- Crie um arquivo `.env` dentro da pasta `mobile/` com as chaves:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

O scaffold usa `flutter_dotenv` para carregar essas variáveis e `supabase_flutter` para conectar ao Supabase.

Como rodar em desenvolvimento:

```bash
# a partir da raiz do workspace
cd mobile
flutter pub get
flutter run
```

Observações:
- Este scaffold é propositalmente simples: demonstra tema dinâmico white-label e estrutura inicial.
- Próximo passo: integrar com Supabase (URL e anon key) para carregar `tenant settings` e resources.

Rodando em desenvolvimento (com Supabase):

```bash
cd mobile
flutter pub get
# copie o .env com SUPABASE_URL e SUPABASE_ANON_KEY
flutter run
```

Novas funcionalidades adicionadas:

- Onboarding / White-label: página para atualizar `nome_fantasia`, `primary_color` e enviar logo (usa `tenants` table + Storage).
- Upload de fotos: `StorageService` para enviar fotos ao bucket `public` e registrar na tabela `photos`.
- Pátio (MVP): `ParkingPage` lista `service_orders` e permite criar uma OS simples.
- OCR de placa on-device: `OcrService` usando `google_mlkit_text_recognition` (exemplo simples via câmera).

Observações para usar OCR e image_picker:
- Android e iOS requerem permissões para câmera e leitura de arquivos; configure `AndroidManifest.xml` e `Info.plist` conforme a documentação das bibliotecas.

Exemplos de permissões nativas (copie para os arquivos apropriados):

- `android/app/src/main/AndroidManifest.xml` (acima da tag `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

- `ios/Runner/Info.plist` (adicione no dicionário principal):

```xml
<key>NSCameraUsageDescription</key>
<string>Usado para tirar fotos de avarias e leitura de placa</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Usado para selecionar imagens para anexar a ordens de serviço</string>
```

Fastlane (exemplo)
- Criei um exemplo simples de `Fastfile` em `mobile/fastlane/Fastfile` com lanes para `debug` e `release` (Android). Ajuste conforme seus certificados/keystore.

Melhorias OCR e fallback
- O serviço OCR no scaffold tenta extrair placas com múltiplos padrões e heurísticas simples. Para produção, considere:
	- Pré-processamento da imagem (aumentar contraste, binarizar) antes do OCR.
	- Usar um serviço especializado (ex.: Plate Recognizer) como fallback para maior precisão.

Signed URLs / Buckets privados
- O scaffold agora grava o `path` do arquivo no banco (campo `photos.url`) em vez de URLs públicas. Isso permite usar buckets privados.
- Para exibir imagens armazenadas em buckets privados, o app pede um signed URL via `StorageService.createSignedUrl(...)` antes de carregar a imagem.
- Se preferir usar URLs públicas, crie um bucket público e adapte `StorageService.uploadPhoto` para salvar a URL pública.

Testes
- Adicionei um teste widget simples em `mobile/test/home_widget_test.dart` que verifica a presença dos botões principais. Para rodar os testes:

```bash
cd mobile
flutter test
```



