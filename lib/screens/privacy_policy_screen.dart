import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_remix/flutter_remix.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yasal Bilgilendirme'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kullanıcı Sözleşmesi'),
            Tab(text: 'KVKK & Gizlilik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPolicyContent(
            context,
            title: "Kullanıcı Sözleşmesi",
            content: """
1. Taraflar
İşbu sözleşme, Anksiyete Takip uygulamasını kullanan kullanıcı ile uygulama sağlayıcısı arasında akdedilmiştir.

2. Hizmetin Tanımı
Anksiyete Takip, kullanıcıların duygu durumlarını, günlüklerini ve anksiyete seviyelerini takip etmelerine yardımcı olan bir mobil uygulamadır.

3. Kullanım Koşulları
- Uygulama tıbbi teşhis veya tedavi aracı değildir.
- Kullanıcı, girdiği verilerin doğruluğundan sorumludur.
- Uygulama içi içerikler (meditasyonlar, öneriler) sadece bilgilendirme amaçlıdır.

4. Sorumluluk Reddi
Bu uygulama profesyonel tıbbi tavsiyenin yerini tutmaz. Ciddi sağlık sorunlarınızda lütfen bir uzmana danışın.

5. Değişiklikler
Uygulama sahibi, sözleşme koşullarını dilediği zaman değiştirme hakkını saklı tutar.
            """,
          ),
          _buildPolicyContent(
            context,
            title: "Gizlilik Politikası ve KVKK",
            content: """
Son Güncelleme: 15 Ocak 2026

Bu Gizlilik Politikası, Hüseyin Kayabaşı tarafından geliştirilen "Anksiyete Takip" mobil uygulaması ("Uygulama") aracılığıyla toplanan verilerin nasıl kullanıldığını, saklandığını ve korunduğunu açıklar.

Uygulamayı indirerek ve kullanarak, bu sözleşmedeki şartları kabul etmiş olursunuz.

1. Toplanan Veriler
Hizmetlerimizi sunabilmek için aşağıdaki veri türlerini işleyebiliriz:

Kimlik ve İletişim Bilgileri: (Eğer üyelik varsa) Ad, e-posta adresi ve profil fotoğrafı.

Özel Nitelikli Kişisel Veriler (Sağlık ve Duygu Durumu): Uygulama içerisine girdiğiniz anksiyete seviyeleri, ruh hali takibi verileri, günlük notları.

Kullanıcı İçerikleri: Yapay zeka asistanı ile yapılan sohbet geçmişleri ve metin girdileri.

Teknik Veriler: Cihaz bilgisi, IP adresi, uygulama çökme raporları (Crashlytics) ve performans verileri.

2. Verilerin Kullanım Amacı
Toplanan veriler şu amaçlarla kullanılır:

Anksiyete takibi ve grafiksel analizlerin sunulması.

Yapay zeka tabanlı sohbet asistanının kişiye özel yanıtlar verebilmesi.

Kullanıcı hesabının oluşturulması ve güvenliğinin sağlanması.

Uygulama hatalarının tespiti ve performansın iyileştirilmesi.

Önemli Not: Uygulamamızdaki sohbet verileri ve ruh hali kayıtları, tıbbi teşhis veya tedavi amacı taşımaz. Uygulama sadece bir kişisel takip aracıdır. Ciddi sağlık sorunlarında lütfen bir uzmana danışınız.

3. Veri Güvenliği ve Şifreleme
Kullanıcılarımızın mahremiyeti bizim için en öncelikli konudur.

Uçtan Uca Şifreleme: Uygulama içerisindeki özel sohbet verileri ve notlar, veritabanına kaydedilmeden önce şifrelenir (Encryption). Bu verilere geliştirici dahil olmak üzere yetkisiz üçüncü şahıslar erişemez ve içeriği okuyamaz.

Verileriniz güvenli sunucularda (Google Firebase vb.) endüstri standartlarına uygun olarak saklanmaktadır.

4. Verilerin Üçüncü Taraflarla Paylaşımı
Kişisel verileriniz reklam amaçlı satılmaz. Ancak uygulamanın çalışabilmesi için aşağıdaki servis sağlayıcılarla veri işbirliği yapılabilir:

Google Firebase: Veritabanı yönetimi, kimlik doğrulama ve analitik hizmetleri için.

Google Gemini: Sohbet özelliğinin çalışması için metin girdileri anonimleştirilmiş şekilde işlemeye tabi tutulabilir.

5. Kullanıcı Hakları (KVKK Madde 11)
Kişisel Verilerin Korunması Kanunu (KVKK) uyarınca, kullanıcılarımız şu haklara sahiptir:

Kişisel verilerinin işlenip işlenmediğini öğrenme,

Verilerinin silinmesini veya yok edilmesini isteme (Hesap silme),

Verilerin düzeltilmesini talep etme.

6. Hesabın ve Verilerin Silinmesi
Kullanıcılar, uygulama içerisindeki "Ayarlar" menüsünden veya bizimle iletişime geçerek hesaplarını ve tüm verilerini kalıcı olarak silebilirler. Hesap silindiğinde şifrelenmiş veriler de dahil olmak üzere tüm kayıtlar sunucularımızdan geri döndürülemez şekilde kaldırılır.

7. İletişim
Bu gizlilik politikasıyla ilgili sorularınız, önerileriniz veya veri silme talepleriniz için bizimle iletişime geçebilirsiniz:

E-posta: hkayabasi1017@gmail.com Geliştirici: Hüseyin Kayabaşı
            """,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent(BuildContext context, {required String title, required String content}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FlutterRemix.shield_check_line, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 24),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
