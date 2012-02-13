function runBatch()
% runBatch runs modelRfq in all subfolders
%
%    runBatch() will traverse all subfolders and run
%    modelRfq() in each subfolder. The function will also:
%       - copy any files in a folder marked "include" to each subfolder
%       - alert the user if there are any errors
%       - post messages on twitter on error or on completion
%       - store all results in a results.log file
%
%   See also modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   15-Jan-2011 M. J. Easton
%       Created function to run mutiple models and save the results.
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

    if nargin > 0 %then throw error ModelRFQ:Functions:runBatch:excessiveInputArguments 
        error('ModelRFQ:Functions:runBatch:excessiveInputArguments', ...
              'Incorrect number of input variables: syntax is batchrfq()');
    end
    if nargout > 0 %then throw error ModelRFQ:Functions:runBatch:excessiveOutputArguments 
        error('ModelRFQ:Functions:runBatch:excessiveOutputArguments', ...
              'Incorrect number of output variables: syntax is batchrfq()');
    end
        
%% Check for include files 

    shouldIncludeFiles = 0;
    if exist('.\include', 'dir') == 7 %then get list of files to include 
        shouldIncludeFiles = 1;
        cd('include');
        includeList = dir;
        cd('..');        
    end

%% Get directory listing 

    currentList = dir;
    
%% Create results file 

    if exist('.\results.log', 'file') == 2, delete('.\results.log'), end;
    resultsFileNo = fopen('results.log', 'wt');
	try %to write headers to file 
        fprintf(resultsFileNo, ['folder\tfreq\tlength\tffac\ttrans\tsurv\t<E>\tErms\tXemit\tYemit' newline]);
    catch exception
        message = ['Failed to write results header in folder ' pwd];
        try %to tweet message 
            twit(message);
        catch %#ok - want to suppress errors (logging system is not running at this point)
        end
        disp([message ': ' exception.message]);
	end

%% Main loop 

    for i = 1:length(currentList) %copy files, run modelRfq and save results 
        if currentList(i).isdir && ~strcmpi(currentList(i).name, '.') && ~strcmpi(currentList(i).name, '..') && ~strcmpi(currentList(i).name, 'include') %then enter the folder
            cd(currentList(i).name);
            disp(currentList(i).name);
            disp(' ');
            if shouldIncludeFiles %then copy files into current directory 
                for j = 1:length(includeList) %copy files (not folders) 
                    if ~includeList(j).isdir %then copy the file 
                        if exist(['.\' includeList(j).name], 'file') ~= 2 %then copy the file (i.e. don't overwrite local versions) 
                            try %to copy file 
                                copyfile(['..\include\' includeList(j).name],'.')
                            catch exception
                                message = ['Failed to copy parent file ' includeList(j).name];
                                try %to tweet message 
                                    twit(message);
                                catch %#ok - want to suppress errors
                                end
                                disp([message ': ' exception.message]);
                            end
                        end                    
                    end                
                end                
            end
            try %to model the RFQ 
                rfqModel = modelRfq();                
            catch exception
                message = ['Run failed in folder ' pwd];
                try %to tweet message 
                    twit(message);
                catch %#ok - want to suppress errors
                end
                disp([message ': ' exception.message]);
            end
            try %to write results to file 
                fprintf(resultsFileNo, [currentList(i).name ...
                              '\t' num2str(rfqModel.parameters.beam.frequency.*1e-6) ...                                    frequency in MHz
                              '\t' num2str(rfqModel.parameters.tracking.rfqLength) ...                                      length in m
                              '\t' num2str(rfqModel.parameters.tracking.fieldFactor) ...                                    field scaling factor
                              '\t' num2str(rfqModel.results.transmission.*100) ...                                          transmission in %
                              '\t' num2str(rfqModel.results.survival.*100) ...                                              survival in %
                              '\t' num2str(rfqModel.results.meanEnergy.*1e-3 / rfqModel.parameters.particle.nNucleons) ...  mean energy in keV/u
                              '\t' num2str(rfqModel.results.rmsEnergy.*1e-3 / rfqModel.parameters.particle.nNucleons) ...   rms energy in keV/u
                              '\t' num2str(rfqModel.results.xFinalEmittance.normalised) ...                                 final x emittance in pi mm mrad
                              '\t' num2str(rfqModel.results.yFinalEmittance.normalised) ...                                 final y emittance in pi mm mrad
                              newline]);
            catch exception
                message = ['Failed to save results from folder ' pwd];
                try %to tweet message 
                    twit(message);
                catch %#ok - want to suppress errors
                end
                disp([message ': ' exception.message]);
            end
            disp(' ');
            cd('..');
        end
    end
    
%% Clean up 

    fclose(resultsFileNo);
    message = ['Batch complete in folder ' pwd];
    try %to tweet message 
        twit(message);
    catch %#ok - want to suppress errors
    end
    disp(message);
    
return