# 🌐 SkyBrowser

**SkyBrowser**, web'in çalışma mantığını (HTML/CSS yorumlama, script çalıştırma ve DNS çözümleme) anlamak için Flutter ile geliştirdiğim deneysel bir web tarayıcısıdır.

`sky://` protokolünü kullanarak alan adlarını çözer ve sayfaları ekrana getirir.

---

## 🚀 Öne Çıkan Özellikler

- **`sky://` Özel Protokolü**: Alan adlarını SkyDNS servisi üzerinden çözüp ilgili GitHub reposundaki dosyaları çeker.
- **HTML → Widget Yorumlayıcı**: HTML etiketlerini parse ederek doğrudan Flutter Widget'larına dönüştürür.
- **Özel CSS Ayrıştırıcı**: Temel CSS kurallarını ayrıştırıp elemanlara stil verir.
- **Dinamik Script Çalıştırıcı (`dart_eval`)**: `script.dart` dosyalarını sanal bir ortamda (sandbox) çalıştırıp sayfa ile etkileşime sokar.
- **Minimalist Arayüz**: Adres çubuğu, favicon desteği ve karanlık tema.

---

## 📦 Çalıştırma

```bash
cd browser
flutter pub get
flutter run
```
