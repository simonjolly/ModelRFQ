function [comsolModel, parameters, selectionNames, vaneBoundBoxes, modelBoundBox, nCells, ...
    lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
     = createModel(varargin)
%
% function [comsolModel, parameters, selectionNames, vaneBoundBoxes, modelBoundBox, nCells,
%    lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth]
%       = createModel(parameters)
%
%   createModel runs the steps needed to model an RFQ in Comsol and
%   produce a field map.
%
%   createModel makes use of the global parameters variable, which is
%   defined in getModelParameters. Also required is the logMessage
%   function, which in turn requires a log file to be open. See help
%   logMessage for details.
%
%   See also modelRfq, getModelParameters, setupModel, logMessage,
%   buildComsolModel.

% File released under the GNU public license.
% Originally written by Simon Jolly. Based on code by Matt Easton.
%
% File history:
%
%   24-May-2011 S. Jolly
%       Created function from various sections of buildComsolModel to
%       simplify model creation without scripting.
%
%   29-Nov-2011 S. Jolly
%       Added code to deal with 4-quadrant models.
%
%   23-Dec-2011 S. Jolly
%       Added capability to specify boxWidth as an input variable to
%       getModelParameters.
%
%=========================================================================

%% Declarations 

    import com.comsol.model.*
    import com.comsol.model.util.*
       
%% Check syntax 

    if nargin == 1 && isstruct(varargin{1})
        parameters = varargin{1} ;
    else % store parameters
        parameters = getModelParameters(varargin{:}) ;
    end

    if isfield(parameters, 'vane') && isfield(parameters.vane, 'fourQuad')
        fourQuad = parameters.vane.fourQuad ;
    else
        fourQuad = false ;
    end

    try %to test syntax
%        if nargin ~= 0 %then throw error ModelRFQ:ComsolInterface:createModel:incorrectInputArguments 
%            error('ModelRFQ:ComsolInterface:createModel:incorrectInputArguments', ...
%                'Incorrect input arguments: correct syntax is createModel()');
%        end
        if nargout > 14 %then throw error ModelRFQ:ComsolInterface:createModel:incorrectOutputArguments 
            error('ModelRFQ:ComsolInterface:createModel:excessiveOutputArguments', ...
                ['Too many output variables: correct syntax is ' ...
                '[comsolModel, parameters, selectionNames, vaneBoundBoxes, modelBoundBox, nCells, ' ...
                'lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, ' ...
                'beamBoxWidth] = createModel(...)']) ;
        end
        if ~ispc
            error('ModelRFQ:ComsolInterface:createModel:unPC', ...
                'Can only create model from scratch on Windows: CAD import doesn''t work on Mac or Linux') ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createModel:syntaxException';
        message.text = 'Syntax error calling createModel: correct syntax is createModel()';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Retrieve modulation data from spreadsheet 

    try %to import data and extract what is needed 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:createModel:retrieveSpreadsheetData:start';
            message.text = ' - Retrieving modulation data from spreadsheet...';
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            parameters = logMessage(message, parameters) ;
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:createModel:retrieveSpreadsheetData:startTime';
            message.text = ['   Start time: ' currentTime()];
            comsolSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            parameters = logMessage(message, parameters) ;
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:createModel:retrieveSpreadsheetData:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            parameters = logMessage(errorMessage, parameters) ;
        end
        [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
           = getModulationParameters(parameters.files.modulationsFile) ;
        if fourQuad
            nBeamBoxCells = 2*nBeamBoxCells ;
        end
        try %to notify end 
            sectionTimeSeconds = toc(comsolSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:createModel:retrieveSpreadsheetData:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            parameters = logMessage(message, parameters) ;
            clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:createModel:retrieveSpreadsheetData:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            parameters = logMessage(errorMessage, parameters) ;
        end        
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createModel:retrieveSpreadsheetDataException';
        message.text = 'Error accessing modulation data';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Create Comsol model 

    try %to build Comsol model 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:createModel:loadComsolModel:start';
            if fourQuad
                message.text = ' - Creating 4-quadrant Comsol model...';
            else
                message.text = ' - Creating Comsol model...';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:createModel:loadComsolModel:startTime';
            message.text = ['   Start time: ' currentTime()];
            comsolSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:createModel:loadComsolModel:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        initialCellNo = 4;
        [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] ...
            = getCellParameters(lengthData, initialCellNo, cadOffset, verticalCellHeight, rho, 1) ;
        if isfield(parameters, 'vane') && isfield(parameters.vane, 'boxWidth') && ~isempty(parameters.vane.boxWidth)
            boxWidth = parameters.vane.boxWidth ;
        end
        [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, parameters] ...
            = setupModel(parameters.files.comsolSourceFolder, parameters.files.comsolModel, parameters.files.cadFile, ...
                         r0, rho, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd, ...
                         boxWidth, beamBoxWidth, nBeamBoxCells, fourQuad, parameters) ;
        try %to notify end 
            sectionTimeSeconds = toc(comsolSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:createModel:loadComsolModel:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:createModel:loadComsolModel:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createModel:loadComsolModelException';
        message.text = 'Error during Comsol model load';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

    return
