%% AŞAMA 5: Otomatik Fetal Ölçüm Modülü
clear; clc; close all;

fprintf('=== AŞAMA 5: Otomatik Fetal Ölçüm Modülü ===\n\n');

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

%% 3. Ölçek Çubuğu Tespiti
fprintf('\n2. Ölçek çubuğu tespit ediliyor...\n');

% Ölçek çubuğunu tespit et
scaleBarLengthPixels = detectScaleBar(originalImage);

if ~isnan(scaleBarLengthPixels)
    fprintf('   ✓ Ölçek çubuğu bulundu: %.2f piksel\n', scaleBarLengthPixels);
    
    pixelToMM = calculatePixelToMM(scaleBarLengthPixels, 1.0);
    scaleBarDetected = true;
    fprintf('   ✓ Pixel-to-MM oranı: %.4f mm/piksel\n', pixelToMM);
    fprintf('   ✓ Gerçek ölçümler kullanılacak (scale bar detected)\n');
else
    fprintf('   ⚠ Ölçek çubuğu bulunamadı.\n');
    pixelToMM = 0.15;
    scaleBarDetected = false;
    fprintf('   ⚠ Pixel-based ölçüm kullanılacak (no scale bar)\n');
end

%% 4. Ön İşleme: Denoising
fprintf('\n3. Gürültü azaltma uygulanıyor...\n');

% Wiener filter ile gürültü azaltma (fetal görüntüler için uygun)
denoisedImage = wiener2(originalImage, [5, 5]);
fprintf('   ✓ Wiener filter uygulandı.\n');

%% 5. Edge Detection (Femur Length için)
fprintf('\n4. Edge detection uygulanıyor (Femur Length için)...\n');

% Canny edge detection
edges = edge(denoisedImage, 'Canny', [0.1, 0.2], 1.5);
fprintf('   ✓ Canny edge detection tamamlandı.\n');

%% 6. Femur Length Ölçümü (Hough Transform)
fprintf('\n5. Femur Length ölçümü (Hough Transform)...\n');

% Hough transform parametreleri
houghParams = struct();
houghParams.rhoResolution = 1; % Pixel cinsinden
houghParams.thetaResolution = 0.5; % Derece cinsinden
houghParams.minLineLength = 50; % Minimum çizgi uzunluğu (piksel)
houghParams.maxLineGap = 20; % Maksimum çizgi boşluğu (piksel)
houghParams.numPeaks = 10; % Tespit edilecek maksimum çizgi sayısı

% Hough transform uygula
[H, theta, rho] = hough(edges, 'RhoResolution', houghParams.rhoResolution, ...
                        'ThetaResolution', houghParams.thetaResolution);

% Hough peaks bul
P = houghpeaks(H, houghParams.numPeaks, 'threshold', ceil(0.3 * max(H(:))));

% Hough lines bul
lines = houghlines(edges, theta, rho, P, 'FillGap', houghParams.maxLineGap, ...
                   'MinLength', houghParams.minLineLength);

fprintf('   ✓ %d çizgi tespit edildi.\n', length(lines));

% En uzun çizgiyi bul (femur için)
if ~isempty(lines)
    maxLen = 0;
    longestLine = [];
    
    for k = 1:length(lines)
        % Çizgi uzunluğunu hesapla
        xy = [lines(k).point1; lines(k).point2];
        len = norm(xy(2,:) - xy(1,:));
        
        if len > maxLen
            maxLen = len;
            longestLine = lines(k);
        end
    end
    
    % Femur length (piksel cinsinden)
    femurLengthPixels = maxLen;
    
    % Gerçek ölçümleri hesapla (pixelToMM zaten hesaplandı)
    femurLengthMM = femurLengthPixels * pixelToMM;
    femurLengthCM = femurLengthMM / 10;
    
    if scaleBarDetected
        fprintf('   ✓ Femur Length: %.2f piksel (%.2f mm, %.2f cm) [REAL MEASUREMENT]\n', ...
                femurLengthPixels, femurLengthMM, femurLengthCM);
    else
        fprintf('   ✓ Femur Length: %.2f piksel (≈ %.2f mm, ≈ %.2f cm) [PIXEL-BASED]\n', ...
                femurLengthPixels, femurLengthMM, femurLengthCM);
    end
else
    femurLengthPixels = 0;
    femurLengthMM = 0;
    femurLengthCM = 0;
    longestLine = [];
    fprintf('   ⚠ Femur çizgisi tespit edilemedi.\n');
end

%% 7. Head Circumference Ölçümü (Ellipse Fitting - Opsiyonel)
fprintf('\n6. Head Circumference ölçümü (Ellipse Fitting)...\n');

edgesHC = edge(denoisedImage, 'Canny', [0.05, 0.15], 1.0);
contours = bwboundaries(edgesHC, 'noholes');

if ~isempty(contours)
    % En büyük contour'u bul
    maxContourSize = 0;
    largestContour = [];
    
    for i = 1:length(contours)
        contourSize = length(contours{i});
        if contourSize > maxContourSize
            maxContourSize = contourSize;
            largestContour = contours{i};
        end
    end
    
    if ~isempty(largestContour) && length(largestContour) >= 5
        % Contour'u ellipse'e fit et
        try
            % Contour koordinatlarını al
            x = largestContour(:, 2); % Column
            y = largestContour(:, 1); % Row
            
            % Ellipse fitting (least squares)
            [ellipseParams, ellipsePoints] = fitEllipse(x, y);
            
            a = ellipseParams.semiMajorAxis;
            b = ellipseParams.semiMinorAxis;
            hcPixels = pi * (3 * (a + b) - sqrt((3*a + b) * (a + 3*b)));
            
            hcMM = hcPixels * pixelToMM;
            hcCM = hcMM / 10;
            
            if scaleBarDetected
                fprintf('   ✓ Head Circumference: %.2f piksel (%.2f mm, %.2f cm) [REAL MEASUREMENT]\n', ...
                        hcPixels, hcMM, hcCM);
            else
                fprintf('   ✓ Head Circumference: %.2f piksel (≈ %.2f mm, ≈ %.2f cm) [PIXEL-BASED]\n', ...
                        hcPixels, hcMM, hcCM);
            end
            
            hcSuccess = true;
        catch
            fprintf('   ⚠ Ellipse fitting başarısız oldu.\n');
            hcPixels = 0;
            hcMM = 0;
            hcCM = 0;
            ellipseParams = [];
            ellipsePoints = [];
            hcSuccess = false;
        end
    else
        fprintf('   ⚠ Yeterli büyüklükte contour bulunamadı.\n');
        hcPixels = 0;
        hcMM = 0;
        hcCM = 0;
        ellipseParams = [];
        ellipsePoints = [];
        hcSuccess = false;
    end
else
    fprintf('   ⚠ Contour bulunamadı.\n');
    hcPixels = 0;
    hcMM = 0;
    hcCM = 0;
    ellipseParams = [];
    ellipsePoints = [];
    hcSuccess = false;
end

%% 8. Sonuçları Görselleştir
fprintf('\n7. Sonuçlar görselleştiriliyor...\n');

% Ana görselleştirme
figure('Name', 'Otomatik Fetal Ölçümler', 'Position', [50, 50, 1600, 900]);

% Orijinal görüntü
subplot(2, 3, 1);
imshow(originalImage);
if scaleBarDetected
    title(sprintf('Orijinal Görüntü\n[Scale Bar: %.1f px = 1 cm]', scaleBarLengthPixels), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'green');
else
    title('Orijinal Görüntü\n[No Scale Bar]', ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'red');
end
xlabel(fileName, 'Interpreter', 'none', 'FontSize', 9);

% Denoised görüntü
subplot(2, 3, 2);
imshow(denoisedImage);
title('Gürültü Azaltılmış', 'FontSize', 11, 'FontWeight', 'bold');

% Edge detection
subplot(2, 3, 3);
imshow(edges);
title('Edge Detection (Femur için)', 'FontSize', 11, 'FontWeight', 'bold');

% Femur Length ölçümü
subplot(2, 3, 4);
imshow(originalImage);
hold on;
if ~isempty(longestLine)
    xy = [longestLine.point1; longestLine.point2];
    plot(xy(:,1), xy(:,2), 'LineWidth', 3, 'Color', 'red');
    plot(xy(1,1), xy(1,2), 'x', 'LineWidth', 3, 'Color', 'yellow', 'MarkerSize', 15);
    plot(xy(2,1), xy(2,2), 'x', 'LineWidth', 3, 'Color', 'yellow', 'MarkerSize', 15);
    if scaleBarDetected
        labelText = ' [REAL]';
    else
        labelText = ' [EST]';
    end
    text(mean(xy(:,1)), mean(xy(:,2))-20, ...
         sprintf('FL: %.1f cm%s', femurLengthCM, labelText), ...
         'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold', ...
         'BackgroundColor', 'black');
end
if scaleBarDetected
    title(sprintf('Femur Length: %.2f cm [REAL MEASUREMENT]', femurLengthCM), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'green');
else
    title(sprintf('Femur Length: ≈ %.2f cm [PIXEL-BASED]', femurLengthCM), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'red');
end
hold off;

% Head Circumference - Edge
subplot(2, 3, 5);
imshow(edgesHC);
title('Edge Detection (HC için)', 'FontSize', 11, 'FontWeight', 'bold');

% Head Circumference - Ellipse
subplot(2, 3, 6);
imshow(originalImage);
hold on;
if hcSuccess && ~isempty(ellipsePoints)
    plot(ellipsePoints(:,1), ellipsePoints(:,2), 'r-', 'LineWidth', 2);
    plot(ellipseParams.center(1), ellipseParams.center(2), 'r+', ...
         'LineWidth', 2, 'MarkerSize', 15);
    if scaleBarDetected
        labelText = ' [REAL]';
    else
        labelText = ' [EST]';
    end
    text(ellipseParams.center(1), ellipseParams.center(2)-30, ...
         sprintf('HC: %.1f cm%s', hcCM, labelText), ...
         'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold', ...
         'BackgroundColor', 'black');
end
if scaleBarDetected
    title(sprintf('Head Circumference: %.2f cm [REAL MEASUREMENT]', hcCM), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'green');
else
    title(sprintf('Head Circumference: ≈ %.2f cm [PIXEL-BASED]', hcCM), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'red');
end
hold off;

%% 9. Ölçüm Özeti
fprintf('\n=== ÖLÇÜM ÖZETİ ===\n');

if scaleBarDetected
    fprintf('📏 ÖLÇEK ÇUBUĞU TESPİT EDİLDİ - GERÇEK ÖLÇÜMLER\n');
    fprintf('   Ölçek çubuğu uzunluğu: %.2f piksel (1 cm)\n', scaleBarLengthPixels);
    fprintf('   Pixel-to-MM oranı: %.4f mm/piksel\n', pixelToMM);
else
    fprintf('⚠ ÖLÇEK ÇUBUĞU BULUNAMDI - PİKSEL BAZLI ÖLÇÜMLER\n');
    fprintf('   Varsayılan pixel-to-MM oranı: %.4f mm/piksel\n', pixelToMM);
    fprintf('   ⚠ Bu ölçümler yaklaşıktır, gerçek ölçümler için ölçek çubuğu gerekir.\n');
end

fprintf('\nFemur Length (FL):\n');
fprintf('  Piksel: %.2f\n', femurLengthPixels);
if scaleBarDetected
    fprintf('  Milimetre: %.2f mm [REAL]\n', femurLengthMM);
    fprintf('  Santimetre: %.2f cm [REAL]\n', femurLengthCM);
else
    fprintf('  Milimetre: ≈ %.2f mm [ESTIMATED]\n', femurLengthMM);
    fprintf('  Santimetre: ≈ %.2f cm [ESTIMATED]\n', femurLengthCM);
end

fprintf('\nHead Circumference (HC):\n');
if hcSuccess
    fprintf('  Piksel: %.2f\n', hcPixels);
    if scaleBarDetected
        fprintf('  Milimetre: %.2f mm [REAL]\n', hcMM);
        fprintf('  Santimetre: %.2f cm [REAL]\n', hcCM);
    else
        fprintf('  Milimetre: ≈ %.2f mm [ESTIMATED]\n', hcMM);
        fprintf('  Santimetre: ≈ %.2f cm [ESTIMATED]\n', hcCM);
    end
else
    fprintf('  ⚠ Ölçüm yapılamadı.\n');
end

%% 10. Sonuçları Workspace'e Kaydet
fprintf('\n8. Sonuçlar workspace''e kaydediliyor...\n');

measurementResults = struct();
measurementResults.originalImage = originalImage;
measurementResults.denoisedImage = denoisedImage;
measurementResults.edges = edges;
measurementResults.scaleBar = struct();
measurementResults.scaleBar.detected = scaleBarDetected;
measurementResults.scaleBar.lengthPixels = scaleBarLengthPixels;
measurementResults.scaleBar.pixelToMM = pixelToMM;
measurementResults.femurLength = struct();
measurementResults.femurLength.pixels = femurLengthPixels;
measurementResults.femurLength.mm = femurLengthMM;
measurementResults.femurLength.cm = femurLengthCM;
measurementResults.femurLength.line = longestLine;
measurementResults.femurLength.isRealMeasurement = scaleBarDetected;
measurementResults.headCircumference = struct();
measurementResults.headCircumference.pixels = hcPixels;
measurementResults.headCircumference.mm = hcMM;
measurementResults.headCircumference.cm = hcCM;
measurementResults.headCircumference.success = hcSuccess;
measurementResults.headCircumference.ellipseParams = ellipseParams;
measurementResults.headCircumference.isRealMeasurement = scaleBarDetected;

assignin('base', 'measurementResults', measurementResults);

fprintf('   ✓ Sonuçlar ''measurementResults'' değişkenine kaydedildi.\n');

fprintf('\n✓ AŞAMA 5 TAMAMLANDI!\n');
fprintf('Otomatik fetal ölçümler başarıyla yapıldı ve sonuçlar görselleştirildi.\n\n');


