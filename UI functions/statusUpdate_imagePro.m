% Update the status window in the vertex detection wizard tab
function statusUpdate_imagePro(app,str)
    app.MsgImgProcess.Value = [sprintf('%s > %s',datestr(now,'HH:MM:SS'),str);app.MsgImgProcess.Value];
end