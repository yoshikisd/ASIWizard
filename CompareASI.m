classdef CompareASI < matlab.mixin.Copyable % Allows to create copies of handle objects
    % Object to store and compare ("cf.") sequences of ASIWizard-generated datasets
    properties
        asi    % (1D struct) Stores the ASI data structures ("vd" in IceWizard)
    end
    
    methods
        function obj = CompareASI(dataASI)      % Construct CompareASI object. Requires the first dataset dataASI
            obj.asi = filterData(dataASI);
        end
        
        function obj = addData(obj,dataASI)     % Adds a new dataset to the CompareASI object
            obj.asi(end+1) = filterData(dataASI);
        end

        function obj = deleteData(obj,idx)      % Deletes a dataset with index "idx"
            obj.asi(idx) = [];
        end

        function l = numel(obj)                 % Returns the number of datasets currently in the object
            l = length(obj.asi);
        end

        function obj = alignDatasets(obj)       % Aligns the images in the ASI
            % First, compare the number of detected magnets in each ASI dataset
            % Create vector containing the lengths of each magnet structure
            l = length(obj.asi); magLengths = zeros(l,1);
            % Fill magLengths with lengths of each magnet
            for i = 1:l
                magLengths(i) = length(obj.asi(i).magnet);
            end
            % Determine smallest magnet structure (idxSmallest). Save associated lattice points in "coordinates"
            % If there are more than 1 entry in idxSmallest, select the smallest of the indices
            idxSmallest = find(magLengths == min(magLengths),1); 
            coordinates = [vertcat(obj.asi(idxSmallest).magnet.xR),vertcat(obj.asi(idxSmallest).magnet.yR)];
            % Reduce "coordinates" to contain only those lattice points present in all the datasets
            for i = 1:l
                if i ~= idxSmallest
                    coordinatesI = [vertcat(obj.asi(i).magnet.xR),vertcat(obj.asi(i).magnet.yR)];
                    % Remove any elements that are not present in both arrays
                    coordinates(~ismember(coordinates, coordinatesI,'rows'),:) = [];
                end
            end
            % Delete all magnet entries in each dataset whose positions are not listed in "coordinates"
            for i = 1:l
                coordinatesI = [vertcat(obj.asi(i).magnet.xR),vertcat(obj.asi(i).magnet.yR)];
                obj.asi(i).magnet(~ismember(coordinatesI,coordinates,'rows'))=[];
                % Sort the x and y lattice coordinates
                coordinatesI = [vertcat(obj.asi(i).magnet.xR),vertcat(obj.asi(i).magnet.yR)];
                [~,idx] = sortrows(coordinatesI,[1,2]);
                obj.asi(i).magnet(:) = obj.asi(i).magnet(idx);
            end
            % align the images of each dataset together using image registration
            % Technique: Geometric transform using ASIWizard-detected positions as control points
            % All sorting (and thus fixed points, fp) are based off of first acquired image
            fp = [vertcat(obj.asi(1).magnet.colXPos),vertcat(obj.asi(1).magnet.rowYPos)];
            RFixed = imref2d(size(obj.asi(1).xasGrid));
            % For the experimental magnetic contrast, subtract by the background level, "bl"
            bl = obj.asi(1).background.mean;
            % For the 1st image, just copy all the relevant images into the align substructure
            obj.asi(1).align.xas = obj.asi(1).xasGrid;
            obj.asi(1).align.xmcd = obj.asi(1).xmcd - bl;
            obj.asi(1).align.xmcdBoost = obj.asi(1).xmcdBoost - bl;
            obj.asi(1).align.xmcdTrinary = obj.asi(1).xmcdTrinary;
            obj.asi(1).align.xmcdCorrectedTrinary = obj.asi(1).xmcdCorrectedTrinary;
            obj.asi(1).align.xmcdTrinarySkeleton = obj.asi(1).xmcdTrinarySkeleton;
            obj.asi(1).align.xmcdBoostSkeleton = obj.asi(1).xmcdBoostSkeleton;
            obj.asi(1).align.xmcdOriginalSkeleton = obj.asi(1).xmcdOriginalSkeleton;
            % Define zeroMask to use in automated cropping later.
            %zeroMask = obj.asi(1).align.xas;
            for i = 2:l
                % Subtract background level, bl, from unprocessed images
                bl = obj.asi(i).background.mean;
                % Moving points defined as the image to be observed
                mp = [vertcat(obj.asi(i).magnet.colXPos),vertcat(obj.asi(i).magnet.rowYPos)];
                % Introduce a new transform object into asi
                obj.asi(i).align.tform = fitgeotrans(mp,fp,'polynomial',3);
                % Warp the image
                [obj.asi(i).align.xas, obj.asi(i).align.R] = imwarp(obj.asi(i).xasGrid,obj.asi(i).align.tform,'OutputView',RFixed);
                obj.asi(i).align.xmcd = imwarp(obj.asi(i).xmcd,obj.asi(i).align.tform,'OutputView',RFixed) - bl;
                obj.asi(i).align.xmcdBoost = imwarp(obj.asi(i).xmcdBoost,obj.asi(i).align.tform,'OutputView',RFixed) - bl;
                obj.asi(i).align.xmcdTrinary = imwarp(obj.asi(i).xmcdTrinary,obj.asi(i).align.tform,'OutputView',RFixed);
                obj.asi(i).align.xmcdCorrectedTrinary = imwarp(obj.asi(i).xmcdCorrectedTrinary,obj.asi(i).align.tform,'OutputView',RFixed);
                obj.asi(i).align.xmcdTrinarySkeleton = imwarp(obj.asi(i).xmcdTrinarySkeleton,obj.asi(i).align.tform,'OutputView',RFixed);
                obj.asi(i).align.xmcdBoostSkeleton = imwarp(obj.asi(i).xmcdBoostSkeleton,obj.asi(i).align.tform,'OutputView',RFixed);
                obj.asi(i).align.xmcdOriginalSkeleton = imwarp(obj.asi(i).xmcdOriginalSkeleton,obj.asi(i).align.tform,'OutputView',RFixed);
                % Update zeroMask
                %zeroMask = zeroMask.* obj.asi(i).align.xas;
            end
        end

        function obj = calcMSF(obj,app,steps,qMax)  % Calculates the MSFs of each ASI
            l = length(obj.asi);
            for i = 1:l
                [obj.asi(i).MSF.matrix,obj.asi(i).MSF.table] = generateMSF(app,...
                    steps,qMax,vertcat(obj.asi(i).magnet.xSpin),vertcat(obj.asi(i).magnet.ySpin),...
                    vertcat(obj.asi(i).magnet.xR),vertcat(obj.asi(i).magnet.yR),'half','asi');
            end
        end
    end
end


%% Local function dungeon
function data = filterData(rawData)   % Keeps only certain items from imported data  
    data = struct('xasGrid',rawData.xasGrid(:,:,1),...
        'typeASI',rawData.typeASI,...
        'magnet',rawData.magnet,...
        'vertex',rawData.vertex,...
        'xmcd',rawData.xmcd,...
        'xmcdBoost',rawData.xmcdBoost,...
        'xmcdTrinary',rawData.xmcdTrinary,...
        'xmcdCorrectedTrinary',rawData.xmcdCorrectedTrinary,...
        'xmcdTrinarySkeleton',rawData.xmcdTrinarySkeleton,...
        'xmcdBoostSkeleton',rawData.xmcdBoostSkeleton,...
        'xmcdOriginalSkeleton',rawData.xmcdOriginalSkeleton,...
        'magnetInterpretCombinedImg',rawData.magnetInterpretCombinedImg,...
        'whiteOffsetX',rawData.whiteOffsetX,...
        'whiteOffsetY',rawData.whiteOffsetY,...
        'whiteVectorX',rawData.whiteVectorX,...
        'whiteVectorY',rawData.whiteVectorY,...
        'blackOffsetX',rawData.blackOffsetX,...
        'blackOffsetY',rawData.blackOffsetY,...
        'blackVectorX',rawData.blackVectorX,...
        'blackVectorY',rawData.blackVectorY,...
        'background',rawData.background);
end