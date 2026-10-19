# CineLog

Kişisel kullanım için geliştirilmiş, çevrimdışı yerel veritabanı (**SQLite / Drift**) kullanan modern masaüstü film ve dizi takip uygulaması (**Flutter**).  
A modern, privacy-friendly desktop movie & TV show tracker built with **Flutter** and local **SQLite (Drift)** storage.

> **Platform Desteği / Platform Support:** Windows'ta test edildi; macOS ve Linux için derleme yapılandırması hazırdır. / Tested on Windows; macOS and Linux build configurations are included.

---

## 🇹🇷 Özellikler (Türkçe)

- **Keşfet ve Canlı Arama:** TMDB üzerinden en yüksek puanlı (*En İyiler*) ve popüler (*Popüler*) film/dizileri keşfetme, sonsuz kaydırma (infinite scroll) ve anlık arama.
- **Gerçekçi Puanlama (IMDb Bayes Formülü):** Az oylu yapımların sıralamayı bozmasını engelleyen ağırlıklı puan hesaplaması ve minimum oy eşikleri.
- **Kategori Filtreleme ve Kalıcı Kategori Gizleme:** 20 farklı kategori (Anime, Kore Dizileri, Bilim Kurgu, Suç vb.) ile filtreleme ve istemediğiniz türleri (ör. Anime veya Reality) kalıcı olarak gizleme.
- **Hızlı Aksiyonlar ve Favoriler (♥):** Poster kartlarının sağ üstünden tek tıkla **İzlenecek (`+`)**, **İzledim (`✓`)** ve **Favori (`♥`)** işaretleme; sol üstte puan rozeti.
- **Zengin İçerik Detayları:**
  - **Hangi Platformda Var? (Watch Providers):** Yapımın Türkiye (`TR`) veya seçili bölgede hangi dijital platformlarda (*Netflix, Prime Video, Disney+, MUBI, Apple TV+* vb.) yayında, kiralık veya satılık olduğunu resmi logolarıyla görme.
  - **Tıklanabilir Oyuncu ve Yönetmen Filmografisi:** Oyuncu kadrosuna veya yönetmene tıklayarak kişinin biyografisini ve diğer tüm film/dizilerini görüntüleme.
  - **YouTube Fragman ve Benzer Yapımlar:** Tek tıkla resmi fragmanı açma ve benzer içerikler arasında gezinme.
- **Kapsamlı Kütüphane Yönetimi:** Kütüphane içi anlık arama (başlık, orijinal ad, kişisel not, tür), **♥ Favoriler** filtresi, dinamik tür filtresi, 1–10 kişisel puanlama, kısa not ve **🎲 Ne İzlesem? (Rastgele Seçici)**.
- **Sezon ve Bölüm Takibi:** Dizilerde bölüm bazında işaretleme, *"buraya kadar izledim"* özelliği ve tüm bölümler bittiğinde durumun otomatik **İzledim** olması.
- **İstatistikler:** Toplam izlenen film/dizi/bölüm sayısı, tahmini toplam ekran süresi (saat/gün), tür ve yıl dağılım grafikleri.
- **Çift Dil Desteği (`Türkçe` / `English`):** Ayarlar ekranından hem arayüz dilini hem de TMDB içerik dilini (`tr-TR` / `en-US`) anlık değiştirme.
- **Güvenli JSON Yedekleme:** Kütüphaneyi, favorileri, notları ve bölüm ilerlemesini atomik olarak JSON dosyasına dışa/içe aktarma (API anahtarı yedeklere asla dahil edilmez).

---

## 🇬🇧 Features (English)

- **Discover & Instant Search:** Browse top-rated and popular movies & TV shows via TMDB with infinite scrolling and debounced multi-search.
- **Realistic Bayesian Ratings:** IMDb Top 250 style weighted rating calculation and vote-count thresholds.
- **Category Filters & Permanent Exclusion:** Filter by 20 curated categories or permanently hide specific categories (e.g., Anime, Reality) across the app.
- **Quick Actions & Favorites (♥):** One-click **Plan to Watch (`+`)**, **Watched (`✓`)**, and **Favorite (`♥`)** buttons directly on poster cards.
- **Rich Title Details:**
  - **Where to Watch (Watch Providers):** See streaming, rental, and purchase platforms (*Netflix, Prime Video, Disney+, MUBI, Apple TV+*, etc.) with official logos.
  - **Clickable Cast & Director Filmography:** Click any actor or director/creator to explore their biography and full filmography.
  - **YouTube Trailers & Similar Titles:** Watch official trailers and browse recommendations.
- **Library Management:** In-library search (title, original name, notes, genres), **♥ Favorites** filter, genre filter, 1–10 personal rating, notes, and **🎲 Surprise Me** random picker.
- **Season & Episode Tracking:** Track individual episodes or mark *"watched up to here"*; completing all episodes automatically marks a show as **Watched**.
- **Statistics:** Total watched movies, shows, episodes, estimated watch time, and breakdowns by genre and release year.
- **Bilingual (`Türkçe` / `English`):** Switch both UI and TMDB metadata language (`tr-TR` / `en-US`) anytime from Settings.
- **Safe JSON Backup:** Export and import your entire library, favorites, ratings, and episode progress as JSON (API keys are never exported).

---

## TMDB API Anahtarı Alma / Getting a TMDB API Key

Bu uygulama içerik verilerini [TMDB](https://www.themoviedb.org/) üzerinden çeker. Repo içinde hiçbir API anahtarı bulunmaz; herkes kendi ücretsiz anahtarını kullanır:

1. [themoviedb.org](https://www.themoviedb.org/) adresinden ücretsiz bir hesap oluşturun.
2. **Ayarlar (Settings) → API** sayfasından ücretsiz bir API anahtarı oluşturun.
3. **API Anahtarı (v3 auth)** veya **Okuma Erişim Jetonu (v4 Read Access Token)** değerini kopyalayın.
4. Uygulamada **Ayarlar (Settings)** sekmesine gidip anahtarı yapıştırın ve **Doğrula ve Kaydet (Verify & Save)** butonuna tıklayın. Anahtar yalnızca bilgisayarınızdaki yerel uygulama veritabanında saklanır.

---

## Kurulum ve Derleme / Setup & Build

### Gereksinimler / Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable)
- **Windows:** Visual Studio 2022 (*"Desktop development with C++"* iş yükü) ve Windows **Geliştirici Modu (Developer Mode)** açık olmalıdır.
- **macOS:** Xcode & CocoaPods
- **Linux (Ubuntu/Debian):**
  ```bash
  sudo apt-get update
  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsqlite3-dev
  ```

### Çalıştırma ve Release Derlemesi / Run & Release Build

```bash
# Bağımlılıkları yükle / Install dependencies
flutter pub get

# Geliştirme modunda çalıştır / Run in debug mode
flutter run -d windows

# Windows Release derlemesi / Build Windows Release
# Çıktı / Output: build/windows/x64/runner/Release/
flutter build windows --release
```

---

## Lisans ve Yasal Bildirim / License & Attribution

- Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.
- **TMDB Attribution:** *This product uses the TMDB API but is not endorsed or certified by TMDB.*
