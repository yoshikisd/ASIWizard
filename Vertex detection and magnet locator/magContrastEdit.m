function xmcd = magContrastEdit(xmcd,sigma,threshold)
    % Edits the magnetic contrast image based on provided flatfield sigma and thresholding (in units of std relative to the image mean)
    xmcd = imflatfield(xmcd,sigma);
    meanXMCD = mean(xmcd,'all');
    stdXMCD = std(xmcd,0,'all');
    %xmcd = mat2gray(xmcd, double(meanXMCD + stdXMCD*threshold*[-1, 1]))-0.5;
end

