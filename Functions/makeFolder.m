function makeFolder(folderPath, shouldLog)
%
% function makeFolder(folderPath, [shouldLog])
%
%   Checks whether folderPath exists, and creates it if not.
%
%   Set shouldLog to false to bypass log system (default is true).
%
%   See also modelRfq, findFile.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   16-Dec-2010 M. Easton
%       Created function to create folders
%
%=========================================================================

    if nargin < 2, shouldLog = true; end

    if exist(folderPath, 'dir') ~= 7 %then make subfolder 
        mkdir(folderPath);
        if shouldLog %then log message
            message = struct;
            message.identifier = 'ModelRFQ:Functions:makeFolder';
            message.text = [' - Created folder ' regexprep(folderPath, '\\', '\\\\')];
            message.priorityLevel = 7;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        end
    end
    
return