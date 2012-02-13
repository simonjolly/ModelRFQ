function [timeData, positionData, trajectoryData] = importGdf(inputFile)
%
% function [timeData, positionData, trajectoryData] = importGdf(inputFile)
%
%   importGdf imports data from a GDF binary data file created by GPT.
%
%   Based on gdf2mat code by Simon Jolly, released under GPL.
%
%   importGdf is used to convert GPT particle data, from a GDF binary file,
%   into a format that Matlab can read.
%
%   importGdf can read both time/position slice data and trajectory data,
%   created using the GPT function GDFTrans.  Since a data file will only
%   contain one of these two kinds of data, arrays corresponding to the
%   other type will be empty.
%
%   [timeData] = importGdf(inputFile) 
%     - reads in GDF file inputFile, converts the data into Matlab format, 
%       and outputs the time data as the structure array timeData.
%
%   [timeData, positionData] = importGdf(inputFile) 
%     - as above, but also outputs the position data as the structure 
%       array positionData.
%
%   [~, ~, trajectoryData] = importGdf(inputFile) 
%     - as above, but outputs trajectory data as the structure array 
%       trajectoryData instead of the time and position data.  This implies 
%       that the GDF file being read contains trajectory data.
%
%   **Note** - by using the full syntax: 
%   [timeData, positionData, trajectoryData] = importGdf(inputFile)
%   either trajectoryData or timeData and positionData will be empty, 
%   since a GDF file can either contain time/position slice data or 
%   trajectory data, but not both. The forms above are more efficient.
%
%   parameters should be a globally available structure defined by 
%   getModelParameters, containing parameters.options.verbosity,
%   parameters.particle.electronCharge and parameters.particle.lightSpeed
%
%   importGdf draws heavily on the function gdf2mat written by Simon Jolly
%   and released under the GNU public licence. gdf2mat can handle many more
%   input and output variables, and allows much more flexibility for
%   importing data. importGdf includes only the code required for the
%   ModelRFQ distribution.
%
%   See also modelRfq, getModelParameters, runGptCommand, readGdfHeader, 
%   readGdf.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from gdf2mat by Simon Jolly, Imperial College London.
%
% File history
%
%   01-Apr-2008 S. Jolly
%       gdf2mat original version.
%
%   10-Jul-2009 S. Jolly
%       gdf2mat version used for this distribution.
%
%   18-Apr-2010 M. J. Easton
%       Created importGdf as part of ModelRFQ distribution.
%
%======================================================================

%% Declarations 

    global parameters;

%% Check syntax 

    try %to check syntax 
        if nargin > 1 %then throw error ModelRFQ:GptInterface:importGdf:excessiveInputArguments 
            error('ModelRFQ:GptInterface:importGdf:excessiveInputArguments', ...
                  'Can only specify 1 input argument: [timeData, positionData, trajectoryData] = importGdf(inputFile)');
        end
        if nargin < 1 %then throw error ModelRFQ:GptInterface:importGdf:insufficientInputArguments 
            error('ModelRFQ:GptInterface:importGdf:insufficientInputArguments', ...
                  'Must specify at least 1 input argument: [timeData, positionData, trajectoryData] = importGdf(inputFile)');
        end
        if nargout > 3 %then throw error ModelRFQ:GptInterface:importGdf:excessiveOutputArguments 
            error('ModelRFQ:GptInterface:importGdf:excessiveOutputArguments', ... 
                  'Can only specify 3 output arguments: [timeData, positionData, trajectoryData] = importGdf(inputFile)');
        end
        if nargin < 1 %then throw error ModelRFQ:GptInterface:importGdf:insufficientOutputArguments 
            error('ModelRFQ:GptInterface:importGdf:insufficientOutputArguments', ...
                  'Must specify at least 1 input argument: [timeData] = importGdf(inputFile)');
        end
        if ~ischar(inputFile) %then throw error ModelRFQ:GptInterface:importGdf:invalidFileName 
            error('ModelRFQ:GptInterface:importGdf:invalidFileName', ...
                  'Input filename must be a string');
        end
        if ~strcmpi(inputFile(end-2:end),'gdf') %then throw error ModelRFQ:GptInterface:importGdf:invalidFileType 
            error('ModelRFQ:GptInterface:importGdf:invalidFileType', ...
                  'Input file is not a GDF file')
        end
        if exist(inputFile,'file') ~= 2  %then throw error ModelRFQ:GptInterface:importGdf:invalidFile 
            error('ModelRFQ:GptInterface:importGdf:invalidFile', ...
                  'Input file cannot be found')
        end
    catch syntaxException
        syntaxMessage = struct;
        syntaxMessage.identifier = 'ModelRFQ:GptInterface:importGdf:syntaxException';
        syntaxMessage.text = 'Syntax error calling importGdf: correct syntax is [timeData, positionData, trajectoryData] = importGdf(inputFile)';
        syntaxMessage.priorityLevel = 3;
        syntaxMessage.errorLevel = 'error';
        syntaxMessage.exception = syntaxException;
        logMessage(syntaxMessage);
    end
    
%% Initialise variables 

    timeData = [];
    positionData = [];
    trajectoryData = [];
    numderivs = 0;
    cputime = 0;
    
%% Select particle coordinates to read out 

    particleSet = {'x', 'y', 'z', 'Bx', 'By', 'Bz', 'G', 'rxy', 'fEx', ...
                   'fEy', 'fEz', 'fBx', 'fBy', 'fBz', 'm', 'q', 'nmacro', 'rmacro', ...
                   'ID', 'time', 'position', 'xp', 'yp', 'E'} ;

%% Open file and read in main data header (start timer) 

    try %to open file 
        inputFileNo = fopen(inputFile, 'r');
        % find length of file 
        fseek(inputFileNo,0,'eof');
        endPosition = ftell(inputFileNo);
        % return to start of file 
        fseek(inputFileNo,0,'bof');
    catch fileException
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:GptInterface:importGdf:loadFileException';
        fileMessage.text = ['Could not load input file: ' inputFile];
        fileMessage.priorityLevel = 3;
        fileMessage.errorLevel = 'error';
        fileMessage.exception = fileException;
        logMessage(fileMessage);
    end
    try %to display progress bar 
        if parameters.options.verbosity.toScreen >= 3 %then display progress bar and start timer 
            waitbarNo = waitbar(0,'Loading data slice... ','Name','GDF File Progress');             
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:importGdf:createProgressBar1Exception';
        message.text = 'Could not create progress bar';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    tic;
    try %to read main header information 
        %[~,~,fileType,~,~,~,~,~,~] = gdfreadmainhead(inputFileNo);
        fileType = readGdfHeader(inputFileNo);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:importGdf:readHeaderException';
        message.text = 'Could not read header information';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Main loop 

    iTime = 0;
    iPosition = 0;
    iTrajectory = 0;
    isEndOfFile = false;
    while ~isEndOfFile %read in data 
        try %to find out how large the file is, to set the length of the waitbar 
            currentPosition = ftell(inputFileNo) ;
            currentProgress = currentPosition/endPosition ;
            if parameters.options.verbosity.toScreen >= 3 %then show progress bar 
                if iTrajectory > iTime %then progress is trajectory data, otherwise time data 
                    waitbarNo = waitbar(currentProgress,waitbarNo,['Loading trajectory slice ' num2str(iTrajectory+1) ' (' num2str(currentProgress.*100,'%12.0f') '%)']) ;
                else
                    waitbarNo = waitbar(currentProgress,waitbarNo,['Loading timeslice ' num2str(iTime+1) ' (' num2str(currentProgress.*100,'%12.0f') '%)']) ;
                end
            end
        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:importGdf:findFileLength';
            message.text = 'Could not read file length';
            message.priorityLevel = 5;
            message.errorLevel = 'warning';
            message.exception = exception;
            logMessage(message);
        end
        try %to read in data header 
            [dataName, dataLength, readString, extraOperators, isStartOfDirectory, isEndOfDirectory, isEndOfFile] = readGdf(inputFileNo);  %#ok - variables are used in eval strings
        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:importGdf:readDataHeaderException';
            message.text = 'Could not read data header';
            message.priorityLevel = 3;
            message.errorLevel = 'error';
            message.exception = exception;
            logMessage(message);
        end
        if isEndOfFile, break; end
        try %to read in first data point 
            eval([dataName ' = fread(inputFileNo, dataLength, readString)' extraOperators ';']);
        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:importGdf:readFirstDataPointException';
            message.text = 'Could not read first data point';
            message.priorityLevel = 3;
            message.errorLevel = 'error';
            message.exception = exception;
            logMessage(message);
        end
        try %to read in all directory data 
            if isStartOfDirectory %then work through whole directory 
                switch dataName(1:2) %define type of data 
                    case 'ti' %time data 
                        currentArrayName = 'timeData' ;
                        iCurrentName = 'iTime' ;
                        iTime = iTime + 1 ;
                    case 'po' %position data 
                        currentArrayName = 'positionData' ;
                        iCurrentName = 'iPosition' ;
                        iPosition = iPosition + 1 ;
                    case 'ID' %trajectory data
                        currentArrayName = 'trajectoryData' ;
                        iCurrentName = 'iTrajectory' ;
                        iTrajectory = iTrajectory + 1 ;
                    otherwise %show warning ModelRFQ:GptInterface:importGdf:unknownDirectoryType 
                        currentArrayName = [];
                        iCurrentName = [];
                        message = struct;
                        message.identifier = 'ModelRFQ:GptInterface:importGdf:unknownDirectoryType';
                        message.text = ['Unknown directory type ' dataName '...'];
                        message.priorityLevel = 3;
                        message.errorLevel = 'warning';
                        logMessage(message);
                end
                eval([currentArrayName '(' iCurrentName ').' dataName ' = ' dataName ' ;']) ;
                isEndOfDirectory = false;
                while ~isEndOfDirectory %read out the directory to the relevant structure 
                    [dataName, dataLength, readString, extraOperators, isStartOfDirectory, isEndOfDirectory, isEndOfFile] = readGdf(inputFileNo);  %#ok - variables are used in eval strings
                    if isEndOfDirectory || isEndOfFile, break; end
                    if sum(strcmp(particleSet,dataName)) > 0 || strcmp(fileType,'GDFA') %then store data 
                        eval([currentArrayName '(' iCurrentName ').' dataName ' = fread(inputFileNo, dataLength, readString)' extraOperators ' ;']) ;
                    else
                        eval([dataName ' = fread(inputFileNo, dataLength, readString)' extraOperators ' ;']) ;
                    end
                end
                if isEndOfDirectory %then calculate dependant variables 
                    eval(['hasBx = isfield(' currentArrayName ', ''Bx'') ;']);
                    eval(['hasBy = isfield(' currentArrayName ', ''By'') ;']);
                    eval(['hasBz = isfield(' currentArrayName ', ''Bz'') ;']);
                    eval(['hasM = isfield(' currentArrayName ', ''m'') ;']);
                    if hasBx && hasBz %then calculate xp
                        eval([currentArrayName '(' iCurrentName ').xp = ' ...
                                'atan2(' currentArrayName '(' iCurrentName ').Bx,' ...
                                         currentArrayName '(' iCurrentName ').Bz);']);
                    end
                    if hasBx && hasBz %then calculate yp
                        eval([currentArrayName '(' iCurrentName ').yp = ' ...
                                'atan2(' currentArrayName '(' iCurrentName ').By,' ...
                                         currentArrayName '(' iCurrentName ').Bz);']);
                    end
                    if hasM %then calculate E
                        eval([currentArrayName '(' iCurrentName ').E = (' ...
                              currentArrayName '(' iCurrentName ').m.* ' ...
                              '(' currentArrayName '(' iCurrentName ').G - 1).*' ...
                              '(parameters.particle.lightSpeed.^2)) / parameters.particle.electronCharge;']);
                    end
                end
            end
        catch exception
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:importGdf:readDirectoryDataException';
            message.text = 'Could not read directory data';
            message.priorityLevel = 3;
            message.errorLevel = 'error';
            message.exception = exception;
            logMessage(message);
        end
    end

%% Close file and waitbar 

    try %to close file and waitbar 
        fclose(inputFileNo);
        if parameters.options.verbosity.toScreen >= 3, close(waitbarNo), end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:importGdf:closeFileException';
        message.text = ['Could not close input file: ' inputFile];
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Display statistics (end timer) 
    
    try %to display statistics 
        if exist('cputime','var') && length(cputime) == 1 && cputime > 0
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:importGdf:cputime';
            message.text = ['CPU Time   : ' num2str(cputime,'%0.6f')];
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
        end
        if exist('numderivs','var') && length(numderivs) == 1 && numderivs > 0
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:importGdf:numderivs';
            message.text = ['Num. Derivs: ' num2str(numderivs,'%0.0f')];
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
        end
        loadTime = toc;
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:importGdf:numderivs';
        message.text = ['Load time  : ' num2str(loadTime,'%0.6f') ' secs'];
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:importGdf:displayStatistics';
        message.text = 'Could not display statistics';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

return