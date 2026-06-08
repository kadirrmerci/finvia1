# KNOWN_ISSUES.md

> Finvia bilinen riskler, açık işler ve teknik borç listesi.
>
> Severity ölçeği:
>
> - **S0 / Build-blocker:** Derlemeyi veya temel çalışmayı kırabilir.
> - **S1 / Critical runtime:** App açılır ama önemli akış kırılabilir/veri kaybı olabilir.
> - **S2 / Functional bug:** Özellik beklenen gibi çalışmayabilir.
> - **S3 / UX/maintainability:** Kullanıcı deneyimi veya bakım kalitesi etkilenir.
> - **S4 / Nice-to-have:** İyileştirme.

## S0 — Build-blocker / derleme riski

### 1. `AndroidManifest.xml` içinde geçersiz komut satırı var

Dosya:

- `android/app/src/main/AndroidManifest.xml`

Manifest içinde şu satır XML elemanı gibi duruyor:

```xml
flutter pub add flutter_local_notifications
```

Bu satır Android manifest XML formatını bozabilir ve Android build’i kırabilir.

Önerilen çözüm:

- Bu satırı manifestten sil.
- Paket zaten `pubspec.yaml` içinde dependency olarak var.
- Sonra `flutter build apk --debug` veya `flutter run` ile test et.

### 2. `lib/models/credit_card.dart` dosyası bulunamadı

`DatabaseService` ve `FinanceScreen` şu modeli import ediyor/kullanıyor:

```dart
import '../models/credit_card.dart';
```

ve

```dart
import '../../models/credit_card.dart';
```

Fakat taramada `lib/models/credit_card.dart` dosyası bulunamadı.

Etkisi:

- Dart analyzer/build `Target of URI doesn't exist` hatası verebilir.
- `CreditCard` ve `CreditCardStatement` tipleri tanımsız kalabilir.
- Finans ekranı ve database service build’i kırabilir.

Önerilen çözüm:

- `lib/models/credit_card.dart` dosyasını oluştur.
- İçinde `CreditCard` ve `CreditCardStatement` modellerini DB tablo kolonlarıyla uyumlu tanımla.
- DB tabloları:
  - `credit_cards`
  - `credit_card_statements`

Beklenen `CreditCard` alanları:

- `id`
- `bankName`
- `cardName`
- `creditLimit`
- `currentDebt`
- `statementDay`
- `dueDay`
- `color`

Beklenen `CreditCardStatement` alanları:

- `id`
- `cardId`
- `cardName`
- `amount`
- `paidAmount`
- `statementDate`
- `dueDate`

## S1 — Firebase / platform config riskleri

### 3. Firebase iOS/macOS bundle id eski isimde

Dosya:

- `lib/firebase_options.dart`

iOS/macOS config içinde hâlâ şu değer görünüyor:

```dart
iosBundleId: 'com.example.mylife'
```

Etkisi:

- iOS/macOS Firebase Auth, Firestore veya Google Sign-In uyumsuz çalışabilir.
- App display name Finvia olsa bile Firebase app registration eski bundle id’ye bağlı olabilir.

Önerilen çözüm:

- Firebase Console’da iOS/macOS app bundle id kararını netleştir.
- Gerçek bundle id Finvia için ne olacaksa onu Xcode project + Firebase Console + `firebase_options.dart` ile eşitle.
- `flutterfire configure` ile configleri yeniden üret.

### 4. Firebase Android app id / google-services uyumu mutlaka doğrulanmalı

Mevcut Android applicationId:

```kotlin
applicationId = "com.finvia.app"
```

`google-services.json` içinde package_name de `com.finvia.app` görünüyor.

Risk:

- `mobilesdk_app_id` eski Firebase Android app kaydından kalmış olabilir.
- Firebase Console’da gerçekten `com.finvia.app` kayıtlı değilse runtime veya Google Services plugin tarafında sorun çıkabilir.

Önerilen çözüm:

- Firebase Console > Project settings > Your apps > Android app package name kontrolü.
- Gerekirse `com.finvia.app` için yeni Android app ekle.
- Yeni `google-services.json` indir.
- `flutterfire configure` çalıştır.

### 5. Linux Firebase desteklenmiyor

`DefaultFirebaseOptions.currentPlatform` Linux için `UnsupportedError` fırlatıyor.

Etkisi:

- Linux build çalışsa bile app açılışta Firebase initialize sırasında patlar.

Önerilen çözüm:

- Linux hedeflenecekse Firebase Linux stratejisi belirle.
- Ya Linux için Firebase init koşullu devre dışı bırakılır, ya desteklenen alternatif kullanılır.
- Ya da README/context içinde Linux hedef dışı olarak belirtilir.

## S1 — Veri kaybı / migration riskleri

### 6. DB migration stratejisi güvenli değil

Dosya:

- `lib/services/database_service.dart`

Mevcut yaklaşım:

```dart
onUpgrade: (db, oldVersion, newVersion) async => await _createTables(db)
```

Sorun:

- `_createTables` içindeki `CREATE TABLE IF NOT EXISTS` mevcut tabloyu değiştirmez.
- Yeni kolon eklendiğinde eski kullanıcı DB’sinde kolon oluşmaz.
- Sonuç: `no such column` veya veri uyumsuzluğu.

Önerilen çözüm:

- `onUpgrade` içinde versiyon bazlı migration yaz.
- Örnek:

```dart
onUpgrade: (db, oldVersion, newVersion) async {
  if (oldVersion < 8) {
    await db.execute('ALTER TABLE notes ADD COLUMN ...');
  }
}
```

- Migration helper oluştur.
- Her schema değişikliğini `AI_CHANGELOG.md` ve `PROJECT_CONTEXT.md` içine işle.

### 7. DB dosya adı değişikliği eski kullanıcı verisini ayırabilir

Önceden DB dosyası `mylife.db` idi, şu anda `finvia.db`.

Etkisi:

- Eski kullanıcı cihazlarında veriler eski DB dosyasında kalabilir.
- Uygulama yeni boş `finvia.db` açabilir.

Önerilen çözüm:

- Production kullanıcı varsa startup migration:
  - eski `mylife.db` var mı kontrol et
  - `finvia.db` yoksa taşı/kopyala
- Production yoksa bu risk düşük.

## S1 — Bildirim güvenilirliği

### 8. Hatırlatıcılar `Future.delayed` ile planlanıyor

Dosya:

- `lib/services/notification_service.dart`

Sorun:

- App process kapanırsa hatırlatıcı çalışmaz.
- Telefon restart olursa kaybolur.
- OS background kısıtları nedeniyle güvenilir değildir.

Etkilenenler:

- Not hatırlatıcıları
- Abonelik hatırlatıcıları
- Kilo hatırlatıcısı
- Alışkanlık hatırlatıcısı

Önerilen çözüm:

- `flutter_local_notifications.zonedSchedule` kullan.
- Timezone doğru ayarlansın.
- Android exact alarm izinleri için doğru manifest + runtime/ayar yönlendirme akışı ekle.
- Reboot sonrası tekrar schedule için receiver/plugin desteği incelensin.
- Scheduled notification id’leri DB’de saklansın.

### 9. Notification settings gerçek davranışa bağlı değil

Ayarlar ekranında:

- `notifications`
- `debtReminder`
- `subscriptionReminder`

değerleri saklanıyor, fakat bildirim gönderme/schedule operasyonları bu değerleri merkezi olarak kontrol etmiyor.

Etkisi:

- Kullanıcı bildirimleri kapatsa bile bazı bildirimler schedule/show edilebilir.

Önerilen çözüm:

- `NotificationService` içine settings check ekle.
- Her schedule/show öncesi prefs kontrolü yap.
- Granüler toggle mapping oluştur.

### 10. Android notification permission runtime akışı eksik olabilir

Manifestte `POST_NOTIFICATIONS` var, fakat Android 13+ için runtime permission isteği ayrı gerekir.

Önerilen çözüm:

- `flutter_local_notifications` Android implementation üzerinden permission request ekle.
- Ayarlar ekranında izin durumu göster.

## S2 — Auth/profil sorunları

### 11. Email verification kontrolü Google/Phone girişlerini etkileyebilir

`main.dart` içinde auth state user varsa `user.emailVerified` kontrol ediliyor.

Risk:

- Telefon auth kullanıcısında email olmayabilir.
- Google auth genelde verified olabilir ama davranış provider’a bağlıdır.
- Email verification sadece email/password akışı için zorunlu olmalı.

Önerilen çözüm:

- Provider bazlı kontrol yap.
- Email/password provider için email verification iste.
- Phone provider ve Google provider için ayrı kabul kriteri belirle.

### 12. Google login Firestore profil alanlarını eksik yazabilir

Google girişinde `_saveUserToFirestore(user)` çağrılıyor; `age`, `city`, `district` controller/default değerlerden gider.

Etkisi:

- `age: 0`
- `district: ''`
- default city `İstanbul`
- eksik profil

Önerilen çözüm:

- İlk giriş sonrası profil tamamlama ekranı.
- Firestore merge’de boş/default alanları overwrite etmeme.
- `createdAt` yerine `createdAt ?? serverTimestamp` mantığı.

### 13. Telefon login Firestore kaydı sadece name doluysa yazılıyor olabilir

OTP doğrulama sonrası:

- user varsa ve `_nameController.text.isNotEmpty` ise displayName + Firestore save

Risk:

- Login modunda telefonla giriş yapan kullanıcı Firestore’a yazılmayabilir.
- Profil eksik kalır.

Önerilen çözüm:

- Phone auth sonrası her durumda kullanıcı dokümanı olduğundan emin ol.
- Eksik alanlar için onboarding/profil tamamlama ekranı kullan.

### 14. Auth ekranında il/ilçe listesi hard-coded ve çok büyük

Risk:

- `login_screen.dart` çok büyüyor.
- Yazım hataları ve bakım maliyeti artıyor.
- Lokalizasyon/arama/validasyon zorlaşıyor.

Önerilen çözüm:

- `lib/data/turkey_locations.dart` gibi ayrı dosyaya taşı.
- Gerekirse JSON asset olarak tut.
- İl/ilçe seçim widget’ını ayrı component yap.

### 15. İlçe listesinde typo var

`Çankırı` altında `Khanköy` görünüyor; muhtemelen `Kızılırmak`, `Korgun`, `Kurşunlu`, vb. doğrulama gerekir. Bu liste resmi kaynakla kontrol edilmeli.

## S2 — Finans modülü sorunları

### 16. Para birimi ayarı merkezi kullanılmıyor

Ayarlar ekranında `_currency` kaydediliyor fakat finans ekranlarında değerler çoğunlukla `₺` ile hard-coded.

Etkisi:

- Kullanıcı para birimi seçse bile UI değişmez.

Önerilen çözüm:

- Currency formatter helper oluştur.
- `SharedPreferences` yerine app-level state/provider düşün.
- Tüm finans/borsa ekranlarında formatter kullan.

### 17. “Tüm verileri sil” gerçek veri silmiyor

Ayarlar ekranında delete confirm sadece snackbar gösteriyor.

Etkisi:

- Kullanıcı verinin silindiğini sanır ama DB kalır.

Önerilen çözüm:

- Gerçek DB temizleme metodu ekle.
- Kritik onay dialogu.
- Geri alınamaz uyarısı.
- Sonra tüm ekran state’lerini reload et.

### 18. Backup/export/cloud sync placeholder durumda

Ayarlar ekranında:

- Veriyi Yedekle
- Veriyi Dışa Aktar
- Bulut Senkronizasyon
- Aile Paylaşımı

“Yakında” mesajı gösteriyor.

Önerilen çözüm:

- MVP’de gizle veya disabled göster.
- Ya da gerçek implementasyon planı yaz.

## S2 — Borsa/yatırım sorunları

### 19. Fiyat alarmı memory-only

`StockAlertService` alert listesini memory içinde tutuyor.

Etkisi:

- App kapanınca alarm kaybolur.
- Restart sonrası takip yok.
- Background takip yok.

Önerilen çözüm:

- Alert modelini SQLite’a kaydet.
- App açılışında tekrar yükle.
- Background fetch/workmanager stratejisi tasarla.
- Kullanıcıya “uygulama açıkken takip” gibi doğru beklenti ver.

### 20. Yahoo Finance endpointleri doğrudan, timeout/cache/rate-limit yok

Risk:

- Endpoint yavaşlarsa UI takılabilir.
- Rate limit / network hatası kullanıcıya iyi yansımayabilir.
- Aynı fiyatlar tekrar tekrar çekiliyor.

Önerilen çözüm:

- `StockDataService` oluştur.
- Timeout ekle.
- Cache TTL ekle.
- Error model/fallback ekle.
- UI’da retry ve açık hata mesajı.

### 21. Finansal veri/tavsiye dili netleştirilmeli

Borsa modülü kar/zarar, simülasyon, alarm sunuyor.

Öneri:

- “Yatırım tavsiyesi değildir” notu eklenebilir.
- Bilgilendirici dil korunmalı.

## S2 — Sağlık/alışkanlık sorunları

### 22. `Habit.currentStreak` listeyi mutate ediyor olabilir

Kod pattern’i:

```dart
final sorted = completedDays..sort((a, b) => b.compareTo(a));
```

Bu, orijinal `completedDays` listesini sıralar.

Etkisi:

- Model state beklenmedik değişebilir.
- UI davranışı kararsız olabilir.

Önerilen çözüm:

```dart
final sorted = [...completedDays]..sort((a, b) => b.compareTo(a));
```

### 23. Sağlık verileri hassas ama privacy akışı yok

Kilo ve alışkanlık verileri kişisel/hassas olabilir.

Önerilen çözüm:

- Privacy policy gerçek içeriği.
- Cloud sync öncesi açık kullanıcı izni.
- Export/backup şifreleme değerlendirmesi.

## S2 — Notlar sorunları

### 24. `Note.copyWith` ile `reminderTime` null yapmak zor

Mevcut pattern:

```dart
reminderTime: reminderTime ?? this.reminderTime
```

Bu, reminderTime’ı bilinçli olarak null’a set etmeyi engelleyebilir.

Önerilen çözüm:

- Sentinel parametre
- Ayrı `clearReminder` parametresi
- veya nullable wrapper yaklaşımı

### 25. Not reminder id için `hashCode` kullanımı tartışmalı

`note.id.hashCode` notification id olarak kullanılıyor.

Risk:

- Dart hash stabilitesi/platform/process davranışı düşünülmeli.
- Çakışma ihtimali var.
- Uygulama restart sonrası aynı id garantisi gözden geçirilmeli.

Önerilen çözüm:

- UUID’den deterministic int üret.
- Notification id DB’de saklansın.

## S2 — Tema/ayar sorunları

### 26. Accent color kaydediliyor ama ana temaya uygulanmıyor

Ayarlar ekranı `accentColor` saklıyor; `main.dart` seedColor sabit.

Etkisi:

- Kullanıcı tema rengi seçer ama Material theme değişmez.

Önerilen çözüm:

- `FinviaApp` state içine accent color ekle.
- `_loadTheme` hem darkMode hem accentColor yüklesin.
- `updateTheme` yanında `updateAccentColor` olsun.
- Sabit mor renkler kademeli temaya taşınsın.

### 27. Renkler birçok yerde hard-coded

Örnek:

- `Color(0xFF6C63FF)`
- Auth ekranında yeşil gradient
- Finans/borsa/sağlık modüllerinde sabit renkler

Önerilen çözüm:

- `AppTheme` veya `AppColors` oluştur.
- Material colorScheme kullan.
- Modül renkleri bilinçli token olarak tanımlansın.

## S3 — Kod bakım sorunları

### 28. Ekran dosyaları çok büyük

Büyük dosyalar:

- `login_screen.dart`
- `finance_screen.dart`
- `stocks_screen.dart`
- `health_screen.dart`
- `settings_screen.dart`

Risk:

- Değişiklik yapmak zorlaşır.
- Test yazmak zorlaşır.
- Merge conflict olasılığı artar.

Önerilen çözüm:

- Widget parçalama
- Service/repository ayrımı
- Form dialoglarını ayrı widgetlara taşıma
- Sabit listeleri data dosyalarına taşıma

### 29. Controller dispose kontrolleri sistematik değil

Bazı ekranlarda TextEditingController modal içinde lokal yaratılıyor, bazı state controller’ları dispose gerektiriyor.

Önerilen çözüm:

- State class controller’ları için `dispose`.
- Modal-local controller’larda lifecycle basit ama uzun yaşayan controller’lar dikkat.

### 30. Async sonrası `setState` için `mounted` kontrolü eksik yerler var

Örnek riskli pattern:

```dart
final data = await service.get...
setState(...)
```

Ekran dispose olursa hata olabilir.

Önerilen çözüm:

- Her async sonrası `if (!mounted) return;`.
- Özellikle network ve DB load metotlarında.

### 31. Provider dependency var ama state yönetiminde kullanılmıyor gibi

`provider` dependency mevcut ama ana state çoğunlukla StatefulWidget-local.

Önerilen çözüm:

- Ya provider dependency kaldırılır.
- Ya da theme/settings/auth/finance gibi global state için planlı kullanılır.

## S3 — Repo/dokümantasyon sorunları

### 32. README hâlâ Flutter starter seviyesinde

README şu an kısa ve generic.

Önerilen çözüm:

- Proje açıklaması
- Özellikler
- Kurulum
- Firebase setup
- Android/iOS setup
- Build komutları
- Bilinen sorunlar
- Roadmap

### 33. Context dokümanları güncel tutulmalı

`AGENTS.md` ve `docs/ai_context/*` dosyaları eklendi. Yeni mimari/veri modeli/platform/Firebase değişikliklerinde bu dosyalar da güncellenmeli.

## S4 — İyileştirme önerileri

### 34. Modül bazlı klasörleme güçlendirilebilir

Önerilen yapı:

```text
lib/
  core/
    theme/
    utils/
    constants/
  data/
    local/
    remote/
  features/
    auth/
    notes/
    finance/
    stocks/
    health/
    settings/
  services/
  models/
```

### 35. Tests yok/görünmüyor

Önerilen testler:

- Model serialization tests
- Database migration tests
- Finance calculation tests
- Habit streak tests
- Notification id tests
- Auth validation tests

### 36. Lint kuralları artırılabilir

Mevcut `flutter_lints` var.

Ek düşünülebilir:

- `prefer_const_constructors`
- `avoid_print`
- `unawaited_futures` dikkat
- custom analysis strictness
