function findFile(destinationFile, localSourceFile, masterSourceFile, shouldLog)
%
% function findFile(destinationFile, localSourceFile, masterSourceFile, [shouldLog])
%
%   Looks for the missing file at localSourceFile first, then at
%    masterSourceFile.
%
%   Once the file has been found, it is moved or copied to the correct place.
%
%   destinationFile, localSourceFile, masterSourceFile should all be fully
%    qualified paths to files, not folders.
%
%   Set shouldLog to false to bypass log system (default is true).
%
%   See also modelRfq, makeFolder, copyfile, movefile.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   15-Dec-2010 M. J. Easton
%       Created function to log messages to screen, file and Twitter
%
%=========================================================================

    if nargin < 4, shouldLog = true; end
    
    if exist(destinationFile, 'file') ~= 2 %copy in the file if it is missing 
        if exist(localSourceFile, 'file') == 2 %look for file in local source file 
            movefile(localSourceFile, destinationFile);
            if shouldLog %then log message
                message = struct;
                message.identifier = 'ModelRFQ:Functions:findFile:move';
                message.text = [' - Moved file from ' regexprep(localSourceFile, '\\', '\\\\') ' to ' regexprep(destinationFile, '\\', '\\\\')];
                message.priorityLevel = 7;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            end
        else
            copyfile(masterSourceFile, destinationFile);
            if shouldLog %then log message
                message = struct;
                message.identifier = 'ModelRFQ:Functions:findFile:copy';
                message.text = [' - Copied file from ' regexprep(masterSourceFile, '\\', '\\\\') ' to ' regexprep(destinationFile, '\\', '\\\\')];
                message.priorityLevel = 7;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            end
        end
    end
    
return