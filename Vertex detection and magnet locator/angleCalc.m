% Calculates the relative angle a magnet makes in relation to another magnet
function relativeAngle = angleCalc(app, refVertexStart, refVertexEnd, originVertex, projectVertex)
    vectorReference = [app.vd.vertex(refVertexEnd).colXPos - app.vd.vertex(refVertexStart).colXPos, ...
        app.vd.vertex(refVertexEnd).rowYPos - app.vd.vertex(refVertexStart).rowYPos, 0];

    vectorProject = [app.vd.vertex(projectVertex).colXPos - app.vd.vertex(originVertex).colXPos,...
        app.vd.vertex(projectVertex).rowYPos - app.vd.vertex(originVertex).rowYPos, 0];

    vectorCross = cross(vectorReference,vectorProject);

    if vectorCross(3) < 0
        relativeAngle = -atan2d(norm(vectorCross), dot(vectorReference,vectorProject));
    else
        relativeAngle = atan2d(norm(vectorCross), dot(vectorReference,vectorProject));
    end
end