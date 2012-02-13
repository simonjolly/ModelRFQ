function buildComsolModel()
%
% function buildComsolModel()
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
%   See also modelRfq, getModelParameters, logMessage.

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
    
    global parameters;
    import com.comsol.model.*
    import com.comsol.model.util.*
       
%% Check syntax 

    try %to test syntax 
        if nargin ~= 0 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:incorrectInputArguments 
            error('ModelRFQ:ComsolInterface:buildComsolModel:incorrectInputArguments', 'Incorrect input arguments: correct syntax is buildComsolModel()');
        end
        if nargout ~= 0 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:incorrectOutputArguments 
            error('ModelRFQ:ComsolInterface:buildComsolModel:incorrectOutputArguments', 'Incorrect output arguments: correct syntax is buildComsolModel()');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:syntaxException';
        message.text = 'Syntax error calling buildComsolModel: correct syntax is buildComsolModel()';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Retrieve modulation data from spreadsheet 

    try %to import data and extract what is needed 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:start';
            message.text = ' - Retrieving modulation data from spreadsheet...';
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:startTime';
            message.text = ['   Start time: ' currentTime()];
            comsolSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
           = getModulationParameters(['..' filesep parameters.files.cadFolder filesep parameters.files.modulationsFile]);       %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
        try %to notify end 
            sectionTimeSeconds = toc(comsolSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetData:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end        
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:retrieveSpreadsheetDataException';
        message.text = 'Error accessing modulation data';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Get Comsol port 

    try %to get Comsol port number 
        comsolPort = getComsolPort(parameters.files.comsolPort); %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:getComsolPortException';
        message.text = 'Cannot get Comsol port number. Proceeding with default value.';
        message.priorityLevel = 6;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
        comsolPort = 2036;
    end

%% Start Comsol server 

    try %to start Comsol server 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:start';
            message.text = ' - Starting Comsol server...';
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:startTime';
            message.text = ['   Start time: ' currentTime()];
            comsolSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to start Comsol server 
            [status,result] = system([parameters.files.comsolServer ' -port ' num2str(comsolPort) ' &']);     %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            if status ~= 0 %then throw ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:invalidServerResponse 
                errorException = MException('ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:invalidServerResponse', result);
                throw(errorException);
            end
            clear status result;
            % for some reason mphstart clears the global variable :(
            tempParameters = parameters;                                        %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            mphstart(comsolPort);
            global parameters;                                                  %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            parameters = tempParameters;                                        %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            clear tempParameters;
        catch exception
            if ~exist('parameters', 'var') %then reinstate global variable 
                parameters = tempParameters; %#ok
                clear tempParameters;
            end
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
            logMessage(message);
            clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServer:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:startComsolServerException';
        message.text = 'Cannot start Comsol server';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        if ~exist('parameters', 'var') %then reinstate global variable
            parameters = tempParameters; %#ok
            clear tempParameters;
            logMessage(message, parameters); %#ok
        else
            logMessage(message);
        end
    end
    
%% Load Comsol model 

    try %to load Comsol model 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModel:start';
            message.text = ' - Loading Comsol model...';
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModel:startTime';
            message.text = ['   Start time: ' currentTime()];
            comsolSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModel:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        if parameters.options.shouldUseCadImport %#ok: then create comsolModel from scratch using CAD model              %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            initialCellNo = 4;
            [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] ...
                = getCellParameters(lengthData, initialCellNo, cadOffset, verticalCellHeight, rho, 1);
            currentFolder = pwd;
            rootFolder = currentFolder(1:max(regexp(currentFolder, regexprep(filesep, '\\', '\\\\'))));
            [comsolModel, selectionNames] ...
                = setupModel(currentFolder, parameters.files.comsolModel, fullfile(rootFolder, parameters.files.cadFolder, parameters.files.cadFile), ...
                             r0, rho, vaneVoltage, initialCellNo, ...
                             cellStart, cellEnd, selectionStart, selectionEnd, ...
                             boxWidth, beamBoxWidth, nBeamBoxCells);                                            %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            clear currentFolder rootFolder;
        else %load comsolModel from template
            comsolModel = ModelUtil.load('RFQ', fullfile(pwd, parameters.files.comsolModel));                   %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
            selectionNames = parameters.defaultSelectionNames;                                                  %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
        end
        try %to notify end 
            sectionTimeSeconds = toc(comsolSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModel:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModel:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:loadComsolModelException';
        message.text = 'Error during Comsol model load';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
     
%% Loop through model cells one at a time 

    try %to notify start 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:start';
        message.text = ' - Starting to solve for field map...';
        message.priorityLevel = 3;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:startTime';
        message.text = ['   Start time: ' currentTime()];
        comsolSectionTimer = tic;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:startException';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    try %to see if process has already been started 
        if exist(parameters.files.outputFieldMapMatlab, 'file') == 2 %#ok: then load the last cell number and start from there 
            load(parameters.files.outputFieldMapMatlab, 'lastCellNo'); %#ok
            if isnumeric(lastCellNo) %then start from the next cell rather than the beginning 
                startCellNo = lastCellNo+1;
            else
                startCellNo = 1;
            end
        else
            startCellNo = 1;
        end
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:checkLastCellException';
        errorMessage.text = 'Could not load last cell number from fieldmap data file. Starting from cell 1.';
        errorMessage.priorityLevel = 5;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
        startCellNo = 1;
    end
    for i = startCellNo : nCells %build and solve 
        if i ~= startCellNo && mod(i-startCellNo,40) == 0 %every 40 cells, reload the server to free memory 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:start';
                message.text = ' - Reloading Comsol to free memory...';
                message.priorityLevel = 5;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:startTime';
                message.text = ['   Start time: ' currentTime()];
                comsolSubSectionTimer = tic;
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to disconnect from Comsol 
                if ~parameters.options.shouldUseCadImport %#ok: then save comsolModel to reloard after the restart              %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
                    comsolModel.save([pwd filesep parameters.files.comsolModel]) %#ok
                end
                clear comsolModel;
                ModelUtil.disconnect;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:closeException';
                errorMessage.text = 'Could not close Comsol model';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to restart Comsol server 
                [status,result] = system([parameters.files.comsolServer ' -port ' num2str(comsolPort) ' &']); %#ok
                if status ~= 0 %then throw error ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restart:invalidServerResponse 
                    errorException = MException('ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restart:invalidServerResponse', result);
                    throw(errorException);
                end
                clear status result;
                ModelUtil.connect('127.0.0.1', comsolPort);
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:restartException';
                errorMessage.text = 'Could not restart Comsol server';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to reload Comsol model 
                if parameters.options.shouldUseCadImport %#ok: then create comsolModel from scratch using CAD model              %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
                    [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] ...
                        = getCellParameters(lengthData, initialCellNo, cadOffset, verticalCellHeight, rho, 1);
                    currentFolder = pwd;
                    rootFolder = currentFolder(1:max(regexp(currentFolder, regexprep(filesep, '\\', '\\\\'))));
                    [comsolModel, selectionNames] ...
                        = setupModel(currentFolder, parameters.files.comsolModel, fullfile(rootFolder, parameters.files.cadFolder, parameters.files.cadFile), ...
                                     r0, rho, vaneVoltage, initialCellNo, ...
                                     cellStart, cellEnd, selectionStart, selectionEnd, ...
                                     boxWidth, beamBoxWidth, nBeamBoxCells);                                            %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
                    clear currentFolder rootFolder;
                else %load comsolModel from saved file
                    comsolModel = ModelUtil.load('RFQ', fullfile(pwd, parameters.files.comsolModel));                             %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
                end
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:reloadException';
                errorMessage.text = 'Could not reload Comsol model';
                errorMessage.priorityLevel = 5;
                errorMessage.errorLevel = 'error';
                errorMessage.exception = exception;
                logMessage(errorMessage);
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
                logMessage(message);
                clear comsolSubSectionTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:reloadComsolServer:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
        end
        try %to build current cell 
            comsolModel = buildCell(comsolModel, i, nCells, selectionNames, lengthData, vaneVoltage, cadOffset,...
                                    verticalCellHeight, rho, parameters.vane.nExtraCells, nBeamBoxCells, ...
                                    parameters.files.comsolModel, parameters.files.outputFieldMapMatlab, ...
                                    parameters.vane.shouldSaveSeparateCells);  %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:buildException';
            errorMessage.text = 'Could not build model cell';
            errorMessage.priorityLevel = 3;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end        
    end
    try %to build field map 
        fieldmap = loadFieldMap(parameters.files.outputFieldMapMatlab); %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
        fieldmap = fillFieldMapFromQuadrant(fieldmap);
        fid = fopen(parameters.files.outputFieldMapText, 'w');          %#ok - parameters is a global variable - this message comes because mphstart removes the global variable hence it has two declarations
        if ispc %then define correct EOL character 
            newline = '\r\n';
        else
            newline = '\n';
        end
        fprintf(fid,['x\ty\tz\tEx\tEy\tEz\tBx\tBy\tBz' newline]);
        fclose(fid);
        dlmwrite(parameters.files.outputFieldMapText, fieldmap, '-append', 'delimiter','\t', 'newline','pc', 'precision',10); %#ok
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:buildException';
        errorMessage.text = 'Could not build field map';
        errorMessage.priorityLevel = 3;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage);
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
        logMessage(message);
        clear comsolSectionTimer sectionTimeSeconds sectionTime text message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:endTimeException';
        errorMessage.text = 'Could not notify end of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    clear lengthData r0 rho cadOffset initialCellNo nCells verticalCellHeight beamBoxWidth nBeamBoxCells cellStart cellEnd selectionStart selectionEnd boxWidth;
    
%% Clean up 

    try %to save model and close 
        comsolModel.save([pwd filesep parameters.files.comsolModel]); %#ok
        clear comsolModel;
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
        logMessage(message);
    end

return