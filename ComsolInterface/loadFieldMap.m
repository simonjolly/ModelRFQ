function fieldmap = loadFieldMap(inputFile)
%
% function fieldmap = loadFieldMap(inputFile)
%
% loadFieldMap loads a fieldmap from a Matlab file consisting of separate
% fieldmap variables and combines them into a single fieldmap variable.
%
% See also buildComsolModel, modelRfq, getModelParameters, logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history
%
%   23-Feb-2011 M. J. Easton
%       Created function to load and combine field maps.
%       Included as part of the ModelRFQ distribution.
%
%=======================================================================

%% Check syntax 

    try %to test syntax 
        if nargin < 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:loadFieldMap:insufficientInputArguments', ...
                  'Too few input variables: syntax is fieldmap = loadFieldMap(inputFile)');
        end
        if nargin > 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:loadFieldMap:excessiveInputArguments', ...
                  'Too many input variables: syntax is fieldmap = loadFieldMap(inputFile)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:loadFieldMap:insufficientOutputArguments', ...
                  'Too few output variables: syntax is fieldmap = loadFieldMap(inputFile)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:loadFieldMap:excessiveOutputArguments', ...
                  'Too many output variables: syntax is fieldmap = loadFieldMap(inputFile)');
        end
        if exist(inputFile, 'file') ~= 2 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:invalidFile 
            error('ModelRFQ:ComsolInterface:loadFieldMap:invalidFile', ...
                 ['Invalid file: ' inputFile]);
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:syntaxException';
        message.text = 'Syntax error calling loadFieldMap';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Load data 

    try %to notify start 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:start';
        message.text = '    > Building full field map...';
        message.priorityLevel = 3;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:startTime';
        message.text = ['      Start time: ' currentTime()];
        loadFieldMapTimer = tic;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:startException';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    try %to load data 
        load(inputFile);
        fieldmap = fieldmap1;
        for i = 2:lastCellNo
            currentFieldMap = ['fieldmap' num2str(i)];
            eval(['fieldmap = [fieldmap; ' currentFieldMap '];']);
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:runException';
        message.text = 'Error loading fieldmap from file.';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    try %to notify end 
        sectionTimeSeconds = toc(loadFieldMapTimer);
        sectionTime = convertSecondsToText(sectionTimeSeconds);
        text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' sectionTime '.'];
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:endTime';
        message.text = text;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
        clear loadFieldMapTimer sectionTimeSeconds sectionTime text message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:loadFieldMap:endTimeException';
        errorMessage.text = 'Could not notify end of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end

return