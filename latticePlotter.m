function latticePlotter(magnet)
    % Takes the lattice coordinate data and plots a position-corrected quiver plot
    figure();
    % Create four vectors containing indices of different x- and y combinations of x and y spin
    xPos = vertcat(magnet.xSpin) > 0;
    xNeg = vertcat(magnet.xSpin) < 0;
    yPos = vertcat(magnet.ySpin) > 0;
    yNeg = vertcat(magnet.ySpin) < 0;
    % Combine the four vectors into a nx4 matrix
    posIdx = [xPos,xNeg,yPos,yNeg];
    % Create offset vectors
    xOffset = 1/2*[-1,1,0,0];
    yOffset = 1/2*[0,0,-1,1];
    
    hold on;
    for i = 1:4
        % Introduce appropriate x and y offsets to the quiver spins based on the value of xSpin and ySpin
        posI = find(posIdx(:,i));
        if ~isempty(posI)
            quiver(vertcat(magnet(posI).xR)+xOffset(i),...
                vertcat(magnet(posI).yR)+yOffset(i),...
                vertcat(magnet(posI).xSpin),...
                vertcat(magnet(posI).ySpin),'AutoScale','off');
            plot(vertcat(magnet(posI).xR),vertcat(magnet(posI).yR),'r.');
            for j = 1:length(posI)
                xText = magnet(posI(j)).xR;
                yText = magnet(posI(j)).yR;
                a = round(magnet(posI(j)).xR);
                b = round(magnet(posI(j)).yR);
                text(xText,yText,sprintf('(%i,%i)',a,b),'FontSize',7,'Color','green');
            end
        end
    end
end