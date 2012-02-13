function logMessage(message, inputParameters)
%
% function logMessage(message, [inputParameters])
%
%   Logs the message to screen, file and Twitter based on the message level
%   and the verbosity settings.
%
%   message is a structure holding the message ID, message text, 
%   error level and priority level, and the exception object if applicable.
%
%   message.identifier should be the message identifier,
%    e.g. 'ModelRFQ:buildEnergyFigure:cannotSetAxis'
%
%   message.text should be the message to be logged as a string.
%
%   message.errorLevel should be a string, one of:
%         'error' - throw an error and stop
%       'warning' - show a warning and continue
%   'information' - log information, no warning or error
%
%   message.priorityLevel should be a priority level such that 
%   verbosity.method >= message.priorityLevel displays the message at the 
%   correct verbosity level. For example, if verbosity.toScreen is set to 5, 
%   then a message.priorityLevel of 5 or lower will be displayed. 
%
%   message.priorityLevel = 1 is the highest priority and is displayed at 
%   any verbosity level above zero.
%
%   message.priorityLevel = 10 is the lowest priority and is only displayed 
%   at the highest verbosity level of 10.
%
%   message.exception should contain the exception object if relevant.
%
%   parameters should be a globally available structure defined by 
%   getModelParameters, containing parameters.options.verbosity
%   and parameters.files.logFileNo. If the global parameters variable is
%   not available, the parameters structure can be sent as an input
%   variable, inputParameters.
%
%   The calling function should have already opened the log file for writing.
%
%   Verbosity levels
%    0 - no output
%    1 - start and stop of full function
%    2 - also start of each major section in the main modelRfq function
%    3 - also start of major sections in subroutines
%    4 - also more detail in modelRfq function
%    5 - also more detail in subroutines
%    9 - also include Twitter connection errors
%   10 - maximum detail
%
%   See also modelRfq, getModelParameters

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   15-Dec-2010 M. J. Easton
%       Created function to log messages to screen, file and Twitter
%
%   14-Feb-2011 M. J. Easton
%       Added last exception check to reduce repeated exception details in
%       log file.
%
%=========================================================================

%% Declarations 

    global parameters;
    persistent lastException; 
    
    if ispc
        newline = '\r\n';
    else
        newline = '\n';
    end

%% Check syntax 

    try %to check syntax 
        if nargin < 1 %then throw error ModelRFQ:Functions:logMessage:insufficientInputArguments 
            error('ModelRFQ:Functions:logMessage:insufficientInputArguments', 'Insufficient input arguments: correct syntax is logMessage(message)');
        end
        if nargin > 2 %then throw error ModelRFQ:Functions:logMessage:excessiveInputArguments 
            error('ModelRFQ:Functions:logMessage:excessiveInputArguments', 'Excessive input arguments: correct syntax is logMessage(message, [inputParameters])');
        end
        if nargout ~= 0 %then throw error ModelRFQ:Functions:logMessage:incorrectOutputArguments 
            error('ModelRFQ:Functions:logMessage:incorrectOutputArguments', 'Incorrect output arguments: correct syntax is logMessage(message)');
        end
        if ~isstruct(message) ... %then throw error ModelRFQ:Functions:logMessage:invalidMessage 
                || ~ischar(message.identifier) || ~ischar(message.text) ...
                || ~isnumeric(message.priorityLevel) || ~ischar(message.errorLevel) 
            warning('ModelRFQ:Functions:logMessage:invalidMessage', ...
                    'Incorrect message structure: type ''help logMessage'' for details. Using default values.');
            if ischar(message) %then use this for the message text 
                messageText = message;
            else
                messageText = '';
            end
            message = struct;
            message.identifier = 'ModelRFQ:Functions:logMessage:dummyIdentifier';
            message.text = messageText;
            message.priorityLevel = 1;
            message.errorLevel = 'information';
        end
        if nargin == 2 %then store parameters 
            parameters = inputParameters;
        end
        if ~isstruct(parameters) ... %then throw error ModelRFQ:Functions:logMessage:incorrectParameters
            || ~isstruct(parameters.options.verbosity) || ~isnumeric(parameters.files.logFileNo) ...
            || ~isnumeric(parameters.options.verbosity.toScreen) || ~isnumeric(parameters.options.verbosity.toFile) || ~isnumeric(parameters.options.verbosity.toTwitter)
            warning('ModelRFQ:Functions:logMessage:incorrectParameters', ...
                    'Cannot find global parameters structure. Using default parameters.');
            parameters = struct;
            parameters.options = struct;
            parameters.options.verbosity = struct;
            parameters.options.verbosity.toScreen = 5;
            parameters.options.verbosity.toFile = 10;
            parameters.options.verbosity.toTwitter = 3;
            parameters.files = struct;
            parameters.files.logFileNo = fopen('ModelRFQ.log', 'a');
        end
    catch syntaxException
        syntaxMessage = struct;
        syntaxMessage.identifier = 'ModelRFQ:Functions:logMessage:syntaxException';
        syntaxMessage.text = 'Syntax error calling logMessage: correct syntax is logMessage(message)';
        syntaxMessage.priorityLevel = 1;
        syntaxMessage.errorLevel = 'error';
        syntaxMessage.exception = syntaxException;
        logMessage(syntaxMessage);
    end    
    
%% Check last exception to avoid duplication 

    shouldSkipExceptionDetails = false;
    if ~strcmpi(message.errorLevel, 'information') %then check if it is the same as the prvious error 
        try
            if strcmpi(message.exception.identifier, lastException.identifier) %then don't print the exception details
                shouldSkipExceptionDetails = true;
            end        
        catch %#ok - there may not be an exception or a last exception, in which case, ignore this section
        end
        try
            lastException = message.exception;
        catch %#ok - there may not be an exception, in which case, ignore this section
        end
    end
    
%% Write output to screen 
    
    if parameters.options.verbosity.toScreen >= message.priorityLevel %then display the message 
        switch message.errorLevel
            case 'error'
                disp(' ');
                disp(['Error: ' sprintf(message.text)]);
                disp(['       ' message.identifier]);
                disp(' ');
            case 'warning'
                % warning notice will be shown (below) 
                % so no extra text required
            case 'information'
                fprintf([message.text '\n']);
        end
    end

%% Write messages to file 
    
    if parameters.options.verbosity.toFile >= message.priorityLevel %then write the message 
        try %to write to file
            if ispc
                text = regexprep(message.text, '\\n', '\\r\\n');
                try exceptionText = regexprep(message.exception.message, '\n', '\r\n'); catch; end %#ok - exception may not exist
            else
                text = message.text;
                try exceptionText = message.exception.message; catch; end %#ok - exception may not exist
            end
            switch message.errorLevel
                case 'error' 
                    fprintf(parameters.files.logFileNo, [newline  '%s' newline], ['Error: ' sprintf(text)]);
                    fprintf(parameters.files.logFileNo, [ '%s' newline], ['       ' message.identifier]);
                    if ~shouldSkipExceptionDetails %then write exception details
                        fprintf(parameters.files.logFileNo, [newline  '%s' newline], 'Exception details:');
                        fprintf(parameters.files.logFileNo, [ '%s' newline], ['    code: ' message.exception.identifier]);
                        fprintf(parameters.files.logFileNo, [ '%s' newline], [' message: ' exceptionText]);
                        for i = 1 : length(message.exception.stack)
                            fprintf(parameters.files.logFileNo, [ '%s' newline], ['    file: ' message.exception.stack(i).file]);
                            fprintf(parameters.files.logFileNo, [ '%s' newline], ['    name: ' message.exception.stack(i).name]);
                            fprintf(parameters.files.logFileNo, [ '%s' newline], ['    line: ' num2str(message.exception.stack(i).line)]);
                        end
                        fprintf(parameters.files.logFileNo, newline);
                    end                    
                case 'warning' 
                    fprintf(parameters.files.logFileNo, [ '%s' newline], ['Warning: ' sprintf(text)]);
                    fprintf(parameters.files.logFileNo, [ '%s' newline], ['         ' message.identifier]);
                    if ~shouldSkipExceptionDetails %then write exception details
                        try %to show exception details, which may not exist 
                            fprintf(parameters.files.logFileNo, [ '%s' newline], ['    code: ' message.exception.identifier]);
                            fprintf(parameters.files.logFileNo, [ '%s' newline], [' message: ' exceptionText]);
                            for i = 1 : length(message.exception.stack)
                                fprintf(parameters.files.logFileNo, [ '%s' newline], ['    file: ' message.exception.stack(i).file]);
                                fprintf(parameters.files.logFileNo, [ '%s' newline], ['    name: ' message.exception.stack(i).name]);
                                fprintf(parameters.files.logFileNo, [ '%s' newline], ['    line: ' num2str(message.exception.stack(i).line)]);
                            end
                            fprintf(parameters.files.logFileNo, newline);
                        catch %#ok
                            %do nothing
                        end
                    end
                case 'information' 
                    fprintf(parameters.files.logFileNo, [ '%s' newline], sprintf(text));
            end
            clear text;
        catch fileException
            fileMessage = struct;
            fileMessage.identifier = 'ModelRFQ:Functions:logMessage:fileException';
            fileMessage.text = 'Connection to log file failed';
            fileMessage.priorityLevel = 8;
            fileMessage.errorLevel = 'warning';
            fileMessage.exception = fileException;
            logMessage(fileMessage);
        end
    end

%% Send messages to Twitter 
    
    if ~strcmpi(message.identifier, 'ModelRFQ:Functions:logMessage:twitterException') %don't loop infinitely 
        shouldTweet = false;
        switch message.errorLevel %tweet all errors, warnings under level 9, and information based on verbosity 
            case 'error'
                shouldTweet = true;
                text = ['Error: ' message.text];
            case 'warning'
                if message.priorityLevel < 8 %then prepare the message
                    shouldTweet = true;
                    text = ['Warning: ' message.text];
                end
            case 'information'
                if parameters.options.verbosity.toTwitter >= message.priorityLevel %then prepare the message
                    shouldTweet = true;
                    text = message.text;
                end
        end
        if shouldTweet %then tweet the message 
            try %to tweet message 
                text = regexprep(text, '\\n', ' \| ');
                text = regexprep(text, '\\\\', '\\');
                text = regexprep(text, '\%\%', '\%');
                text = regexprep(text, ' - ', '');
                text = regexprep(text, '    > ', '');
                text = regexprep(text, '      ', '');
                if strcmp(text(1:3), ' | '), text = text(4:end); end
                if length(text) > 140, text = [text(1:137) '...']; end
                twit(text);
            catch twitterException
                twitterMessage = struct;
                twitterMessage.identifier = 'ModelRFQ:Functions:logMessage:twitterException';
                twitterMessage.text = 'Connection to Twitter failed';
                twitterMessage.priorityLevel = 9;
                twitterMessage.errorLevel = 'warning';
                twitterMessage.exception = twitterException;
                logMessage(twitterMessage);
            end
        end
    end

%% Throw errors or show warnings 

    switch message.errorLevel %error, warning or information 
        case 'error'
            % Always rethrow errors, irrespective of priority.
            % Handling passes back to the calling function.
            shouldFakeError = false;
            try %to define exception
                dummy = message.exception;      %#ok
            catch                               %#ok
                shouldFakeError = true;
            end
            if shouldFakeError
                error(message.identifier, message.text);
            else
                rethrow(message.exception);               
            end            
        case 'warning' % only show significant warnings
            if parameters.options.verbosity.toScreen >= message.priorityLevel %then display the message
                warning(message.identifier, message.text);                
            end
    end

return