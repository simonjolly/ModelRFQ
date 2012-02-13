function writeResults(input, outputFile)
% writeResults writes a single results line to outputFile
%
%   After calling rfqModel = modelRfq(), call 
%   writeResults(rfqModel, outputFile) to write the results line to a log
%   file.
%
%   Call writeResults('header', outputFile) to write the header row.
%
%   Intended when using a batch file outside of Matlab rather than using
%   runBatch.
%
%   See also runBatch, modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   30-Jan-2011 M. J. Easton
%       Created function to save the results to file.
%
%=========================================================================

%% Prepare 
    
    close all;
    if ispc %then use correct end-of-line character 
        newline = '\r\n';
    else
        newline = '\n';
    end

%% Check syntax 

    if nargin > 2 %then throw error ModelRFQ:Functions:writeResults:excessiveInputArguments 
        error('ModelRFQ:Functions:writeResults:excessiveInputArguments', ...
              'Incorrect number of input variables: syntax is writeResults(input, outputFile)');
    end
    if nargin < 2 %then throw error ModelRFQ:Functions:writeResults:insufficientInputArguments 
        error('ModelRFQ:Functions:writeResults:insufficientInputArguments', ...
              'Incorrect number of input variables: syntax is writeResults(input, outputFile)');
    end
    if nargout > 0 %then throw error ModelRFQ:Functions:writeResults:excessiveOutputArguments 
        error('ModelRFQ:Functions:writeResults:excessiveOutputArguments', ...
              'Incorrect number of output variables: syntax is writeResults(input, outputFile)');
    end
    if ~strcmpi(input, 'header') %then check structure 
        if ~isstruct(input) || ~isstruct(input.results) || ~isstruct(input.parameters) %then throw error ModelRFQ:Functions:writeResults:invalidInputArguments
            error('ModelRFQ:Functions:writeResults:invalidInputArguments', ...
                  'Invalid input structure.');
        end
    end
    if ~ischar(outputFile) %then throw error ModelRFQ:Functions:writeResults:invalidOutputArguments
        error('ModelRFQ:Functions:writeResults:invalidOutputArguments', ...
              'Output file name not recognised as string variable.');
    end
    if exist(outputFile, 'file') ~= 2 && ~strcmpi(input, 'header') %then throw error ModelRFQ:Functions:writeResults:invalidFile
        error('ModelRFQ:Functions:writeResults:invalidFile', ...
             ['Cannot find file ' outputFile]);
    end
        
%% Open file 

    if strcmpi(input, 'header') %then write header rather than output data 
        resultsFileNo = fopen(outputFile,'w');
    else
        resultsFileNo = fopen(outputFile,'a');
    end
    
%% Write to file 

    if strcmpi(input, 'header') %then write header rather than output data 
        fprintf(resultsFileNo, ['folder\tfreq\tlength\tffac\ttrans\tsurv\t<E>\tErms\tXemit\tYemit' newline]);
    else
        folderName = regexp(pwd, filesep, 'split');
        folderName = folderName(length(folderName));
        folderName = folderName{1};
        fprintf(resultsFileNo, [folderName ...
                      '\t' num2str(input.parameters.beam.frequency.*1e-6) ...                                   frequency in MHz
                      '\t' num2str(input.parameters.tracking.rfqLength) ...                                     length in m
                      '\t' num2str(input.parameters.tracking.fieldFactor) ...                                   field scaling factor
                      '\t' num2str(input.results.transmission.*100) ...                                         transmission in %
                      '\t' num2str(input.results.survival.*100) ...                                             survival in %
                      '\t' num2str(input.results.meanEnergy.*1e-3 / input.parameters.particle.nNucleons) ...    mean energy in keV/u
                      '\t' num2str(input.results.rmsEnergy.*1e-3 / input.parameters.particle.nNucleons) ...     rms energy in keV/u
                      '\t' num2str(input.results.xFinalEmittance.normalised) ...                                final x emittance in pi mm mrad
                      '\t' num2str(input.results.yFinalEmittance.normalised) ...                                final y emittance in pi mm mrad
                      newline]);
    end
    
%% Close file 

    fclose(resultsFileNo);    
    
return