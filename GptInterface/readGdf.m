function [dataName, dataLength, readString, extraOperators, ...
          isStartOfDirectory, isEndOfDirectory, isEndOfFile]  ...
          = readGdf(inputFileNo)
%
% function [dataName, dataLength, readString, extraOperators, ...
%           isStartOfDirectory, isEndOfDirectory, isEndOfFile]  ...
%           = readGdf(inputFileNo)
%
%   readGdf reads out the data header at the start of each block of
%   binary data within a binary GDF file produced by GPT.
%
%   Based on gdfreadhead code by Simon Jolly.
%
%   readGdf(inputFileNo) 
%     - read the header data from the GDF file with file ID FID.  
%       The file must previously have been opened with the FOPEN command 
%       to produce the valid FID.
%
%   [dataName, dataLength, readString, extraOperators, ...
%    isStartOfDirectory, isEndOfDirectory, isEndOfFile]  ...
%    = readGdf(inputFileNo)
%     - read out the header data and output as separate variables.  
%
%   The output variables are:
%
%       dataName (string)
%         - name of variable to read out 
%       dataLength (double)
%         - length of data, in bytes 
%       readString (string)
%         - string that specifies what format the data is in and what to 
%           convert it to eg. uchar=>char, *uint8; used directly by fread            
%       extraOperators (string)
%         - additional characters for reading out data eg. the ' character 
%           to transpose a character array 
%       isStartOfDirectory (boolean)
%         - indicates whether the variable is the start of a group; 
%           true if directory entry start, false otherwise
%       isEndOfDirectory (boolean)
%         - indicates whether the variable is the last in a group;
%           true if directory entry end, false otherwise
%       isEndOfFile (boolean)
%         - indicates whether the end of file has been reached;
%           true if feof(inputFileNo), false otherwise.
%
%    The header data has a standard structure, with the following format:
%
%       struct gdfhead
%
%       U8 name[GDFNAMELEN] ;
%       U32 type ;
%       U32 size ;
%
%       Data types
%
%       t_ascii  0x0001      /* Ascii string	      */
%       t_s32	 0x0002      /* Signed long	      */
%       t_dbl	 0x0003      /* Double		      */
%
%       t_undef  0x0000      /* Data type not defined */
%       t_nul	 0x0010      /* No data 	      */
%       t_u8	 0x0020      /* Unsigned char	      */
%       t_s8	 0x0030      /* Signed char	      */
%       t_u16	 0x0040      /* Unsigned short	      */
%       t_s16	 0x0050      /* Signed short	      */
%       t_u32	 0x0060      /* Unsigned long	      */
%       t_u64	 0x0070      /* Unsigned 64bit int    */
%       t_s64	 0x0080      /* Signed 64bit int      */
%       t_flt	 0x0090      /* Float		      */
%
%       Block types
%
%       t_dir	 0x0100      /* Directory entry start */
%       t_edir	 0x0200      /* Directory entry end   */
%       t_sval	 0x0400      /* Single valued	      */
%       t_arr	 0x0800      /* Array		      */
%
%   readGdfHeader draws heavily on the function gdfreadhead written 
%   by Simon Jolly and released under the GNU public licence. 
%   gdfreadhead can handle more input and output variables, and 
%   allows much more flexibility for importing data. 
%   readGdfHeader includes only the code required for the ModelRFQ 
%   distribution.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from gdfreadhead by Simon Jolly, Imperial College London.
%
% File history
%
%   26-Jun-2008 S. Jolly
%       gdfreadhead original version
%
%   18-Dec-2010 M. J. Easton
%       Created readGdf as part of ModelRFQ distribution.
%
%======================================================================

%% Declarations 

    gdfNameLength = 16;

%% Check syntax 

    try %to check syntax 
        if nargin > 1 %then throw error ModelRFQ:GptInterface:readGdf:excessiveInputArguments 
            error('ModelRFQ:GptInterface:readGdf:excessiveInputArguments', ...
                  'Can only specify 1 input argument: readGdf(inputFileNo)');
        end
        if nargin < 1 %then throw error ModelRFQ:GptInterface:readGdf:insufficientInputArguments 
            error('ModelRFQ:GptInterface:readGdf:insufficientInputArguments', ...
                  'Must specify at least 1 input argument: readGdf(inputFileNo)');
        end
        if nargout > 7 %then throw error ModelRFQ:GptInterface:readGdf:excessiveOutputArguments 
            error('ModelRFQ:GptInterface:readGdf:excessiveOutputArguments', ... 
                  'Too many output arguments: [dataName, dataLength, readString, extraOperators, isStartOfDirectory, isEndOfDirectory, isEndOfFile] = readGdf(inputFileNo)');
        end        
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdf:syntaxException';
        message.text = 'Syntax error calling readGdf: correct syntax is [dataName, dataLength, readString, extraOperators, isStartOfDirectory, isEndOfDirectory, isEndOfFile] = readGdf(inputFileNo)';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Read out header data: name, type and size 

    try %to read out header data 
        gdfName = fread(inputFileNo, gdfNameLength, '*uint8');
        gdfType = dec2hex(fread(inputFileNo, 1, '*uint32'));
        gdfSize = fread(inputFileNo, 1, 'uint32=>double');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdf:readException';
        message.text = 'Cannot read header data from input file';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Determine if the end of file has been reached 

    try %to determine end of file
        if isempty(gdfName) && isempty(gdfType) && isempty(gdfSize) %then check file status 
            if feof(inputFileNo) %then report end of file 
                isEndOfFile = true;
                dataName = '';
                dataLength = 0;
                readString = '';
                extraOperators = [];
                isStartOfDirectory = false;
                isEndOfDirectory = false;                
                return
            else
                isEndOfFile = false;
            end
        else
            isEndOfFile = false;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdf:checkEndOfFileException';
        message.text = 'Cannot determine end of file';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    
%% Set the name of the variable 

    try %to set dataName 
        [wordEnd] = find(gdfName == 0) ;
        dataName = char(gdfName(1:wordEnd(1)-1))';
        if numel(dataName) > 0 && strcmp(dataName(1),'@') %then remove @ symbol 
            dataName(1) = [];
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdf:dataNameException';
        message.text = 'Cannot set dataName variable';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Determine the block type 
%  and whether it is the start or end of a block of data (directory)

    try %to determine block type 
        blockType = dec2bin(str2double(gdfType(1)),4);
        if blockType(4) == '1' %then this is the start of a directory 
            isStartOfDirectory = true;
        else
            isStartOfDirectory = false;
        end
        if blockType(3) == '1' %then this is the end of a directory 
            isEndOfDirectory = true;
        else
            isEndOfDirectory = false;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdf:blockException';
        message.text = 'Cannot read determine block type. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Set the readout string and data length based on the data type 

    try %to set the read parameters 
        switch gdfType(3)
            case '0'
                switch gdfType(2)
                    case '1'
                        readString = '*uint8';
                        dataLength = gdfSize;
                        extraOperators = [];
                    case '2'
                        readString = 'uchar=>char';
                        dataLength = gdfSize;
                        extraOperators = '''';
                    case '3'
                        readString = 'schar=>char';
                        dataLength = gdfSize;
                        extraOperators = '''';
                    case '4'
                        readString = 'uint16=>double';
                        dataLength = gdfSize./2;
                        extraOperators = [];
                    case '5'
                        readString = 'int16=>double';
                        dataLength = gdfSize./2;
                        extraOperators = [];
                    case '6'
                        readString = 'uint32=>double';
                        dataLength = gdfSize./4;
                        extraOperators = [];
                    case '7'
                        readString = 'uint64=>double';
                        dataLength = gdfSize./8;
                        extraOperators = [];
                    case '8'
                        readString = 'int64=>double';
                        dataLength = gdfSize./8;
                        extraOperators = [];
                    case '9'
                        readString = 'float64=>double';
                        dataLength = gdfSize./8;
                        extraOperators = [];
                    otherwise
                        error('Unknown data type');
                end
            case '1'
                readString = 'uchar=>char';
                dataLength = gdfSize;
                extraOperators = '''';
            case '2'
                readString = '*int32';
                dataLength = gdfSize./4;
                extraOperators = [];
            case '3'
                readString = '*double';
                dataLength = gdfSize./8;
                extraOperators = [];
            otherwise
                error('ModelRFQ:GptInterface:readGdf:uknownDataType', 'Unknown data type');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:GptInterface:readGdf:setReadParametersException';
        message.text = 'Cannot set read parameters. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

return