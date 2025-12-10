%% AŞAMA 3: CNN Eğitimi (Transfer Learning)
clear; clc; close all;

fprintf('=== AŞAMA 3: CNN Eğitimi (Transfer Learning) ===\n\n');

%% 1. Dataset'in Yüklü Olduğunu Kontrol Et
if ~exist('datasetInfo', 'var')
    fprintf('⚠ Dataset bilgileri bulunamadı. Stage1_LoadDataset.m çalıştırılıyor...\n');
    Stage1_LoadDataset;
end

%% 2. Model Seçimi ve Yükleme
fprintf('1. Transfer Learning modeli seçiliyor ve yükleniyor...\n');
modelChoice = 'resnet18';

fprintf('   Seçilen model: %s\n', modelChoice);
fprintf('   Pretrained model yükleniyor...\n');
try
    switch lower(modelChoice)
        case 'resnet18'
            net = resnet18;
            inputSize = net.Layers(1).InputSize;
        case 'mobilenetv2'
            net = mobilenetv2;
            inputSize = net.Layers(1).InputSize;
        otherwise
            error('Geçersiz model seçimi. ''resnet18'' veya ''mobilenetv2'' kullanın.');
    end
    fprintf('   ✓ Model yüklendi. Giriş boyutu: %dx%dx%d\n', inputSize(1), inputSize(2), inputSize(3));
catch ME
    if contains(ME.message, 'Undefined function') || contains(ME.message, 'not found')
        error(['❌ Deep Learning Toolbox bulunamadı veya model fonksiyonu mevcut değil!\n' ...
               '   Hata: %s\n' ...
               '   Lütfen Deep Learning Toolbox''ın yüklü olduğundan emin olun.'], ME.message);
    else
        error('Model yüklenemedi: %s', ME.message);
    end
end

%% 4. Dataset Hazırlama
fprintf('\n3. Dataset hazırlanıyor...\n');

% Görüntü yolları ve etiketleri al
imagePaths = datasetInfo.trainImagePaths;
labels = datasetInfo.trainLabels;

% Geçerli görüntüleri kontrol et
validIndices = [];
for i = 1:length(imagePaths)
    if exist(imagePaths(i), 'file')
        validIndices = [validIndices; i];
    end
end

imagePaths = imagePaths(validIndices);
labels = labels(validIndices);

fprintf('   ✓ %d geçerli görüntü bulundu.\n', length(imagePaths));

% Sınıfları belirle
uniqueClasses = unique(labels);
numClasses = length(uniqueClasses);
fprintf('   ✓ %d sınıf tespit edildi: %s\n', numClasses, strjoin(uniqueClasses, ', '));

%% 5. Training/Validation Split
fprintf('\n4. Training/Validation split yapılıyor...\n');

% Her sınıftan eşit dağılım için stratified split
rng(42); % Reproducibility için
trainRatio = 0.8; % %80 training, %20 validation

trainIndices = [];
valIndices = [];

for i = 1:numClasses
    classIdx = find(labels == uniqueClasses(i));
    numSamples = length(classIdx);
    numTrain = round(numSamples * trainRatio);
    
    % Rastgele karıştır
    shuffledIdx = classIdx(randperm(numSamples));
    
    trainIndices = [trainIndices; shuffledIdx(1:numTrain)];
    valIndices = [valIndices; shuffledIdx(numTrain+1:end)];
end

% Karıştır
trainIndices = trainIndices(randperm(length(trainIndices)));
valIndices = valIndices(randperm(length(valIndices)));

trainPaths = imagePaths(trainIndices);
trainLabels = labels(trainIndices);
valPaths = imagePaths(valIndices);
valLabels = labels(valIndices);

fprintf('   ✓ Training set: %d görüntü\n', length(trainPaths));
fprintf('   ✓ Validation set: %d görüntü\n', length(valPaths));

% Sınıf dağılımını göster
fprintf('\n   Training set sınıf dağılımı:\n');
for i = 1:numClasses
    count = sum(trainLabels == uniqueClasses(i));
    fprintf('     %s: %d görüntü\n', uniqueClasses(i), count);
end

%% 6. imageDatastore Oluşturma
fprintf('\n5. imageDatastore oluşturuluyor...\n');

% Training datastore - cell array'i string array'e çevir
if iscell(trainPaths)
    trainPathsStr = string(trainPaths);
else
    trainPathsStr = trainPaths;
end

if iscell(valPaths)
    valPathsStr = string(valPaths);
else
    valPathsStr = valPaths;
end

% imageDatastore oluştur
trainDSBase = imageDatastore(trainPathsStr, 'Labels', categorical(trainLabels));
valDSBase = imageDatastore(valPathsStr, 'Labels', categorical(valLabels));

% Görüntü boyutlandırma için augmentedImageDatastore kullan
% Grayscale görüntüleri RGB'ye çevir (model 3 kanal bekliyor)
trainDS = augmentedImageDatastore(inputSize(1:2), trainDSBase, 'ColorPreprocessing', 'gray2rgb');
valDS = augmentedImageDatastore(inputSize(1:2), valDSBase, 'ColorPreprocessing', 'gray2rgb');

fprintf('   ✓ Training datastore: %d görüntü\n', numel(trainDSBase.Files));
fprintf('   ✓ Validation datastore: %d görüntü\n', numel(valDSBase.Files));

%% 7. Model Mimarisi (Transfer Learning)
fprintf('\n6. Transfer Learning modeli hazırlanıyor...\n');

% Son katmanları değiştir
lgraph = layerGraph(net);

% Sınıflandırma katmanını bul ve değiştir
if strcmp(modelChoice, 'resnet18')
    % ResNet18 için
    [learnableLayer, classLayer] = findLayersToReplace(lgraph);
else
    % MobileNet için
    [learnableLayer, classLayer] = findLayersToReplace(lgraph);
end

numClasses = length(uniqueClasses);
newLearnableLayer = fullyConnectedLayer(numClasses, ...
    'Name', 'new_fc', ...
    'WeightLearnRateFactor', 50, ...
    'BiasLearnRateFactor', 50);

% Yeni classification layer ekle
newClassLayer = classificationLayer('Name', 'new_classoutput');

% Katmanları değiştir
lgraph = replaceLayer(lgraph, learnableLayer.Name, newLearnableLayer);
lgraph = replaceLayer(lgraph, classLayer.Name, newClassLayer);

layers = lgraph.Layers;
numLayersToUpdate = min(20, length(layers));
for i = max(1, length(layers)-numLayersToUpdate):length(layers)
    if isa(layers(i), 'nnet.cnn.layer.Convolution2DLayer')
        layers(i).WeightLearnRateFactor = 0.5;
        layers(i).BiasLearnRateFactor = 0.5;
    end
end

for i = 1:length(layers)
    layerName = layers(i).Name;
    try
        lgraph = replaceLayer(lgraph, layerName, layers(i));
    catch
    end
end

fprintf('   ✓ Model mimarisi hazırlandı.\n');
fprintf('   ✓ Sınıf sayısı: %d\n', numClasses);

%% 8. Training Options
fprintf('\n7. Training options ayarlanıyor...\n');

% Data augmentation ekle (overfitting'i önlemek için)
augmenter = imageDataAugmenter(...
    'RandRotation', [-15, 15], ...      % Daha geniş rotation
    'RandXReflection', true, ...
    'RandYReflection', false, ...
    'RandXTranslation', [-15, 15], ...  % Daha geniş translation
    'RandYTranslation', [-15, 15], ...
    'RandXScale', [0.85, 1.15], ...     % Daha geniş scale
    'RandYScale', [0.85, 1.15], ...
    'RandXShear', [-5, 5], ...          % Shear ekle
    'RandYShear', [-5, 5]);

% Training datastore'a augmentation ekle
trainDSAugmented = augmentedImageDatastore(inputSize(1:2), trainDSBase, ...
    'ColorPreprocessing', 'gray2rgb', ...
    'DataAugmentation', augmenter);

options = trainingOptions('adam', ...
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 40, ...
    'MiniBatchSize', 16, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', valDS, ...
    'ValidationFrequency', 30, ...
    'ValidationPatience', 15, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.5, ...
    'LearnRateDropPeriod', 10, ...
    'L2Regularization', 0.0001, ...
    'GradientThreshold', 1, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto');

fprintf('   ✓ Training options ayarlandı.\n');

%% 9. Model Eğitimi
fprintf('\n8. Model eğitimi başlatılıyor...\n\n');

try
    [trainedNet, info] = trainNetwork(trainDSAugmented, lgraph, options);
    fprintf('\n   ✓ Model eğitimi tamamlandı!\n');
catch ME
    error('Eğitim sırasında hata: %s', ME.message);
end

%% 10. Validation Accuracy Hesaplama
fprintf('\n9. Validation accuracy hesaplanıyor...\n');

YPred = classify(trainedNet, valDS);
YTrue = valDSBase.Labels;

accuracy = mean(YPred == YTrue);
fprintf('   ✓ Validation Accuracy: %.2f%%\n', accuracy * 100);

%% 11. Confusion Matrix
fprintf('\n10. Confusion Matrix oluşturuluyor...\n');

try
    figure('Name', 'Confusion Matrix', 'Position', [100, 100, 800, 600]);
    cm = confusionmat(YTrue, YPred);
    chart = confusionchart(cm, uniqueClasses);
    chart.Title = sprintf('Confusion Matrix - Accuracy: %.2f%%', accuracy * 100);
    chart.FontSize = 12;
    fprintf('   ✓ Confusion Matrix oluşturuldu.\n');
catch ME
    fprintf('   ⚠ Confusion Matrix oluşturulurken hata: %s\n', ME.message);
    fprintf('   Devam ediliyor...\n');
    % Basit confusion matrix
    cm = confusionmat(YTrue, YPred);
end

%% 12. Accuracy Plot (Training History)
fprintf('\n11. Training history görselleştiriliyor...\n');

try
    if isfield(info, 'TrainingAccuracy')
        figure('Name', 'Training History', 'Position', [950, 100, 800, 600]);
        
        subplot(2, 1, 1);
        plot(info.TrainingLoss, 'LineWidth', 2);
        hold on;
        plot(info.ValidationLoss, 'LineWidth', 2);
        xlabel('Iteration');
        ylabel('Loss');
        title('Training and Validation Loss', 'FontSize', 12, 'FontWeight', 'bold');
        legend('Training Loss', 'Validation Loss', 'Location', 'best');
        grid on;
        
        subplot(2, 1, 2);
        plot(info.TrainingAccuracy, 'LineWidth', 2);
        hold on;
        plot(info.ValidationAccuracy, 'LineWidth', 2);
        xlabel('Iteration');
        ylabel('Accuracy');
        title('Training and Validation Accuracy', 'FontSize', 12, 'FontWeight', 'bold');
        legend('Training Accuracy', 'Validation Accuracy', 'Location', 'best');
        grid on;
        fprintf('   ✓ Training history görselleştirildi.\n');
    end
catch ME
    fprintf('   ⚠ Training history görselleştirilirken hata: %s\n', ME.message);
    fprintf('   Devam ediliyor...\n');
end

%% 13. Sınıf Bazlı Performans
fprintf('\n12. Sınıf bazlı performans analizi...\n');

try
    for i = 1:numClasses
        classIdx = (YTrue == uniqueClasses(i));
        classPred = YPred(classIdx);
        classAcc = mean(classPred == YTrue(classIdx));
        fprintf('   %s: %.2f%% accuracy (%d/%d)\n', ...
                uniqueClasses(i), classAcc * 100, ...
                sum(classPred == YTrue(classIdx)), sum(classIdx));
    end
catch ME
    fprintf('   ⚠ Sınıf bazlı performans analizi sırasında hata: %s\n', ME.message);
end

%% 14. Model ve Sonuçları Kaydet
fprintf('\n13. Model ve sonuçlar kaydediliyor...\n');

% Modeli kaydet
modelPath = fullfile(fileparts(mfilename('fullpath')), 'trained_model.mat');
save(modelPath, 'trainedNet', 'info', 'accuracy', 'uniqueClasses', 'inputSize', 'modelChoice');
fprintf('   ✓ Model kaydedildi: %s\n', modelPath);

% Sonuçları workspace'e kaydet
cnnResults = struct();
cnnResults.trainedNet = trainedNet;
cnnResults.info = info;
cnnResults.accuracy = accuracy;
cnnResults.uniqueClasses = uniqueClasses;
cnnResults.inputSize = inputSize;
cnnResults.modelChoice = modelChoice;
cnnResults.confusionMatrix = cm;
cnnResults.YPred = YPred;
cnnResults.YTrue = YTrue;

assignin('base', 'cnnResults', cnnResults);

fprintf('   ✓ Sonuçlar ''cnnResults'' değişkenine kaydedildi.\n');

%% 15. Özet
fprintf('\n=== ÖZET ===\n');
fprintf('Model: %s\n', modelChoice);
fprintf('Training görüntüleri: %d\n', length(trainPaths));
fprintf('Validation görüntüleri: %d\n', length(valPaths));
fprintf('Sınıf sayısı: %d\n', numClasses);
fprintf('Validation Accuracy: %.2f%%\n', accuracy * 100);
fprintf('\n✓ AŞAMA 3 TAMAMLANDI!\n');
fprintf('Model eğitildi ve kaydedildi. Sonuçlar ''cnnResults'' değişkeninde.\n\n');

function [learnableLayer, classLayer] = findLayersToReplace(lgraph)
    if ~isa(lgraph, 'nnet.cnn.LayerGraph')
        error('Geçersiz layer graph');
    end
    
    layers = lgraph.Layers;
    learnableLayer = [];
    classLayer = [];
    
    for i = length(layers):-1:1
        if isa(layers(i), 'nnet.cnn.layer.FullyConnectedLayer')
            learnableLayer = layers(i);
            break;
        end
    end
    
    for i = length(layers):-1:1
        if isa(layers(i), 'nnet.cnn.layer.ClassificationOutputLayer')
            classLayer = layers(i);
            break;
        end
    end
    
    if isempty(learnableLayer) || isempty(classLayer)
        error('Fully connected veya classification layer bulunamadı');
    end
end

