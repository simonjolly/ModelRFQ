function combineFieldMaps(inputFiles, outputFile, shouldSkipZero)
%
% function combineFieldMaps(inputFiles, outputFile, [shouldSkipZero]) 
%
%   combineFieldMaps combines the field maps referenced in the inputFiles
%   array into a single field map, saved as outputFile, with headers
%   stripped for entry into GPT.
%
%   inputFiles should be a cell array of files and their starting 
%   z-locations 
%      e.g. for a matching section at z=0 and an RFQ at z=21.8mm:
%           inputFiles = {'matching.txt', 0; 'rfq.txt', 21.8};
%
%   The input files should be in a recognised format. See the code below
%   for details.
%
%   If the final field map is to be used in GPT, all input field maps
%   must have the same x and y points.
%
%   If shouldSkipZero is set to 1 then the z=0 line of each field map 
%   will be skipped. this is useful if the z=0 of one field map is 
%   the same location as the last entry of the previous field map.
%
%   See also modelRrfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   17-Dec-2010 M. J. Easton
%       Created function to combine input files into single output file.
%
%=========================================================================

%% Check syntax 

    try %to check syntax
        if nargin < 2 || nargin > 3 %then throw error ModelRFQ:Functions:combineFieldMaps:incorrectInputArguments 
            error('ModelRFQ:Functions:combineFieldMaps:incorrectInputArguments', 'Incorrect input arguments: correct syntax is combineFieldMaps(inputFiles, outputFile, [shouldSkipZero])');
        end
        if nargout ~= 0 %then throw error ModelRFQ:Functions:combineFieldMaps:incorrectOutputArguments 
            error('ModelRFQ:Functions:combineFieldMaps:incorrectOutputArguments', 'Incorrect output arguments: correct syntax is combineFieldMaps(inputFiles, outputFile, [shouldSkipZero])');
        end        
    catch syntaxException
        syntaxMessage = struct;
        syntaxMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:syntaxException';
        syntaxMessage.text = 'Syntax error calling combineFieldMaps: correct syntax is combineFieldMaps(inputFiles, outputFile, [shouldSkipZero])';
        syntaxMessage.priorityLevel = 3;
        syntaxMessage.errorLevel = 'error';
        syntaxMessage.exception = syntaxException;
        logMessage(syntaxMessage);
    end
    
    if nargin == 2, shouldSkipZero = 0; end     
    
    try %to find all input files 
        for i = 1:length(inputFiles(:,1)) %check each file 
            % get filename
            inputFile = inputFiles(i,1);
            inputFile = inputFile{1}; % convert from cell to string
            if exist(inputFile, 'file') ~= 2 %then throw error ModelRFQ:Functions:combineFieldMaps:missingFile 
                error('ModelRFQ:Functions:combineFieldMaps:missingInputFile', ['Cannot find input file: ' inputFile]);
            end            
        end
    catch fileException
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:checkInputFileException';
        fileMessage.text = 'Error locating input files.';
        fileMessage.priorityLevel = 3;
        fileMessage.errorLevel = 'error';
        fileMessage.exception = fileException;
        logMessage(fileMessage);
    end
    
%% Write headers to output file 

    try %to open output file for writing 
        outputFileid = fopen(outputFile, 'w');
    catch fileException
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:openOutputFileException';
        fileMessage.text = ['Cannot open output file: ' outputFile];
        fileMessage.priorityLevel = 3;
        fileMessage.errorLevel = 'error';
        fileMessage.exception = fileException;
        logMessage(fileMessage);
    end
    try %to write headers to file 
        fprintf(outputFileid,'x\ty\tz\tEx\tEy\tEz\tBx\tBy\tBz\r\n');
    catch fileException
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:writeHeadersException';
        fileMessage.text = ['Cannot write headers to output file ' outputFile];
        fileMessage.priorityLevel = 3;
        fileMessage.errorLevel = 'error';
        fileMessage.exception = fileException;
        logMessage(fileMessage);
    end
    try %to close output file for now 
        fclose(outputFileid);
    catch fileException
        fileMessage = struct;
        fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:closeOutputFileException';
        fileMessage.text = ['Cannot close output file: ' outputFile];
        fileMessage.priorityLevel = 3;
        fileMessage.errorLevel = 'error';
        fileMessage.exception = fileException;
        logMessage(fileMessage);
    end
    
%% Loop through input files 
    
    try %to read data from each file and write to output file 
        for i = 1:length(inputFiles(:,1)) %read and write one file at a time 
            % get filename
            inputFile = inputFiles(i,1);
            inputFile = inputFile{1}; % convert from cell to string
            try %to open current file to read 
                inputFileNo = fopen(inputFile, 'r');
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:openInputFileException';
                fileMessage.text = ['Cannot open input file: ' insputFile];
                fileMessage.priorityLevel = 3;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            % check whether file is CST-style, COMSOL-style or GPT-style
            header = textscan(inputFileNo, '%s', 1, 'delimiter', '\n');
            if strcmpi(header{1}{1}(1:6), 'x [mm]') %then this is a CST style file 
                fileStyle = 'cst';
                % skip second line (all dashes)
                textscan(inputFileNo, '%s', 1, 'delimiter', '\n');
                if strcmpi(header{1}{1}(42:45), 'ExRe') %then include B field 
                    % data is x y z ExRe EyRe EzRe ExIm EyIm EzIm
                   fileFormat = '%n %n %n %n %n %n %n %n %n';
                else
                    % data is x y z Ex Ey Ez
                    fileFormat = '%n %n %n %n %n %n';                
                end
            else                
                if strcmpi(header{1}{1}(1), '%') %then this is a COMSOL file 
                    % COMSOL-style file
                    fileStyle = 'comsol';
                    % skip headers
                    header = textscan(inputFileNo, '%s', 7, 'delimiter', '\n');                         %#ok
                    % data is x y z Ex Ey Ez
                    fileFormat = '%n %n %n %n %n %n';
                else
                    % skip a line and check whether there is a blank line following
                    textscan(inputFileNo, '%s', 1, 'delimiter', '\n');
                    header = textscan(inputFileNo, '%s', 1, 'delimiter', '\n');
                    if strcmpi(header{1}{1}, '') %then this is a COMSOL 3.5a file 
                        % old COMSOL-style file
                        fileStyle = 'oldcomsol'; 
                        % data is x y z Ex Ey Ez
                        fileFormat = '%n %n %n %n %n %n';
                    else
                        % GPT-style file
                        fileStyle = 'gpt';
                        % data is x y z Ex Ey Ez Bx By Bz
                        fileFormat = '%n %n %n %n %n %n %n %n %n';
                    end
                    % reopen file and get back to correct position 
                    % (we have read too far in order to check file type)
                    fclose(inputFileNo);
                    inputFileNo = fopen(inputFile, 'r');
                    header = textscan(inputFileNo, '%s', 1, 'delimiter', '\n');                         %#ok
                end
            end
            % display load message
            message = struct;
            message.identifier = 'ModelRFQ:Functions:combineFieldMaps:displayLoadFile';
            message.text = ['Loading file ' num2str(i) ' of ' num2str(length(inputFiles(:,1))) ': ' inputFile];
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            message = struct;
            message.identifier = 'ModelRFQ:Functions:combineFieldMaps:displayLoadFileDetails';
            message.text = ['File is ' fileStyle '-style, using format ''' regexprep(fileFormat, '\%', '\%\%') ''''];
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            try %to read in data 
                data = textscan(inputFileNo, fileFormat);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:scanInputFileException';
                fileMessage.text = ['Cannot scan input file: ' insputFile];
                fileMessage.priorityLevel = 3;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to close file 
                fclose(inputFileNo);
            catch fileException
                fileMessage = struct;
                fileMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:closeInputFileException';
                fileMessage.text = ['Cannot close input file: ' insputFile];
                fileMessage.priorityLevel = 3;
                fileMessage.errorLevel = 'error';
                fileMessage.exception = fileException;
                logMessage(fileMessage);
            end
            try %to store data in array 
                % get z-offset
                offset = inputFiles(i,2);
                offset = offset{1}; % convert from cell to numeric
                % initialise matrix
                fieldMap = zeros(length(data{1}), 9);
                % store data in matrix
                for j = 1:2 % x, y 
                    if(strcmpi(fileStyle, 'gpt')) %then set values accordingly 
                        fieldMap(:,j) = data{j};
                    else
                        fieldMap(:,j) = data{j}.*1e-3;
                    end
                end
                for j = 3:3 % z 
                    if(strcmpi(fileStyle, 'gpt')) %then set values accordingly 
                        fieldMap(:,j) = data{j} + offset.*1e-3;
                    else
                        fieldMap(:,j) = data{j}.*1e-3 + offset.*1e-3;
                    end
                end
                for j = 4:6 % Ex, Ey, Ez 
                    fieldMap(:,j) = data{j};
                end
                for j = 7:9 % Bx, By, Bz (empty)
                    fieldMap(:,j) = 0;
                end
            catch runException
                runMessage = struct;
                runMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:runException';
                runMessage.text = 'Cannot save field map data to fieldMap variable';
                runMessage.priorityLevel = 3;
                runMessage.errorLevel = 'error';
                runMessage.exception = runException;
                logMessage(runMessage);
            end
            if shouldSkipZero %then skip zero line 
                isZero = fieldMap(:,3) == offset.*1e-3;                
                fieldMap(isZero,:) = [];
            end
            % remove duplucates
            [~, isUnique] = unique(fieldMap(:,1:3),'rows', 'first');
            fieldMap = fieldMap(isUnique,:);
            try %to write matrix to output file 
                dlmwrite(outputFile, fieldMap, '-append', 'delimiter','\t', 'newline','pc', 'precision',10);
            catch writeException
                writeMessage = struct;
                writeMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:writeException';
                writeMessage.text = ['Cannot write fieldmap data to output file: ' outputFile];
                writeMessage.priorityLevel = 3;
                writeMessage.errorLevel = 'error';
                writeMessage.exception = writeException;
                logMessage(writeMessage);
            end
        end
    catch loopException
        loopMessage = struct;
        loopMessage.identifier = 'ModelRFQ:Functions:combineFieldMaps:loopException';
        loopMessage.text = 'Error in input file combination loop.';
        loopMessage.priorityLevel = 3;
        loopMessage.errorLevel = 'error';
        loopMessage.exception = loopException;
        logMessage(loopMessage);
    end

return