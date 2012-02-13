function [outputParameters, recurseLevout] = logMessage(message, inputParameters, recurseLevel)
%
% function [outputParameters, recurseLevout] = logMessage(message, inputParameters, recurseLevel)
%
%   LOGMESSAGE - Log messages to screen, file and Twitter
%
%   logMessage(message)
%   logMessage(message, inputParameters)
%   logMessage(message, inputParameters, recurseLevel)
%   [outputParameters] = logMessage(...)
%   [outputParameters, recurseLevout] = logMessage(...)
%
%   Logs the message to screen, file and Twitter based on the message level
%   and the verbosity settings.
%
%   logMessage(message) - log details from MESSAGE to screen, file and
%   Twitter. MESSAGE is a structure holding the message ID, message text, 
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
%   logMessage(message, inputParameters) - also pass through the parameters
%   structure INPUTPARAMETERS: should be a structure (normally defined by
%   getModelParameters), containing parameters.options.verbosity and
%   parameters.files.logFileNo. If INPUTPARAMETERS is not specified, the
%   default parameters structure is used (for details on verbosity levels,
%   see below):
%
%        parameters.files.logFileNo = fopen('ModelRFQ.log', 'a');
%        parameters.options.verbosity.toScreen = 0;
%        parameters.options.verbosity.toFile = 8 ;
%        parameters.options.verbosity.toTwitter = 0 ;
%
%   logMessage(message, inputParameters, recurseLevel) - adds recursion
%   checking to the recursive calls to logMessage.  If RECURSELEVEL is
%   greater than 10, logMessage stops trying to write messages to Twitter
%   and the log file: this prevents infinite loops if neither can be
%   written to.
%
%   [outputParameters] = logMessage(...) - returns the modified PARAMETERS
%   structure as OUTPUTPARAMETERS.
%
%   [outputParameters, recurseLevout] = logMessage(...) - also returns the
%   recursion level as RECURSELEVOUT.
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
%   11-May-2011 S. Jolly
%       Modified input syntax checking to remove global parameters
%       reference and prevent infinite loops in self-referenced function.
%       Also added file closure at function end to prevent multiple
%       openings of the same log file.
%
%=========================================================================

%% Declarations 

%    global parameters;
    persistent lastException; 
    
    if ispc
        newline = '\r\n';
    else
        newline = '\n';
    end

    defTwitVerbLev = 0 ;
    defScreenVerbLev = 10 ;
    defFileVerbLev = 10 ;

%% Check syntax 

    if nargin < 3 || isempty(recurseLevel)
        recurseLevel = 0 ;
    end
    if nargin < 2 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
    else % store parameters
        parameters = inputParameters;
    end

    try %to check syntax
        if nargin < 1 %then throw error ModelRFQ:Functions:logMessage:insufficientInputArguments 
            error('ModelRFQ:Functions:logMessage:insufficientInputArguments', 'Insufficient input arguments: correct syntax is logMessage(message)');
        end
        if nargin > 3 %then throw error ModelRFQ:Functions:logMessage:excessiveInputArguments 
            error('ModelRFQ:Functions:logMessage:excessiveInputArguments', ...
                'Excessive input arguments: correct syntax is logMessage(message, inputParameters, recurseLevel)');
        end
        if nargout > 2 %then throw error ModelRFQ:Functions:logMessage:incorrectOutputArguments 
            error('ModelRFQ:Functions:logMessage:incorrectOutputArguments', ...
                'Excessive output arguments: correct syntax is [outputParameters, recurseLevout] = logMessage(message)');
        end
        if ~isstruct(message) ... %then throw error ModelRFQ:Functions:logMessage:invalidMessage 
                || ~isfield(message, 'identifier') || ~ischar(message.identifier) ...
                || ~isfield(message, 'text') || ~ischar(message.text) ...
                || ~isfield(message, 'priorityLevel') || ~isnumeric(message.priorityLevel) ...
                || ~isfield(message, 'errorLevel') || ~ischar(message.errorLevel)

            warning('ModelRFQ:Functions:logMessage:invalidMessage', ...
                    'Incorrect message structure: type ''help logMessage'' for details. Using default values.') ;

            if ischar(message) %then use this for the message text 
                messageText = message;
            else
                messageText = '';
            end
            if ~isstruct(message)
                message = struct ;
            end
            if ~isfield(message, 'identifier') || ~ischar(message.identifier)
                message.identifier = 'ModelRFQ:Functions:logMessage:dummyIdentifier' ;
            end
            if ~isfield(message, 'text') || ~ischar(message.text)
                message.text = messageText ;
            end
            if ~isfield(message, 'priorityLevel') || ~isnumeric(message.priorityLevel)
                message.priorityLevel = 1;
            end
            if ~isfield(message, 'errorLevel') || ~ischar(message.errorLevel)
                message.errorLevel = 'information';
            end

        end
        if ~isfield(parameters, 'options') || ~isstruct(parameters.options) ... %then throw error ModelRFQ:Functions:logMessage:incorrectParameters
                || ~isfield(parameters, 'files') || ~isstruct(parameters.files) ...
                || ~isfield(parameters.files, 'logFileName') || ~ischar(parameters.files.logFileName) ...
                || ~isfield(parameters.options, 'verbosity') || ~isstruct(parameters.options.verbosity) ...
                || ~isfield(parameters.options.verbosity, 'toScreen') || ~isnumeric(parameters.options.verbosity.toScreen) ...
                || ~isfield(parameters.options.verbosity, 'toFile') || ~isnumeric(parameters.options.verbosity.toFile) ...
                || ~isfield(parameters.options.verbosity, 'toTwitter') || ~isnumeric(parameters.options.verbosity.toTwitter)

            warning('ModelRFQ:Functions:logMessage:incorrectParameters', ...
                    'Invalid parameters structure. Using default parameters.') ;

            if ~isfield(parameters, 'files') || ~isstruct(parameters.files)
                parameters.files = struct;
            end
            if ~isfield(parameters.files, 'logFileName') || ~ischar(parameters.files.logFileName)
                parameters.files.logFileName = 'ModelRFQ.log' ;
            end
            if ~isfield(parameters, 'options') || ~isstruct(parameters.options)
                parameters.options = struct ;
            end
            if ~isfield(parameters.options, 'verbosity') || ~isstruct(parameters.options.verbosity)
                parameters.options.verbosity = struct ;
            end
            if ~isfield(parameters.options.verbosity, 'toScreen') || ~isnumeric(parameters.options.verbosity.toScreen)
                parameters.options.verbosity.toScreen = defScreenVerbLev ;
            end
            if ~isfield(parameters.options.verbosity, 'toFile') || ~isnumeric(parameters.options.verbosity.toFile)
                parameters.options.verbosity.toFile = defFileVerbLev ;
            end
            if ~isfield(parameters.options.verbosity, 'toTwitter') || ~isnumeric(parameters.options.verbosity.toTwitter)
                parameters.options.verbosity.toTwitter = defTwitVerbLev ;
            end

        end
        if ~isfield(parameters.files, 'logFileNo') || ~isnumeric(parameters.files.logFileNo)
%            parameters.files.logFileNo = fopen('ModelRFQ.log', 'a') ;
            parameters.files.logFileNo = [] ;
        end
    catch syntaxException
        syntaxMessage = struct;
        syntaxMessage.identifier = 'ModelRFQ:Functions:logMessage:syntaxException';
        syntaxMessage.text = 'Syntax error calling logMessage: correct syntax is logMessage(message)';
        syntaxMessage.priorityLevel = 1;
        syntaxMessage.errorLevel = 'error';
        syntaxMessage.exception = syntaxException;
        parameters = struct ;
        parameters.files = struct;
        parameters.files.logFileNo = [] ;
        parameters.files.logFileName = 'ModelRFQ.log' ;
        parameters.options = struct ;
        parameters.options.verbosity = struct ;
        parameters.options.verbosity.toScreen = defScreenVerbLev ;
        parameters.options.verbosity.toFile = defFileVerbLev ;
        parameters.options.verbosity.toTwitter = defTwitVerbLev ;
        recurseLevel = recurseLevel + 1 ;
        [parameters, recurseLevel] = logMessage(syntaxMessage, parameters, recurseLevel) ;
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
    
    if parameters.options.verbosity.toScreen >= message.priorityLevel && recurseLevel < 10 %then display the message 
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
    
    if parameters.options.verbosity.toFile >= message.priorityLevel && recurseLevel < 10 %then write the message 
        try %to write to file
            if isempty(parameters.files.logFileNo) || isempty(fopen(parameters.files.logFileNo))
                parameters.files.logFileNo = fopen(parameters.files.logFileName, 'a') ;
            end
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
            recurseLevel = recurseLevel + 1 ;
            parameters.options.verbosity.toFile = 0 ;
            [parameters, recurseLevel] = logMessage(fileMessage, parameters, recurseLevel);
        end
    end

%% Send messages to Twitter 
    
    if ~strcmpi(message.identifier, 'ModelRFQ:Functions:logMessage:twitterException') ...%don't loop infinitely
            && parameters.options.verbosity.toTwitter >= message.priorityLevel && recurseLevel < 10 %then write the message 
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
                recurseLevel = recurseLevel + 1 ;
                [parameters, recurseLevel] = logMessage(twitterMessage, parameters, recurseLevel);
            end
        end
    end

%% Close log file and set up output parameters

    if ~isempty(fopen(parameters.files.logFileNo))
        fclose(parameters.files.logFileNo) ;
    end

    recurseLevout = recurseLevel ;
    outputParameters = parameters ;

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

