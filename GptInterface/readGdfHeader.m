function fileType = readGdfHeader(inputFileNo)
%
% function fileType = readGdfHeader(inputFileNo)
%
%   readGdfHeader reads out the data at the start of a binary GDF data
%   file produced by GPT.
%
%   Based on gdfreadmainhead code by Simon Jolly.
%
%	readGdfHeader(inputFileNo) 
%     - read the header data from the GDF file with file fileID inputFileNo
%       and display it.  The file must previously have been opened with 
%       the fopen command to produce the valid FinputFileNo.
%
%   fileType = readGdfHeader(inputFileNo)
%     - also return the file type.
%
%   The header data has a standard structure, with the following format:
%
%       struct gdfmainhead
%
%       U32 fileID ;                    /* fileID so you can see that its a GDF  */
%       U32 creationTime ;          /* Creation time                     */
%       U8  fileType[GDFNAMELEN] ;  /* Creator of the DataFile           */
%       U8  destination[GDFNAMELEN] ;    /* Destination, "" means "General"   */
%
%       U8  gdfMajorVersion ;                /* Major version of GDF-software	 */
%       U8  gdfMinorVersion ;                /* Minor version of GDF-software	 */
%
%       U8  gptMajorVersion ;                /* Major version of fileType         */
%       U8  gptMinorVersion ;                /* Minor version of fileType         */
%       U8  desmaj ;                /* Major version of destination or 0 */
%       U8  desmin ;                /* Minor version of destination or 0 */
%       U8  dummy1 ;                /* Alignment (on 32-bit boundary)    */
%       U8  dummy2 ;
%
%   readGdfHeader draws heavily on the function gdfreadmainhead written 
%   by Simon Jolly and released under the GNU public licence. 
%   gdfreadmainhead can handle many more input and output variables, and 
%   allows much more flexibility for importing data. 
%   readGdfHeader includes only the code required for the ModelRFQ 
%   distribution.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from gdfreadmainhead by Simon Jolly, Imperial College London.
%
% File history
%
%   26-Jun-2008 S. Jolly
%       gdfreadmainhead original version.
%
%   18-Dec-2010 M. J. Easton
%       Created readGdfHeader as part of ModelRFQ distribution.
%
%======================================================================


%% Declarations

    gdfID = 94325877;
	gdfNameLength = 16;

%% Check syntax 

    try %to check syntax 
        if nargin > 1 %then throw error ModelRFQ:GptInterface:readGdfHeader:excessiveInputArguments 
            error('ModelRFQ:GptInterface:readGdfHeader:excessiveInputArguments', ...
                  'Can only specify 1 input argument: readGdfHeader(inputFileNo)');
        end
        if nargin < 1 %then throw error ModelRFQ:GptInterface:readGdfHeader:insufficientInputArguments 
            error('ModelRFQ:GptInterface:readGdfHeader:insufficientInputArguments', ...
                  'Must specify at least 1 input argument: readGdfHeader(inputFileNo)');
        end
        if nargout > 1 %then throw error ModelRFQ:GptInterface:readGdfHeader:excessiveOutputArguments 
            error('ModelRFQ:GptInterface:readGdfHeader:excessiveOutputArguments', ... 
                  'Can only specify 1 output argument: fileType = readGdfHeader(inputFileNo)');
        end        
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:syntaxException';
        message.text = 'Syntax error calling readGdfHeader: correct syntax is [fileType =] readGdfHeader(inputFileNo)';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Find start of file 

    try %to find start of file 
        position = ftell(inputFileNo);
        if position ~= 0
            wasStartOfFile = false;
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:notStartOfFile';
            message.text = 'File pointer is not at the start of the GDF file: seeking file start...';
            message.priorityLevel = 5;
            message.errorLevel = 'warning';
            message.exception = exception;
            logMessage(message);            
            fseek(inputFileNo, 0, 'bof') ;
        else
            wasStartOfFile = true;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:checkPositionException';
        message.text = 'Cannot find start of file';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Read in main file header 

    try %to read in main file header 
        fileID = fread(inputFileNo, 1, '*uint32');
        creationTime = datestr(((fread(inputFileNo, 1, 'uint32=>double'))./60./60./24)+(365.*1970)+479);
        creatorCharacter = fread(inputFileNo, gdfNameLength, '*uint8');
        [wordEnd] = find(creatorCharacter == 0);
        fileType = char(creatorCharacter(1:wordEnd(1)-1))';
        destinationCharacter = fread(inputFileNo, gdfNameLength, '*uint8');
        [wordEnd] = find(destinationCharacter == 0);
        destination = char(destinationCharacter(1:wordEnd(1)-1))';
        if isempty(destination)
            destination = 'General';
        end
        gdfMajorVersion = fread(inputFileNo, 1, 'uint8=>double');
        gdfMinorVersion = fread(inputFileNo, 1, 'uint8=>double');
        gdfVersion = gdfMajorVersion + (gdfMinorVersion./100);
        gptMajorVersion = fread(inputFileNo, 1, 'uint8=>double');
        gptMinorVersion = fread(inputFileNo, 1, 'uint8=>double');
        gptVersion = gptMajorVersion + (gptMinorVersion./100);
        fread(inputFileNo, 1, 'uint8=>double');
        fread(inputFileNo, 1, 'uint8=>double');
        fread(inputFileNo, 1, '*uint8');
        fread(inputFileNo, 1, '*uint8');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:runException';
        message.text = 'Cannot read header data from file';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Display the file header data

    try %to display/log information 
        text = [          'GDF-version: ' num2str(gdfVersion)];
        text = [text '\n' 'Creator    : ' fileType];
        text = [text '\n' '  version  : ' num2str(gptVersion,'%3.2f')];
        text = [text '\n' 'At         : ' creationTime];
        text = [text '\n' 'Binary mode: ' 'Compatible machine'];
        text = [text '\n' 'Destination: ' destination];
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:displayHeader';
        message.text = text;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
	catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:displayException';
        message.text = 'Cannot log file header information';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Check to see if the file ID is correct

    try %to check file ID 
        if fileID ~= gdfID %then show warning 
            message = struct;
            message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:idMismatch';
            message.text = ['File ID is not GPT: should be ' num2str(gdfID) ', is ' num2str(fileID) '.'];
            message.priorityLevel = 5;
            message.errorLevel = 'warning';
            logMessage(message);            
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:checkFileIdException';
        message.text = 'Cannot check file ID';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Reset position of file pointer if it was moved

    try %to return to start of file 
        if ~wasStartOfFile, fseek(inputFileNo, position, 'bof'); end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdfHeader:returnToStart';
        message.text = 'Cannot return to start of file';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

return