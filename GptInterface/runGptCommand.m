function [status,result] = runGptCommand(gptCommand, gptRunFolder)
%
% function [status,result] = runGptCommand(gptCommand, gptRunFolder) 
%
%   runGptCommand executes GPT command within Matlab
%
%   Based on gptcom by Simon Jolly, released under GPL.
%
%   runGptCommand allows GPT code to be executed from the Matlab 
%   command line, to allow the analysis of GPT data in Matlab.  
%   The commang to be executed is passed directly to DOS using the 
%   Matlab SYSTEM command.  The GPT output is always echoed to the 
%   Matlab command window.
%
%   runGptCommand(gptCommand)
%     - executes command in the GPT run folder 
%
%   eg: runGptCommand('gpt -v -o rfq.gdf rfq.in');
%   This executes the command 'gpt -v -o rfq.gdf rfq.in' as if it had been
%   run in the GPT command window.  
%
%   The default GPT folder is:
%      Windows 32-bit:  C:\Program Files\General Particle Tracer\bin
%      Windows 64-bit:  C:\Program Files (x86)\General Particle Tracer\bin
%            Mac OS X:  /Applications/GPY/bin
%
%   runGptCommand(gptCommand, gptRunFolder) 
%     - runs command in the alternative folder gptRunFolder.  This is used 
%       if the GPT binaries are not stored in the default folder given 
%       above.
%
%   [status,result] = runGptCommand('...') 
%     - returns the STATUS and RESULT variables from the SYSTEM command.
%
%   parameters should be a globally available structure defined by 
%   getModelParameters, containing parameters.options.verbosity,
%   parameters.files.logFile, logFolder and logFileNo

% File released under the GNU public license.
% Originally written by Simon Jolly as gptcom.
%
% File history:
%
%   15-Dec-2010 M. J. Easton
%       Incorporated into ModelRFQ distribution. Structure altered to fit
%       coding conventions and to utilise logMessage feature, programming
%       content largely unchanged from original (gptcom).
%
%=========================================================================

%% Declarations

    global parameters;

%% Check syntax 

    try %to check syntax 
        if nargin > 2 %then throw error ModelRFQ:GptInterface:runGptCommand:excessiveInputArguments 
            error('ModelRFQ:GptInterface:runGptCommand:excessiveInputArguments', ...
                  'Can only specify 2 input arguments: [status,result] = gptcom(gptCommand, gptRunFolder)');
        end
        if nargin < 1 %then throw error ModelRFQ:GptInterface:runGptCommand:insufficientInputArguments 
            error('ModelRFQ:GptInterface:runGptCommand:insufficientInputArguments', ...
                  'Must specify at least 1 input argument: gptcom(gptCommand)');
        end
        if nargout > 2 %then throw error ModelRFQ:GptInterface:runGptCommand:excessiveOutputArguments 
            error('ModelRFQ:GptInterface:runGptCommand:excessiveOutputArguments', ... 
                  'Can only specify 2 output arguments: [status,result] = gptcom(gptCommand,gptRunFolder)');
        end
        if ~ischar(gptCommand) %then throw error ModelRFQ:GptInterface:runGptCommand:invalidCommand 
            error('ModelRFQ:GptInterface:runGptCommand:invalidCommand', ...
                  'GPT command variable must be a string');
        end
        if nargin == 2 %then also check gptBinFolder argument 
            if ~ischar(gptRunFolder) %then throw error ModelRFQ:GptInterface:runGptCommand:invalidFolder 
                error('ModelRFQ:GptInterface:runGptCommand:invalidFolder', ...
                      'GPT run folder variable must be a string') ;
            end
        end
    catch syntaxException
        syntaxMessage = struct;
        syntaxMessage.identifier = 'ModelRFQ:GptInterface:runGptCommand:syntaxException';
        syntaxMessage.text = 'Syntax error calling runGptCommand: correct syntax is [status,result] = gptcom(gptCommand, gptRunFolder)';
        syntaxMessage.priorityLevel = 3;
        syntaxMessage.errorLevel = 'error';
        syntaxMessage.exception = syntaxException;
        logMessage(syntaxMessage);
    end
        
%% Get license information 

    computerType = computer;
    try %to find licence details 
        if ispc %then find licence from the registry
            [~, hostName] = system('hostName') ;
            hostName(end) = [] ;
            if sum(strcmpi(hostName,{'heppc222'})) %then don't add licence details, otherwise find in registy 
                shouldAddLicence = 0 ;
            else
                shouldAddLicence = 1 ;
                if strcmp(computerType(end-1:end),'64') %then look in WOW6432 node 
                    license = winqueryreg('HKEY_LOCAL_MACHINE', 'SOFTWARE\Wow6432Node\Pulsar Physics\General Particle Tracer\2.8', 'ProductID') ;
                else
                    license = winqueryreg('HKEY_LOCAL_MACHINE', 'SOFTWARE\Pulsar Physics\General Particle Tracer\2.8', 'ProductID') ;
                end
            end
        else %manually define licence 
            shouldAddLicence = 1;
            license = '1120483491'; % ENTER YOUR LICENCE CODE HERE
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:runGptCommand:findLicenceException';
        message.text = 'Could not find GPT lincence';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    try %to apply licence details 
        if shouldAddLicence && strcmp('gpt ', gptCommand(1:4)) == 1 %then add licence to command string
            gptCommand = [gptCommand ' GPTLICENSE=' license];
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:runGptCommand:applyLicenceException';
        message.text = 'Could not app;y GPT lincence to command string';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    
%% Set GPT run folder 

    try %to find and set correct run folder 
        if nargin < 2 %then use default folder 
            if ispc %then set run folder accordingly 
                if strcmp(computerType(end-1:end),'64') %then set run folder accordingly 
                    gptRunFolder = 'C:\PROGRA~2\GENERA~1\bin\';
                else
                    gptRunFolder = 'C:\PROGRA~1\GENERA~1\bin\';
                end
            elseif ismac
                gptRunFolder = '/Applications/GPT/bin/';
            end
        end
        if ~strcmp(gptRunFolder(end),filesep) %then add a trailing slash 
            gptRunFolder(end+1) = filesep;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:runGptCommand:gptRunFolderException';
        message.text = 'Could not set GPT run folder';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Run GPT command

    try %to log command string 
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:runGptCommand:gptCommand';
        message.text = ['  > ' gptCommand];
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:runGptCommand:logCommandException';
        message.text = 'Could not log GPT command string';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    try %to run command 
        if parameters.options.verbosity.toScreen >= 6 %then echo output to the screen 
            if parameters.options.verbosity.toFile >= 6 %then also echo to file 
                fclose(parameters.files.logFileNo);
                diary(parameters.files.fullLogFile);
            end
            [status,result] = system([gptRunFolder gptCommand],'-echo');
            if parameters.options.verbosity.toFile >= 6 %then stop echoing to file 
                diary off;
                parameters.files.logFileNo = fopen(parameters.files.fullLogFile, 'a');
            end
        else
            if parameters.options.verbosity.toFile >= 6 %then echo to file instead, otherwise don't echo 
                [text, status, result] = evalc('system([gptRunFolder gptCommand],''-echo'')');
                fprintf(parameters.files.logFileNo, '%s', text);
            else %run without logging
                [status, result] = system([gptRunFolder gptCommand]);
            end
        end
    catch runException
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:runGptCommand:runException';
        message.text = 'Could not run GPT command';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = runException;
        logMessage(message);
    end
        
return