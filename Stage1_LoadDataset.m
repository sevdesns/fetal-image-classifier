%% AŞAMA 1: Proje Yapısının Oluşturulması
clear; clc; close all;

%% 1. Proje Yollarını Tanımla
projectRoot = fileparts(mfilename('fullpath'));
csvPath = fullfile(projectRoot, 'Classification', 'image_label.csv');
trainImagesPath = fullfile(projectRoot, 'Classification', 'images');
testImagesPath = fullfile(projectRoot, 'Classification', 'External Test images');

fprintf('=== AŞAMA 1: Proje Yapısının Oluşturulması ===\n\n');

%% 2. CSV Dosyasını Oku
fprintf('1. CSV dosyası okunuyor...\n');
if ~exist(csvPath, 'file')
    error('CSV dosyası bulunamadı: %s', csvPath);
end

% CSV'yi tablo olarak oku
labelTable = readtable(csvPath, 'Delimiter', ',', 'TextType', 'string');

fprintf('   ✓ CSV okundu. Toplam %d satır bulundu.\n', height(labelTable));

%% 3. Sınıf İstatistiklerini Göster
fprintf('\n2. Sınıf dağılımı analiz ediliyor...\n');
uniqueClasses = unique(labelTable.Plane);
classCounts = countcats(categorical(labelTable.Plane));

fprintf('   Bulunan sınıflar:\n');
for i = 1:length(uniqueClasses)
    fprintf('   - %s: %d görüntü\n', uniqueClasses(i), classCounts(i));
end

%% 4. Görüntü Dosya Yollarını Oluştur
fprintf('\n3. Görüntü dosya yolları oluşturuluyor...\n');

% Eğitim görüntüleri için tam yolları oluştur
imageFiles = dir(fullfile(trainImagesPath, '*.png'));
numTrainImages = length(imageFiles);
fprintf('   ✓ Eğitim klasöründe %d PNG dosyası bulundu.\n', numTrainImages);

% Test görüntüleri için
testFiles = dir(fullfile(testImagesPath, '*.png'));
numTestImages = length(testFiles);
fprintf('   ✓ Test klasöründe %d PNG dosyası bulundu.\n', numTestImages);

%% 5. Görüntü/Etiket Eşleşmesi Oluştur
fprintf('\n4. Görüntü/etiket eşleşmesi oluşturuluyor...\n');

% Eğitim görüntüleri için eşleşme
trainImagePaths = strings(numTrainImages, 1);
trainLabels = strings(numTrainImages, 1);
matchedCount = 0;

for i = 1:numTrainImages
    imageName = imageFiles(i).name;
    % .png uzantısını kaldır
    imageNameNoExt = erase(imageName, '.png');
    
    % CSV'de bu görüntüyü ara
    idx = find(labelTable.Image_name == imageNameNoExt, 1);
    
    if ~isempty(idx)
        trainImagePaths(i) = fullfile(trainImagesPath, imageName);
        trainLabels(i) = labelTable.Plane(idx);
        matchedCount = matchedCount + 1;
    else
        trainImagePaths(i) = fullfile(trainImagesPath, imageName);
        trainLabels(i) = "Unknown";
    end
end

fprintf('   ✓ %d eğitim görüntüsü etiketle eşleştirildi.\n', matchedCount);
if matchedCount < numTrainImages
    fprintf('   ⚠ %d görüntü için etiket bulunamadı.\n', numTrainImages - matchedCount);
end

% Eşleşen görüntüleri filtrele (Unknown olmayanlar)
validIdx = trainLabels ~= "Unknown";
trainImagePaths = trainImagePaths(validIdx);
trainLabels = trainLabels(validIdx);

fprintf('   ✓ Toplam %d geçerli eğitim görüntüsü hazır.\n', length(trainImagePaths));

%% 6. Dataset Yapısını Workspace'e Kaydet
fprintf('\n5. Dataset yapısı workspace''e kaydediliyor...\n');

% Dataset yapısını struct olarak kaydet
datasetInfo = struct();
datasetInfo.trainImagePaths = trainImagePaths;
datasetInfo.trainLabels = trainLabels;
datasetInfo.testImagePaths = fullfile(testImagesPath, {testFiles.name}');
datasetInfo.uniqueClasses = uniqueClasses;
datasetInfo.classCounts = classCounts;
datasetInfo.csvPath = csvPath;
datasetInfo.trainImagesPath = trainImagesPath;
datasetInfo.testImagesPath = testImagesPath;

% Workspace'e kaydet
assignin('base', 'datasetInfo', datasetInfo);

fprintf('   ✓ Dataset bilgileri ''datasetInfo'' değişkenine kaydedildi.\n');

%% 7. Özet Bilgileri Göster
fprintf('\n=== ÖZET ===\n');
fprintf('Eğitim görüntüleri: %d\n', length(trainImagePaths));
fprintf('Test görüntüleri: %d\n', numTestImages);
fprintf('Sınıf sayısı: %d\n', length(uniqueClasses));
fprintf('\nSınıf dağılımı:\n');
for i = 1:length(uniqueClasses)
    count = sum(trainLabels == uniqueClasses(i));
    fprintf('  %s: %d görüntü\n', uniqueClasses(i), count);
end

fprintf('\n✓ AŞAMA 1 TAMAMLANDI!\n');
fprintf('Dataset bilgileri ''datasetInfo'' değişkeninde hazır.\n\n');

%% 8. Örnek Görüntü Gösterimi
fprintf('Örnek görüntüler gösteriliyor...\n');
figure('Name', 'Örnek Eğitim Görüntüleri', 'Position', [100, 100, 1200, 300]);

for i = 1:min(4, length(trainImagePaths))
    subplot(1, 4, i);
    img = imread(trainImagePaths(i));
    imshow(img);
    [~, fileName, ~] = fileparts(trainImagePaths(i));
    title(sprintf('%s\n%s', fileName, trainLabels(i)), ...
          'Interpreter', 'none', 'FontSize', 9);
end

fprintf('✓ AŞAMA 1 başarıyla tamamlandı!\n');

