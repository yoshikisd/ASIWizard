% Compare the lengths of the different magnet structures used in the analysis
% First, compare the lengths of the magnet structures in each of the imported files
A = struct('data',[]);
A(1).data = Ref2;
A(2).data = Ref1;
A(3).data = Ref3;
% Create vector containing the lengths of each magnet structure
magLengths = zeros(length(A),1);
% Fill magLengths with lengths of each magnet
for i = 1:length(A)
    magLengths(i) = length(A(i).data.magnet);
end
% Find which magnet structure is the smallest (sM)
sM = find(magLengths == min(magLengths));
% Use the smallest magnet to make comparisons against
% Save the lattice coordinates as a 2xn vector
% This list will be updated to contain only the values that are common to ALL the imported data
coordinates = [vertcat(A(sM).data.magnet.xR),vertcat(A(sM).data.magnet.yR)];
% Start making comparisons against the other imported data. Reduce the size of coordinates to contain only
% coordinates that are present in all imported magnets
for i = 1:length(A)
    if i ~= sM
        coordinatesI = [vertcat(A(i).data.magnet.xR),vertcat(A(i).data.magnet.yR)];
        % Remove any elements that are not present in both arrays
        coordinates(~ismember(coordinates, coordinatesI,'rows'),:) = [];
    end
end
% Delete all magnet entries whose positions are not listed in "coordinates"
for i = 1:length(A)
    coordinatesI = [vertcat(A(i).data.magnet.xR),vertcat(A(i).data.magnet.yR)];
    A(i).data.magnet(~ismember(coordinatesI,coordinates,'rows'))=[];
    % Sort the x and y lattice coordinates
    coordinatesI = [vertcat(A(i).data.magnet.xR),vertcat(A(i).data.magnet.yR)];
    [~,idx] = sortrows(coordinatesI,[1,2]);
    A(i).data.magnet(:) = A(i).data.magnet(idx);
end
%% Register the images based on the positions of the magnet entries
% All sorting (and thus fixed points) are based off of first acquired image
fp = [vertcat(A(1).data.magnet.colXPos),vertcat(A(1).data.magnet.rowYPos)];
Rfixed = imref2d(size(A(1).data.xasGrid(:,:,1)));
for i = 2:length(A)
    % Moving points defined as the image to be observed
    mp = [vertcat(A(i).data.magnet.colXPos),vertcat(A(i).data.magnet.rowYPos)];
    
end

%{
imagesc(A(3).data.xasGrid(:,:,1))
f = figure('visible','on');
ax1 = axes(f,'Position',[0,0,1,1],'Visible','off');
hold(ax1,'on');
imagesc(ax1,A(1).data.xasGrid(:,:,1));
%imshow(mat2gray(app.vd.xasGrid(:,:,1)),'Parent',ax1);
axis(ax1,'image');
for magIdx = 1:length(A(1).data.magnet)
    x = A(1).data.magnet(magIdx).colXPos;
    y = A(1).data.magnet(magIdx).rowYPos;
    a = A(1).data.magnet(magIdx).aInd;
    b = A(1).data.magnet(magIdx).bInd;
    plot(ax1,x,y,'r.','MarkerSize',20);
    text(ax1,x,y,sprintf('(%i,%i)',a,b),'FontSize',7,'Color','green');
end
hold(ax1,'off');

%}
tform = fitgeotrans(fp,mp,'polynomial',3);
B = imwarp(A(2).data.xasOld(:,:,1),tform);
imshowpair(A(1).data.xasOld(:,:,1),B);