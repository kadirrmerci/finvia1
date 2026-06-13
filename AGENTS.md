# AGENTS.md

> AI çalışma talimatları — Finvia repo’su (`kadirrmerci/finvia1`) için.
>
> Bu dosya, yeni bir chat/session veya coding agent çalışması başladığında **her şeyden önce** okunmalıdır. Kod değişikliği yapmadan önce bu dosyayı, ardından `docs/ai_context/PROJECT_CONTEXT.md`, `docs/ai_context/KNOWN_ISSUES.md` ve `docs/ai_context/AI_CHANGELOG.md` dosyalarını oku.
> Bu proje üzerinde çalışan her AI agent, herhangi bir işe başlamadan önce `docs/ai_context/` altındaki tüm dosyaları mutlaka okumalıdır.

## 1. Proje kimliği

- Ürün adı: **Finvia**
- Repo: `kadirrmerci/finvia1`
- Flutter package adı: `finvia`
- Tanım: **Finvia - Akıllı Yaşam Asistanı**
- Ana platform hedefleri: Android, iOS, Web, Windows, Linux, macOS
- Ana teknik yığın:
  - Flutter / Dart
  - Firebase Core, Firebase Auth, Cloud Firestore
  - Cloud Firestore ile kullanıcı verisi ve ayar kalıcılığı
  - flutter_local_notifications + timezone
  - fl_chart
  - http ile Yahoo Finance endpointleri
  - google_sign_in
  - uuid, intl, package_info_plus

## 2. Context dosyaları ve okuma sırası

Coding agent şu sırayı izlemelidir:

1. `AGENTS.md`
2. `docs/ai_context/PROJECT_CONTEXT.md`
3. `docs/ai_context/KNOWN_ISSUES.md`
4. `docs/ai_context/AI_CHANGELOG.md`
5. Görevle ilgili gerçek kaynak dosyaları

`AGENTS.md` repo root’ta kalmalıdır. Bunun nedeni birçok coding agent’ın root seviyedeki agent talimatlarını otomatik ya da yarı otomatik olarak aramasıdır. Diğer AI context dosyaları `docs/ai_context/` altında tutulur; böylece normal ürün dokümantasyonundan ayrılır ama yine de repo içinde version control altında kalır.

## 3. Mutlaka korunacak ürün kararları

1. Kullanıcıya görünen ürün adı **Finvia** olmalı.
2. Eski marka/ad izleri (`mylife`, `MyLife`, `Elite Life`, `elite_life`, `elitelife`) yeni eklenen kodda kullanılmamalı.
3. Firebase backend project id şu anda `elite-life-48631` olarak duruyor. Bu değer marka metni gibi değiştirilmemeli; Firebase Console / FlutterFire yeniden yapılandırması yapılmadan keyfi değiştirme.
4. Android uygulama kimliği şu anda `com.finvia.app` olarak hedeflenmiş durumda.
5. Kullanıcı domain verisinin tek kalıcı kaynağı Cloud Firestore'dur.
6. Ana navigasyon sırası korunmalı:
   - Notlar
   - Finans
   - Borsa
   - Sağlık
   - Ayarlar

## 4. Yeni görev başlangıç protokolü

Yeni bir görev geldiğinde:

1. Önce bu dosyayı oku.
2. Sonra sırayla context dosyalarını oku.
3. Görev hangi alanla ilgiliyse sadece ilgili dosyaları derin oku.
4. Tüm repo’yu baştan analiz etmeye çalışma; context dosyalarını harita olarak kullan.
5. Kod değişikliği yapmadan önce etkilenebilecek dosyaları belirle.
6. Yalnızca gerekli dosyaları değiştir.
7. Değişiklik mimari, veri modeli, Firebase, DB, bildirim, auth, platform config veya marka davranışını etkiliyorsa context dokümanlarını da güncelle.
8. Push, commit veya PR açmadan önce kullanıcının açık talimatını bekle.

## 5. Push ve commit politikası

- Kullanıcı açıkça istemedikçe **push yapma**.
- Kullanıcı “push et” derse:
  1. Hangi repo/branch’e push yapılacağını netleştir.
  2. Hangi dosyaları değiştireceğini belirt.
  3. Kod dosyalarını güncelle.
  4. Gerekirse context dokümanlarını da aynı değişiklik setine dahil et.
  5. Commit mesajını kısa, net ve İngilizce yaz.
  6. Commit/push başarılıysa hangi dosyaların değiştiğini söyle.
- Kullanıcı “onayıma sun, push yapma” derse:
  - Sadece taslak dosya içeriklerini veya patch önerisini hazırla.
  - GitHub’a yazma işlemi yapma.

## 6. Kod değişikliği öncesi minimum kontrol listesi

Her görevde şu soruları cevapla:

- Bu değişiklik hangi ekranı/servisi etkiliyor?
- Lokal SQLite schema değişiyor mu?
- Firebase Auth / Firestore / Firebase Options etkileniyor mu?
- Android/iOS bundle/application id etkileniyor mu?
- Bildirim davranışı etkileniyor mu?
- Eski kullanıcı verisi migration ister mi?
- `shared_preferences` anahtarları değişiyor mu?
- Web/desktop platformlarında kırılma ihtimali var mı?
- Kullanıcıya görünen metinlerde marka adı tutarlı mı?
- Context dokümanlarını güncellemek gerekiyor mu?

## 7. Firebase kuralları

Firebase ile ilgili özel dikkat:

- `lib/firebase_options.dart`, `android/app/google-services.json`, iOS/macOS bundle id’leri ve Firebase Console birlikte düşünülmeli.
- `projectId`, `storageBucket`, `appId`, `apiKey`, `messagingSenderId` gibi değerleri otomatik “Finvia” yapmak için değiştirme.
- Firebase projesinin adı hâlâ `elite-life-48631` olabilir; bu backend teknik kimliğidir.
- Android package id `com.finvia.app` ile Firebase Android app kaydı eşleşmeli.
- iOS/macOS tarafında `iosBundleId` hâlâ eski `com.example.mylife` görünüyorsa FlutterFire yeniden yapılandırması gerekebilir.
- Google Sign-In, Firebase Auth ve Firestore kuralları birlikte test edilmeden auth refactor yapma.
- Public repo’da Firebase web/mobile API key görünmesi tek başına klasik secret sayılmaz; yine de Firestore rules, API restrictions ve App Check kontrol edilmeden production’a çıkma.

## 8. Firestore / veri modeli kuralları

- `lib/services/database_service.dart`, kullanıcı domain verisini doğrudan
  `users/{uid}/{collection}/{documentId}` altında yönetir.
- SQLite, cihaz dosyası ve kalıcı SharedPreferences kullanıcı verisi için
  kullanılmamalıdır.
- Firestore okumaları strict cloud-only davranış için sunucu kaynağını ister.
- Model `toMap/fromMap` alanları Firestore dokümanlarıyla uyumlu olmalıdır.
- Yeni kullanıcı koleksiyonları `deleteAllCurrentUserData()` kapsamına da
  eklenmelidir.
- Production'da eski lokal veri migration ihtiyacı release öncesi ayrıca
  değerlendirilmelidir.

## 9. Bildirim kuralları

- Bildirim servisi: `lib/services/notification_service.dart`
- Şu an hatırlatıcılar ağırlıklı olarak `Future.delayed` ile planlanıyor.
- Kalıcı ve güvenilir hatırlatıcı için `zonedSchedule`, izin yönetimi ve reboot sonrası yeniden kurulum gerekir.
- Android 13+ için bildirim izni runtime’da ayrıca istenmelidir.
- Kullanıcı ayarlarındaki “bildirimler açık/kapalı” değerleri schedule/show operasyonlarına bağlanmadan yeni bildirim özelliği ekleme.
- Bildirim id’leri çakışmayacak şekilde deterministik tasarlanmalı.
- Fiyat alarmı gibi sürekli takip gerektiren işler app process öldüğünde durur; background task stratejisi olmadan “garantili alarm” vaadi verme.

## 10. Auth ve kullanıcı profili kuralları

- Giriş ekranı: `lib/screens/auth/login_screen.dart`
- Firebase Auth metotları:
  - Email/password
  - Google Sign-In
  - Phone OTP
- Firestore koleksiyonu: `users`
- Kullanıcı alanları:
  - `name`
  - `email`
  - `phone`
  - `age`
  - `city`
  - `district`
  - `createdAt`
- Email kayıt akışında email verification gönderiliyor ve kullanıcı sign-out ediliyor.
- Google ve telefon girişlerinde profil alanları eksik/varsayılan kalabilir; bu alanları kullanacak yeni özelliklerde null/empty/default durumunu hesaba kat.
- Auth ekranındaki il/ilçe listesi büyük ve hard-coded; bu listeyi büyütmeden önce ayrı data/service yapısı düşün.

## 11. Finans kuralları

- Finans ekranı: `lib/screens/finance/finance_screen.dart`
- Kullanılan modeller:
  - `FinanceTransaction`
  - `Subscription`
  - `Debt`
  - `Budget`
  - `CreditCard`
  - `CreditCardStatement`
- İşlevler:
  - gelir/gider takibi
  - abonelik takibi
  - borç takibi
  - bütçe takibi
  - kredi kartı takibi
  - özet grafikler
- Finansal değerlerde para birimi ayarı şu an UI genelinde tam merkezi uygulanmıyor; yeni özellikte para birimini merkezi bir helper/theme/context üzerinden kullan.
- Hesaplama değişikliklerinde negatif, sıfır, null ve eski veri durumlarını test et.

## 12. Borsa / yatırım kuralları

- Borsa ekranı: `lib/screens/stocks/stocks_screen.dart`
- Detay ekranı: `lib/screens/stocks/stock_detail_screen.dart`
- Alarm servisi: `lib/services/stock_alert_service.dart`
- Yahoo Finance endpointleri doğrudan kullanılmakta:
  - `/v8/finance/chart`
  - `/v1/finance/search`
- Watchlist hard-coded market listeleriyle başlıyor:
  - BIST
  - ABD
  - Avrupa
  - Kripto
  - Emtia
- Harici endpointler için hata, rate-limit, timeout ve fallback dikkate alınmalı.
- Fiyat alarmı in-memory tutuluyor; uygulama kapanınca kaybolur.
- Borsa/kripto verileri finansal tavsiye gibi sunulmamalı; UI dili bilgilendirici olmalı.

## 13. Sağlık kuralları

- Sağlık ekranı: `lib/screens/health/health_screen.dart`
- Modüller:
  - Kilo takibi
  - Alışkanlık takibi
- Modeller:
  - `HealthRecord`
  - `Habit`
- Habit streak hesabında liste mutasyonu riski var; bu alana dokunurken defensive copy kullan.
- Sağlık verileri hassas kabul edilmeli; bulut senkronizasyon eklenirse gizlilik/izin/metinler hazırlanmalı.

## 14. Notlar kuralları

- Not ekranı: `lib/screens/notes/notes_screen.dart`
- Model: `Note`
- Özellikler:
  - kategori
  - renk
  - arama
  - sabitleme
  - arşiv alanı modelde var
  - hatırlatıcı
- `copyWith` şu an `reminderTime` alanını null’a set etmeyi zorlaştırabilir; null-clearing gerekiyorsa sentinel veya ayrı parametre yaklaşımı kullan.
- Not hatırlatıcı iptal id’leri schedule id ile tutarlı olmalı.

## 15. Tema ve ayarlar kuralları

- Ana tema `lib/main.dart` içinde `Color(0xFF6C63FF)` seedColor ile kurulmuş.
- Ayarlar `users/{uid}/settings/app` dokümanında tutulur.
- Seçilen accent color şu an `MaterialApp` theme seedColor’a bağlı görünmüyor.
- Tema refactor yapılacaksa:
  - `FinviaApp` state’i accent color ve theme mode’u birlikte yönetsin.
  - Firestore settings dokümanı tek kalıcı kaynak olsun.
  - Tüm sabit `Color(0xFF6C63FF)` kullanımları kademeli merkezi tema tokenlarına taşınsın.

## 16. Platform config kuralları

- Android:
  - `android/app/build.gradle.kts`
  - `android/app/google-services.json`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/finvia/app/MainActivity.kt`
- iOS:
  - `ios/Runner/Info.plist`
  - `ios/Runner.xcodeproj/project.pbxproj`
  - Firebase bundle id uyumu kontrol edilmeli.
- Web:
  - `web/index.html`
  - `web/manifest.json`
- Linux:
  - `linux/CMakeLists.txt`
  - `linux/runner/my_application.cc`
- Windows:
  - `windows/runner/main.cpp`
  - `windows/runner/Runner.rc`
- macOS:
  - `macos/Runner/Configs/AppInfo.xcconfig`
- Marka adı veya bundle/application id değişirse tüm platformlar birlikte kontrol edilmeli.

## 17. Kod stili

- Mevcut kod çoğunlukla tek dosyada büyük StatefulWidget yapısında ilerliyor.
- Büyük refactor istenmedikçe küçük ve güvenli değişiklikler yap.
- Yeni büyük özelliklerde model / service / screen / widget / helper ayrımını koru.
- Kullanıcıya görünür metinlerde Türkçe kullan.
- `setState` async sonrası çağrılıyorsa `mounted` kontrolü ekle.
- TextEditingController / TabController gibi controller’lar için `dispose` kontrolü yap.
- Hata mesajları kullanıcı dostu olmalı.

## 18. Test/build politikası

Kod değişikliği sonrası mümkünse:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

Platform etkisi varsa ayrıca:

```bash
flutter build apk --debug
flutter build web
```

Bu ortamda komutlar çalıştırılamıyorsa veya repo clone edilemiyorsa bunu açıkça belirt.

## 19. Context dokümanlarını güncelleme şartları

Aşağıdaki değişikliklerden biri yapılırsa context dokümanlarını da güncelle:

- Yeni ekran/modül
- Yeni model/tablo/kolon
- DB version değişikliği
- Firebase config/Auth/Firestore değişikliği
- Platform bundle/application id değişikliği
- Marka adı/görünür ürün kimliği değişikliği
- Bildirim çalışma mantığı değişikliği
- Borsa/veri endpointi değişikliği
- Bilinen issue fix’i veya yeni kritik issue
- Build/test sonucunda yeni bilgi

Güncellenecek dosyalar:

- `docs/ai_context/PROJECT_CONTEXT.md`: mimari ve güncel yapı değiştiyse
- `docs/ai_context/KNOWN_ISSUES.md`: risk eklendi/çözüldüyse
- `docs/ai_context/AI_CHANGELOG.md`: AI tarafından yapılan önemli değişiklik kaydı

## 20. Güvenlik ve gizlilik

- Public repo’ya secret, servis account, private key, keystore, `.env`, production token commit etme.
- Mevcut Firebase API key’leri public görünse de secret gibi davran; değiştirmeden önce kullanıcıya sor.
- Keystore dosyaları `.gitignore` ile dışarıda kalmalı.
- Sağlık ve finans verileri hassas sayılmalı.
- Veri dışa aktarma/yedekleme özelliği eklenirse açık izin ve güvenli saklama tasarlanmalı.

## 21. Kısa görev şablonu

Her yeni kod görevinde iç plan:

1. Context dosyalarını oku.
2. Etkilenen dosyaları listele.
3. İlgili kodu oku.
4. Riskleri belirle.
5. Minimal değişiklik yap.
6. Format/analyze imkanı varsa çalıştır.
7. Context dokümanını gerekirse güncelle.
8. Kullanıcıya ne değiştiğini, hangi dosyaların etkilendiğini, test/build durumunu ve kalan riskleri raporla.
