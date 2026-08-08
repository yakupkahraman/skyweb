# 🌌 SkyWeb Monorepo

> 💡 **Bu proje tamamen deneysel bir hobi çalışmasıdır!** 
> Temel amacım, web'in arkasında yatan çalışma mantığını (DNS nasıl çalışır, tarayıcılar HTML/CSS'i nasıl parse edip widget'a dönüştürür, script'ler nasıl çalıştırılır) sıfırdan kendi küçük `sky://` ekosistemimi kurarak daha iyi anlamak.

---

## 🧐 Nedir Bu SkyWeb?

SkyWeb, klasik `http/https` ağından bağımsız çalışan deneysel bir web altyapısı fikridir. 
Kendi yazdığım özel DNS servisi (**SkyDNS**) ve geliştirdiğim Flutter tabanlı tarayıcı (**SkyBrowser**) sayesinde `sky://` protokolü üzerinden özel alan adlarını çözüp web sayfalarını ekrana çizer.

---

## 📂 Proje Bileşenleri

1. [**`browser/` (SkyBrowser)**](./browser/README.md): `sky://` adreslerini alan adından çözüp GitHub'dan aldığı HTML, CSS ve Dart script'lerini Flutter Widget'larına dönüştüren tarayıcım.
2. [**`skydns/` (SkyDNS Service)**](./skydns/README.md): `sky://` alan adlarını ilgili GitHub repolarına bağlayan Cloudflare Workers & D1 tabanlı hafif DNS servisim.
3. [**`sites/`**](./sites/): `sky://` ağı üzerinde yayınlanan örnek siteler (örneğin domain kayıt arayüzü).

---

## 🚀 Hızlı Başlangıç

### 1. Tarayıcıyı Çalıştırma (`browser`)
```bash
cd browser
flutter pub get
flutter run
```

### 2. DNS Servisini Geliştirme/Dağıtma (`skydns`)
```bash
cd skydns/skydns-worker
npm install
npm run dev     # Yerel test ortamı
npm run deploy  # Cloudflare Workers'a canlıya alma
```
