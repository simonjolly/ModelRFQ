function [comsolModel, outputParameters] = meshCell(comsolModel, cellNo, nBeamBoxCells, inputParameters)
%
% function comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)
%
% meshCell remeshes the current cell in the Comsol model.
%
% Credit for the majority of the modelling code must go to Simon Jolly of
% Imperial College London.
%
% See also buildCell, buildComsolModel, modelRfq, getModelParameters, 
% logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Feb-2011 M. J. Easton
%       Split buildComsolModel into subroutines to allow unit testing of 
%       separate parts.
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

    try %to test syntax 
        if nargin < 3 %then throw error ModelRFQ:ComsolInterface:meshCell:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)') ;
        end
        if nargin > 4 %then throw error ModelRFQ:ComsolInterface:meshCell:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells, inputParameters)') ;
        end
%        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:meshCell:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:meshCell:insufficientOutputArguments', ...
%                  'Too few output variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)');
%        end
        if nargout > 2 %then throw error ModelRFQ:ComsolInterface:meshCell:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:excessiveOutputArguments', ...
                  'Too many output variables: syntax is [comsolModel, outputParameters] = meshCell(comsolModel, cellNo, nBeamBoxCells)') ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:meshCell:syntaxException';
        message.text = 'Syntax error calling meshCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Read out variables from Comsol model

    try % to read out variable data from Comsol model

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

        selectionStartStr = comsolModel.param.get('selectionStart') ;
        metrepos = strfind(selectionStartStr,'[') ;
        selectionStart = str2num(selectionStartStr(1:metrepos-1)) ;

        selectionEndStr = comsolModel.param.get('selectionEnd') ;
        metrepos = strfind(selectionEndStr,'[') ;
        selectionEnd = str2num(selectionEndStr(1:metrepos-1)) ;

        clear *Str metrepos
    
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:meshCell:variableReadOutException';
        message.text = 'Unable to read out variables from Comsol Model';
        message.priorityLevel = 5 ;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

    numElemDis1 = 32 ;
    numElemDis2 = 32 ;
    numElemDis3 = 32 ;
    if cellNo == 1
        numElemDis1 = 128 ;
        numElemDis2 = 128 ;
    elseif cellNo == 2
        numElemDis1 = 128 ;
    end
%    (cellLength./numElemDis2)./(beamBoxWidth./nBeamBoxCells)

%% Remesh model 

    try % to remesh vane surfaces

        numDomains = comsolModel.geom('geom1').getNDomains ;

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshTerminals';
        if numDomains > 9
            message.text = '        --> Remeshing vane tip and end flange surfaces...';
        else
            message.text = '        --> Remeshing vane tip surfaces...';
        end
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        parameters = logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').run('ftri1');

    catch exception
        numDomains = comsolModel.geom('geom1').getNDomains ;
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshTerminals:exception';
        if numDomains > 9
            errorMessage.text = 'Could not remesh vane tip and end flange surfaces';
        else
            errorMessage.text = 'Could not remesh vane tip surfaces';
        end
        errorMessage.priorityLevel = 5; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        parameters = logMessage(errorMessage, parameters) ; 
    end

    goodobbmesh = 0 ;

    try

        while ~goodobbmesh

            try % to remesh inner beam box

                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshInnerBeamBox';
                message.text = '        --> Remeshing inner beam box...';
                message.priorityLevel = 9;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;

                comsolModel.mesh('mesh1').feature('map1').feature('dis1').set('numelem', num2str(nBeamBoxCells)) ;
                comsolModel.mesh('mesh1').run('map1');

                comsolModel.mesh('mesh1').feature('swe1').feature('dis1').set('numelem', num2str(numElemDis1)) ;
                comsolModel.mesh('mesh1').feature('swe1').feature('dis2').set('numelem', num2str(numElemDis2)) ;
                comsolModel.mesh('mesh1').feature('swe1').feature('dis3').set('numelem', num2str(numElemDis3)) ;
                comsolModel.mesh('mesh1').run('swe1');
                comsolModel.mesh('mesh1').run('conv1');

            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshInnerBeamBox:exception';
                errorMessage.text = 'Could not remesh inner beam box';
                errorMessage.priorityLevel = 5; 
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ; 
            end

            try % to remesh outer beam box

                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshOuterBeamBox';
                message.text = '        --> Remeshing outer beam box...';
                message.priorityLevel = 9;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;

                comsolModel.mesh('mesh1').run('ftet1');
                goodobbmesh = 1 ;

            catch exception
                goodobbmesh = 0 ;
                numElemDis1 = 2.*numElemDis1 ;
                numElemDis2 = 2.*numElemDis2 ;
                numElemDis3 = 2.*numElemDis3 ;
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshOuterBeamBox:exception';
                errorMessage.text = ['Could not remesh outer beam box: increasing inner beam box mesh steps to ' num2str(numElemDis2) ' and retrying...'] ;
                errorMessage.priorityLevel = 5; 
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ; 
            end

            if (cellLength./numElemDis2)./(beamBoxWidth./nBeamBoxCells) < 0.1
                error('ModelRFQ:ComsolInterface:meshCell:remeshBeamBoxes:stepsException', ...
                  'Inner beam box mesh step size has become too small: outer beam box cannot be meshed') ;
            end

        end

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshBeamBox:exception';
        errorMessage.text = 'Could not remesh beam box';
        errorMessage.priorityLevel = 5;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to remesh air bag

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshAirBag';
        message.text = '        --> Remeshing air bag...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:meshCell:remeshAirBag:exception';
        errorMessage.text = 'Could not remesh air bag';
        errorMessage.priorityLevel = 5; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end

    outputParameters = parameters ;

    return
