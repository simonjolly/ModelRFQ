function rfqModel = modelRfq()
%
% function rfqModel = modelRfq()
%
%   rfqModel runs the steps needed to model an RFQ.
%
%   Parameters for the model are retrieved via the getModelParameters
%   function. These include the options of which further steps to include.
%   When certain steps have already been performed, it may be beneficial to
%   only include the minimum set of steps on each subsequent run.
%   Parameters also include settings for the RFQ model, the particle
%   dynamics simulation and the output functions.
%
%   Comsol is used to model the RFQ electric field and produce a field map
%   for particle tracking. The inputs to the Comsol process are a CAD SAT
%   file or an Autodesk Inventor assembly, and a Microsoft Excel
%   spreadsheet containing the cell modulation parameters.
%
%   GPT is used to model the particle tracking through the field map. The
%   field map files are first combined, then converted to GDF format, then
%   the GPT simulation is set up to track the particles through the field.
%
%   Matlab then reads in the GPT data and manipulates it to produce
%   numerical and graphical results.
%
%   Movie files can be produced showing the dynamics of the particles
%   through the simulation.
%
%   See also getModelParameters, buildComsolModel.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   15-Dec-2010 M. J. Easton
%       Created coherent function to shape the modelling process.
%
%   21-Feb-2011 M. J. Easton
%       Added fullfile calls to avoid file system errors.
%       Removed combine field maps section as no longer required.
%
%=========================================================================

%% Declarations 

    global parameters;
        
%% Check syntax 

    try %to test syntax 
        if nargin > 0 %then throw error ModelRFQ:modelRfq:incorrectInputArguments 
            error('ModelRFQ:modelRfq:incorrectInputArguments', 'Incorrect input arguments: correct syntax is rfqModel = modelRfq()');
        end
        if nargout > 1 %then throw error ModelRFQ:modelRfq:incorrectOutputArguments 
            error('ModelRFQ:modelRfq:incorrectOutputArguments', 'Incorrect output arguments: correct syntax is rfqModel = modelRfq()');
        end
    catch syntaxException
        syntaxMessage = struct;
        syntaxMessage.identifier = 'ModelRFQ:modelRfq:syntaxException';
        syntaxMessage.text = 'Syntax error calling modelRfq';
        syntaxMessage.priorityLevel = 1;
        syntaxMessage.errorLevel = 'error';
        syntaxMessage.exception = syntaxException;
        parameters = struct;
        parameters.options = struct;
        parameters.options.verbosity = struct;
        parameters.options.verbosity.toScreen = 5;
        parameters.options.verbosity.toFile = 10;
        parameters.options.verbosity.toTwitter = 3;
        parameters.files = struct;
        parameters.files.logFileNo = fopen('error.log', 'w');
        logMessage(syntaxMessage);
        fclose(parameters.files.logFileNo);
    end
    
%% Hard-coded locations 
%   - required because they are used before getModelParameters is called

    matlabFolder = 'Matlab';
    switch getComputerName() %define default Matlab location 
        case 'heppc237' 
            defaultMatlabLocation = 'D:\MJE\Dropbox\ModelRFQ\Matlab\';
        case 'chui' 
            defaultMatlabLocation = '~/Dropbox/ModelRFQ/Matlab/';
        case 'windui' 
            defaultMatlabLocation = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\Matlab\';
        otherwise 
            defaultMatlabLocation = pwd;
    end
    
%% Get model parameters 

    try %to find getModelParameters.m file
        makeFolder(fullfile(pwd, matlabFolder), false);
        destinationFile = fullfile(pwd, matlabFolder, 'getModelParameters.m');
        localSourceFile = fullfile(pwd, 'getModelParameters.m');
        masterSourceFile = fullfile(defaultMatlabLocation, 'getModelParameters.m');
        findFile(destinationFile, localSourceFile, masterSourceFile, false);
        clear destinationFile localSourceFile masterSourceFile defaultMatlabLocation;
    catch fileException
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:modelRfq:getModelParameters:fileException';
        fileMessage.text = 'Could not find getModelParameters.m file';
        fileMessage.priorityLevel = 1;
        fileMessage.errorLevel = 'error';
        fileMessage.exception = fileException;
        parameters = struct;
        parameters.options = struct;
        parameters.options.verbosity = struct;
        parameters.options.verbosity.toScreen = 5;
        parameters.options.verbosity.toFile = 10;
        parameters.options.verbosity.toTwitter = 3;
        parameters.files = struct;
        parameters.files.logFileNo = fopen('error.log', 'w');
        logMessage(fileMessage);
        fclose(parameters.files.logFileNo);
    end
    try %to get model parameters 
        cd(matlabFolder);
        parameters = getModelParameters();
        cd('..');
        clear matlabFolder;
    catch runException
        runMessage = struct;
        runMessage.identifier = 'ModelRFQ:modelRfq:getModelParameters:runException';
        runMessage.text = 'Error parsing getModelParameters.m file';
        runMessage.priorityLevel = 1;
        runMessage.errorLevel = 'error';
        runMessage.exception = runException;
        parameters = struct;
        parameters.options = struct;
        parameters.options.verbosity = struct;
        parameters.options.verbosity.toScreen = 5;
        parameters.options.verbosity.toFile = 10;
        parameters.options.verbosity.toTwitter = 3;
        parameters.files = struct;
        parameters.files.logFileNo = fopen('error.log', 'w');
        logMessage(runMessage);
        fclose(parameters.files.logFileNo);
    end

%% Start log 

    try %to set up log file 
        currentFolder = regexp(pwd, filesep, 'split');
        currentFolder = currentFolder(length(currentFolder));
        currentFolder = currentFolder{1};
        % generate log file name
        parameters.files.logFile = [currentFolder '-' date '-' '1' '.log'];
        try %to make log folder if it doesn't exist 
            makeFolder(fullfile(pwd, parameters.files.logFolder), false);
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:modelRfq:startLog:makeLogFolderException';
            fileMessage.text = ['Could not create folder ' parameters.files.logFolder];
            fileMessage.priorityLevel = 4;
            fileMessage.errorLevel = 'error';
            fileMessage.exception = fileException;
            parameters.files.logFileNo = fopen('error.log', 'w');
            logMessage(fileMessage);
            fclose(parameters.files.logFileNo);
        end  
        i = 1;
        while exist(fullfile(pwd, parameters.files.logFolder, parameters.files.logFile), 'file') == 2 %add a number to the filename 
            i = i + 1;
            parameters.files.logFile = [currentFolder '-' date '-' num2str(i) '.log'];
        end
        clear currentFolder i;
        parameters.files.fullLogFile = fullfile(pwd, parameters.files.logFolder, parameters.files.logFile);
        parameters.files.logFileNo = fopen(parameters.files.fullLogFile, 'w');
    catch fileException        
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:modelRfq:startLog:fileException';
        fileMessage.text = 'Could not create log file';
        fileMessage.priorityLevel = 4;
        fileMessage.errorLevel = 'warning';
        fileMessage.exception = fileException;
        parameters.files.logFileNo = fopen('error.log', 'w');
        logMessage(fileMessage);
        fclose(parameters.files.logFileNo);
    end
    
%% Start of function 

    try %to notify start of function 
        message = struct;
        message.identifier = 'ModelRFQ:modelRfq:startFunction';
        message.text = ['Started to model RFQ in folder ' regexprep(pwd, '\\', '\\\\') ' at ' currentTime()];
        masterTimer = tic;
        message.priorityLevel = 1;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:startFunction:exception';
        errorMessage.text = 'Could not notify start of function';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    
%% Build Comsol model and save field map 

    if parameters.options.shouldBuildModel 
        try %to build and solve Comsol model 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildComsolModel:start';
                message.text = '\nSolving for fieldmap in Comsol model...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildComsolModel:startTime';
                message.text = ['Start time: ' currentTime()];
                buildComsolTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to make CAD folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.cadFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:makeCadFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.cadFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end        
            try %to find CAD files 
                cadFileList = dir(parameters.files.cadSourceFolder);
                for i = 1 : length(cadFileList) %find each file 
                    if ~cadFileList(i).isdir %ignore directories 
                        if parameters.options.shouldUseCadImport == 1 %then include Inventor files 
                            if ( strcmpi(cadFileList(i).name(length(cadFileList(i).name)-3:length(cadFileList(i).name)), '.ipt') || strcmpi(cadFileList(i).name(length(cadFileList(i).name)-3:length(cadFileList(i).name)), '.iam') || strcmpi(cadFileList(i).name(length(cadFileList(i).name)-3:length(cadFileList(i).name)), '.xls') || strcmpi(cadFileList(i).name(length(cadFileList(i).name)-4:length(cadFileList(i).name)), '.xlsx') || strcmpi(cadFileList(i).name(length(cadFileList(i).name)-3:length(cadFileList(i).name)), '.sat') ) %then find this file 
                                destinationFile = fullfile(pwd, parameters.files.cadFolder, cadFileList(i).name);
                                localSourceFile = fullfile(pwd, cadFileList(i).name);
                                masterSourceFile = fullfile(parameters.files.cadSourceFolder, cadFileList(i).name);
                                findFile(destinationFile, localSourceFile, masterSourceFile);
                                clear destinationFile localSourceFile masterSourceFile;
                            end
                        else %only include Excel and SAT files
                            if ( strcmpi(cadFileList(i).name(length(cadFileList(i).name)-3:length(cadFileList(i).name)), '.xls') || strcmpi(cadFileList(i).name(length(cadFileList(i).name)-4:length(cadFileList(i).name)), '.xlsx') || strcmpi(cadFileList(i).name(length(cadFileList(i).name)-3:length(cadFileList(i).name)), '.sat') ) %then find this file 
                                destinationFile = fullfile(pwd, parameters.files.cadFolder, cadFileList(i).name);
                                localSourceFile = fullfile(pwd, cadFileList(i).name);
                                masterSourceFile = fullfile(parameters.files.cadSourceFolder, cadFileList(i).name);
                                findFile(destinationFile, localSourceFile, masterSourceFile);
                                clear destinationFile localSourceFile masterSourceFile;
                            end
                        end
                    end
                end
                clear cadFileList i;
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:findCadFileException';
                fileMessage.text = 'Could not find CAD files';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to make Comsol folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.comsolFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:makeComsolFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.comsolFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            if ~parameters.options.shouldUseCadImport %then use the template Comsol model file instead 
                try %to find Comsol model file 
                    destinationFile = fullfile(pwd, parameters.files.comsolFolder, parameters.files.comsolModel);
                    localSourceFile = fullfile(pwd, parameters.files.comsolModel);
                    masterSourceFile = fullfile(parameters.files.comsolSourceFolder, parameters.files.comsolModel);
                    findFile(destinationFile, localSourceFile, masterSourceFile);
                    clear destinationFile localSourceFile masterSourceFile;
                catch fileException
                    fileMessage = struct;
                    fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:findComsolModelFileException';
                    fileMessage.text = 'Could not find Comsol model file';
                    fileMessage.priorityLevel = 4;
                    fileMessage.errorLevel = 'error';
                    fileMessage.exception = fileException;
                    logMessage(fileMessage);
                end
            end
            try %to change to Comsol folder 
                cd(parameters.files.comsolFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:cdComsolFolderException';
                fileMessage.text = 'Could not enter Comsol folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to build and solve Comsol model 
                tempParameters = parameters;    %save parameters as mphstart clears them
                buildComsolModel();
                parameters = tempParameters;
                clear tempParameters;
            catch runException
                if ~exist('parameters', 'var') %then reinstate global variable
                    parameters = tempParameters;
                    clear tempParameters;
                end
                rethrow(runException);
            end
            try %to change back from Comsol folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:cdReturnFolderException';
                fileMessage.text = 'Could not return from Comsol folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end        
            try %to move fieldmap to GPT folder ready for next stage 
                makeFolder(fullfile(pwd, parameters.files.gptFolder));
                movefile(fullfile(pwd, parameters.files.comsolFolder, parameters.files.outputFieldMapText), fullfile(pwd, parameters.files.gptFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:copyFieldMapFileException';
                fileMessage.text = ['Could not move ' parameters.files.outputFieldMapText ' from ' regexprep(fullfile(pwd, parameters.files.comsolFolder), '\\', '\\\\') ' to ' regexprep(fullfile(pwd, parameters.files.gptFolder), '\\', '\\\\')];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to notify end 
                sectionTimeSeconds = toc(buildComsolTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildComsolModel:endTime';
                message.text = text;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear buildComsolTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end        
        catch generalException
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:buildComsolModel:generalException';
            errorMessage.text = 'Error building Comsol model, cannot continue...';
            errorMessage.priorityLevel = 2;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = generalException;
            if ~exist('parameters', 'var') %then reinstate global variable 
                parameters = tempParameters;
                clear tempParameters;
                logMessage(errorMessage, parameters);
            else
                logMessage(errorMessage);
            end
        end
    end

%% Convert field maps to GDF 

    if parameters.options.shouldConvertFieldMaps
        try %to convert field maps 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:start';
                message.text = '\nConverting field map to GDF...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:startTime';
                message.text = ['Start time: ' currentTime()];
                convertFieldMapsTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to make GPT folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.gptFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:combineFieldMaps:makeGptFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.gptFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to find field map 
                destinationFile = fullfile(pwd, parameters.files.gptFolder, parameters.files.inputFieldMapText);
                localSourceFile = fullfile(pwd, parameters.files.inputFieldMapText);
                masterSourceFile = [parameters.files.gptSourceFolder parameters.files.inputFieldMapText];
                findFile(destinationFile, localSourceFile, masterSourceFile);
                clear destinationFile localSourceFile masterSourceFile;
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:findFileException';
                fileMessage.text = 'Could not find field map';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change to GPT folder 
                cd(parameters.files.gptFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:cdGptFolderException';
                fileMessage.text = 'Could not enter GPT folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            gptCommand = 'asci2gdf -v ';
            gptCommand = [gptCommand '-o ' parameters.files.inputFieldMapGdf ' '];
            gptCommand = [gptCommand parameters.files.inputFieldMapText ' '];
            gptCommand = [gptCommand 'x ' num2str(parameters.tracking.xFactor) ' '];
            gptCommand = [gptCommand 'y ' num2str(parameters.tracking.yFactor) ' '];
            gptCommand = [gptCommand 'z ' num2str(parameters.tracking.zFactor) ' '];
            runGptCommand(gptCommand);
            clear gptCommand;
            try %to delete text file (no longer required as we have the .mat and .gdf files) 
                delete(parameters.files.inputFieldMapText);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:combineFieldMaps:deleteException';
                fileMessage.text = 'Could not delete field map text file.';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'warning';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change back from GPT folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:combineFieldMaps:cdReturnFolderException';
                fileMessage.text = 'Could not return from GPT folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end        
            try %to notify end 
                sectionTimeSeconds = toc(convertFieldMapsTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:endTime';
                message.text = text;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear convertFieldMapsTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end            
        catch generalException
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:convertFieldMaps:generalException';
            errorMessage.text = 'Error converting field maps, cannot continue.';
            errorMessage.priorityLevel = 2;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = generalException;
            logMessage(errorMessage);
        end
    end
    
%% Run particle tracking 

    if parameters.options.shouldRunGpt 
        try %to run GPT 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:runGpt:start';
                message.text = '\nRunning General Particle Tracer...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:runGpt:startTime';
                message.text = ['Start time: ' currentTime()];
                runGptTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:runGpt:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to make GPT folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.gptFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGpt:makeGptFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.gptFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to find input file 
                destinationFile = fullfile(pwd, parameters.files.gptFolder, parameters.files.gptInputFile);
                localSourceFile = fullfile(pwd, parameters.files.gptInputFile);
                masterSourceFile = fullfile(parameters.files.gptSourceFolder, parameters.files.gptInputFile);
                findFile(destinationFile, localSourceFile, masterSourceFile);
                clear destinationFile localSourceFile masterSourceFile;
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGpt:findFileException';
                fileMessage.text = 'Could not find GPT input file';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to find field map file 
                destinationFile = fullfile(pwd, parameters.files.gptFolder, parameters.files.inputFieldMapGdf);
                localSourceFile = fullfile(pwd, parameters.files.inputFieldMapGdf);
                masterSourceFile = fullfile(parameters.files.gptSourceFolder, parameters.files.inputFieldMapGdf);
                findFile(destinationFile, localSourceFile, masterSourceFile);
                clear destinationFile localSourceFile masterSourceFile;
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGpt:findFileException';
                fileMessage.text = 'Could not find GDF field map';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change to GPT folder 
                cd(parameters.files.gptFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGpt:cdGptFolderException';
                fileMessage.text = 'Could not enter GPT folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            gptCommand = 'gpt -v ';
            gptCommand = [gptCommand '-o ' parameters.files.gptParticleFile ' '];
            gptCommand = [gptCommand parameters.files.gptInputFile ' '];
            gptCommand = [gptCommand ' E0=' num2str(parameters.particle.energy)];
            gptCommand = [gptCommand ' m0=' num2str(parameters.particle.mass)];
            gptCommand = [gptCommand ' q0=' num2str(parameters.particle.charge)];
            gptCommand = [gptCommand ' npart=' num2str(parameters.beam.nParticles)];
            gptCommand = [gptCommand ' I=' num2str(parameters.beam.current)];
            gptCommand = [gptCommand ' tbeam=' num2str(parameters.beam.pulseLength)];
            gptCommand = [gptCommand ' freq=' num2str(parameters.beam.frequency)];
            gptCommand = [gptCommand ' ffac=' num2str(parameters.tracking.fieldFactor)];
            gptCommand = [gptCommand ' rfqfac=' num2str(parameters.tracking.zFactor)];
            gptCommand = [gptCommand ' zlen=' num2str(parameters.tracking.simulationLength)];
            gptCommand = [gptCommand ' tsim=' num2str(parameters.tracking.simulationTime)];
            gptCommand = [gptCommand ' tstep=' num2str(parameters.tracking.timeStepLength)];
            gptCommand = [gptCommand ' zstep=' num2str(parameters.tracking.screenStepLength)];
            gptCommand = [gptCommand ' rfqlen=' num2str(parameters.tracking.rfqLength)];
            runGptCommand(gptCommand);
            clear gptCommand;
            try %to change back from GPT folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGpt:cdReturnFolderException';
                fileMessage.text = 'Could not return from GPT folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to notify end 
                sectionTimeSeconds = toc(runGptTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:runGpt:endTime';
                message.text = text;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear runGptTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:runGpt:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end            
        catch generalException
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:runGpt:generalException';
            errorMessage.text = 'Error running GPT, cannot continue.';
            errorMessage.priorityLevel = 2;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = generalException;
            logMessage(errorMessage);
        end
    end
  
%% Calculate trajectories 

    if parameters.options.shouldRunGdftrans 
        try %to run GDFtrans
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:runGdftrans:start';
                message.text = '\nCalculating trajectories...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:runGdftrans:startTime';
                message.text = ['Start time: ' currentTime()];
                runGdfTransTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to make GPT folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.gptFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:makeGptFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.gptFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to find particle data 
                destinationFile = fullfile(pwd, parameters.files.gptFolder, parameters.files.gptParticleFile);
                localSourceFile = fullfile(pwd, parameters.files.gptParticleFile);
                masterSourceFile = fullfile(parameters.files.gptSourceFolder, parameters.files.gptParticleFile);
                findFile(destinationFile, localSourceFile, masterSourceFile);
                clear destinationFile localSourceFile masterSourceFile;
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:findFileException';
                fileMessage.text = 'Could not find GPT particle data for trajectory conversion';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change to GPT folder 
                cd(parameters.files.gptFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:cdGptFolderException';
                fileMessage.text = 'Could not enter GPT folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            gptCommand = 'gdftrans ';
            gptCommand = [gptCommand '-o ' parameters.files.gptTrajectoryFile ' '];
            gptCommand = [gptCommand parameters.files.gptParticleFile ' '];
            gptCommand = [gptCommand 'time x y z Bx By Bz rxy'];
            runGptCommand(gptCommand);
            clear gptCommand;
            try %to change back from GPT folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:cdReturnFolderException';
                fileMessage.text = 'Could not return from GPT folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end        
            try %to notify end 
                sectionTimeSeconds = toc(runGdfTransTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:runGdftrans:endTime';
                message.text = text;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear runGdfTransTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end            
        catch generalException
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:runGdftrans:generalException';
            errorMessage.text = 'Error running GDFTrans, cannot continue...';
            errorMessage.priorityLevel = 2;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = generalException;
            logMessage(errorMessage);
        end
    end

%% Read data into Matlab 

    try %to load trajectory data 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:start';
            message.text = '\nReading trajectory file...';
            message.priorityLevel = 2;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:startTime';
            message.text = ['Start time: ' currentTime()];
            readTrajectoryDataTimer = tic;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to make GPT folder if it doesn't exist 
            makeFolder(fullfile(pwd, parameters.files.gptFolder));
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:makeGptFolderException';
            fileMessage.text = ['Could not create folder ' parameters.files.gptFolder];
            fileMessage.priorityLevel = 4;
            fileMessage.errorLevel = 'error';
            fileMessage.exception = fileException;
            logMessage(fileMessage);
        end
        try %to find trajectory data file 
            destinationFile = fullfile(pwd, parameters.files.gptFolder, parameters.files.gptTrajectoryFile);
            localSourceFile = fullfile(pwd, parameters.files.gptTrajectoryFile);
            masterSourceFile = fullfile(parameters.files.gptSourceFolder, parameters.files.gptTrajectoryFile);
            findFile(destinationFile, localSourceFile, masterSourceFile);
            clear destinationFile localSourceFile masterSourceFile;
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:findFileException';
            fileMessage.text = 'Could not find GPT trajectory data for analysis';
            fileMessage.priorityLevel = 4;
            fileMessage.errorLevel = 'error';
            fileMessage.exception = fileException;
            logMessage(fileMessage);
        end
        [~, ~, trajectoryData] = importGdf(fullfile(parameters.files.gptFolder, parameters.files.gptTrajectoryFile));
        try %to notify end 
            sectionTimeSeconds = toc(readTrajectoryDataTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:endTime';
            message.text = text;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear readTrajectoryDataTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        if parameters.options.shouldPause %then pause 
            display('Press a key to continue...');
            pause;
        end
    catch generalException
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:readTrajectoryData:generalException';
        errorMessage.text = 'Error loading trajectory data, cannot continue.';
        errorMessage.priorityLevel = 2;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = generalException;
        logMessage(errorMessage);
    end
    try %to load particle data 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:readParticleData:start';
            message.text = '\nReading particle file...';
            message.priorityLevel = 2;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:readParticleData:startTime';
            message.text = ['Start time: ' currentTime()];
            readParticleDataTimer = tic;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:readParticleData:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to make GPT folder if it doesn't exist 
            makeFolder(fullfile(pwd, parameters.files.gptFolder));
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:modelRfq:readParticleData:makeGptFolderException';
            fileMessage.text = ['Could not create folder ' parameters.files.gptFolder];
            fileMessage.priorityLevel = 4;
            fileMessage.errorLevel = 'error';
            fileMessage.exception = fileException;
            logMessage(fileMessage);
        end
        try %to find particle data file 
            destinationFile = fullfile(pwd, parameters.files.gptFolder, parameters.files.gptParticleFile);
            localSourceFile = fullfile(pwd, parameters.files.gptParticleFile);
            masterSourceFile = fullfile(parameters.files.gptSourceFolder, parameters.files.gptParticleFile);
            findFile(destinationFile, localSourceFile, masterSourceFile);
            clear destinationFile localSourceFile masterSourceFile;
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:modelRfq:readParticleData:findFileException';
            fileMessage.text = 'Could not find GPT particle data for analysis';
            fileMessage.priorityLevel = 4;
            fileMessage.errorLevel = 'error';
            fileMessage.exception = fileException;
            logMessage(fileMessage);
        end
        [timeData, positionData] = importGdf(fullfile(parameters.files.gptFolder, parameters.files.gptParticleFile));
        try %to notify end 
            sectionTimeSeconds = toc(readParticleDataTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:readParticleData:endTime';
            message.text = text;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear readParticleDataTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:readParticleData:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        if parameters.options.shouldPause %then pause 
            display('Press a key to continue...');
            pause;
        end            
    catch generalException
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:readParticleData:generalException';
        errorMessage.text = 'Error loading particle data, cannot continue.';
        errorMessage.priorityLevel = 2;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = generalException;
        logMessage(errorMessage);
    end
   
%% Calculate losses 

    try %to calculate particle losses 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:calculateLosses:start';
            message.text = '\nCalculating particle losses from trajectory data...';
            message.priorityLevel = 2;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:calculateLosses:startTime';
            message.text = ['Start time: ' currentTime()];
            calculateLossesTimer = tic;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:calculateLosses:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        colours = tagLosses(trajectoryData, parameters.tagging);
        try %to notify end 
            sectionTimeSeconds = toc(calculateLossesTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:calculateLosses:endTime';
            message.text = text;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear calculateLossesTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:calculateLosses:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        if parameters.options.shouldPause %then pause 
            display('Press a key to continue...');
            pause;
        end            
    catch generalException
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:calculateLosses:generalException';
        errorMessage.text = 'Error calculating losses, attempting to continue...';
        errorMessage.priorityLevel = 2;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = generalException;
        logMessage(errorMessage);
    end

%% Find special particles 

    try %to find special particles 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:findSpecialParticles:start';
            message.text = '\nFinding special particles...';
            message.priorityLevel = 2;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:findSpecialParticles:startTime';
            message.text = ['Start time: ' currentTime()];
            findSpecialParticlesTimer = tic;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:findSpecialParticles:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        endScreen = positionData(parameters.tracking.endScreenNo);
        nSurvivingParticles = length(endScreen.ID);
        isGoodEnergy = endScreen.E > parameters.plot.minEnergy * parameters.particle.nNucleons;
        isGraphEnergy = endScreen.E > parameters.plot.minGraphEnergy * parameters.particle.nNucleons;
        goodEnergies = endScreen.E(isGoodEnergy);
        graphEnergies = endScreen.E(isGraphEnergy);
        nGoodEnergyParticles = length(goodEnergies);
        clear positionData isGraphEnergy;
        try %to notify end 
            sectionTimeSeconds = toc(findSpecialParticlesTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:findSpecialParticles:endTime';
            message.text = text;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear findSpecialParticlesTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:findSpecialParticles:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        if parameters.options.shouldPause %then pause 
            display('Press a key to continue...');
            pause;
        end            
    catch generalException
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:findSpecialParticles:generalException';
        errorMessage.text = 'Error finding special particles, attempting to continue...';
        errorMessage.priorityLevel = 2;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = generalException;
        logMessage(errorMessage);
    end
    
%% Calculate results 

    try %to calculate results 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:calculateResults:start';
            message.text = '\nCalculating results...';
            message.priorityLevel = 2;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:calculateResults:startTime';
            message.text = ['Start time: ' currentTime()];
            calculateResultsTimer = tic;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:calculateResults:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        results = struct;
        results.transmission = nGoodEnergyParticles/parameters.beam.nParticles;
        results.survival = nSurvivingParticles/parameters.beam.nParticles;
        results.meanEnergy = mean(goodEnergies);
        results.rmsEnergy = std(goodEnergies);
        if strcmpi(parameters.plot.energyScale,'keV') %then display in keV rather then MeV 
            displayMeanEnergy = results.meanEnergy.*1e-3;
            meanEnergyLabel = 'keV';
        else % default MeV
            displayMeanEnergy = results.meanEnergy.*1e-6;
            meanEnergyLabel = 'MeV';
        end
        displayRmsEnergy = results.rmsEnergy.*1e-3; rmsEnergyLabel = 'keV'; % rms energy always in keV
        if parameters.plot.isPerNucleon %then calculate per nucleon values 
            displayMeanEnergy = displayMeanEnergy/parameters.particle.nNucleons;
            displayRmsEnergy = displayRmsEnergy/parameters.particle.nNucleons;
            meanEnergyLabel = [meanEnergyLabel '/u'];
            rmsEnergyLabel = [rmsEnergyLabel '/u'];
        end
        clear nSurvivingParticles goodEnergies nGoodEnergyParticles;
        if parameters.options.shouldCalculateEmittance %then calculate the emittance 
            try %to calculate emittance 
                % initial x emittance
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:calculateResults:calculateEmittance:xInitialEmittance';
                message.text = ' - Calulating initial x emittance...';
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                results.xInitialEmittance = calculateEmittance(timeData(1).x.*1e3, timeData(1).xp.*1e3, timeData(1).E, parameters.particle.evMass, 'x');
                % initial y emittance
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:calculateResults:calculateEmittance:yInitialEmittance';
                message.text = ' - Calulating initial y emittance...';
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                results.yInitialEmittance = calculateEmittance(timeData(1).y.*1e3, timeData(1).yp.*1e3, timeData(1).E, parameters.particle.evMass, 'y');
                % final x emittance
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:calculateResults:calculateEmittance:xFinalEmittance';
                message.text = ' - Calulating final x emittance...';
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                results.xFinalEmittance = calculateEmittance(endScreen.x(isGoodEnergy).*1e3, endScreen.xp(isGoodEnergy).*1e3, endScreen.E(isGoodEnergy), parameters.particle.evMass, 'x');
                % final y emittance
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:calculateResults:calculateEmittance:yFinalEmittance';
                message.text = ' - Calulating final y emittance...';
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                results.yFinalEmittance = calculateEmittance(endScreen.y(isGoodEnergy).*1e3, endScreen.yp(isGoodEnergy).*1e3, endScreen.E(isGoodEnergy), parameters.particle.evMass, 'y');
                clear endScreen isGoodEnergy;
            catch runException
                runMessage = struct;
                runMessage.identifier = 'ModelRFQ:modelRfq:calculateResults:calculateEmittance:runException';
                runMessage.text = 'Error during emittance calculations';
                runMessage.priorityLevel = 2;
                runMessage.errorLevel = 'error';
                runMessage.exception = runException;
                logMessage(runMessage);
            end
        end
        try %to notify end 
            sectionTimeSeconds = toc(calculateResultsTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:calculateResults:endTime';
            message.text = text;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear calculateResultsTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:calculateResults:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to display results 
            results.text = '\nSimulation results:';
            if results.transmission == 1 %then don't display decimal places 
                displayFormat = '%1.0f';
            else
                displayFormat = '%1.1f';
            end
            results.text = [results.text '\n - transmission = ' num2str(results.transmission*100, displayFormat) '%%'];
            if results.survival == 1 %then don't display decimal places 
                displayFormat = '%1.0f';
            else
                displayFormat = '%1.1f';
            end
            results.text = [results.text '\n - survival = ' num2str(results.survival*100, displayFormat) '%%'];
            results.text = [results.text '\n - mean energy = ' num2str(displayMeanEnergy, '%1.1f') ' ' meanEnergyLabel];
            results.text = [results.text '\n - energy rms = ' num2str(displayRmsEnergy, '%1.0f') ' ' rmsEnergyLabel];
            try results.text = [results.text '\n - initial x emittance = ' num2str(results.xInitialEmittance.normalised, '%1.4f') ' mm mrad normalised']; catch, end; %#ok
            try results.text = [results.text '\n - initial y emittance = ' num2str(results.yInitialEmittance.normalised, '%1.4f') ' mm mrad normalised']; catch, end; %#ok
            try results.text = [results.text '\n - final x emittance = ' num2str(results.xFinalEmittance.normalised, '%1.4f') ' mm mrad normalised']; catch, end; %#ok
            try results.text = [results.text '\n - final y emittance = ' num2str(results.yFinalEmittance.normalised, '%1.4f') ' mm mrad normalised']; catch, end; %#ok
            resultsMessage = struct;
            resultsMessage.identifier = 'ModelRFQ:modelRfq:calculateResults:displayResults';
            resultsMessage.text = results.text;
            resultsMessage.priorityLevel = 2;
            resultsMessage.errorLevel = 'information';
            logMessage(resultsMessage);
            clear displayMeanEnergy meanEnergyLabel displayRmsEnergy rmsEnergyLabel displayFormat resultsMessage;
        catch displayException
            displayMessage = struct;
            displayMessage.identifier = 'ModelRFQ:modelRfq:calculateResults:displayException';
            displayMessage.text = 'Error displaying calculations';
            displayMessage.priorityLevel = 2;
            displayMessage.errorLevel = 'error';
            displayMessage.exception = displayException;
            logMessage(displayMessage);
        end
        if parameters.options.shouldPause %then pause 
            display('Press a key to continue...');
            pause;
        end            
    catch generalException
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:calculateResults:generalException';
        errorMessage.text = 'Error calculating results, attempting to continue...';
        errorMessage.priorityLevel = 2;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = generalException;
        logMessage(errorMessage);
    end
    
%% Build losses figures 
   
    if parameters.options.shouldBuildLossesFigure 
        try %to build losses figures 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildLosses:start';
                message.text = '\nBuilding loss diagrams...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildLosses:startTime';
                message.text = ['Start time: ' currentTime()];
                buildLossesTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildLosses:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);            
            end
            try %to make results folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.resultsFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildLosses:makeResultsFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.resultsFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change to results folder 
                cd(parameters.files.resultsFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildLosses:cdResultsFolderException';
                fileMessage.text = 'Could not enter results folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end        
            lossesFigureNo = figure;
            plotTrajectories(timeData, trajectoryData, colours, parameters.tracking.endSliceNo, parameters.tracking.endSliceNo, 0, parameters.tracking.rfqLength);
            saveFigure(lossesFigureNo, parameters.files.lossesFigure);
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end
            close(lossesFigureNo);
            clear trajectoryData colours lossesFigureNo;
            try %to change back from results folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildLosses:cdReturnFolderException';
                fileMessage.text = 'Could not return from results folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to notify end 
                sectionTimeSeconds = toc(buildLossesTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildLosses:endTime';
                message.text = text;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear buildLossesTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildLosses:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end
        catch runException
            runMessage = struct;
            runMessage.identifier = 'ModelRFQ:modelRfq:buildLosses:runException';
            runMessage.text = 'Could not build losses figures';
            runMessage.priorityLevel = 3;
            runMessage.errorLevel = 'warning';
            runMessage.exception = runException;
            logMessage(runMessage);
        end
    end
   
%% Build energy profiles 

    if parameters.options.shouldBuildEnergyFigures
        try %to build energy figures 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildEnergy:start';
                message.text = '\nBuilding energy profiles...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildEnergy:startTime';
                message.text = ['Start time: ' currentTime()];
                buildEnergyTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildEnergy:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to make results folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.resultsFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildEnergy:makeResultsFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.resultsFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change to results folder 
                cd(parameters.files.resultsFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildEnergy:cdResultsFolderException';
                fileMessage.text = 'Could not enter results folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            energyFigureNo = figure;
            if ~parameters.plot.shouldUseTightEnergy %then plot x-axis from zero to max rather than tight
                plotEnergies(energyFigureNo, graphEnergies, 0, parameters.plot.maxEnergy);
            else
                plotEnergies(energyFigureNo, graphEnergies);
            end            
            saveFigure(energyFigureNo, parameters.files.energyFigure);
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end
            close(energyFigureNo);
            % close up (5rms)
            minCloseupEnergy = results.meanEnergy - results.rmsEnergy * 5;
            maxCloseupEnergy = results.meanEnergy + results.rmsEnergy * 5;
            isCloseupGraphEnergy = graphEnergies > minCloseupEnergy & graphEnergies < maxCloseupEnergy;
            closeupGraphEnergies = graphEnergies(isCloseupGraphEnergy);
            energyFigureNo = figure;
            plotEnergies(energyFigureNo, closeupGraphEnergies, minCloseupEnergy, maxCloseupEnergy);
            saveFigure(energyFigureNo, parameters.files.closeupEnergyFigure);
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end
            close(energyFigureNo);
            clear graphEnergies energyFigureNo minCloseupEnergy maxCloseupEnergy isCloseupGraphEnergy closeupGraphEnergies;
            try %to change back from results folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildEnergy:cdReturnFolderException';
                fileMessage.text = 'Could not return from results folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to notify end 
                sectionTimeSeconds = toc(buildEnergyTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildEnergy:endTime';
                message.text = ['End time: ' currentTime()];
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear buildEnergyTimer sectionTimeSeconds sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildEnergy:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end
        catch runException
            runMessage = struct;
            runMessage.identifier = 'ModelRFQ:modelRfq:buildEnergy:runException';
            runMessage.text = 'Could not build energy profiles';
            runMessage.priorityLevel = 3;
            runMessage.errorLevel = 'warning';
            runMessage.exception = runException;
            logMessage(runMessage);
        end
    end

%% Build movie files 
 
     if parameters.options.shouldBuildMovies 
        try %to build movies 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildMovies:start';
                message.text = '\nBuilding movies...';
                message.priorityLevel = 2;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildMovies:startTime';
                message.text = ['Start time: ' currentTime()];
                buildMoviesTimer = tic;
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildMovies:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            try %to make results folder if it doesn't exist 
                makeFolder(fullfile(pwd, parameters.files.resultsFolder));
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildMovies:makeResultsFolderException';
                fileMessage.text = ['Could not create folder ' parameters.files.resultsFolder];
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to change to results folder 
                cd(parameters.files.resultsFolder);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildMovies:cdResultsFolderException';
                fileMessage.text = 'Could not enter results folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            buildMovies(timeData);
            clear timeData;
            try %to change back from results folder 
                cd('..');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:modelRfq:buildMovies:cdReturnFolderException';
                fileMessage.text = 'Could not return from results folder';
                fileMessage.priorityLevel = 4;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to notify end 
                sectionTimeSeconds = toc(buildMoviesTimer);
                sectionTime = convertSecondsToText(sectionTimeSeconds);
                text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
                message = struct;
                message.identifier = 'ModelRFQ:modelRfq:buildMovies:endTime';
                message.text = ['End time: ' currentTime()];
                message.priorityLevel = 4;
                message.errorLevel = 'information';
                logMessage(message);
                clear buildMoviesTimer sectionTimeSectons sectionTime text message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:modelRfq:buildMovies:endTimeException';
                errorMessage.text = 'Could not notify end of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if parameters.options.shouldPause %then pause 
                display('Press a key to continue...');
                pause;
            end
        catch runException
            runMessage = struct;
            runMessage.identifier = 'ModelRFQ:modelRfq:buildMovies:runException';
            runMessage.text = 'Could not build movies';
            runMessage.priorityLevel = 2;
            runMessage.errorLevel = 'error';
            runMessage.exception = runException;
            logMessage(runMessage);
        end
     end   
    
%% Write results to file 
    
    try %to write results 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:writeResults:start';
            message.text = '\nWriting results to file...';
            message.priorityLevel = 2;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:writeResults:startTime';
            message.text = ['Start time: ' currentTime()];
            writeResultsTimer = tic;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:writeResults:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to make results folder if it doesn't exist 
            makeFolder(fullfile(pwd, parameters.files.resultsFolder));
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:modelRfq:writeResults:makeResultsFolderException';
            fileMessage.text = ['Could not create folder ' parameters.files.gresultsFolder];
            fileMessage.priorityLevel = 4;
            fileMessage.errorLevel = 'error';
            fileMessage.exception = fileException;
            logMessage(fileMessage);
        end
        try %to produce results text 
            text =          'Results';
            text = [text, '\n-------'];
            try text = [text '\n' evalc('disp(results)')]; catch, end; %#ok
            text = [text '\nxInitialEmmittance:'];
            try text = [text '\n' evalc('display(results.xInitialEmittance)')]; catch, end; %#ok
            text = [text '\nxInitialEmmittance.twiss:'];
            try text = [text '\n' evalc('display(results.xInitialEmittance.twiss)')]; catch, end; %#ok
            text = [text '\nyInitialEmmittance:'];
            try text = [text '\n' evalc('display(results.yInitialEmittance)')]; catch, end; %#ok
            text = [text '\nyInitialEmmittance.twiss:'];
            try text = [text '\n' evalc('display(results.yInitialEmittance.twiss)')]; catch, end; %#ok
            text = [text '\nxFinalEmittance:'];
            try text = [text '\n' evalc('display(results.xFinalEmittance)')]; catch, end; %#ok
            text = [text '\nxFinalEmmittance.twiss:'];
            try text = [text '\n' evalc('display(results.xFinalEmittance.twiss)')]; catch, end; %#ok
            text = [text '\nyFinalEmittance:'];
            try text = [text '\n' evalc('display(results.yFinalEmittance)')]; catch, end; %#ok
            text = [text '\nyFinalEmittance.twiss:'];
            try text = [text '\n' evalc('display(results.yFinalEmittance.twiss)')]; catch, end; %#ok
            text = [text '\nParameters'];
            text = [text '\n----------'];
            text = [text '\nrfqType: ' parameters.rfqType];
            text = [text '\noptions:'];
            try text = [text '\n' evalc('display(parameters.options)')]; catch, end; %#ok
            text = [text '\noptions.verbosity:'];
            try text = [text '\n' evalc('display(parameters.options.verbosity)')]; catch, end; %#ok
            text = [text '\nfiles:'];
            try text = [text '\n' evalc('display(parameters.files)')]; catch, end; %#ok
            text = [text '\ninputFieldMaps:'];
            try text = [text '\n' evalc('display(parameters.files.inputFieldMaps)')]; catch, end; %#ok
            text = [text '\ntagging:'];
            try text = [text '\n' evalc('display(parameters.tagging)')]; catch, end; %#ok
            text = [text '\nplot:'];
            try text = [text '\n' evalc('display(parameters.plot)')]; catch, end; %#ok
            text = [text '\nvane:'];
            try text = [text '\n' evalc('display(parameters.vane)')]; catch, end; %#ok
            text = [text '\nparticle:'];
            try text = [text '\n' evalc('display(parameters.particle)')]; catch, end; %#ok
            text = [text '\nbeam:'];
            try text = [text '\n' evalc('display(parameters.beam)')]; catch, end; %#ok
            text = [text '\ntracking:'];
            try text = [text '\n' evalc('display(parameters.tracking)')]; catch, end; %#ok
            text = regexprep(text, '\\', '\\\\');
            text = regexprep(text, '\n', '\\n');
            text = regexprep(text, '\\\\n', '\\n');      
            results.text2 = text;
        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:writeResults:produceResults';
            message.text = 'Could not produce results text';
            message.priorityLevel = 4;
            message.errorLevel = 'error';
            message.exception = exception;
            logMessage(message);
        end
        try %to write results and parameters to text file 
            if ispc %line ending is \r\n for Windows, \n for Mac
                text2 = regexprep(text, '\\n', '\\r\\n');
            else
                text2 = text;
            end
            parameters.files.resultsFile = parameters.files.logFile; %same filename, different location
            resultsFileNo = fopen(fullfile(pwd, parameters.files.resultsFolder, parameters.files.resultsFile), 'w');
            fprintf(resultsFileNo, text2);
            fclose(resultsFileNo);
            clear text2 resultsFileNo;
        catch runException
            runMessage = struct;
            runMessage.identifier = 'ModelRFQ:modelRfq:writeResults:writeException';
            runMessage.text = 'Could not write results to file';
            runMessage.priorityLevel = 4;
            runMessage.errorLevel = 'warning';
            runMessage.exception = runException;
            logMessage(runMessage);
        end
        try %to log results 
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:writeResults:logMessage';
            message.text = ['\n' text];
            message.priorityLevel = 7;
            message.errorLevel = 'information';
            logMessage(message);
            clear text message;
        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:writeResults:logMessageException';
            message.text = 'Could not log results';
            message.priorityLevel = 8;
            message.errorLevel = 'warning';
            message.exception = exception;
            logMessage(message);
        end
        try %to write results and parameters to Matlab files 
            save(fullfile(pwd, parameters.files.resultsFolder, [parameters.files.resultsFile(1:end-4) '.mat']), 'results');
            save(fullfile(pwd, parameters.files.logFolder, ['parameters-' parameters.files.logFile(1:end-4) '.mat']), 'parameters');
        catch runException
            runMessage = struct;
            runMessage.identifier = 'ModelRFQ:modelRfq:writeResultsMatlab:saveException';
            runMessage.text = 'Could not save results to file';
            runMessage.priorityLevel = 4;
            runMessage.errorLevel = 'warning';
            runMessage.exception = runException;
            logMessage(runMessage);
        end
        try %to notify end 
            sectionTimeSeconds = toc(writeResultsTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['End time: ' currentTime() '\n' 'Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:modelRfq:writeResults:endTime';
            message.text = text;
            message.priorityLevel = 4;
            message.errorLevel = 'information';
            logMessage(message);
            clear writeResultsTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:modelRfq:writeResults:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    catch generalException
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:writeResults:generalException';
        errorMessage.text = 'Could not write results to file';
        errorMessage.priorityLevel = 4;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = generalException;
        logMessage(errorMessage);
    end

%% Notify completion 

    try %to notify end of function 
        text = ['ModelRFQ complete in folder ' regexprep(pwd, '\\', '\\\\') ' at ' currentTime()];
        modelTimeSeconds = toc(masterTimer);
        modelTime = convertSecondsToText(modelTimeSeconds);
        text = [text '\n' 'Elapsed time: ' modelTime '.'];
        if parameters.options.verbosity.toScreen > 1 %then add a blank line 
           text = ['\n' text];
        end
        message = struct;
        message.identifier = 'ModelRFQ:modelRfq:endFunction';
        message.text = text;
        message.priorityLevel = 1;
        message.errorLevel = 'information';
        logMessage(message);
        clear text message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:modelRfq:endFunctionException';
        errorMessage.text = 'Could not notify end of function';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    
%% Clean up 

    try %to clean up 
        fclose(parameters.files.logFileNo);
        clear parameters.files.logFileNo;
    catch fileException
        runMessage = struct;
        runMessage.identifier = 'ModelRFQ:modelRfq:cleanUp:cleanupException';
        runMessage.text = 'Error cleaning up. Attempting to continue...';
        runMessage.priorityLevel = 4;
        runMessage.errorLevel = 'warning';
        runMessage.exception = fileException;
        logMessage(runMessage);
    end
    
%% Return model details 

    rfqModel = struct;
    rfqModel.parameters = parameters;
    rfqModel.results = results;
    
    clear results;
    clear global parameters;

return