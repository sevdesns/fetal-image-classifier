function scaleBarLength = detectScaleBar(image)

    % Görüntü boyutları
    [rows, cols] = size(image);
    
    % Sağ üst bölgeyi al (görüntünün sağ %30'u ve üst %20'si)
    roiColStart = max(1, round(cols * 0.7));
    roiRowStart = 1;
    roiColEnd = cols;
    roiRowEnd = min(rows, round(rows * 0.2));
    
    roi = image(roiRowStart:roiRowEnd, roiColStart:roiColEnd);
    
    % ROI boşsa NaN döndür
    if isempty(roi) || numel(roi) < 100
        scaleBarLength = NaN;
        return;
    end
    
    threshold = graythresh(roi);
    binary = imbinarize(roi, threshold * 0.8);
    
    % Morphological filtering
    se = strel('disk', 2);
    binary = imopen(binary, se);
    binary = imclose(binary, se);
    
    % Connected components bul
    cc = bwconncomp(binary);
    
    if cc.NumObjects == 0
        scaleBarLength = NaN;
        return;
    end
    
    % Her component için özellikler hesapla
    stats = regionprops(cc, 'Area', 'BoundingBox', 'MajorAxisLength', ...
                       'MinorAxisLength', 'Orientation', 'Eccentricity');
    
    bestCandidate = [];
    bestScore = 0;
    
    for i = 1:length(stats)
        bbox = stats(i).BoundingBox;
        width = bbox(3);
        height = bbox(4);
        maxDim = max(width, height);
        minDim = min(width, height);
        
        if minDim < 1
            continue;
        end
        
        aspectRatio = maxDim / minDim;
        
        if maxDim < 20
            continue;
        end
        
        orientation = abs(stats(i).Orientation);
        isHorizontal = (orientation < 15 || orientation > 165);
        isVertical = (orientation > 75 && orientation < 105);
        
        if ~isHorizontal && ~isVertical
            continue;
        end
        
        score = aspectRatio * stats(i).Area;
        if isHorizontal || isVertical
            score = score * 1.5;
        end
        
        if score > bestScore
            bestScore = score;
            bestCandidate = stats(i);
        end
    end
    
    if isempty(bestCandidate)
        scaleBarLength = NaN;
        return;
    end
    
    scaleBarLength = bestCandidate.MajorAxisLength;
    bbox = bestCandidate.BoundingBox;
    lengthFromBBox = max(bbox(3), bbox(4));
    scaleBarLength = max(scaleBarLength, lengthFromBBox);
    
    if scaleBarLength < 15
        scaleBarLength = NaN;
    end
end

