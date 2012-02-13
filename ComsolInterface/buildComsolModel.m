function [comsolModel, parameters] = buildComsolModel(varargin)
%
% function [comsolModel, parameters] = buildComsolModel(parameters)
%
%   buildComsolModel runs the steps needed to model an RFQ in Comsol and
%   produce a field map.
%
%   buildComsolModel makes use of the global parameters variable, which is
%   defined in getModelParameters. Also required is the logMessage
%   function, which in turn requires a log file to be open. See help
%   logMessage for details.
%
%   Credit for the majority of the modelling code must go to Simon Jolly of
%   Imperial College London.
%
%   See also modelRfq, getModelParameters, setupModel, logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history:
%
%   06-Jan-2011 M. J. Easton
%       Created coherent function to shape the modelling process.
%
%   15-Feb-2011 M. J. Easton
%       Added setupComsolModel code.
%       Changed error handling to remove excessive logging.
%
%=========================================================================

%% Declarations 

    import com.comsol.model.*
    import com.comsol.model.util.*
       
%% Check syntax 

    try %to test syntax
%        if nargin ~= 0 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:incorrectInputArguments 
%            error('ModelRFQ:ComsolInterface:buildComsolModel:incorrectInputArguments', ...
%                'Incorrect input arguments: correct syntax is buildComsolModel()');
%        end
        if nargout > 2 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:incorrectOutputArguments 
            error('ModelRFQ:ComsolInterface:buildComsolModel:excessiveOutputArguments', ...
                'Too many output variables: correct syntax is [comsolModel, parameters] = buildComsolModel(...)');
        end
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

        comsolModelFile = fullfile(parameters.files.comsolSourceFolder, parameters.files.comsolModel) ;

        binloc = strfind(parameters.files.comsolServer,'bin') ;
        comdir = parameters.files.comsolServer(1:binloc-1) ;
        mphloc = fullfile(comdir, 'mli') ;
        curpath = path ;
        newpath = path(mphloc,curpath) ;

    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:syntaxException';
        message.text = 'Syntax error calling buildComsolModel: correct syntax is buildComsolModel()';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end
    
%% Get Comsol port 

    try %to get Comsol port number 
        comsolPort = getComsolPort(parameters.files.comsolPort) ;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:getComsolPortException';
        message.text = 'Cannot get Comsol port number. Proceeding with default value.';
        message.priorityLevel = 6;
        message.errorLevel = 'warning';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
        comsolPort = 2036 ;
    end

%% Start Comsol server

    try %to start Comsol server
        if ispc
            [status, result] = system('tasklist /FI "IMAGENAME eq comsolserver.exe"') ;
            serverrunning = ~isempty(strfind(result,'comsolserver.exe')) ;
        else
            [status, result] = system('ps -ax') ;
            serverrunning = ~isempty(strfind(result,'comsolserver.ini')) ;
        end
        clear status ;
        if serverrunning
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:start';
            message.text = ' - Comsol server already running';
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            parameters = logMessage(message, parameters) ;
            if exist('com/comsol/model/impl/ModelImpl','class') == 8
                ModelUtil.connect('127.0.0.1', comsolPort) ;
            else
                mphstart(comsolPort) ;
            end
            clear message result ;
        else
            try %to notify start
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:start';
                message.text = ' - Starting Comsol server...';
                message.priorityLevel = 3;
                message.errorLevel = 'information';
                parameters = logMessage(message, parameters) ;
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:startTime';
                message.text = ['   Start time: ' currentTime()];
                comsolSectionTimer = tic;
                message.priorityLevel = 5;
                message.errorLevel = 'information';
                parameters = logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                parameters = logMessage(errorMessage, parameters) ;
            end
            try %to start Comsol server 
                [status,result] = system([parameters.files.comsolServer ' -port ' num2str(comsolPort) ' &']) ;
                if status ~= 0 %then throw ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:invalidServerResponse 
                    errorException = MException('ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:invalidServerResponse', result);
                    throw(errorException);
                end
                clear status result ;
                if exist('com/comsol/model/impl/ModelImpl','class') == 8
                    ModelUtil.connect('127.0.0.1', comsolPort) ;
                else
                    mphstart(comsolPort) ;
                end
            catch exception
                rethrow(exception);
            end
            try %to notify end 
                sectionTimeSeconds = toc(comsolSectionTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:endTime';
                message.text = text;
                message.priorityLevel = 5;
                message.errorLevel = 'information';
                parameters = logMessage(message, parameters) ;
                clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                parameters = logMessage(errorMessage, parameters) ;
            end
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServerException';
        message.text = 'Cannot start Comsol server';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception ;
        parameters = logMessage(message, parameters) ;
    end

%% Load Comsol model 

    try %to notify start 

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:createComsolModel:start';
        message.text = ' - Loading Comsol model...';
        message.priorityLevel = 3;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message ;

        if parameters.options.shouldUseCadImport && ispc
            [comsolModel, parameters, selectionNames, vaneBoundBoxes, modelBoundBox, nCells, lengthData, ...
                rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
                = createModel(parameters) ;
            vaneModelStart = modelBoundBox(5) ;
            vaneModelEnd = modelBoundBox(6) ;
        else %load comsolModel from template
            try %to import data from spreadsheet
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:start';
                    message.text = ' - Retrieving modulation data from spreadsheet...';
                    message.priorityLevel = 3;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:startTime';
                    message.text = ['   Start time: ' currentTime()];
                    comsolSectionTimer = tic;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:startException';
                    errorMessage.text = 'Could not notify start of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage, parameters) ;
                end
                [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
                   = getModulationParameters(parameters.files.modulationsFile) ;
                try %to notify end 
                    sectionTimeSeconds = toc(comsolSectionTimer);
                    sectionTime = convertSecondsToText(sectionTimeSeconds);
                    text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:endTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:endTimeException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage, parameters) ;
                end        
            catch exception
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetDataException';
                message.text = 'Error accessing modulation data';
                message.priorityLevel = 3;
                message.errorLevel = 'error';
                message.exception = exception;
                logMessage(message, parameters) ;
            end
            
            try %to load model from file
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadExistingModel:start';
                    message.text = ' - Loading Comsol model from file...';
                    message.priorityLevel = 3;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadExistingModel:startTime';
                    message.text = ['   Start time: ' currentTime()];
                    comsolSectionTimer = tic;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadExistingModel:startException';
                    errorMessage.text = 'Could not notify start of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage, parameters) ;
                end
                comsolModel = ModelUtil.load('RFQ', fullfile(comsolModelFile)) ;
                selectionNames = parameters.defaultSelectionNames ;
                varnames = comsolModel.param.varnames ;
                goodModelStart = false ; goodModelEnd = false ;
                for i = 1:length(varnames)
                    if strfind(char(varnames(i)),'vaneModelStart')
                        goodModelStart = true ;
                    elseif strfind(char(varnames(i)),'vaneModelEnd')
                        goodModelEnd = true ;
                    end
                end
                if goodModelStart
                    vaneModelStartStr = comsolModel.param.get('vaneModelStart') ;
                    metrepos = strfind(vaneModelStartStr,'[m]') ;
                    vaneModelStart = str2num(vaneModelStartStr(1:metrepos-1)) ;
                else
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:setModelBoundBox:startException';
                    message.text = 'Model does not contain bounding box start information: using default value';
                    message.priorityLevel = 8;
                    message.errorLevel = 'warning';
                    logMessage(message, parameters) ;
                    vaneModelStart = cadOffset ;
                end
                if goodModelEnd
                    vaneModelEndStr = comsolModel.param.get('vaneModelEnd') ;
                    metrepos = strfind(vaneModelEndStr,'[m]') ;
                    vaneModelEnd = str2num(vaneModelEndStr(1:metrepos-1)) ;
                    clear metrepos ;
                else
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:setModelBoundBox:endException';
                    message.text = 'Model does not contain bounding box end information: using default value';
                    message.priorityLevel = 8;
                    message.errorLevel = 'warning';
                    logMessage(message, parameters) ;
                    vaneModelEnd = lengthData(end) + cadOffset ;
                end
                try %to notify end 
                    sectionTimeSeconds = toc(comsolSectionTimer);
                    sectionTime = convertSecondsToText(sectionTimeSeconds);
                    text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadExistingModel:endTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadExistingModel:endTimeException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage, parameters) ;
                end        
            catch exception
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadExistingModelException';
                message.text = 'Error loading existing model';
                message.priorityLevel = 3;
                message.errorLevel = 'error';
                message.exception = exception;
                logMessage(message, parameters) ;
            end

        end

    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModelException';
        message.text = 'Error during Comsol model load';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

%% Save Comsol model

    try %to save model 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:saveModel';
        message.text = '    > Saving model...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;
        comsolModel.save(fullfile(parameters.files.comsolSourceFolder, parameters.files.comsolModel));
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:saveException';
        errorMessage.text = 'Could not save Comsol model';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end
        
%% Loop through model cells one at a time 

    initialCellNo = 4 ;

    try %to notify start 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:start';
        message.text = ' - Starting to solve for field map...';
        message.priorityLevel = 3;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:startTime';
        message.text = ['   Start time: ' currentTime()];
        comsolSectionTimer = tic;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:startException';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end
    try %to see if process has already been started 
        if exist(parameters.files.outputFieldMapMatlab, 'file') == 2 % then load the last cell number and start from there 
            load(parameters.files.outputFieldMapMatlab, 'lastCellNo') ;
            if isnumeric(lastCellNo) % then start from the next cell rather than the beginning 
                startCellNo = lastCellNo+1 ;
            else
                startCellNo = 1 ;
            end
        else
            startCellNo = 1 ;
        end
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:checkLastCellException';
        errorMessage.text = 'Could not load last cell number from fieldmap data file. Starting from cell 1.';
        errorMessage.priorityLevel = 5;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
        startCellNo = 1 ;
    end

    if fourQuad
        resetCell = 10 ;
    else
        resetCell = 40 ;
    end
    
    for i = startCellNo : nCells + 1 %build and solve

        if i ~= startCellNo && mod(i-startCellNo,resetCell) == 0 %every 40 cells, reload the server to free memory 

            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:start';
                message.text = ' - Reloading Comsol to free memory...';
                message.priorityLevel = 5;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:startTime';
                message.text = ['   Start time: ' currentTime()];
                comsolSubSectionTimer = tic;
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            
            try %to disconnect from Comsol and kill server
                if ~parameters.options.shouldUseCadImport % then save comsolModel to reload after the restart
                    [comsolModelDir, comsolModelName] = fileparts(comsolModelFile) ;
                    comsolModel.save(fullfile(comsolModelDir, [comsolModelName '_temp.mph'])) ;
                end
                clear comsolModel comsolModelDir comsolModelName ;
                ModelUtil.disconnect ;
                if ispc && 0
                    [status, result] = system('taskkill /im comsolserver.exe') ;
                    if status ~= 0 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restart:serverShutdownError 
                        errorException = MException('ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restart:serverShutdownError', result);
                        throw(errorException);
                    end
                end
                clear status result;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:closeException';
                errorMessage.text = 'Could not close Comsol model';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            
            try %to restart Comsol server
                if ~ispc
                    [status,result] = system([parameters.files.comsolServer ' -port ' num2str(comsolPort) ' &']) ;
                    if status ~= 0 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restart:invalidServerResponse 
                        errorException = MException('ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restart:invalidServerResponse', result);
                        throw(errorException);
                    end
                    clear status result ;
                end
                if exist('com/comsol/model/impl/ModelImpl','class') == 8
                    ModelUtil.connect('127.0.0.1', comsolPort) ;
                else
                    mphstart(comsolPort) ;
                end
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restartException';
                errorMessage.text = 'Could not restart Comsol server';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            
            try %to reload Comsol model
                if parameters.options.shouldUseCadImport && ispc    % then recreate comsolModel from scratch using CAD model
                    [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] ...
                        = getCellParameters(lengthData, initialCellNo, cadOffset, verticalCellHeight, rho, parameters.vane.nExtraCells) ;
                    [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox] ...
                        = setupModel(parameters.files.comsolSourceFolder, parameters.files.comsolModel, parameters.files.cadFile, ...
                                     r0, rho, vaneVoltage, initialCellNo, nCells, ...
                                     cellStart, cellEnd, selectionStart, selectionEnd, ...
                                     boxWidth, beamBoxWidth, nBeamBoxCells, fourQuad, parameters) ;
                    vaneModelStart = modelBoundBox(5) ;
                    vaneModelEnd = modelBoundBox(6) ;
                else %load comsolModel from saved file
                    [comsolModelDir, comsolModelName] = fileparts(comsolModelFile) ;
                    comsolModel = ModelUtil.load('RFQ', fullfile(comsolModelDir, [comsolModelName '_temp.mph'])) ;
                    selectionNames = parameters.defaultSelectionNames ;
                    clear comsolModelDir comsolModelName ;
                end
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:reloadException';
                errorMessage.text = 'Could not reload Comsol model';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            
            try %to notify end
                sectionTimeSeconds = toc(comsolSubSectionTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:endTime';
                message.text = text;
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear comsolSubSectionTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            
        end

        try % to rebuild and solve cell

            try %to notify start
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:buildAndSolveCell:startCell';
                message.text = ['    > Cell ' num2str(i)];
                if ~mod(i, 10) %then upgrade message priority every 10 cells
                    message.priorityLevel = 3;
                else
                    message.priorityLevel = 5;
                end
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:buildAndSolveCell:startException';
                errorMessage.text = 'Could not notify start of cell';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end

            try %to build and solve current cell
                [comsolModel, cellfieldmap] = buildAndSolveCell(comsolModel, i, selectionNames, lengthData, nCells, ...
                                 verticalCellHeight, rho, nBeamBoxCells, parameters.vane.nExtraCells, cadOffset, ...
                                 vaneModelStart, vaneModelEnd, 14e-3, [], [], [], parameters) ;     %#ok
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:buildAndSolveCell:buildException';
                errorMessage.text = 'Could not build model cell';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end

            if parameters.vane.shouldSaveSeparateCells %then save current cell separately
                try % to save Comsol model
                    [cellModelDir, cellModelFile, cellModelExt] = fileparts(comsolModelFile) ;
                    comsolModel.save(fullfile(cellModelDir, [cellModelFile num2str(i) cellModelExt])) ;
                    message = struct;
                    message.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:saveCell' ;
                    message.text = ['      Saved ' regexprep(fullfile(cellModelDir, [cellModelFile num2str(i) cellModelExt]), '\\', '\\\\')] ;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message, parameters) ;
                    clear message cellModelDir cellModelFile ;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:saveCellException';
                    errorMessage.text = 'Could not save cell for troubleshooting';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage, parameters) ;
                end
            end
            % Cell complete

            try %to output field map to file 
                currentFieldMap = ['fieldmap' num2str(i)] ;
                eval([currentFieldMap ' = cellfieldmap ;']) ;
                if i == 1 %then create the file; otherwise append to it
                    save(parameters.files.outputFieldMapMatlab, currentFieldMap);
                else
                    save(parameters.files.outputFieldMapMatlab, currentFieldMap, '-append') ;
                end
                lastCellNo = i ;    %#ok
                save(parameters.files.outputFieldMapMatlab, 'lastCellNo', '-append') ;
                eval(['clear ' currentFieldMap]) ;
                clear cellfieldmap lastCellNo currentFieldMap ;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:outputFieldMap:runException';
                errorMessage.text = 'Could not save field map.';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end

        catch exception
            try %to save model so user can manually find the problem
                [comsolModelDir, comsolModelName] = fileparts(comsolModelFile) ;
                comsolModel.save(fullfile(comsolModelDir, [comsolModelName '_temp.mph'])) ;
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:saveTempModel';
                message.text = ['Comsol model saved as ' regexprep(fullfile(comsolModelDir, [comsolModelName '_temp.mph']), '\\', '\\\\') ' for troubleshooting.']; 
                message.priorityLevel = 3;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:solveCell:saveTempModelException';
                errorMessage.text = 'Could not save model for troubleshooting';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            rethrow(exception);
        end
        
    end
    
    try %to build field map

        try % to load field map from file

            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:start';
            message.text = '    > Building full field map...';
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:startTime';
            message.text = ['      Start time: ' currentTime()];
            loadFieldMapTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear message;

            fieldmap = loadFieldMap(parameters.files.outputFieldMapMatlab) ;

            sectionTimeSeconds = toc(loadFieldMapTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;

            clear loadFieldMapTimer sectionTimeSeconds sectionTime text message;

        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadFieldMap:runException';
            message.text = 'Error loading fieldmap from file.';
            message.priorityLevel = 5;
            message.errorLevel = 'error';
            message.exception = exception;
            logMessage(message, parameters) ;
        end

        if ~fourQuad
            fieldmap = fillFieldMapFromQuadrant(fieldmap) ;
        end
        fid = fopen(parameters.files.outputFieldMapText, 'w') ;
        if ispc %then define correct EOL character 
            newline = '\r\n';
        else
            newline = '\n';
        end
        fprintf(fid,['x\ty\tz\tEx\tEy\tEz\tBx\tBy\tBz' newline]);
        fclose(fid);
        dlmwrite(parameters.files.outputFieldMapText, fieldmap, '-append', 'delimiter','\t', 'newline','pc', 'precision',10) ;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:buildException';
        errorMessage.text = 'Could not build field map';
        errorMessage.priorityLevel = 3;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end
    
    try %to notify end
        sectionTimeSeconds = toc(comsolSectionTimer);
        sectionTime = convertSecondsToText(sectionTimeSeconds);
        text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:endTime';
        message.text = text;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:endTimeException';
        errorMessage.text = 'Could not notify end of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end
    
    clear lengthData r0 rho cadOffset initialCellNo nCells verticalCellHeight beamBoxWidth nBeamBoxCells cellStart cellEnd selectionStart selectionEnd boxWidth;
    
%% Clean up 

    try %to save model and close 
        comsolModel.save([pwd filesep parameters.files.comsolModel]) ;
%        clear comsolModel;
        ModelUtil.disconnect;
        if exist(['.' filesep 'state'], 'dir') == 7 %remove server state subfolder 
            rmdir('state', 's');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:cleanUpException';
        message.text = 'Could not stop Comsol server';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message, parameters) ;
    end

    return
