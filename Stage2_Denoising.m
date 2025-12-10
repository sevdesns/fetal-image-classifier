%% AŞAMA 2: Denoising (Gürültü Azaltma) Modülü
clear; clc; close all;

fprintf('=== AŞAMA 2: Denoising (Gürültü Azaltma) Modülü ===\n\n');

%% 1. Dataset'in Yüklü Olduğunu Kontrol Et
if ~exist('datasetInfo', 'var')
    fprintf('⚠ Dataset bilgileri bulunamadı. Stage1_LoadDataset.m çalıştırılıyor...\n');
    Stage1_LoadDataset;
end

%% 2. Test Görüntüsü Seç (Gürültülü Görüntü Bul)
fprintf('1. Gürültülü test görüntüsü seçiliyor...\n');

% Görüntü seçenekleri: önce test, sonra eğitim
if isempty(datasetInfo.testImagePaths)
    imageCandidates = datasetInfo.trainImagePaths;
    fprintf('   Test görüntüsü bulunamadı, eğitim görüntüleri aranıyor...\n');
else
    % Tüm yolları cell array'e çevir
    if iscell(datasetInfo.testImagePaths)
        testPaths = datasetInfo.testImagePaths(:);
    else
        testPaths = cellstr(datasetInfo.testImagePaths(:));
    end
    trainPaths = datasetInfo.trainImagePaths(1:min(10, length(datasetInfo.trainImagePaths)));
    if iscell(trainPaths)
        imageCandidates = [testPaths; trainPaths];
    else
        imageCandidates = [testPaths; cellstr(trainPaths)];
    end
    fprintf('   Test ve eğitim görüntüleri arasından seçiliyor...\n');
end

% En gürültülü görüntüyü bul (yüksek varyans = daha fazla gürültü)
fprintf('   Gürültü seviyesi analiz ediliyor...\n');
maxVariance = 0;
bestImagePath = '';
bestImage = [];

for i = 1:min(20, length(imageCandidates)) % İlk 20 görüntüyü kontrol et
    try
        % Cell array veya string array'den güvenli okuma
        if iscell(imageCandidates)
            imgPath = imageCandidates{i};
        else
            imgPath = imageCandidates(i);
        end
        img = imread(imgPath);
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        img = im2double(img);
        imgVariance = var(img(:));
        
        if imgVariance > maxVariance
            maxVariance = imgVariance;
            if iscell(imageCandidates)
                bestImagePath = imageCandidates{i};
            else
                bestImagePath = imageCandidates(i);
            end
            bestImage = img;
        end
    catch
        continue;
    end
end

if isempty(bestImage)
    if iscell(imageCandidates)
        bestImagePath = imageCandidates{1};
    else
        bestImagePath = imageCandidates(1);
    end
    bestImage = imread(bestImagePath);
    if size(bestImage, 3) == 3
        bestImage = rgb2gray(bestImage);
    end
    bestImage = im2double(bestImage);
end

originalImage = bestImage;
[~, fileName, ~] = fileparts(bestImagePath);
fprintf('   ✓ Görüntü seçildi: %s (Varyans: %.6f)\n', fileName, maxVariance);
fprintf('   ✓ Görüntü yüklendi. Boyut: %dx%d\n', size(originalImage, 1), size(originalImage, 2));

%% 3. Filtre Parametrelerini Tanımla
fprintf('\n2. Filtre parametreleri ayarlanıyor...\n');

medianFilterSize = 7;
wienerFilterSize = 5;
gaussianSigma = 2.0;
gaussianFilterSize = 7;
bilateralSigmaSpatial = 7;
bilateralSigmaIntensity = 0.15;
bilateralWindowSize = 7;

fprintf('   ✓ Parametreler ayarlandı.\n');

%% 4. Median Filter Uygula
fprintf('\n3. Median Filter uygulanıyor...\n');
denoisedMedian = medfilt2(originalImage, [medianFilterSize, medianFilterSize]);
fprintf('   ✓ Median Filter tamamlandı.\n');

%% 5. Wiener Filter Uygula
fprintf('\n4. Wiener Filter uygulanıyor...\n');
denoisedWiener = wiener2(originalImage, [wienerFilterSize, wienerFilterSize]);
fprintf('   ✓ Wiener Filter tamamlandı.\n');

%% 6. Gaussian Filter Uygula
fprintf('\n5. Gaussian Filter uygulanıyor...\n');
denoisedGaussian = imgaussfilt(originalImage, gaussianSigma, 'FilterSize', gaussianFilterSize);
fprintf('   ✓ Gaussian Filter tamamlandı.\n');

%% 7. Bilateral Filter Uygula
fprintf('\n6. Bilateral Filter uygulanıyor...\n');
denoisedBilateral = bilateralFilter(originalImage, bilateralSigmaSpatial, ...
                                    bilateralSigmaIntensity, bilateralWindowSize);
fprintf('   ✓ Bilateral Filter tamamlandı.\n');

%% 8. Sonuçları Görselleştir
fprintf('\n7. Sonuçlar görselleştiriliyor...\n');

figure('Name', 'Gürültü Azaltma Sonuçları', 'Position', [50, 50, 1600, 900]);
subplot(3, 3, 1);
imshow(originalImage);
[~, fileName, ~] = fileparts(bestImagePath);
title(sprintf('Orijinal Görüntü\n%s', fileName), 'FontSize', 11, 'FontWeight', 'bold', ...
      'Interpreter', 'none');
xlabel(sprintf('Boyut: %dx%d', size(originalImage, 1), size(originalImage, 2)));

% Median Filter
subplot(3, 3, 2);
imshow(denoisedMedian);
title(sprintf('Median Filter (%dx%d)', medianFilterSize, medianFilterSize), ...
      'FontSize', 11, 'FontWeight', 'bold');

% Wiener Filter
subplot(3, 3, 3);
imshow(denoisedWiener);
title(sprintf('Wiener Filter (%dx%d)', wienerFilterSize, wienerFilterSize), ...
      'FontSize', 11, 'FontWeight', 'bold');

% Gaussian Filter
subplot(3, 3, 4);
imshow(denoisedGaussian);
title(sprintf('Gaussian Filter (σ=%.1f)', gaussianSigma), ...
      'FontSize', 11, 'FontWeight', 'bold');

% Bilateral Filter
subplot(3, 3, 5);
imshow(denoisedBilateral);
title(sprintf('Bilateral Filter (σ_s=%.1f, σ_i=%.2f)', ...
      bilateralSigmaSpatial, bilateralSigmaIntensity), ...
      'FontSize', 11, 'FontWeight', 'bold');

% Fark görüntüleri - Filtrelerin etkisini daha net göster
subplot(3, 3, 6);
diffMedian = abs(originalImage - denoisedMedian);
imshow(diffMedian, []);
title('Median Farkı', 'FontSize', 11, 'FontWeight', 'bold');
colorbar;

subplot(3, 3, 7);
diffWiener = abs(originalImage - denoisedWiener);
imshow(diffWiener, []);
title('Wiener Farkı', 'FontSize', 11, 'FontWeight', 'bold');
colorbar;

subplot(3, 3, 8);
diffGaussian = abs(originalImage - denoisedGaussian);
imshow(diffGaussian, []);
title('Gaussian Farkı', 'FontSize', 11, 'FontWeight', 'bold');
colorbar;

subplot(3, 3, 9);
diffBilateral = abs(originalImage - denoisedBilateral);
imshow(diffBilateral, []);
title('Bilateral Farkı', 'FontSize', 11, 'FontWeight', 'bold');
colorbar;

%% 9. Metrikleri Hesapla
fprintf('\n8. Gürültü azaltma metrikleri hesaplanıyor...\n');

originalVariance = var(originalImage(:));
medianVariance = var(denoisedMedian(:));
wienerVariance = var(denoisedWiener(:));
gaussianVariance = var(denoisedGaussian(:));
bilateralVariance = var(denoisedBilateral(:));

noiseReductionMedian = (originalVariance - medianVariance) / originalVariance * 100;
noiseReductionWiener = (originalVariance - wienerVariance) / originalVariance * 100;
noiseReductionGaussian = (originalVariance - gaussianVariance) / originalVariance * 100;
noiseReductionBilateral = (originalVariance - bilateralVariance) / originalVariance * 100;

psnrMedian = calculatePSNR(originalImage, denoisedMedian);
psnrWiener = calculatePSNR(originalImage, denoisedWiener);
psnrGaussian = calculatePSNR(originalImage, denoisedGaussian);
psnrBilateral = calculatePSNR(originalImage, denoisedBilateral);

snrMedian = calculateSNR(originalImage, denoisedMedian);
snrWiener = calculateSNR(originalImage, denoisedWiener);
snrGaussian = calculateSNR(originalImage, denoisedGaussian);
snrBilateral = calculateSNR(originalImage, denoisedBilateral);

try
    ssimMedian = ssim(denoisedMedian, originalImage);
    ssimWiener = ssim(denoisedWiener, originalImage);
    ssimGaussian = ssim(denoisedGaussian, originalImage);
    ssimBilateral = ssim(denoisedBilateral, originalImage);
    hasSSIM = true;
catch
    hasSSIM = false;
    fprintf('   ⚠ SSIM hesaplanamadı (Image Processing Toolbox gerekli).\n');
end

fprintf('\n=== GÜRÜLTÜ AZALTMA METRİKLERİ ===\n');
fprintf('Orijinal görüntü varyansı: %.6f\n', originalVariance);
fprintf('\n📊 Filtre Performansı (Varyans Bazlı):\n');
fprintf('  Median Filter:    Varyans = %.6f, Azalma = %.2f%%\n', ...
        medianVariance, noiseReductionMedian);
fprintf('  Wiener Filter:    Varyans = %.6f, Azalma = %.2f%%\n', ...
        wienerVariance, noiseReductionWiener);
fprintf('  Gaussian Filter:  Varyans = %.6f, Azalma = %.2f%%\n', ...
        gaussianVariance, noiseReductionGaussian);
fprintf('  Bilateral Filter: Varyans = %.6f, Azalma = %.2f%%\n', ...
        bilateralVariance, noiseReductionBilateral);

fprintf('\n📈 PSNR (Peak Signal-to-Noise Ratio) - dB:\n');
fprintf('  Median Filter:    PSNR = %.2f dB\n', psnrMedian);
fprintf('  Wiener Filter:    PSNR = %.2f dB\n', psnrWiener);
fprintf('  Gaussian Filter:  PSNR = %.2f dB\n', psnrGaussian);
fprintf('  Bilateral Filter: PSNR = %.2f dB\n', psnrBilateral);

fprintf('\n📉 SNR (Signal-to-Noise Ratio) - dB:\n');
fprintf('  Median Filter:    SNR = %.2f dB\n', snrMedian);
fprintf('  Wiener Filter:    SNR = %.2f dB\n', snrWiener);
fprintf('  Gaussian Filter:  SNR = %.2f dB\n', snrGaussian);
fprintf('  Bilateral Filter: SNR = %.2f dB\n', snrBilateral);

if hasSSIM
    fprintf('\n🔍 SSIM (Structural Similarity Index):\n');
    fprintf('  Median Filter:    SSIM = %.4f\n', ssimMedian);
    fprintf('  Wiener Filter:    SSIM = %.4f\n', ssimWiener);
    fprintf('  Gaussian Filter:  SSIM = %.4f\n', ssimGaussian);
    fprintf('  Bilateral Filter: SSIM = %.4f\n', ssimBilateral);
end

fprintf('\n💡 DEĞERLENDİRME:\n');
fprintf('  ✅ En iyi performans: ');
[maxPSNR, idx] = max([psnrMedian, psnrWiener, psnrGaussian, psnrBilateral]);
filterNames = {'Median', 'Wiener', 'Gaussian', 'Bilateral'};
fprintf('%s Filter (PSNR: %.2f dB)\n', filterNames{idx}, maxPSNR);

%% 10. Sonuçları Workspace'e Kaydet
fprintf('\n9. Sonuçlar workspace''e kaydediliyor...\n');

denoisingResults = struct();
denoisingResults.originalImage = originalImage;
denoisingResults.denoisedMedian = denoisedMedian;
denoisingResults.denoisedWiener = denoisedWiener;
denoisingResults.denoisedGaussian = denoisedGaussian;
denoisingResults.denoisedBilateral = denoisedBilateral;
denoisingResults.metrics = struct();
denoisingResults.metrics.originalVariance = originalVariance;
denoisingResults.metrics.medianVariance = medianVariance;
denoisingResults.metrics.wienerVariance = wienerVariance;
denoisingResults.metrics.gaussianVariance = gaussianVariance;
denoisingResults.metrics.bilateralVariance = bilateralVariance;
denoisingResults.metrics.noiseReductionMedian = noiseReductionMedian;
denoisingResults.metrics.noiseReductionWiener = noiseReductionWiener;
denoisingResults.metrics.noiseReductionGaussian = noiseReductionGaussian;
denoisingResults.metrics.noiseReductionBilateral = noiseReductionBilateral;
denoisingResults.metrics.psnrMedian = psnrMedian;
denoisingResults.metrics.psnrWiener = psnrWiener;
denoisingResults.metrics.psnrGaussian = psnrGaussian;
denoisingResults.metrics.psnrBilateral = psnrBilateral;
denoisingResults.metrics.snrMedian = snrMedian;
denoisingResults.metrics.snrWiener = snrWiener;
denoisingResults.metrics.snrGaussian = snrGaussian;
denoisingResults.metrics.snrBilateral = snrBilateral;
if hasSSIM
    denoisingResults.metrics.ssimMedian = ssimMedian;
    denoisingResults.metrics.ssimWiener = ssimWiener;
    denoisingResults.metrics.ssimGaussian = ssimGaussian;
    denoisingResults.metrics.ssimBilateral = ssimBilateral;
end

assignin('base', 'denoisingResults', denoisingResults);

fprintf('   ✓ Sonuçlar ''denoisingResults'' değişkenine kaydedildi.\n');

fprintf('\n✓ AŞAMA 2 TAMAMLANDI!\n');
fprintf('Gürültü azaltma filtreleri başarıyla uygulandı ve sonuçlar görselleştirildi.\n\n');

%% ============================================================
% Bilateral Filter Fonksiyonu
% Edge-preserving bilateral filter implementasyonu
% ============================================================
function filtered = bilateralFilter(image, sigmaSpatial, sigmaIntensity, windowSize)
    [rows, cols] = size(image);
    filtered = zeros(size(image));
    radius = floor(windowSize / 2);
    [X, Y] = meshgrid(-radius:radius, -radius:radius);
    spatialKernel = exp(-(X.^2 + Y.^2) / (2 * sigmaSpatial^2));
    
    for i = 1:rows
        for j = 1:cols
            iMin = max(1, i - radius);
            iMax = min(rows, i + radius);
            jMin = max(1, j - radius);
            jMax = min(cols, j + radius);
            window = image(iMin:iMax, jMin:jMax);
            centerValue = image(i, j);
            intensityDiff = window - centerValue;
            intensityKernel = exp(-(intensityDiff.^2) / (2 * sigmaIntensity^2));
            spatialWindow = spatialKernel(radius+1-(i-iMin):radius+1+(iMax-i), ...
                                         radius+1-(j-jMin):radius+1+(jMax-j));
            weight = spatialWindow .* intensityKernel;
            filtered(i, j) = sum(window(:) .* weight(:)) / sum(weight(:));
        end
    end
end

function psnrValue = calculatePSNR(original, filtered)
    mse = mean((original(:) - filtered(:)).^2);
    if mse == 0
        psnrValue = Inf;
    else
        maxPixelValue = 1.0;
        psnrValue = 10 * log10((maxPixelValue^2) / mse);
    end
end

function snrValue = calculateSNR(original, filtered)
    signalPower = mean(original(:).^2);
    noise = original(:) - filtered(:);
    noisePower = mean(noise.^2);
    
    if noisePower == 0
        snrValue = Inf;
    else
        snrValue = 10 * log10(signalPower / noisePower);
    end
end

