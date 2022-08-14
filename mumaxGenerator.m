% Generates mumax scripts from ASI data
function mumaxGenerator(type,xR,yR,xSpin,ySpin,domainState,Aex,Msat,a,l,w,h,boxSize,texture,directory,fileName)
    arguments
        type {mustBeMember(type,['Brickwork','Square','Kagome'])}
        xR (:,1) double         % Vector containing x position of position vector
        yR (:,1) double         % Vector containing y position of position vector
        xSpin (:,1) double      % Vector containing x component of spin vector
        ySpin (:,1) double      % Vector containing y component of spin vector
        domainState             % String vector containing information about domain state
        Aex (1,1) double        % Exchange energy in pJ/m
        Msat (1,1) double       % Saturation magnetization in A/m
        a (1,1) double          % Lattice parameter in nm
        l (1,1) double          % Nanoisland length in nm
        w (1,1) double          % Nanoisland width in nm
        h (1,1) double          % Nanoisland height in nm
        boxSize (1,1) double    % Total size of simulation box in nm
        texture {mustBeMember(texture,{'ising','arbitrary','Type I','NE','NW','SE','SW','OWIB','OBIW','TWBB','TBBW'})}
        directory string        % Path to save file
        fileName string         % File name
    end
    % Initially multiply xR and yR by 2. This has to do with how the lattice parameter is defined in
    % IceScanner vs ASIWizard; The ASI lattice parameter in IceScanner is defined as the Island-to-vertex distance
    % while in ASIWizard its defined as the island-to-island distance
    xR = xR*2;
    yR = yR*2;
    % Write script
    mumaxScript(1,1)     = {sprintf('OutputFormat = OVF1_TEXT;')};
    mumaxScript(end+1,1) = {sprintf('Aex = %fe-12;',Aex)};
    mumaxScript(end+1,1) = {sprintf('Msat = %f;',Msat)};
    mumaxScript(end+1,1) = {sprintf('a := %fe-9;',a)};
    mumaxScript(end+1,1) = {sprintf('l := %fe-9;',l)};
    mumaxScript(end+1,1) = {sprintf('w := %fe-9;',w)};
    mumaxScript(end+1,1) = {sprintf('h := %fe-9;',h)};
    % Define the nanoisland
    mumaxScript(end+1,1) = {'island := cylinder(w,h).transl(-(l-w)/2,0,0).add(cylinder(w,h).transl((l-w)/2,0,0)).add(cuboid(l-w,w,h));'};
    % Determine the bounding box size
    ySpan = (max(yR)-min(yR));
    xSpan = (max(xR)-min(xR));
    maxSpan = (max([xSpan,ySpan])/2+2)*a;
    % Shift the x and y positions to be centered
    yR_True = yR - min(yR) - ySpan/2;
    xR_True = xR - min(xR) - xSpan/2;
    % Convert the xR and yR positions to normalized to "true" positions in nm
    yR_True = yR_True/2*a;
    xR_True = xR_True/2*a;
    % Set sim box, save miniature m ovf
    mumaxScript(end+1,1) = {sprintf('Cz := %fe-9;',h)};
    mumaxScript(end+1,1) = {sprintf('Nz := 1;')};
    mumaxScript(end+1,1) = {sprintf('Nx := %d;',boxSize)};
    mumaxScript(end+1,1) = {sprintf('Cx_Sum := %fe-9;',maxSpan)};
    mumaxScript(end+1,1) = {sprintf('Cx := Cx_Sum/Nx;')};
    mumaxScript(end+1,1) = {sprintf('setmesh(Nx,Nx,Nz,Cx,Cx,Cz,0,0,0);')};
    % Set up the ASI: Fabricate all the geometries
    constructASI;
    mumaxScript(end+1,1) = {sprintf('setgeom(asi);')};
    % Define chkIsland
    mumaxScript(end+1,1) = {sprintf('chkIsland := island;')};
    mumaxScript(end+1,1) = {sprintf('Half1 := cuboid(l/2,l/2,h).transl(-l/4,0,0);')};
    mumaxScript(end+1,1) = {sprintf('Half2 := cuboid(l/2,l/2,h).transl(l/4,0,0);')};
    mumaxScript(end+1,1) = {sprintf('chkIsland_Half1 := Half1;')};
    mumaxScript(end+1,1) = {sprintf('chkIsland_Half2 := Half2;')};
    % Set up the ASI: Set magnetizations
    k = 1;
    
    for i = 1:length(xR)
        switch type
            case {'Brickwork','Square'}
                % Employ selection rules for nanoisland orientations in square-type systems
                if mod(round(xR(i)),2) == 0 && mod(round(yR(i)),2) == 0
                    rot = 'pi/2';
                elseif mod(round(xR(i)),2) == 1 && mod(round(yR(i)),2) == 1
                    rot = '0';
                end
        end
        % Define magnetization based on domain state
        switch texture
            case 'ising'
                switch domainState(i)
                    case 'Ising'; appendIsing(i,'true',rot); end
            case 'arbitrary'
                switch domainState(i)
                    case 'Ising'; appendIsing(i,'true',rot);
                        if k == 1
                            mumaxScript(end+1,1) = {sprintf('isingSet := chkIsland;')};
                            k = k+1;
                        else
                            mumaxScript(end+1,1) = {sprintf('isingSet = isingSet.add(chkIsland);')};
                        end
                    case 'TWBB'; appendTWBB(i);
                    case 'TBBW'; appendTBBW(i);
                    case 'OWIB'; appendOWIB(i);
                    case 'OBIW'; appendOBIW(i);
                end
            case 'OWIB'; appendOWIB(i);
            case 'OBIW'; appendOBIW(i);
            case 'TWBB'; appendTWBB(i);
            case 'TBBW'; appendTBBW(i);
            case {'NE','NW','SW','SE'}; appendIsing(i,texture,rot);
        end
    end

    % Freeze Ising spins
    
    switch texture
        case {'arbitrary','OWIB','OBIW','TWBB','TBBW'}
            if k ~= 1 % This value only changes if an ising state is present
                mumaxScript(end+1,1) = {sprintf('defregion(1,isingSet);')};
                mumaxScript(end+1,1) = {sprintf('frozenspins.SetRegion(1,1);')};
            end
            mumaxScript(end+1,1) = {sprintf('relax();')}; 
    end
    %mumaxScript(end+1,1) = {sprintf('saveas(m,"%s\\%s");',directory,fileName)}; % windows
    mumaxScript(end+1,1) = {sprintf('saveas(m,"%s");',fileName)}; % linux
    mumaxScript(end+1,1) = {sprintf('snapshot(m);')};
    %fid = fopen(sprintf('%s/%s.txt',directory,fileName),'w');
    fid = fopen(sprintf('%s/%s.txt',directory,fileName),'w');
    fprintf(fid,'%s\n',mumaxScript{:});
    fclose(fid);

    % Function dungeon
    % Construct ASI geometry
    function constructASI
        switch type
            case {'Brickwork','Square'}
                switch texture
                    case 'ising'
                        ctr = 1;
                        for r = 1:length(xR)
                            switch domainState(r)
                                case 'Ising'
                                    % Employ ASI selection rules for square systems
                                    if mod(round(xR(r)),2) == 0 && mod(round(yR(r)),2) == 0
                                        rot = 'pi/2';
                                    elseif mod(round(xR(r)),2) == 1 && mod(round(yR(r)),2) == 1
                                        rot = '0';
                                    end
                                    if ctr == 1
                                        mumaxScript(end+1,1) = {sprintf('asi := island.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(r),yR_True(r))};
                                        ctr = ctr + 1;
                                    else
                                        mumaxScript(end+1,1) = {sprintf('asi = asi.add(island.rotz(%s).transl(%fe-9,%fe-9,0));',rot,xR_True(r),yR_True(r))};
                                    end
                            end
                        end
                    otherwise
                        for r = 1:length(xR)
                            % Employ ASI selection rules for square systems
                            if mod(round(xR(r)),2) == 0 && mod(round(yR(r)),2) == 0
                                rot = 'pi/2';
                            elseif mod(round(xR(r)),2) == 1 && mod(round(yR(r)),2) == 1
                                rot = '0';
                            end
                            if r == 1
                                mumaxScript(end+1,1) = {sprintf('asi := island.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(r),yR_True(r))};
                            else
                                mumaxScript(end+1,1) = {sprintf('asi = asi.add(island.rotz(%s).transl(%fe-9,%fe-9,0));',rot,xR_True(r),yR_True(r))};
                            end
                        end
                end
        end
    end
    % Append Ising domain in mumax script
    function appendIsing(i,spinOrient,rot)
        mumaxScript(end+1,1) = {sprintf('chkIsland = island.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        switch spinOrient
            case 'true'
                mumaxScript(end+1,1) = {sprintf('m.setInShape(chkIsland,uniform(%f,%f,0));',xSpin(i),ySpin(i))};
            otherwise
                xSpinI = 0; ySpinI = 0;
                % Eventually you should clean up this nested switch rats nest below...
                switch rot
                    case 'pi/2'
                        switch spinOrient
                            case {'NW','NE'}; ySpinI = 1;
                            case {'SW','SE'}; ySpinI = -1;
                        end
                    case '0'
                        switch spinOrient
                            case {'NW','SW'}; xSpinI = -1;
                            case {'NE','SE'}; xSpinI = 1;
                        end
                end
                mumaxScript(end+1,1) = {sprintf('m.setInShape(chkIsland,uniform(%f,%f,0));',xSpinI,ySpinI)};
        end
    end
    % Append TWBB domain in mumax script
    function appendTWBB(i)
        mumaxScript(end+1,1) = {sprintf('chkIsland = island.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        mumaxScript(end+1,1) = ...
            {sprintf('m.setInShape(chkIsland,vortex(-1,0).rotz(%s).transl(%fe-9,%fe-9,0));',rot,xR_True(i),yR_True(i))};
    end
    % Append TBBW domain in mumax script
    function appendTBBW(i)
        mumaxScript(end+1,1) = {sprintf('chkIsland = island.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        mumaxScript(end+1,1) = ...
            {sprintf('m.setInShape(chkIsland,vortex(1,0).rotz(%s).transl(%fe-9,%fe-9,0));',rot,xR_True(i),yR_True(i))};
    end
    % Append OWIB domain in mumax script
    function appendOWIB(i)
        mumaxScript(end+1,1) = {sprintf('chkIsland_Half1 = Half1.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        mumaxScript(end+1,1) = {sprintf('chkIsland_Half2 = Half2.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        if mod(round(xR(i)),2) == 0 && mod(round(yR(i)),2) == 0
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half1,vortex(1,0).transl(%fe-9,%fe-9-(l/4),0));',xR_True(i),yR_True(i))};
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half2,vortex(-1,0).transl(%fe-9,%fe-9+(l/4),0));',xR_True(i),yR_True(i))};
        elseif mod(round(xR(i)),2) == 1 && mod(round(yR(i)),2) == 1
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half1,vortex(1,0).transl(%fe-9-(l/4),%fe-9,0));',xR_True(i),yR_True(i))};
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half2,vortex(-1,0).transl(%fe-9+(l/4),%fe-9,0));',xR_True(i),yR_True(i))};
        end
    end
    % Append OBIW domain in mumax script
    function appendOBIW(i)
        mumaxScript(end+1,1) = {sprintf('chkIsland_Half1 = Half1.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        mumaxScript(end+1,1) = {sprintf('chkIsland_Half2 = Half2.rotz(%s).transl(%fe-9,%fe-9,0);',rot,xR_True(i),yR_True(i))};
        if mod(round(xR(i)),2) == 0 && mod(round(yR(i)),2) == 0
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half1,vortex(-1,0).transl(%fe-9,%fe-9-(l/4),0));',xR_True(i),yR_True(i))};
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half2,vortex(1,0).transl(%fe-9,%fe-9+(l/4),0));',xR_True(i),yR_True(i))};
        elseif mod(round(xR(i)),2) == 1 && mod(round(yR(i)),2) == 1
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half1,vortex(-1,0).transl(%fe-9-(l/4),%fe-9,0));',xR_True(i),yR_True(i))};
            mumaxScript(end+1,1) = ...
                {sprintf('m.setInShape(chkIsland_Half2,vortex(1,0).transl(%fe-9+(l/4),%fe-9,0));',xR_True(i),yR_True(i))};
        end
    end
end