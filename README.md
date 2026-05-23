<div align="center">

# Nefes

**Anksiyete takibi, günlük, nefes egzersizleri ve AI destekli rehberlik tek uygulamada.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Platform](https://img.shields.io/badge/Android-iOS-Web%20%7C%20Desktop-4B6B88)]()
[![License](https://img.shields.io/badge/License-Private-lightgrey)]()

</div>

---

## Proje Hakkında

**Nefes**, kullanıcıların duygu durumlarını düzenli olarak takip etmesine, düşüncelerini günlükte toplamasına ve kısa rahatlama egzersizleriyle anlık destek almasına yardımcı olan bir Flutter uygulamasıdır. Uygulama; anksiyete kaydı, nefes egzersizleri, hedefler, başarımlar, günlük ve AI sohbet akışlarını tek çatı altında toplar.

## Neden Nefes?

- Günlük ruh halini ve anksiyete seviyesini kayıt altına alır.
- Kısa nefes egzersizleriyle hızlı rahatlama sağlar.
- Duygu günlüğü ve düşünce kaydı ile içgörü sunar.
- Hedefler ve başarımlar ile motivasyonu artırır.
- Firebase altyapısı sayesinde verileri senkronize eder.

## Öne Çıkan Özellikler

| Özellik | Açıklama |
| --- | --- |
| Anksiyete Takibi | Günlük seviye kaydı, grafikler ve geçmiş takip.
| Günlük | Düşünce ve duygu kayıtlarını düzenli tutma.
| Nefes Egzersizleri | Box breathing, 4-7-8, diyafram ve alternatif burun nefesi.
| AI Sohbet | Destekleyici ve yönlendirici sohbet deneyimi.
| Hedefler | Küçük ve sürdürülebilir ilerleme planı.
| Başarımlar | Uygulama içi ilerlemeyi ödüllendirme.
| Onboarding | Anonim Firebase Auth ile hızlı başlangıç.

## Ekranlar

- Onboarding ve giriş akışı
- Ana sayfa ve hızlı erişim kartları
- Anksiyete takip ekranı
- Nefes egzersizi ekranları
- Günlük yazma ve detay ekranları
- AI sohbet ve analiz ekranları
- Hedefler, profil ve başarımlar

## Teknoloji Yığını

- **Framework:** Flutter
- **Backend / BaaS:** Firebase
- **Kimlik Doğrulama:** Firebase Authentication
- **Veritabanı:** Cloud Firestore
- **Depolama:** Firebase Storage
- **Durum Yönetimi:** Provider
- **Yerel Depolama:** SharedPreferences

## Kurulum

Projeyi yerelde çalıştırmak için:

```bash
git clone https://github.com/RRedHeart38/Anksiyete-takip.git
cd Anksiyete-takip
flutter pub get
flutter run
```

Web'de çalıştırmak için:

```bash
flutter run -d chrome
```

## Firebase Kurulumu

Uygulama Firestore ve anonim giriş kullandığı için Firebase tarafında şu adımları tamamlamalısın:

1. Firebase Console > Authentication > Sign-in method > **Anonymous** etkinleştir.
2. Firestore kurallarını yayınla.
3. `firebase_options.dart` dosyasının kendi projenle eşleştiğinden emin ol.

Kuralları yayınlamak için:

```bash
firebase deploy --only firestore:rules
```

## Proje Yapısı

```text
lib/
   screens/   # Uygulama ekranları
   providers/ # Provider tabanlı state yönetimi
   models/    # Veri modelleri
   services/  # Bildirim, rapor vb. servisler
   utils/     # Tema ve yardımcılar
assets/
   images/    # Uygulama görselleri
   fonts/     # Özel yazı tipleri
```

## Notlar

- Uygulama kişisel takip ve destek amaçlıdır; tıbbi teşhis yerine geçmez.
- Asset ekledikten sonra `flutter pub get` ve tam yeniden başlatma yapman gerekebilir.
- Web için derleme alırken `flutter build web` komutunu kullanabilirsin.

## Katkı

Kendi geliştirmelerin için yeni ekranlar, görseller veya akışlar ekleyebilirsin. PR açmadan önce kodun derlendiğinden emin ol.
