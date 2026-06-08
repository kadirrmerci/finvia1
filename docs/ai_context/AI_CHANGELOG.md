# AI_CHANGELOG.md

> AI tarafından yapılan veya AI context’i için önemli görülen değişikliklerin günlüğü.
>
> Bu dosya kullanıcı-facing release changelog değildir. Amaç: yeni chat/session/coding agent çalışmasında önceki AI kararlarını ve teknik gerekçeleri hızlı hatırlamak.

## 2026-06-09 — macOS siyah açılış ekranı düzeltmesi

Durum:

- macOS'ta uygulama penceresinin açılıp siyah kalmasının nedeni bulundu.
- `NotificationService.init()` macOS ayarı olmadan çağrıldığı için
  `flutter_local_notifications`, `runApp()` öncesinde exception fırlatıyordu.
- `InitializationSettings` içine `macOS` Darwin ayarları eklendi.
- Bildirim gösterme ve planlama detaylarına da macOS Darwin ayarları eklendi.
- `dart analyze lib test` ve `flutter test --no-pub` başarıyla tamamlandı.
- Tam macOS build doğrulaması, çalışma ortamının Xcode `sandbox-exec` ve Swift
  Package Manager servislerine izin vermemesi nedeniyle tamamlanamadı.

## 2026-06-09 — Yerel çalıştırma ve build doğrulaması

Durum:

- Flutter 3.44.1 / Dart 3.12.1 ile bağımlılıklar başarıyla çözüldü.
- Eski `mylife` paketini ve `MyApp` sınıfını kullanan starter test Finvia için güncellendi.
- Kredi kartı model dosyası platformlar arası uyumlu küçük harfli ada taşındı.
- Güncel Flutter API deprecation ve lint uyarıları temizlendi.
- `flutter test` ve `flutter build web` başarıyla tamamlandı.
- Android SDK kurulu olmadığı için Android build çalıştırılamadı.
- Xcode ek bileşenleri eksik olduğu için iOS/macOS build doğrulanamadı.

## 2026-06-09 — Image-only splash refinement push’u

Durum:

- Kullanıcının onayıyla splash davranışı yeniden düzenlendi.
- Amaç: görünen splash katmanında ayrı renk/fallback/inpainting algısı olmadan yalnızca verilen Finvia görselini full-screen göstermek.

Yapılan ana değişiklikler:

- `pubspec.yaml`
  - Üst seviye `color` ve `color_dark` splash ayarları kaldırıldı.
  - `background_image` ve `background_image_dark` görsel odaklı kullanımda bırakıldı.
- `lib/main.dart`
  - `_FullScreenSplash` artık `Scaffold` ve `backgroundColor` kullanmıyor.
  - Splash root’u doğrudan `SizedBox.expand + Image(BoxFit.cover)` oldu.
  - Splash sırasında sistem UI `immersiveSticky` yapılıp splash bitince `edgeToEdge` olarak geri alınıyor.

Notlar:

- Android 12 native splash API’si zorunlu olarak bir background color alanı ister; gerçek full-screen görsel ilk Flutter frame’de `_FullScreenSplash` ile gösterilir.
- Localde `dart format lib/main.dart`, `flutter analyze` ve cihaz testi çalıştırılmalı.

## 2026-06-09 — Full-screen splash refactor push’u

Durum:

- Kullanıcının onayıyla splash davranışı için repo’ya push yapıldı.
- Amaç: siyah zemin üzerinde ortalanmış logo yerine Finvia görselini full-screen splash olarak göstermek.

Yapılan ana değişiklikler:

- `pubspec.yaml`
  - `flutter_native_splash` siyah `#0a0a0a` zeminden yeşil `#82BE33` fallback rengine alındı.
  - `image` yerine `background_image` yaklaşımı ayarlandı.
  - `android_gravity: fill` ve `ios_content_mode: scaleAspectFill` eklendi.
- `lib/main.dart`
  - İlk Flutter frame için `_StartupSplashGate` ve `_FullScreenSplash` eklendi.
  - Splash görseli `BoxFit.cover` ile full-screen gösteriliyor.
- Android generated splash XML
  - `launch_background.xml` ve `drawable-v21/launch_background.xml` full-screen bitmap fill kullanacak şekilde güncellendi.
  - Android 12 light/dark fallback splash rengi yeşile çekildi.
- iOS
  - `LaunchScreen.storyboard` içindeki launch image `scaleAspectFill` olarak güncellendi.

Notlar:

- GitHub connector binary PNG replacement desteklemediği için splash asset dosyası bu push içinde değiştirilmedi; mevcut `assets/splash/splash_logo.png` kullanıldı.
- Localde `dart run flutter_native_splash:create`, `dart format lib/main.dart`, `flutter analyze` ve cihaz testi çalıştırılmalı.

## 2026-06-08 — AI context dokümanları repo’ya eklendi

Durum:

- Kullanıcının onayıyla repo’ya AI context dokümanları pushlandı.
- `AGENTS.md` root’a eklendi.
- Detay context dosyaları `docs/ai_context/` altında tutuldu.

Eklenen dosyalar:

- `AGENTS.md`
- `docs/ai_context/PROJECT_CONTEXT.md`
- `docs/ai_context/KNOWN_ISSUES.md`
- `docs/ai_context/AI_CHANGELOG.md`

Yerleşim gerekçesi:

- `AGENTS.md` root’ta kalmalı çünkü coding agent her şeyden önce bunu okumalıdır.
- `docs/ai_context/` klasörü AI’a özel bağlamı normal ürün dokümantasyonundan ayırır.
- Bu yapı, yeni chat/session açıldığında tüm repo’yu baştan analiz etmeden proje haritası ile ilerlemeyi sağlar.

## 2026-06-08 — Context doküman taslakları hazırlandı

Durum:

- Kullanıcının isteğiyle `AGENTS.md`, `docs/ai_context/PROJECT_CONTEXT.md`, `docs/ai_context/KNOWN_ISSUES.md`, `docs/ai_context/AI_CHANGELOG.md` taslakları hazırlandı.
- Kullanıcı önce **push yapmamamı** istedi.
- Taslaklar kullanıcı onayına sunuldu.

Yapılan analiz kapsamı:

- Repo metadata
- Commit history
- `README.md`
- `pubspec.yaml`
- `lib/main.dart`
- `lib/firebase_options.dart`
- `lib/services/database_service.dart`
- `lib/services/notification_service.dart`
- `lib/services/stock_alert_service.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/notes/notes_screen.dart`
- `lib/screens/finance/finance_screen.dart`
- `lib/screens/stocks/stocks_screen.dart`
- `lib/screens/stocks/stock_detail_screen.dart`
- `lib/screens/health/health_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- Okunabilen model dosyaları:
  - `note.dart`
  - `transaction.dart`
  - `subscription.dart`
  - `debt.dart`
  - `budget.dart`
  - `stock_holding.dart`
  - `health_record.dart`
  - `habit.dart`
- Android config:
  - `android/app/build.gradle.kts`
  - `android/app/google-services.json`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/finvia/app/MainActivity.kt`
- Web config:
  - `web/manifest.json`
  - `web/index.html`
- iOS config:
  - `ios/Runner/Info.plist`
- Linux config:
  - `linux/CMakeLists.txt`
- Windows config:
  - `windows/runner/main.cpp`

Önemli bulgular:

- AndroidManifest içinde geçersiz `flutter pub add flutter_local_notifications` satırı var.
- `lib/models/credit_card.dart` dosyası bulunamadı; fakat servis/ekranlar bu dosyayı import ediyor.
- Firebase iOS/macOS bundle id değerleri hâlâ `com.example.mylife` görünüyor.
- DB migration stratejisi güvenli değil.
- Notification scheduling `Future.delayed` temelli, kalıcı değil.
- Settings accent color ana Material theme’e bağlı değil.
- “Tüm verileri sil” gerçek veri silmiyor.
- Stock alerts memory-only.

Not:

- Bu oturumda container üzerinden `git clone` DNS nedeniyle çalışmadı. Analiz GitHub API/file fetch yoluyla yapıldı.
- `flutter analyze` veya build çalıştırılamadı.

## 2026-06-08 — Branding standardization push’u

Durum:

- Kullanıcının onayıyla repo’ya push yapıldı.
- Amaç: `mylife` ve `Elite Life` görünen/yerel adlarını **Finvia** ile eşitlemek.

Yapılan ana değişiklikler:

- `README.md`
  - `mylife` -> `finvia`
- `lib/main.dart`
  - `MyLifeApp` -> `FinviaApp`
  - MaterialApp title -> `Finvia`
- `lib/services/database_service.dart`
  - lokal DB dosyası `mylife.db` -> `finvia.db`
- `lib/services/notification_service.dart`
  - `elite_life_channel` -> `finvia_channel`
  - `Elite Life Bildirimleri` -> `Finvia Bildirimleri`
- `lib/screens/settings/settings_screen.dart`
  - `MyLifeApp` referansı -> `FinviaApp`
  - footer `Elite Life` -> `Finvia`
- iOS
  - display name `Finvia`
- macOS
  - app branding `Finvia`
- Web
  - manifest/index title/description `Finvia`
- Windows
  - window title/metadata `Finvia`
- Linux
  - binary/app id `finvia` / `com.finvia.app`
- Android
  - namespace/applicationId `com.finvia.app`
  - MainActivity package `com.finvia.app`
  - eski `com/elitelife/app/MainActivity.kt` silindi
  - yeni `com/finvia/app/MainActivity.kt` eklendi
  - `google-services.json` package_name `com.finvia.app` yapıldı

Risk notu:

- Firebase backend teknik kimliği `elite-life-48631` olarak kaldı.
- Firebase project id keyfi değiştirilmedi.
- Android package değişikliği Firebase Console ile doğrulanmalı.
- iOS/macOS Firebase bundle id hâlâ ayrıca kontrol edilmeli.

## 2026-06-08 — GitHub write access doğrulandı

Durum:

- Başta GitHub entegrasyonu read-only görünüyordu.
- Kullanıcı GitHub bağlantı/izin tarafını düzelttikten sonra dosya update/commit/push işlemleri başarılı oldu.
- Bundan sonra push yapılabilir, ancak yalnızca kullanıcının açık talimatıyla.

## 2026-06-08 — İlk repo incelemesi

Özet:

- Repo Flutter + Firebase + SQLite tabanlı bir MVP olarak incelendi.
- Ana modüller:
  - Auth
  - Notlar
  - Finans
  - Borsa
  - Sağlık
  - Ayarlar
- İlk teknik riskler:
  - Notification scheduling güvenilirliği
  - DB migration eksikliği
  - Firebase public config/kurallarının kontrol edilmesi
  - İsimlendirme tutarsızlığı
  - Settings theme color’ın uygulanmaması

Sonraki önerilen AI görevleri:

1. Build-blocker fix:
   - AndroidManifest geçersiz satırını kaldır.
   - `credit_card.dart` modelini ekle.
2. Firebase config uyum görevi:
   - Android/iOS/macOS package/bundle id ve Firebase Console uyumu.
3. `flutter analyze` temizliği.
4. Notification scheduling refactor.
5. DB migration altyapısı.
6. Theme/accent color refactor.
7. README ve kurulum dokümantasyonu.
