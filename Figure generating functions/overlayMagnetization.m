% Plots the magnetization vectors over an image
function overlayMagnetization(app,axisFrame,latticeOption)
    app.vd.whiteOffsetX = vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) > 0).spinPlotXOffset);
    app.vd.whiteOffsetY = vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) > 0).spinPlotYOffset);
    app.vd.whiteVectorX = 14*cosd(vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) > 0).spinAngle));
    app.vd.whiteVectorY = 14*sind(vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) > 0).spinAngle));
    app.vd.blackOffsetX = vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) < 0).spinPlotXOffset);
    app.vd.blackOffsetY = vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) < 0).spinPlotYOffset);
    app.vd.blackVectorX = 14*cosd(vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) < 0).spinAngle));
    app.vd.blackVectorY = 14*sind(vertcat(app.vd.magnet(vertcat(app.vd.magnet.projection) < 0).spinAngle));
    nullMags = find(vertcat(app.vd.magnet.projection)==0 & vertcat(app.vd.magnet.domainState) == "Ising");
    OWIBMags = find(vertcat(app.vd.magnet.domainState) == "OWIB");
    OBIWMags = find(vertcat(app.vd.magnet.domainState) == "OBIW");
    TWBBMags = find(vertcat(app.vd.magnet.domainState) == "TWBB");
    TBBWMags = find(vertcat(app.vd.magnet.domainState) == "TBBW");
    hold(axisFrame,'on');
    quiver(axisFrame,app.vd.whiteOffsetX,app.vd.whiteOffsetY,app.vd.whiteVectorX,app.vd.whiteVectorY,'b',...
        'AutoScale','off','LineWidth',1);
    quiver(axisFrame,app.vd.blackOffsetX,app.vd.blackOffsetY,app.vd.blackVectorX,app.vd.blackVectorY,'r',...
        'AutoScale','off','LineWidth',1);
    plot(axisFrame,vertcat(app.vd.magnet(nullMags).colXPos),vertcat(app.vd.magnet(nullMags).rowYPos),'m^','MarkerSize',7,'LineWidth',1);
    plot(axisFrame,vertcat(app.vd.magnet(OWIBMags).colXPos),vertcat(app.vd.magnet(OWIBMags).rowYPos),'rs','MarkerSize',7,'LineWidth',1);
    plot(axisFrame,vertcat(app.vd.magnet(OBIWMags).colXPos),vertcat(app.vd.magnet(OBIWMags).rowYPos),'bs','MarkerSize',7,'LineWidth',1);
    plot(axisFrame,vertcat(app.vd.magnet(TWBBMags).colXPos),vertcat(app.vd.magnet(TWBBMags).rowYPos),'ro','MarkerSize',7,'LineWidth',1);
    plot(axisFrame,vertcat(app.vd.magnet(TBBWMags).colXPos),vertcat(app.vd.magnet(TBBWMags).rowYPos),'bo','MarkerSize',7,'LineWidth',1);
    switch latticeOption
        case 'on'
            for j = 1:length(app.vd.magnet)
                xText = app.vd.magnet(j).colXPos;
                yText = app.vd.magnet(j).rowYPos;
                a = round(app.vd.magnet(j).xR);
                b = round(app.vd.magnet(j).yR);
                text(xText,yText,sprintf('(%i,%i)',a,b),'FontSize',3,'Color','green');
            end
    end
    hold(axisFrame,'off');
end