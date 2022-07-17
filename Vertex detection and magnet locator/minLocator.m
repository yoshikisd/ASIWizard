function minLocator(app)
    % Extracts detected vertex locations from xasGrid
    [app.vd.minLocJ,app.vd.minLocI] = find(app.vd.xasGrid(:,:,4) ~= 0);
    app.vd.minLoc = [app.vd.minLocJ,app.vd.minLocI];
    for i = 1:length(app.vd.minLoc)
        % Store intensity
        app.vd.minLoc(i,3) = app.vd.xasGrid(app.vd.minLoc(i,1),app.vd.minLoc(i,2),3);
        % Store which reference image was utilized for detection
        app.vd.minLoc(i,4) = app.vd.xasGrid(app.vd.minLoc(i,1),app.vd.minLoc(i,2),2);
    end
end