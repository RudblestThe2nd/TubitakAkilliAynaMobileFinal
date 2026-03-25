# TubitakAkilliAynaMobileFinal

TUBITAK 2209-A - Yapay Zeka Destekli Akilli Ayna
Flutter Android Mobil Uygulama | Hugging Face AI Entegrasyonu

Danisman: Doc. Dr. Sinem Akyol
Koordinator: Sevval Kaya
Gelistirici: Berkay Parcal
Gelistirici: Esra Kazan

---

# Ekran Goruntuleri

### Uygulama Ekranlari

| Izin Ekrani | Hosgeldin | Profil Olustur |
|-------------|-----------|---------------|
| ![Izin](screenshots/izin.jpg) | ![Hosgeldin](screenshots/hosgeldin.jpg) | ![Profil Olustur](screenshots/profil_olustur.jpg) |

| Profil Olustur (Rol) | Ana Ekran | Gorevler |
|---------------------|-----------|----------|
| ![Profil Rol](screenshots/profil_olustur_rol.jpg) | ![Ana Ekran](screenshots/anaekran.jpeg) | ![Gorevler](screenshots/gorev.jpg) |

| Profil |
|--------|
| ![Profil](screenshots/profil.jpg) |

---

# Proje Nedir?

Bu uygulama, TUBITAK 2209-A kapsaminda gelistirilen yapay zeka destekli akilli ayna projesinin Android mobil uygulamasidir. Kullanici sesli komutlarla gundelik gorevlerini yonetebilir, yapay zeka asistaniyla konusabilir.

Yapay zeka modeli Hugging Face uzerinde barindirılmaktadir. Yerel bir sunucu kurmaniza gerek yoktur, internet baglantisi yeterlidir.

---

# Nasil Calisir?

```
Kullanici mikrofon butonuna basar ve konusur
      |
Uygulama sesi metne cevirir (speech-to-text, Turkce)
      |
Metin ve gorev listesi Hugging Face API'ye gonderilir
      |
Fine-tuned Qwen2.5-3B modeli yanit uretir
      |
Yanit sesli olarak okunur (text-to-speech, Turkce)
```

---

# Ozellikler

- Sesli komutla gorev sorgulama (bugun ne var, yarin programim ne vb.)
- Sesle gorev ekleme (gorev ekle, hatirla, not al vb.)
- Coklu kullanici destegi (PIN korumali profiller)
- Zaman dilimi algisi (sabah, ogleden sonra, aksam)
- Conversation history (son 5 tur hatirlama)
- Hallusinasyon engelleme (gorev yoksa model uydurma yapmaz)
- Hugging Face API entegrasyonu (yerel sunucu gerekmez)

---

# Kullanilan Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Mobil Framework | Flutter (Android) |
| State Management | BLoC / Cubit |
| AI Modeli | Qwen2.5-3B-Instruct (QLoRA fine-tuned) |
| Model Barindirilmasi | Hugging Face Inference API |
| Ses Tanima | speech_to_text (tr_TR) |
| Ses Sentezi | flutter_tts (tr-TR) |
| Veritabani | SQLite (sqflite) |
| Guvenlik | SHA-256 PIN, flutter_secure_storage |
| HTTP | Dio |
| DI | GetIt |

---

# Kurulum

## 1. Depoyu Indirin

```bash
git clone https://github.com/RudblestThe2nd/TubitakAkilliAynaMobileFinal.git
cd TubitakAkilliAynaMobileFinal
```

## 2. Bagimliliklari Yukleyin

```bash
flutter pub get
```

## 3. HF API Token Ayarini Yapin

lib/core/constants/api_constants.dart dosyasini acin:

```dart
static const String hfToken = 'hf_SIZIN_TOKENINIZ';
static const String hfModel = 'Rudblest/AkilliAyna-Qwen3B';
```

HuggingFace token almak icin: https://huggingface.co/settings/tokens

## 4. Uygulamayi Telefona Yukleyin

Telefonu USB ile baglayin, USB Hata Ayiklama acik olmalidir.

```bash
flutter run
```

---

# Uygulamayi Kullanmak

Uygulama ilk acildiginda izin ekrani gorulur. Onaylayip devam edin.

Profil olusturun: isim, PIN ve rol secin. Birden fazla aile uyesi farkli profil olusturabilir.

Gorev eklemek icin alt menudeki Gorevler sekmesinden + butonuna basin.

Sesli asistan icin ana sayfadaki mikrofon butonuna basin ve konusun.

Ornek sesli komutlar:
- "Bugun ne yapacagim"
- "Yarin programim ne"
- "Bu hafta ne var"
- "Sabah planim nedir"
- "Gorev ekle yarin saat 10 toplanti"
- "Hatirla aksam ilac al"

---

# Sistem Izleme (Prometheus + Grafana)

> Bu bolum model yuklendikten sonra doldurulacaktir.

Backend Prometheus metrikleri ve Grafana dashboard goruntuleri buraya eklenecektir.

---

# Veri Analizi (SPSS / R / Python)

> Bu bolum analiz tamamlandiktan sonra doldurulacaktir.

SQLite veritabanindan uretilen istatistik grafikleri buraya eklenecektir.

| Genel Bakis | Tamamlanma Analizi | Zaman Analizi |
|-------------|-------------------|---------------|
| ![ Genel Bakis](screenshots/grafik1_genel_bakis.png) | ![Tamamlanma](screenshots/grafik2_tamamlanma_analizi.png) | ![Zaman](screenshots/grafik3_zaman_analizi.png) |

---

# Sik Sorulan Sorular

AI yanit vermiyor:
HF token'inin dogru girildiginden emin olun. Token okuma iznine sahip olmalidir.

Yanit cok yavas geliyor:
HF Inference API ucretsiz planda soguk baslangic yasanabilir. Ilk istek 30-60 saniye surebilir, sonrakiler daha hizli olur.

Uygulama telefona yuklenmiyor:
USB Hata Ayiklama seceneginin acik oldugunu kontrol edin.

Yapay zeka yanlis cevap veriyor:
Once Gorevler sekmesinden gorev ekleyin, sonra sorun. Gorev olmadan model "planin bulunmuyor" der.

---

# Ana Repo (Backend + LLM)

Backend, fine-tuning scriptleri ve model egitimi icin ana repo:
https://github.com/RudblestThe2nd/AkilliAynaAsistanLLM

---

TUBITAK 2209-A - Firat Universitesi - 2025-2026
