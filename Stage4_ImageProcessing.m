%% AŞAMA 4: Görüntü İşleme Modülü
clear; clc; close all;

fprintf('=== AŞAMA 4: Görüntü İşleme Modülü ===\n\n');

%% 1. Dataset'in Yüklü Olduğunu Kontrol Et
if ~exist('datasetInfo', 'var')
    fprintf('⚠ Dataset bilgileri bulunamadı. Stage1_LoadDataset.m çalıştırılıyor...\n');
    Stage1_LoadDataset;
end

%% 2. Test Görüntüsü Seç
fprintf('1. Test görüntüsü seçiliyor...\n');

% Test görüntülerinden birini seç (veya eğitim görüntüsü)
if isempty(datasetInfo.testImagePaths)
    % Test görüntüsü yoksa eğitim görüntüsü kullan
    if iscell(datasetInfo.trainImagePaths)
        testImagePath = datasetInfo.trainImagePaths{1};
    else
        testImagePath = datasetInfo.trainImagePaths(1);
    end
    fprintf('   Test görüntüsü bulunamadı, eğitim görüntüsü kullanılıyor.\n');
else
    if iscell(datasetInfo.testImagePaths)
        testImagePath = datasetInfo.testImagePaths{1};
    else
        testImagePath = datasetInfo.testImagePaths(1);
    end
    fprintf('   Test görüntüsü seçildi.\n');
end

% Görüntüyü oku
originalImage = imread(testImagePath);

% Eğer RGB ise gri tonlamaya çevir
if size(originalImage, 3) == 3
    originalImage = rgb2gray(originalImage);
end

% Görüntüyü double formatına çevir (0-1 aralığında)
if ~isa(originalImage, 'double')
    originalImage = im2double(originalImage);
end

[~, fileName, ~] = fileparts(testImagePath);
fprintf('   ✓ Görüntü yüklendi: %s\n', fileName);
fprintf('   ✓ Boyut: %dx%d\n', size(originalImage, 1), size(originalImage, 2));

%% 3. Canny Edge Detection
fprintf('\n2. Canny Edge Detection uygulanıyor...\n');

% Canny edge detection parametreleri
cannyThreshold = [0.1, 0.2]; % Düşük ve yüksek eşik değerleri
cannySigma = 1.5; % Gaussian smoothing sigma

edgesCanny = edge(originalImage, 'Canny', cannyThreshold, cannySigma);
fprintf('   ✓ Canny Edge Detection tamamlandı.\n');

%% 4. Histogram Hesaplama ve Görüntüleme
fprintf('\n4. Histogram hesaplanıyor...\n');

% Histogram hesapla
[counts, centers] = imhist(originalImage);
fprintf('   ✓ Histogram hesaplandı.\n');

%% 5. Kontrast İyileştirme
fprintf('\n3. Kontrast iyileştirme uygulanıyor...\n');

% CLAHE (Contrast Limited Adaptive Histogram Equalization)
% CLAHE için görüntüyü uint8 formatına çevir
imgUint8 = im2uint8(originalImage);
enhancedCLAHE = adapthisteq(imgUint8, 'ClipLimit', 0.02, 'Distribution', 'uniform');
enhancedCLAHE = im2double(enhancedCLAHE); % Tekrar double'a çevir
fprintf('   ✓ CLAHE tamamlandı.\n');

%% 6. Sonuçları Görselleştir
fprintf('\n6. Sonuçlar görselleştiriliyor...\n');

% Ana görselleştirme figure
figure('Name', 'Görüntü İşleme Sonuçları', 'Position', [50, 50, 1400, 600]);

% Orijinal görüntü
subplot(2, 3, 1);
imshow(originalImage);
title('Orijinal Görüntü', 'FontSize', 11, 'FontWeight', 'bold');
xlabel(sprintf('%s', fileName), 'Interpreter', 'none', 'FontSize', 9);

% Canny Edge
subplot(2, 3, 2);
imshow(edgesCanny);
title(sprintf('Canny Edge (σ=%.1f)', cannySigma), 'FontSize', 11, 'FontWeight', 'bold');

% Histogram
subplot(2, 3, 3);
bar(centers, counts);
xlabel('Pixel Değeri', 'FontSize', 10);
ylabel('Frekans', 'FontSize', 10);
title('Orijinal Görüntü Histogramı', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% CLAHE
subplot(2, 3, 4);
imshow(enhancedCLAHE);
title('CLAHE (ClipLimit=0.02)', 'FontSize', 11, 'FontWeight', 'bold');

% Karşılaştırma: Orijinal vs Canny
subplot(2, 3, 5);
imshowpair(originalImage, edgesCanny, 'montage');
title('Orijinal vs Canny Edge', 'FontSize', 11, 'FontWeight', 'bold');

% Karşılaştırma: Orijinal vs CLAHE
subplot(2, 3, 6);
imshowpair(originalImage, enhancedCLAHE, 'montage');
title('Orijinal vs CLAHE', 'FontSize', 11, 'FontWeight', 'bold');

%% 7. Kontrast İyileştirme Karşılaştırması
fprintf('\n4. Kontrast iyileştirme karşılaştırması oluşturuluyor...\n');

figure('Name', 'Kontrast İyileştirme Karşılaştırması', 'Position', [200, 200, 1200, 500]);

subplot(2, 3, 1);
imshow(originalImage);
title('Orijinal', 'FontSize', 11, 'FontWeight', 'bold');

subplot(2, 3, 2);
imshow(enhancedCLAHE);
title('CLAHE', 'FontSize', 11, 'FontWeight', 'bold');

% Histogram karşılaştırması
subplot(2, 3, 3);
hold on;
[countsOrig, centersOrig] = imhist(originalImage);
[countsCLAHE, centersCLAHE] = imhist(enhancedCLAHE);
plot(centersOrig, countsOrig, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Orijinal');
plot(centersCLAHE, countsCLAHE, 'r-', 'LineWidth', 1.5, 'DisplayName', 'CLAHE');
xlabel('Pixel Değeri', 'FontSize', 10);
ylabel('Frekans', 'FontSize', 10);
title('Histogram Karşılaştırması', 'FontSize', 11, 'FontWeight', 'bold');
legend('Location', 'best');
grid on;
hold off;

% Kontrast metrikleri
subplot(2, 3, 4);
% Kontrast metrikleri hesapla
contrastOrig = std(originalImage(:));
contrastCLAHE = std(enhancedCLAHE(:));

bar([contrastOrig, contrastCLAHE]);
set(gca, 'XTickLabel', {'Orijinal', 'CLAHE'});
ylabel('Standart Sapma (Kontrast)', 'FontSize', 10);
title('Kontrast Metrikleri', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

%% 8. Metrikleri Hesapla ve Göster
fprintf('\n5. Görüntü işleme metrikleri hesaplanıyor...\n');

% Edge detection metrikleri
cannyEdgeCount = sum(edgesCanny(:));

% Kontrast metrikleri
contrastOrig = std(originalImage(:));
contrastCLAHE = std(enhancedCLAHE(:));

% Entropi (görüntü bilgi içeriği)
entropyOrig = entropy(originalImage);
entropyCLAHE = entropy(enhancedCLAHE);

fprintf('\n=== GÖRÜNTÜ İŞLEME METRİKLERİ ===\n');
fprintf('\n📊 Edge Detection:\n');
fprintf('  Canny Edge: %d piksel (%.2f%%)\n', cannyEdgeCount, ...
        cannyEdgeCount / numel(originalImage) * 100);

fprintf('\n📈 Kontrast Metrikleri (Standart Sapma):\n');
fprintf('  Orijinal:              %.4f\n', contrastOrig);
fprintf('  CLAHE:                 %.4f (%.1f%% artış)\n', contrastCLAHE, ...
        (contrastCLAHE - contrastOrig) / contrastOrig * 100);

fprintf('\n🔍 Entropi (Bilgi İçeriği):\n');
fprintf('  Orijinal:              %.4f bits\n', entropyOrig);
fprintf('  CLAHE:                 %.4f bits\n', entropyCLAHE);

%% 9. Sonuçları Workspace'e Kaydet
fprintf('\n6. Sonuçlar workspace''e kaydediliyor...\n');

imageProcessingResults = struct();
imageProcessingResults.originalImage = originalImage;
imageProcessingResults.edgesCanny = edgesCanny;
imageProcessingResults.enhancedCLAHE = enhancedCLAHE;
imageProcessingResults.histogram = struct();
imageProcessingResults.histogram.counts = counts;
imageProcessingResults.histogram.centers = centers;
imageProcessingResults.metrics = struct();
imageProcessingResults.metrics.cannyEdgeCount = cannyEdgeCount;
imageProcessingResults.metrics.contrastOrig = contrastOrig;
imageProcessingResults.metrics.contrastCLAHE = contrastCLAHE;
imageProcessingResults.metrics.entropyOrig = entropyOrig;
imageProcessingResults.metrics.entropyCLAHE = entropyCLAHE;

assignin('base', 'imageProcessingResults', imageProcessingResults);

fprintf('   ✓ Sonuçlar ''imageProcessingResults'' değişkenine kaydedildi.\n');

fprintf('\n✓ AŞAMA 4 TAMAMLANDI!\n');
fprintf('Görüntü işleme teknikleri başarıyla uygulandı ve sonuçlar görselleştirildi.\n\n');

