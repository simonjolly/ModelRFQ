function comsolModel = setSelections(comsolModel, selectionNames, endFlangeThickness, inputParameters)
%
% function comsolModel = setSelections(comsolModel, selectionNames, endFlangeThickness, inputParameters)
%
%   SETSELECTIONS.M - set selections for domains within RFQ vane tip model in Comsol.
%
%   setSelections(comsolModel, selectionNames)
%   setSelections(comsolModel, selectionNames, endFlangeThickness)
%   setSelections(comsolModel, selectionNames, endFlangeThickness, inputParameters)
%
%   comsolModel = setSelections(...)
%
%   setSelections searches for the correct domain number for the various
%   domains within the Comsol model and sets the various selections within
%   the model - which govern both the meshing and the electrostatics -
%   using these domain numbers.  At least 9 domains are expected within the
%   model: the 3 inner beam boxes (front, mid and rear), the outer beam
%   box, the air bag, the X vane tip, the X vane back, the Y vane tip and
%   the Y vane back.  In addition, domains fitting the criteria for the end
%   flange are also included (normally 2 domains).  If the end flange is
%   found, setSelections also switches on the ground surface within the
%   electrostatics.
%
%   setSelections(comsolModel, selectionNames) - set selections within the
%   Comsol model COMSOLMODEL using the names defined by the structure array
%   SELECTIONNAMES.  The default values of the selections within
%   selectionNames are:
%
%       selectionNames.allVanes = 'sel1';
%       selectionNames.horizontalVanes = 'sel2';
%       selectionNames.verticalVanes = 'sel3';
%       selectionNames.allTerminals = 'sel4';
%       selectionNames.horizontalTerminals = 'sel5';
%       selectionNames.verticalTerminals = 'sel6';
%       selectionNames.airVolumes = 'sel7';
%       selectionNames.innerBeamBox = 'sel8';
%       selectionNames.innerBeamBoxFront = 'sel9';
%       selectionNames.innerBeamBoxMid = 'sel10';
%       selectionNames.innerBeamBoxRear = 'sel11';
%       selectionNames.innerBeamBoxBoundaries = 'sel12';
%       selectionNames.innerBeamBoxFrontFace = 'sel13';
%       selectionNames.innerBeamBoxRearFace = 'sel14';
%       selectionNames.outerBeamBox = 'sel15';
%       selectionNames.airBag = 'sel16';
%       selectionNames.airBagBoundaries = 'sel17';
%       selectionNames.innerBeamBoxFrontEdges = 'sel18';
%       selectionNames.innerBeamBoxLeadingFaces = 'sel19';
%       selectionNames.innerBeamBoxLeadingEdges = 'sel20';
%       selectionNames.beamBoxes = 'sel21';
%       selectionNames.endFlangeGrounded = 'sel22';
%
%   setSelections(comsolModel, selectionNames, endFlangeThickness) -
%   specify the thickness of the End Flange wall opposite the vane tips, in
%   metres. This does not have to be specified: the default value is 20 mm.
%
%   setSelections(comsolModel, selectionNames, endFlangeThickness, inputParameters)
%   - also specify parameters to be passed to logMessage for information
%   logging and display, produced by getModelParameters.
%
%   [comsolModel] = setSelections(...) - outputs the Comsol model object as
%   COMSOLMODEL.
%
%   See also buildCell, buildComsolModel, modelRfq, getModelParameters,
%   buildCell, logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Feb-2011 M. J. Easton
%       Split buildComsolModel into subroutines to allow unit testing of 
%       separate parts.
%
%   24-Jun-2011 S. Jolly
%       Large code overhaul, including finding domains with mphgetcoords,
%       increasing the error checking, reading out variables from the
%       Comsol Model itself rather than passing them as input variables and
%       adding help documentation.
%
%   22-Dec-2011 S. Jolly
%       Added capability to set selections for 4-quadrant models.  Wrapped
%       end flange electrostatic selection in try/catch block in case its
%       called during model setup when electrostatics doesn't exist.
%
%=======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    if nargin < 4 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
    else % store parameters
        parameters = inputParameters ;
    end
    if nargin < 3 || isempty(endFlangeThickness)
        endFlangeThickness = 20e-3 ;
    end

    try %to test syntax
        if nargin < 2 %then throw error ModelRFQ:ComsolInterface:setSelections:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:insufficientInputArguments', ...
                  ['Too few input variables: syntax is comsolModel = setSelections(comsolModel, selectionNames)']) ;
        end
        if nargin > 4 %then throw error ModelRFQ:ComsolInterface:setSelections:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:excessiveInputArguments', ...
                  ['Too many input variables: syntax is comsolModel = setSelections(comsolModel, selectionNames, endFlangeThickness, inputParameters)']) ;
        end
%        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:setSelections:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:setSelections:insufficientOutputArguments', ...
%                  ['Too few output variables: syntax is comsolModel = setSelections(comsolModel, selectionNames)']) ;
%        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:setSelections:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:excessiveOutputArguments', ...
                  ['Too many output variables: syntax is comsolModel = setSelections(comsolModel, selectionNames, endFlangeThickness, inputParameters)']) ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:syntaxException';
        message.text = 'Syntax error calling buildCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

%% Set up variables

    dispDomains = false ;
    fourQuad = false ;

    ibbfgood = false ; ibbmgood = false ; ibbbgood = false ;
    ibbgood = false ; obbgood = false ; abgood = false ;
    xvtgood = false ; xvbgood = false ; yvtgood = false ; yvbgood = false ;
    xvtngood = false ; xvbngood = false ; yvtngood = false ; yvbngood = false ;
    ffbibbgood = false ; sfbibbgood = false ; tfbibbgood = false ; rfbibbgood = false ;
    efgood = false ;

    innerBeamBoxFrontDomainNo = [] ; innerBeamBoxMidDomainNo = [] ; innerBeamBoxBackDomainNo = [] ;
    innerBeamBoxDomainNo = [] ; outerBeamBoxDomainNo = [] ; airbagDomainNo = [] ;
    yVaneTipDomainNo = [] ; yVaneBackDomainNo = [] ; xVaneTipDomainNo = [] ; xVaneBackDomainNo = [] ;
    yVaneTipNegDomainNo = [] ; yVaneBackNegDomainNo = [] ; xVaneTipNegDomainNo = [] ; xVaneBackNegDomainNo = [] ;
    endFlangeDomainNo = [] ;

    innerBeamBoxFrontFaceBoundary = [] ;
    innerBeamBoxSecondFaceBoundary = [] ;
    innerBeamBoxThirdFaceBoundary = [] ;
    innerBeamBoxRearFaceBoundary = [] ;
    innerBeamBoxLeadingFaces = [] ;

%% Read out variables from Comsol model

    try % to read out variable data from Comsol model

        modelBoundBox = comsolModel.geom('geom1').getBoundingBox ;
        minX = modelBoundBox(1) ;
        maxX = modelBoundBox(2) ;
        minY = modelBoundBox(3) ;
        maxY = modelBoundBox(4) ;
        if ( abs(minX) > ( maxX./2) ) && ( abs(minY) > ( maxY./2) )
            fourQuad = true ;
            if dispDomains
                disp(' ') ;
                disp('Vane model is a 4-quadrant model') ;
                disp(' ') ;
            end
        end

        numDomains = comsolModel.geom('geom1').getNDomains ;

        r0Str = comsolModel.param.get('r0') ;
        metrepos = strfind(r0Str,'[m]') ;
        if isempty(metrepos)
            millimetrepos = strfind(r0Str,'[mm]') ;
            r0 = str2num(r0Str(1:millimetrepos-1)).*1e-3 ;
        else
            r0 = str2num(r0Str(1:metrepos-1)) ;
        end

        rhoStr = comsolModel.param.get('rho') ;
        metrepos = strfind(rhoStr,'[m]') ;
        if isempty(metrepos)
            millimetrepos = strfind(rhoStr,'[mm]') ;
            rho = str2num(rhoStr(1:millimetrepos-1)).*1e-3 ;
        else
            rho = str2num(rhoStr(1:metrepos-1)) ;
        end

        boxWidthStr = comsolModel.param.get('boxWidth') ;
        metrepos = strfind(boxWidthStr,'[') ;
        boxWidth = str2num(boxWidthStr(1:metrepos-1)) ;

        beamBoxWidthStr = comsolModel.param.get('beamBoxWidth') ;
        metrepos = strfind(beamBoxWidthStr,'[') ;
        beamBoxWidth = str2num(beamBoxWidthStr(1:metrepos-1)) ;

        cellStartStr = comsolModel.param.get('cellStart') ;
        metrepos = strfind(cellStartStr,'[') ;
        cellStart = str2num(cellStartStr(1:metrepos-1)) ;

        cellEndStr = comsolModel.param.get('cellEnd') ;
        metrepos = strfind(cellEndStr,'[') ;
        cellEnd = str2num(cellEndStr(1:metrepos-1)) ;

        cellLength = cellEnd - cellStart ;
        cellMiddle = (cellLength./2) + cellStart ;

        selectionStartStr = comsolModel.param.get('selectionStart') ;
        metrepos = strfind(selectionStartStr,'[') ;
        selectionStart = str2num(selectionStartStr(1:metrepos-1)) ;

        selectionEndStr = comsolModel.param.get('selectionEnd') ;
        metrepos = strfind(selectionEndStr,'[') ;
        selectionEnd = str2num(selectionEndStr(1:metrepos-1)) ;

        selectionLength = selectionEnd - selectionStart ;
        selectionMiddle = (selectionLength./2) + selectionStart ;

        outerBeamBoxWidth = (2.*r0)+rho ;

        if 2.*endFlangeThickness > selectionLength
            endFlangeTotal = 0 ;
        else
            endFlangeTotal = 2.*endFlangeThickness ;
        end

        if boxWidth < maxX
            boxWidth = maxX ;
        end
        if boxWidth < maxY
            boxWidth = maxY ;
        end
        
        clear *Str metrepos
    
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:variableReadOutException';
        message.text = 'Unable to read out variables from Comsol Model';
        message.priorityLevel = 3 ;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

%% Find domain numbers

    try % to find domain numbers

        for i = 1:numDomains

            domainBounds = mphgetcoords(comsolModel, 'geom1', 'domain', i) ;

            xmin = (round(min(domainBounds(1,:)).*1e12))./1e12 ; xmax = (round(max(domainBounds(1,:)).*1e12))./1e12 ;
            ymin = (round(min(domainBounds(2,:)).*1e12))./1e12 ; ymax = (round(max(domainBounds(2,:)).*1e12))./1e12 ;
            zmin = (round(min(domainBounds(3,:)).*1e12))./1e12 ; zmax = (round(max(domainBounds(3,:)).*1e12))./1e12 ;

            if dispDomains
                if i == 1
                    disp(['beamBoxWidth = ' num2str(beamBoxWidth,12) '; boxWidth = ' num2str(boxWidth,12) '; rho = ' num2str(rho,12)]) ;
                    disp(' ') ;
                end
                disp(['Domain ' num2str(i) '; xmin = ' num2str(xmin,12) '; xmax = ' num2str(xmax,12)]) ;
                disp(['Domain ' num2str(i) '; ymin = ' num2str(ymin,12) '; ymax = ' num2str(ymax,12)]) ;
                disp(['Domain ' num2str(i) '; zmin = ' num2str(zmin,12) '; zmax = ' num2str(zmax,12)]) ;
                disp(' ') ;
                disp(['xmin >= beamBoxWidth: ' num2str(xmin >= beamBoxWidth) '; xmax <= boxWidth: ' num2str(xmax <= boxWidth)]);
                disp(['xmax - boxWidth: ' num2str(xmax - boxWidth,12)]);
                disp(['ymin == 0: ' num2str(ymin == 0) '; ymax <= (2.*rho): ' num2str(ymax <= (2.*rho))]) ;
                disp(' ') ;
            end

            if fourQuad

                if xmin >= -beamBoxWidth && ymin >= -beamBoxWidth && xmax <= beamBoxWidth && ymax <= beamBoxWidth   % find inner beam box

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the inner beam box']) ; disp(' ') ; end
                    ibbgood = true ;
                    innerBeamBoxDomainNo = [innerBeamBoxDomainNo i] ;
                    if zmin <= selectionStart && zmax <= cellStart  % find front inner beam box
                        if dispDomains, disp(['Domain ' num2str(i) ' is the front inner beam box']) ; disp(' ') ; end
                        if ibbfgood == false
                            ibbfgood = true ;
                            innerBeamBoxFrontDomainNo = i ;
                        else
                            error('Too many domains classed as front inner beam box') ;
                        end
                    elseif zmin >= cellStart && zmax <= cellEnd     % find middle inner beam box
                        if dispDomains, disp(['Domain ' num2str(i) ' is the mid inner beam box']) ; disp(' ') ; end
                        if ibbmgood == false
                            ibbmgood = true ;
                            innerBeamBoxMidDomainNo = i ;
                        else
                            error('Too many domains classed as mid inner beam box') ;
                        end
                    elseif zmin >= cellEnd && zmax <= selectionEnd  % find read inner beam box
                        if dispDomains, disp(['Domain ' num2str(i) ' is the back inner beam box']) ; disp(' ') ; end
                        if ibbbgood == false
                            ibbbgood = true ;
                            innerBeamBoxBackDomainNo = i ;
                        else
                            error('Too many domains classed as back inner beam box') ;
                        end
                    else
                        error('Domain fits only some criteria for inner beam box') ;
                    end

                elseif xmin >= beamBoxWidth && ymin >= -(2.*rho) && xmax <= boxWidth && ymax <= (2.*rho)    % find X vane

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the X vane']) ; disp(' ') ; end
                    if xmax <= outerBeamBoxWidth    % find X vane tip
                        if dispDomains, disp(['Domain ' num2str(i) ' is the X vane tip']) ; disp(' ') ; end
                        if xvtgood == false
                            xvtgood = true ;
                            xVaneTipDomainNo = i ;
                        else
                            error('Too many domains classed as X vane tip') ;
                        end
                    elseif xmin >= outerBeamBoxWidth    % find X vane back
                        if dispDomains, disp(['Domain ' num2str(i) ' is the X vane back']) ; disp(' ') ; end
                        if xvbgood == false
                            xvbgood = true ;
                            xVaneBackDomainNo = i ;
                        else
                            error('Too many domains classed as X vane back') ;
                        end
                    else
                        error('Domain fits only some criteria for X vane') ;
                    end

                elseif xmin >= -boxWidth && ymin >= -(2.*rho) && xmax <= -beamBoxWidth && ymax <= (2.*rho)    % find negative X vane

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the negative X vane']) ; disp(' ') ; end
                    if xmin >= -outerBeamBoxWidth    % find X vane tip
                        if dispDomains, disp(['Domain ' num2str(i) ' is the negative X vane tip']) ; disp(' ') ; end
                        if xvtngood == false
                            xvtngood = true ;
                            xVaneTipNegDomainNo = i ;
                        else
                            error('Too many domains classed as negative X vane tip') ;
                        end
                    elseif xmax <= -outerBeamBoxWidth    % find X vane back
                        if dispDomains, disp(['Domain ' num2str(i) ' is the negative X vane back']) ; disp(' ') ; end
                        if xvbngood == false
                            xvbngood = true ;
                            xVaneBackNegDomainNo = i ;
                        else
                            error('Too many domains classed as negative X vane back') ;
                        end
                    else
                        error('Domain fits only some criteria for X vane') ;
                    end

                elseif ymin >= beamBoxWidth && xmin >= -(2.*rho) && ymax <= boxWidth && xmax <= (2.*rho)    % find Y vane

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the Y vane']) ; disp(' ') ; end
                    if ymax <= outerBeamBoxWidth    % find Y vane tip
                        if dispDomains, disp(['Domain ' num2str(i) ' is the Y vane tip']) ; disp(' ') ; end
                        if yvtgood == false
                            yvtgood = true ;
                            yVaneTipDomainNo = i ;
                        else
                            error('Too many domains classed as Y vane tip') ;
                        end
                    elseif ymin >= outerBeamBoxWidth    % find Y vane back
                        if dispDomains, disp(['Domain ' num2str(i) ' is the Y vane back']) ; disp(' ') ; end
                        if yvbgood == false
                            yvbgood = true ;
                            yVaneBackDomainNo = i ;
                        else
                            error('Too many domains classed as Y vane back') ;
                        end
                    else
                        error('Domain fits only some criteria for Y vane') ;
                    end

                elseif ymin >= -boxWidth && xmin >= -(2.*rho) && ymax <= -beamBoxWidth && xmax <= (2.*rho)    % find negative Y vane

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the negative Y vane']) ; disp(' ') ; end
                    if ymin >= -outerBeamBoxWidth    % find Y vane tip
                        if dispDomains, disp(['Domain ' num2str(i) ' is the negative Y vane tip']) ; disp(' ') ; end
                        if yvtngood == false
                            yvtngood = true ;
                            yVaneTipNegDomainNo = i ;
                        else
                            error('Too many domains classed as negative Y vane tip') ;
                        end
                    elseif ymax <= -outerBeamBoxWidth    % find Y vane back
                        if dispDomains, disp(['Domain ' num2str(i) ' is the negative Y vane back']) ; disp(' ') ; end
                        if yvbngood == false
                            yvbngood = true ;
                            yVaneBackNegDomainNo = i ;
                        else
                            error('Too many domains classed as negative Y vane back') ;
                        end
                    else
                        error('Domain fits only some criteria for negative Y vane') ;
                    end

                elseif xmin >= -outerBeamBoxWidth && ymin >= -outerBeamBoxWidth && xmax <= outerBeamBoxWidth && ymax <= outerBeamBoxWidth && ...
                    xmin < 0 && ymin < 0 && xmax > 0 && ymax > 0    % find outer beam box

                    if dispDomains, disp(['Domain ' num2str(i) ' is the outer beam box']) ; disp(' ') ; end
                    obbgood = true ;
                    outerBeamBoxDomainNo = [outerBeamBoxDomainNo i] ;

                elseif zmax - zmin <= endFlangeTotal && numDomains > 16  % find end flange

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the end flange']) ; disp(' ') ; end
                    efgood = true ;
                    endFlangeDomainNo = [endFlangeDomainNo i] ;

%                elseif xmin >= 0 && ymin >= 0 && xmax == boxWidth && ymax == boxWidth   % find air bag
                else

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the air bag']) ; disp(' ') ; end
                    abgood = true ;
                    airbagDomainNo = [airbagDomainNo i] ;

%                else

%                    error('Domain does not fit any criteria for selection') ;

                end

            else

                if xmin == 0 && ymin == 0 && xmax <= beamBoxWidth && ymax <= beamBoxWidth   % find inner beam box

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the inner beam box']) ; disp(' ') ; end
                    ibbgood = true ;
                    innerBeamBoxDomainNo = [innerBeamBoxDomainNo i] ;
                    if zmin <= selectionStart && zmax <= cellStart  % find front inner beam box
                        if dispDomains, disp(['Domain ' num2str(i) ' is the front inner beam box']) ; disp(' ') ; end
                        if ibbfgood == false
                            ibbfgood = true ;
                            innerBeamBoxFrontDomainNo = i ;
                        else
                            error('Too many domains classed as front inner beam box') ;
                        end
                    elseif zmin >= cellStart && zmax <= cellEnd     % find middle inner beam box
                        if dispDomains, disp(['Domain ' num2str(i) ' is the mid inner beam box']) ; disp(' ') ; end
                        if ibbmgood == false
                            ibbmgood = true ;
                            innerBeamBoxMidDomainNo = i ;
                        else
                            error('Too many domains classed as mid inner beam box') ;
                        end
                    elseif zmin >= cellEnd && zmax <= selectionEnd  % find read inner beam box
                        if dispDomains, disp(['Domain ' num2str(i) ' is the back inner beam box']) ; disp(' ') ; end
                        if ibbbgood == false
                            ibbbgood = true ;
                            innerBeamBoxBackDomainNo = i ;
                        else
                            error('Too many domains classed as back inner beam box') ;
                        end
                    else
                        error('Domain fits only some criteria for inner beam box') ;
                    end

                elseif xmin == 0 && ymin == 0 && xmax <= outerBeamBoxWidth && ymax <= outerBeamBoxWidth     % find outer beam box

                    if dispDomains, disp(['Domain ' num2str(i) ' is the outer beam box']) ; disp(' ') ; end
                    obbgood = true ;
                    outerBeamBoxDomainNo = [outerBeamBoxDomainNo i] ;

                elseif xmin >= beamBoxWidth && ymin == 0 && xmax <= boxWidth && ymax <= (2.*rho)    % find X vane

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the X vane']) ; disp(' ') ; end
                    if xmax <= outerBeamBoxWidth    % find X vane tip
                        if dispDomains, disp(['Domain ' num2str(i) ' is the X vane tip']) ; disp(' ') ; end
                        if xvtgood == false
                            xvtgood = true ;
                            xVaneTipDomainNo = i ;
                        else
                            error('Too many domains classed as X vane tip') ;
                        end
                    elseif xmin >= outerBeamBoxWidth    % find X vane back
                        if dispDomains, disp(['Domain ' num2str(i) ' is the X vane back']) ; disp(' ') ; end
                        if xvbgood == false
                            xvbgood = true ;
                            xVaneBackDomainNo = i ;
                        else
                            error('Too many domains classed as X vane back') ;
                        end
                    else
                        error('Domain fits only some criteria for X vane') ;
                    end

                elseif ymin >= beamBoxWidth && xmin == 0 && ymax <= boxWidth && xmax <= (2.*rho)    % find Y vane

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the Y vane']) ; disp(' ') ; end
                    if ymax <= outerBeamBoxWidth    % find Y vane tip
                        if dispDomains, disp(['Domain ' num2str(i) ' is the Y vane tip']) ; disp(' ') ; end
                        if yvtgood == false
                            yvtgood = true ;
                            yVaneTipDomainNo = i ;
                        else
                            error('Too many domains classed as Y vane tip') ;
                        end
                    elseif ymin >= outerBeamBoxWidth    % find Y vane back
                        if dispDomains, disp(['Domain ' num2str(i) ' is the Y vane back']) ; disp(' ') ; end
                        if yvbgood == false
                            yvbgood = true ;
                            yVaneBackDomainNo = i ;
                        else
                            error('Too many domains classed as Y vane back') ;
                        end
                    else
                        error('Domain fits only some criteria for Y vane') ;
                    end

                elseif zmax - zmin <= endFlangeTotal && numDomains > 9  % find end flange

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the end flange']) ; disp(' ') ; end
                    efgood = true ;
                    endFlangeDomainNo = [endFlangeDomainNo i] ;

%                elseif xmin >= 0 && ymin >= 0 && xmax == boxWidth && ymax == boxWidth   % find air bag
                else

                    if dispDomains, disp(['Domain ' num2str(i) ' is in the air bag']) ; disp(' ') ; end
                    abgood = true ;
                    airbagDomainNo = [airbagDomainNo i] ;

%                 else

%                    error('Domain does not fit any criteria for selection') ;

                end

            end

        end

        if fourQuad
            xVaneTipDomainNo = [xVaneTipDomainNo xVaneTipNegDomainNo] ;
            xVaneBackDomainNo = [xVaneBackDomainNo xVaneBackNegDomainNo] ;
            yVaneTipDomainNo = [yVaneTipDomainNo yVaneTipNegDomainNo] ;
            yVaneBackDomainNo = [yVaneBackDomainNo yVaneBackNegDomainNo] ;
            for i = 1:comsolModel.geom('geom1').getNBoundaries
                boundaryBoundBox =  mphgetcoords(comsolModel, 'geom1', 'boundary', i) ;
                xmin = (round(min(boundaryBoundBox(1,:)).*1e12))./1e12 ; xmax = (round(max(boundaryBoundBox(1,:)).*1e12))./1e12 ;
                ymin = (round(min(boundaryBoundBox(2,:)).*1e12))./1e12 ; ymax = (round(max(boundaryBoundBox(2,:)).*1e12))./1e12 ;
                zmin = (round(min(boundaryBoundBox(3,:)).*1e12))./1e12 ; zmax = (round(max(boundaryBoundBox(3,:)).*1e12))./1e12 ;
                if xmin >= -beamBoxWidth && ymin >= -beamBoxWidth && xmax <= beamBoxWidth && ymax <= beamBoxWidth   % find inner beam box boundaries
                    if dispDomains
                        disp(['Boundary ' num2str(i) ' is in the inner beam box'])
                    end
                    if zmax - zmin < 1e-9
                        if dispDomains
                            disp(['Boundary ' num2str(i) ' is a vertical slice in the inner beam box'])
                        end
                        if zmin < cellStart
                            innerBeamBoxFrontFaceBoundary = i ;
                            ffbibbgood = true ;
                            if dispDomains
                                disp(['Boundary ' num2str(i) ' is the front face of the inner beam box'])
                            end
                        elseif zmax > cellEnd
                            innerBeamBoxRearFaceBoundary = i ;
                            rfbibbgood = true ;
                            if dispDomains
                                disp(['Boundary ' num2str(i) ' is the rear face of the inner beam box'])
                            end
                        elseif zmin >= (cellStart - 1e-9) && zmax <= (cellStart + 1e-9)
                            innerBeamBoxSecondFaceBoundary = i ;
                            sfbibbgood = true ;
                            if dispDomains
                                disp(['Boundary ' num2str(i) ' is the second face of the inner beam box'])
                            end
                        elseif zmin >= (cellEnd - 1e-9) && zmax <= (cellEnd + 1e-9)
                            innerBeamBoxThirdFaceBoundary = i ;
                            tfbibbgood = true ; 
                            if dispDomains
                                disp(['Boundary ' num2str(i) ' is the second face of the inner beam box'])
                            end
                        end
                    end
                end
            end

            innerBeamBoxLeadingFaces = [innerBeamBoxFrontFaceBoundary innerBeamBoxSecondFaceBoundary innerBeamBoxThirdFaceBoundary] ;

        end
        
        innerBeamBoxDomainNo = [innerBeamBoxFrontDomainNo innerBeamBoxMidDomainNo innerBeamBoxBackDomainNo] ;

    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:domainCriteriaException';
        message.text = 'Certain domains are not recognised within defined model parameters';
        message.priorityLevel = 3 ;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

%% Check domain numbering

    try % to check domain numbering

        if ~ibbgood
            error('ModelRFQ:ComsolInterface:setSelections:innerBeamBoxError', ...
                  ['Inner beam box not found']) ;
        elseif length(innerBeamBoxDomainNo) ~= 3
            error('ModelRFQ:ComsolInterface:setSelections:innerBeamBoxDomainNumError', ...
                  ['Inner beam box does not contain 3 sub-domains']) ;
        elseif ~ibbfgood
            error('ModelRFQ:ComsolInterface:setSelections:innerBeamBoxFrontError', ...
                  ['Front inner beam box not found']) ;
        elseif ~ibbmgood
            error('ModelRFQ:ComsolInterface:setSelections:innerBeamBoxMidError', ...
                  ['Mid inner beam box not found']) ;
        elseif ~ibbbgood
            error('ModelRFQ:ComsolInterface:setSelections:innerBeamBoxRearError', ...
                  ['Rear inner beam box not found']) ;
        elseif ~obbgood
            error('ModelRFQ:ComsolInterface:setSelections:outerBeamBoxError', ...
                  ['Outer beam box not found']) ;
        elseif ~abgood
            error('ModelRFQ:ComsolInterface:setSelections:airbagError', ...
                  ['Air bag not found']) ;
        elseif ~xvtgood
            error('ModelRFQ:ComsolInterface:setSelections:xVaneTipError', ...
                  ['X vane tip not found']) ;
        elseif ~xvbgood
            error('ModelRFQ:ComsolInterface:setSelections:xVaneBackError', ...
                  ['X vane back not found']) ;
        elseif ~yvtgood
            error('ModelRFQ:ComsolInterface:setSelections:yVaneTipError', ...
                  ['Y vane tip not found']) ;
        elseif ~yvbgood
            error('ModelRFQ:ComsolInterface:setSelections:yVaneBackError', ...
                  ['Y vane back not found']) ;
        end

    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:domainNoException';
        message.text = 'Certain domains were either not found or incorrectly numbered';
        message.priorityLevel = 3 ;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end


%% Set selections 

    try % to set selection
        comsolModel.selection(selectionNames.allVanes).set([yVaneTipDomainNo yVaneBackDomainNo xVaneTipDomainNo xVaneBackDomainNo]);
        comsolModel.selection(selectionNames.horizontalVanes).set([xVaneTipDomainNo xVaneBackDomainNo]);
        comsolModel.selection(selectionNames.verticalVanes).set([yVaneTipDomainNo yVaneBackDomainNo]);
        comsolModel.selection(selectionNames.allTerminals).set([yVaneTipDomainNo yVaneBackDomainNo xVaneTipDomainNo xVaneBackDomainNo endFlangeDomainNo]);
        comsolModel.selection(selectionNames.horizontalTerminals).set([xVaneTipDomainNo xVaneBackDomainNo]);
        comsolModel.selection(selectionNames.verticalTerminals).set([yVaneTipDomainNo yVaneBackDomainNo]);
        comsolModel.selection(selectionNames.airVolumes).set([innerBeamBoxDomainNo outerBeamBoxDomainNo airbagDomainNo]);
        comsolModel.selection(selectionNames.innerBeamBox).set(innerBeamBoxDomainNo);
        comsolModel.selection(selectionNames.innerBeamBoxFront).set(innerBeamBoxFrontDomainNo);
        comsolModel.selection(selectionNames.innerBeamBoxMid).set(innerBeamBoxMidDomainNo);
        comsolModel.selection(selectionNames.innerBeamBoxRear).set(innerBeamBoxBackDomainNo);
        comsolModel.selection(selectionNames.innerBeamBoxBoundaries).set(innerBeamBoxDomainNo);
        comsolModel.selection(selectionNames.outerBeamBox).set(outerBeamBoxDomainNo);
        comsolModel.selection(selectionNames.airBag).set(airbagDomainNo);
        comsolModel.selection(selectionNames.airBagBoundaries).set(airbagDomainNo);
        comsolModel.selection(selectionNames.beamBoxes).set([innerBeamBoxDomainNo outerBeamBoxDomainNo]);

        if fourQuad
            if ffbibbgood && sfbibbgood && tfbibbgood
                comsolModel.selection(selectionNames.innerBeamBoxFrontFace).set(innerBeamBoxFrontFaceBoundary);
                comsolModel.selection(selectionNames.innerBeamBoxRearFace).set(innerBeamBoxRearFaceBoundary);
                comsolModel.selection(selectionNames.innerBeamBoxFrontEdges).set(innerBeamBoxFrontFaceBoundary);
                comsolModel.selection(selectionNames.innerBeamBoxLeadingFaces).set(innerBeamBoxLeadingFaces);
                comsolModel.selection(selectionNames.innerBeamBoxLeadingEdges).set(innerBeamBoxLeadingFaces);
            else
                error('Need to set inner beam box boundaries for 4-quadrant model but cannot find correct boundaries') ;
            end
        end

    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:setSelectionException';
        message.text = 'Unable to set selections within model';
        message.priorityLevel = 3 ;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

    try
        if efgood
            comsolModel.selection(selectionNames.endFlangeGrounded).set(endFlangeDomainNo);
            comsolModel.physics('es').feature('gnd1').active(true) ;
        else
            comsolModel.selection(selectionNames.endFlangeGrounded).set([]);
            comsolModel.physics('es').feature('gnd1').active(false) ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:setEndFlangeSelectionException';
        message.text = 'Could not set selection for end flange';
        message.priorityLevel = 5 ;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message, parameters) ;
    end
        
    return
