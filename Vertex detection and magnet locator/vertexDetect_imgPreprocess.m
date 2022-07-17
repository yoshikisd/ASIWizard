% Processes imported images for vertex detection via EMD
function outputImg = vertexDetect_imgPreprocess(app,inputImg)
    outputImg = abs(imresize(inputImg,app.EMD_scaleFactor.Value));

    % If the imported image file is RGB, reduce to grayscale
    [~,~,z1] = size(outputImg);
    if z1 > 1
        outputImg = rgb2gray(outputImg);
    end
end