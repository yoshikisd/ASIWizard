% Update the status window in the vertex detection wizard tab
function statusUpdate_vertexDetect(app,str)
    app.MsgVertexDetect.Value = [sprintf('%s > %s',datestr(now,'HH:MM:SS'),str);app.MsgVertexDetect.Value];
end