# Fetal Ultrasound Image Classifier

MATLAB tabanlı fetal ultrason görüntü analiz ve sınıflandırma projesi. Bu proje, fetal ultrason görüntülerini otomatik olarak sınıflandırır ve ölçümler yapar.

## Özellikler

- **Görüntü Sınıflandırma**: CNN (Convolutional Neural Network) ile fetal ultrason görüntülerini sınıflandırma
- **Gürültü Azaltma**: Median, Wiener, Gaussian ve Bilateral filtreler
- **Otomatik Ölçümler**: 
  - Femur Length (Femur uzunluğu)
  - Head Circumference (Baş çevresi)
- **Ölçek Çubuğu Tespiti**: Görüntülerdeki ölçek çubuklarını otomatik tespit ederek gerçek ölçümler yapar
- **Modern GUI**: MATLAB App Designer ile geliştirilmiş kullanıcı dostu arayüz

## Proje Yapısı

```
fetal_image_classifier/
├── FetalImageAnalyzer.m          # Ana GUI uygulaması
├── Stage1_LoadDataset.m          # Veri seti yükleme
├── Stage2_Denoising.m            # Gürültü azaltma
├── Stage3_CNNTraining.m          # CNN eğitimi
├── Stage4_ImageProcessing.m      # Görüntü işleme
├── Stage5_AutomaticMeasurements.m # Otomatik ölçümler
├── detectScaleBar.m              # Ölçek çubuğu tespiti
├── calculatePixelToMM.m           # Piksel-mm dönüşümü
├── fitEllipse.m                  # Elips uydurma
├── trained_model.mat             # Eğitilmiş CNN modeli
└── Classification/
    ├── image_label.csv           # Görüntü etiketleri
    ├── images/                   # Eğitim görüntüleri
    └── External Test images/     # Test görüntüleri
```

## Gereksinimler

- MATLAB R2020b veya üzeri
- Deep Learning Toolbox
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

## Kullanım

### 1. Veri Setini Yükleme
```matlab
Stage1_LoadDataset
```

### 2. CNN Modelini Eğitme
```matlab
Stage3_CNNTraining
```

### 3. GUI Uygulamasını Çalıştırma
```matlab
app = FetalImageAnalyzer;
```

## Ölçüm Yöntemleri

### Femur Length
- Canny edge detection
- Hough transform ile en uzun çizgi tespiti
- Piksel değerlerinin mm/cm'ye dönüştürülmesi

### Head Circumference
- Canny edge detection
- Kontur analizi ve elips uydurma
- Ramanujan formülü ile çevre hesaplama

## Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

## Yazar

Sevde Nur Susancak - [GitHub](https://github.com/sevdesns)

