function pixelToMM = calculatePixelToMM(scaleBarLengthPixels, scaleBarLengthCM)

    if nargin < 2 || isempty(scaleBarLengthCM)
        scaleBarLengthCM = 1.0;
    end
    
    if isnan(scaleBarLengthPixels) || scaleBarLengthPixels <= 0
        pixelToMM = NaN;
        return;
    end
    
    pixelToMM = (scaleBarLengthCM * 10) / scaleBarLengthPixels;
end

