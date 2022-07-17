function importImage = referenceImageImport(app)
    % Get the file name and directory for the image file containing the reference image
    % of a vertex (for square, brickwork, and kagome)
    oldDirImages = app.dirImages;
    [FileName,app.dirImages] = uigetfile(sprintf('%s%s',app.dirImages,'*.tif'),'Select vertex reference image');
    if FileName == 0
        app.dirImages = oldDirImages;
        return;
    end
    importImage = imread(fullfile(app.dirImages,FileName));
    % Initial processing of the reference frame
    importImage = vertexDetect_imgPreprocess(app,importImage);
    % Modifying reference image to prevent crashing in EMD calculation associated with zeros
    importImage(importImage == 0) = 0.01;
end