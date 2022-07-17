% Plots vertex types over an image
function overlayVertexType(app,axisFrame)
    % Then extract the positions associated with the different vertex types
    typeList = vertcat(app.vd.vertex.type);
    indType0 = find(isnan(typeList));
    indType1 = find(typeList == 1);
    indType2 = find(typeList == 2);
    indType3 = find(typeList == 3);
    indType4 = find(typeList == 4);

    type0Pos = [vertcat(app.vd.vertex(indType0).colXPos),vertcat(app.vd.vertex(indType0).rowYPos)];
    type1Pos = [vertcat(app.vd.vertex(indType1).colXPos),vertcat(app.vd.vertex(indType1).rowYPos)];
    type2Pos = [vertcat(app.vd.vertex(indType2).colXPos),vertcat(app.vd.vertex(indType2).rowYPos)];
    type3Pos = [vertcat(app.vd.vertex(indType3).colXPos),vertcat(app.vd.vertex(indType3).rowYPos)];
    type4Pos = [vertcat(app.vd.vertex(indType4).colXPos),vertcat(app.vd.vertex(indType4).rowYPos)];

    hold(axisFrame,'on');
    if ~isempty(type0Pos) plot(axisFrame,type0Pos(:,1),type0Pos(:,2),'mx','MarkerSize',5); end
    if ~isempty(type1Pos) plot(axisFrame,type1Pos(:,1),type1Pos(:,2),'r.','MarkerSize',15); end
    if ~isempty(type2Pos) plot(axisFrame,type2Pos(:,1),type2Pos(:,2),'bo','MarkerSize',5); end
    if ~isempty(type3Pos) plot(axisFrame,type3Pos(:,1),type3Pos(:,2),'g^','MarkerSize',5); end
    if ~isempty(type4Pos) plot(axisFrame,type4Pos(:,1),type4Pos(:,2),'cd','MarkerSize',5); end
    hold(axisFrame,'off');
end