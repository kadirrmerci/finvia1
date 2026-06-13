# PROJECT_CONTEXT.md

> Finvia repo bağlamı.
>
> Bu dosya yeni bir AI/chat/coding agent oturumunda projeyi hızlı anlamak için hazırlanmıştır. Kodun yerine geçmez; hangi dosyalara bakılması gerektiğini gösteren mimari haritadır.

## 1. Genel özet

**Finvia**, Flutter ile yazılmış kişisel yaşam asistanı uygulamasıdır. Uygulama; not tutma, finans yönetimi, borsa/yatırım takibi, sağlık/kilo takibi, alışkanlık takibi ve ayarlar/profil yönetimi modüllerinden oluşur.

Repo adı `finvia1`, Flutter package adı `finvia`, ürün adı **Finvia**.

## 2. Teknoloji yığını

`pubspec.yaml` bilgilerine göre ana bağımlılıklar:

- `flutter`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `google_sign_in`
- `flutter_local_notifications`
- `timezone`
- `fl_chart`
- `http`
- `intl`
- `uuid`
- `google_fonts`
- `provider`
- `package_info_plus`
- `flutter_native_splash`
- `flutter_launcher_icons`

SDK constraint şu anda `sdk: ^3.12.0`.

## 3. Uygulama başlangıcı

Ana giriş dosyası:

- `lib/main.dart`

Başlangıç akışı:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
3. `NotificationService().init()`
4. `runApp(const FinviaApp())`

`FinviaApp`, `StatefulWidget` olarak tema modunu yönetir. Tema modu giriş
sonrasında `users/{uid}/settings/app` Firestore dokümanından yüklenir.
Firestore disk persistence uygulama başlangıcında kapatılır.

`MaterialApp`:

- title: `Finvia`
- debug banner kapalı
- light/dark theme var
- seed color şu anda sabit `Color(0xFF6C63FF)`
- `home` alanında Firebase Auth state izlenir

Auth yönlendirme:

- `FirebaseAuth.instance.authStateChanges()` dinlenir.
- User yoksa `LoginScreen`
- User varsa ve `emailVerified == true` ise `MainNavigation`
- User varsa ama email doğrulanmamışsa sign-out ve `LoginScreen`

Not: Telefon veya Google girişinde `emailVerified` davranışı ayrıca kontrol edilmeli; emailVerified sadece email auth için anlamlı olabilir.

## 4. Ana navigasyon

`MainNavigation` bir `IndexedStack` ile 5 ekranı tutar:

1. `NotesScreen`
2. `FinanceScreen`
3. `StocksScreen`
4. `HealthScreen`
5. `SettingsScreen`

Bottom navigation label’ları:

- Notlar
- Finans
- Borsa
- Sağlık
- Ayarlar

## 5. Firebase katmanı

Dosyalar:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Firebase project id hâlâ:

- `elite-life-48631`

Bu değer backend teknik kimliğidir. Ürün adını Finvia yapmak için bu project id otomatik değiştirilmemelidir.

`DefaultFirebaseOptions.currentPlatform` destekleri:

- Web
- Android
- iOS
- macOS
- Windows
- Linux için `UnsupportedError`

Dikkat edilen mevcut durumlar:

- Android package name `com.finvia.app` olarak güncellenmiş.
- `google-services.json` içindeki package_name de `com.finvia.app` görünüyor.
- `firebase_options.dart` içinde iOS/macOS `iosBundleId` hâlâ `com.example.mylife` görünüyor.
- Firebase web/windows authDomain ve storageBucket değerlerinde `elite-life-48631` geçiyor; bu teknik backend id olarak kalabilir.

## 6. Auth / kayıt / profil

Ana dosya:

- `lib/screens/auth/login_screen.dart`

Desteklenen auth akışları:

- Email/password login/register
- Google Sign-In
- Telefon OTP

Firestore kullanıcı dokümanı:

- collection: `users`
- document id: `user.uid`

Kaydedilen alanlar:

- `name`
- `email`
- `phone`
- `age`
- `city`
- `district`
- `createdAt`

Email kayıt akışı:

1. Form validasyonu
2. `createUserWithEmailAndPassword`
3. `updateDisplayName`
4. `_saveUserToFirestore`
5. `sendEmailVerification`
6. `signOut`
7. Kullanıcıdan email doğrulaması beklenir

Firebase Auth içinde email zaten kayıtlıysa kayıt işlemi durdurulur ve kullanıcıya
`Bu e-mail adresi ile aktif bir kullanıcı hesabı mevcut` uyarısı gösterilir.
Mevcut hesaba otomatik giriş yapılmaz ve Firestore profili güncellenmez.

Login akışı:

1. `signInWithEmailAndPassword`
2. emailVerified değilse signOut
3. Ana auth stream yönlendirir

Google akışı:

1. `GoogleSignIn(scopes: ['email', 'profile'])`
2. Google credential
3. Firebase credential
4. Firestore user merge

Telefon akışı:

1. `verifyPhoneNumber`
2. `codeSent` ile `_verificationId`
3. OTP credential
4. Firebase sign-in
5. Kullanıcı adı doluysa displayName + Firestore kaydı

Auth ekranında Türkiye il/ilçe listesi kod içine gömülü büyük bir map olarak duruyor.

## 7. Firestore veri katmanı

Ana servis:

- `lib/services/database_service.dart`

Kullanıcı alt koleksiyonları:

- `transactions`
- `subscriptions`
- `debts`
- `budgets`
- `holdings`
- `notes`
- `health_records`
- `habits`
- `credit_cards`
- `credit_card_statements`

Ek koleksiyonlar:

- `health_goals`
- `settings`

## Kullanıcı bazlı veri izolasyonu

- `DatabaseService`, tüm CRUD işlemlerini oturumdaki Firebase kullanıcısının
  uid değeri altında doğrudan Firestore'a uygular.
- Firestore verileri `users/{uid}/{collection}/{id}` altında tutulur.
- Okumalar `Source.server` kullanır; yazımlar Firestore tamamlanmadan başarılı
  sayılmaz.
- Kayıt silmeleri hard delete olarak uygulanır.
- Uygulama girişinde lokal merge/sync yapılmaz; yalnızca cloud erişimi ve
  ayarlar yüklenir.
- Ayarlar ekranındaki manuel bulut aksiyonu Firestore bağlantısını ve ayarlar
  dokümanını sunucudan doğrular; tema dahil tüm kullanıcı veri ekranlarını
  yeniden oluşturarak koleksiyonları `Source.server` üzerinden tekrar yükler.
- `Tüm Verileri Sil`, bilinen tüm kullanıcı alt koleksiyonlarını batch'ler
  halinde siler, planlanmış bildirimleri iptal eder ve tüm kullanıcı veri
  ekranlarını boş sunucu durumuyla yeniden oluşturur.
- Android ana manifesti release dahil tüm build türlerinde `INTERNET` izni
  içerir.
- macOS debug/profile ve release sandbox entitlement dosyaları outbound
  bağlantılar için `com.apple.security.network.client` yetkisini içerir.
- macOS release entitlement dosyası Firebase Auth için Keychain Sharing access
  group içerir. Debug/profile build'i VS Code'un ad-hoc imzasıyla çalışabilmesi
  için bu imzalı dağıtım entitlement'ını istemez.
- macOS CocoaPods kurulumu, yalnızca `DEBUG` build'lerinde ve yalnızca macOS'ta
  Firebase Auth'un data-protection Keychain sorgusunu normal Keychain'e
  düşürür. Böylece Apple Development sertifikası olmayan yerel VS Code
  build'lerinde email hesabı oluşturma tamamlanabilir; release build'leri
  Firebase'in standart Keychain Sharing davranışını kullanır.
- Proje, iOS/macOS plugin bağımlılıklarında mevcut CocoaPods kurulumunu kullanır;
  deneysel Swift Package Manager entegrasyonu `pubspec.yaml` üzerinden kapalıdır.
- VS Code macOS launch ve integrated terminal ayarları CocoaPods/Ruby için
  `en_US.UTF-8` locale kullanır.
- iOS, web, Windows ve Linux normal HTTPS/Firebase trafiği için ayrıca
  manifest tabanlı internet izni istemez.

## 8. Model katmanı

Mevcut/okunan modeller:

### `Note`

Dosya: `lib/models/note.dart`

Alanlar:

- `id`
- `title`
- `content`
- `category`
- `color`
- `createdAt`
- `reminderTime`
- `isPinned`
- `isArchived`

### `FinanceTransaction`

Dosya: `lib/models/transaction.dart`

Alanlar:

- `id`
- `title`
- `amount`
- `category`
- `date`
- `isExpense`
- `isFixed`
- `creditCardId`
- `creditCardName`

### `Subscription`

Dosya: `lib/models/subscription.dart`

Alanlar:

- `id`
- `title`
- `amount`
- `category`
- `billingDay`
- `color`
- `creditCardId`
- `creditCardName`
- `lastChargedMonth`

### `Debt`

Dosya: `lib/models/debt.dart`

Alanlar:

- `id`
- `title`
- `totalAmount`
- `paidAmount`
- `monthlyPayment`
- `startDate`
- `interestRate`

Computed alanlar:

- `remainingAmount`
- `remainingMonths`
- `estimatedEndDate`

### `Budget`

Dosya: `lib/models/budget.dart`

Alanlar:

- `id`
- `category`
- `limitAmount`
- `month`

### `StockHolding`

Dosya: `lib/models/stock_holding.dart`

Alanlar:

- `id`
- `symbol`
- `name`
- `buyPrice`
- `quantity`
- `buyDate`
- mutable `currentPrice`

Computed alanlar:

- `totalCost`
- `currentValue`
- `profitLoss`
- `profitLossPercent`

### `HealthRecord`

Dosya: `lib/models/health_record.dart`

Alanlar:

- `id`
- `weight`
- `date`
- `note`

### `Habit`

Dosya: `lib/models/habit.dart`

Alanlar:

- `id`
- `title`
- `type`
- `startDate`
- `completedDays`
- `emoji`
- `motivation`

Computed/behavior:

- `currentStreak`
- `isTodayCompleted`
- `copyWith(completedDays)`

### `CreditCard` / `CreditCardStatement`

Dosya: `lib/models/credit_card_model.dart`

`DatabaseService` ve `FinanceScreen` bu modelleri kullanır.

## 9. Notlar modülü

Ana dosya:

- `lib/screens/notes/notes_screen.dart`

Özellikler:

- Not listeleme
- Arama
- Kategori filtreleme
- Renk seçimi
- Not ekleme
- Not detayı
- Düzenleme
- Silme
- Sabitleme
- Hatırlatıcı ekleme

Kategoriler:

- Tümü
- Kişisel
- İş
- Alışveriş
- Sağlık
- Diğer

Renkler:

- Beyaz
- Sarı
- Yeşil
- Mavi
- Pembe
- Mor

Hatırlatıcı:

- `NotificationService().scheduleNoteReminder`
- Notification id hesaplamasında `note.id.hashCode` kullanılıyor.
- İptalde `1000 + note.id.hashCode` kullanılıyor; schedule tarafı `1000 + id`, id olarak hash verildiğinde uyum var gibi görünür fakat hash stabilitesi/platform davranışı değerlendirilmeli.

## 10. Finans modülü

Ana dosya:

- `lib/screens/finance/finance_screen.dart`

Tab yapısı:

1. Genel
2. İşlemler
3. Abonelikler
4. Borçlar
5. Bütçe
6. Kredi Kartlarım

Veri kaynakları:

- `DatabaseService().getTransactions()`
- `getSubscriptions()`
- `getDebts()`
- `getBudgets()`
- `getCreditCards()`

Öne çıkan hesaplamalar:

- toplam gelir
- toplam gider
- bakiye
- aylık abonelik toplamı
- toplam borç
- toplam kredi kartı borcu
- kategori bazlı harcama
- aylık gider trendi
- tasarruf oranı
- günlük ortalama gider

Grafik:

- `fl_chart` ile pasta grafik ve bar chart

Abonelikler:

- Billing day üzerinden gün farkı hesaplanıyor.
- Yeni aboneliklerde mevcut bir kredi kartı seçimi zorunludur.
- Vadesi gelen abonelikler uygulama açıldığında bağlı kartın borcuna ayda bir kez
  otomatik eklenir.
- Hatırlatıcı NotificationService ile kuruluyor.

Borçlar:

- Remaining amount / remaining months / estimated end date hesaplanıyor.
- Ödeme yapıldığında borç güncellenip transaction da ekleniyor.

Bütçe:

- Mevcut ay `yyyy-MM`
- Kategori bazlı harcama ile bütçe kıyaslanıyor.

Kredi kartı:

- `CreditCard` ve `CreditCardStatement` modellerine bağımlı.
- İlgili model dosyası eksikse derleme kırılır.

## 11. Borsa / yatırım modülü

Ana dosyalar:

- `lib/screens/stocks/stocks_screen.dart`
- `lib/screens/stocks/stock_detail_screen.dart`
- `lib/services/stock_alert_service.dart`

Market listeleri:

- BIST
- ABD
- Avrupa
- Kripto
- Emtia

BIST örnek semboller:

- `THYAO.IS`
- `GARAN.IS`
- `ASELS.IS`
- `EREGL.IS`
- `AKBNK.IS`

Yahoo Finance endpointleri:

- Fiyat: `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1d&range=1d`
- Arama: `https://query1.finance.yahoo.com/v1/finance/search?q={query}&lang=tr-TR&region=TR`
- Grafik: chart endpoint + range

Portföy özellikleri:

- Hisse/varlık ekleme
- Alış fiyatı
- Adet
- Güncel fiyat
- Toplam yatırım
- Toplam değer
- Kar/zarar
- Satış simülasyonu
- Portföy dağılım analizi

Fiyat alarmı:

- `StockAlertService`
- Alert listesi memory içinde
- `Timer.periodic(Duration(minutes: 5))`
- Trigger olunca `NotificationService().checkStockAlarm`
- Trigger sonrası alarm memory listesinden siliniyor

Risk:

- Uygulama kapanınca Timer ve alarm listesi kaybolur.
- Background execution yok.
- Alert persistence yok.

## 12. Sağlık / alışkanlık modülü

Ana dosya:

- `lib/screens/health/health_screen.dart`

Tab yapısı:

1. Kilo Takibi
2. Alışkanlıklar

Kilo özellikleri:

- Kilo kaydı ekleme
- Not ekleme
- Son kilo / ilk kilo farkı
- Kilo grafiği
- Kayıt silme
- Günlük kilo hatırlatıcısı

Alışkanlık özellikleri:

- Hazır şablonlar
  - Sigara Bırak
  - Spor Yap
  - Su İç
  - Kitap Oku
  - Meditasyon
  - Sağlıklı Ye
- Emoji
- Motivasyon cümlesi
- Günlük tamamlama
- Seri/streak
- Son 7 gün mini takvim
- Günlük hatırlatıcı

Risk:

- Habit modelinde `currentStreak`, `completedDays..sort` ile listeyi yerinde mutate ediyor olabilir.
- Reminder sistemi Future.delayed temelli olduğu için kalıcı değil.

## 13. Ayarlar modülü

Ana dosya:

- `lib/screens/settings/settings_screen.dart`

Bölümler:

- Profil
- Görünüm
- Finans
- Bildirimler
- Veri
- Hesap
- Hakkında

Ayarlar:

- name
- email
- currency
- darkMode
- notifications
- debtReminder
- subscriptionReminder
- accentColor

Kullanılan storage:

- `users/{uid}/settings/app`

Entegrasyonlar:

- `darkMode` değişince `FinviaApp.of(context)?.updateTheme(v)`
- `PackageInfo.fromPlatform()` ile versiyon gösterimi
- FirebaseAuth ile çıkış

Eksikler:

- Accent color kaydediliyor ama ana tema seedColor’a bağlı değil.
- Yedekleme/dışa aktarma/aile paylaşımı özellikleri “yakında” placeholder.

## 14. Bildirim servisi

Dosya:

- `lib/services/notification_service.dart`

Başlangıç:

- timezone init
- local timezone: `Europe/Istanbul`
- Android init icon: `@mipmap/ic_launcher`
- Darwin permissions true

Notification türleri:

- Genel Finvia bildirimi
- Not hatırlatıcısı
- Abonelik ödeme hatırlatıcısı
- Hisse alarmı
- Kilo ölçüm hatırlatıcısı
- Alışkanlık hatırlatıcısı

Platform initialization:

- Android initialization ayarı mevcut.
- iOS ve macOS için Darwin initialization ayarları mevcut.
- Bildirim detayları Android, iOS ve macOS platformlarını içeriyor.

Mevcut schedule yaklaşımı:

- `Future.delayed`

Kalıcı schedule:

- Henüz yok.
- `zonedSchedule` kullanılmıyor.
- Reboot receiver / reschedule stratejisi yok.
- Android runtime notification permission akışı görünmüyor.

## 15. Platform konfigürasyonları

### Android

Dosyalar:

- `android/app/build.gradle.kts`
- `android/app/google-services.json`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/finvia/app/MainActivity.kt`

Mevcut değerler:

- namespace: `com.finvia.app`
- applicationId: `com.finvia.app`
- Android label: `Finvia`
- MainActivity package: `com.finvia.app`

Android manifest geçerli XML yapısındadır ve local notification receiver
tanımlarını içerir.

### iOS

Dosya:

- `ios/Runner/Info.plist`

Mevcut değerler:

- CFBundleDisplayName: `Finvia`
- CFBundleName: `finvia`

Firebase options içinde iOS bundle id hâlâ `com.example.mylife`.

### Web

Dosyalar:

- `web/manifest.json`
- `web/index.html`

Mevcut değerler:

- name: `Finvia`
- short_name: `Finvia`
- description: `Finvia - Akıllı Yaşam Asistanı.`
- title: `Finvia`
- apple web app title: `Finvia`

### Linux

Dosya:

- `linux/CMakeLists.txt`

Mevcut değerler:

- binary name: `finvia`
- application id: `com.finvia.app`

### Windows

Dosya:

- `windows/runner/main.cpp`

Mevcut değer:

- Window title: `Finvia`

## 16. Assets

`pubspec.yaml` içinde kayıtlı asset klasörleri:

- `assets/icon/`
- `assets/splash/`

Launcher icon:

- `assets/icon/icon.png`

Splash:

- `assets/splash/splash_logo.png`

Native splash config:

- background color: `#0a0a0a`
- Android 12 splash image: `assets/splash/splash_logo.png`

## 17. Marka durumu

Son branding pass sonrası:

- README başlığı `finvia`
- package adı `finvia`
- `FinviaApp`
- MaterialApp title `Finvia`
- Android label `Finvia`
- Web title/manifest `Finvia`
- iOS display name `Finvia`
- Linux/Windows platform names `Finvia` / `finvia`

Dikkat:

- Firebase backend id içinde `elite-life-48631` hâlâ var.
- `firebase_options.dart` iOS/macOS `com.example.mylife` değerleri hâlâ riskli.
- Eski “mylife” izleri platform/Firebase generated config içinde kalmış olabilir; build öncesi grep önerilir.

## 18. Önerilen geliştirme öncelikleri

1. Firebase bundle/package uyumlarını doğrulama.
2. `flutter analyze` temizliği.
3. DB migration sistemini güvenli hale getirme.
4. Bildirimleri `Future.delayed` yerine gerçek schedule sistemine taşıma.
5. Settings accent color ve notification toggle’larını gerçek davranışa bağlama.
6. Auth onboarding/profil eksik alanlarını toparlama.
7. Büyük ekran dosyalarını widget/service katmanlarına bölme.
8. Yedekleme/dışa aktarma/cloud sync placeholderlarını ya kaldırma ya gerçek yapma.
