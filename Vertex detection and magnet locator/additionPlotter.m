% Generates a new figure to select new vertices to add
function [iAdd, jAdd] = additionPlotter(app)
    additionFigure = figure('Name','Select location to add vertices');
    additionFigure.MenuBar = 'none';
    additionFigure.ToolBar = 'none';
    additionAxes = axes(additionFigure);
    movegui(additionFigure,'center');
    vertexPlot(app,additionAxes)
    set(additionAxes,'position',[0 0 1 1],'units','normalized');
    try
        [iAdd, jAdd] = getpts(additionFigure);
    catch ME
        errorNotice(app,ME)
    end
    close(additionFigure);
end