% Generates vertex statistics plots
function exportVertexStatistics(app,savePath)
    currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Exporting vertex statistics','Message',...
            'Generating counts for classified vertex types.','Indeterminate','on');

    typeList = vertcat(app.vd.vertex.type);
    typeSum = [sum(typeList == 1), sum(typeList == 2), sum(typeList == 3), sum(typeList == 4)];
    totalClassifiedVertices = sum(typeSum);
    totalVertices = length(typeList);

    vertexFigure = figure('visible','off','Name','Classified vertex counts', 'Position', [100,100,1000,1000]);
    ax1 = axes(vertexFigure,'Visible','off');

    switch app.vd.typeASI
        case {'Brickwork','Kagome'}
            typeName = categorical({'I','II','III'});
            typeSum(4) = [];
        case 'Square'
            typeName = categorical({'I','II','III','IV'});  
    end
    bar(ax1,typeName,typeSum);

    for i = 1:length(typeSum)
        text(ax1,typeName(i),typeSum(i),num2str(typeSum(i),'%0.0f'),...
           'HorizontalAlignment','center',...
           'VerticalAlignment','bottom')
    end
    verticesString = sprintf('Total number of classified vertices: %d\nTotal number of detected vertices: %d',...
        totalClassifiedVertices,totalVertices);
    dim = [.625 .6 .25 .3];
    annotation(vertexFigure,'textbox',dim,'String',verticesString,'FitBoxToText','on');
    pbaspect(ax1,[1,1,1]);
    print(vertexFigure,sprintf('%sVertex counts.tif',savePath),'-dtiffn');
    close(currentStatus)
end