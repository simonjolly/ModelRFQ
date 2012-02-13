function fieldmap = loadFieldMap(inputFile)
%
% function fieldmap = loadFieldMap(inputFile)
%
% loadFieldMap loads a fieldmap from a Matlab file consisting of separate
% fieldmap variables and combines them into a single fieldmap variable.
%
% See also buildComsolModel, modelRfq, getModelParameters, logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history
%
%   23-Feb-2011 M. J. Easton
%       Created function to load and combine field maps.
%       Included as part of the ModelRFQ distribution.
%
%   30-Jun-2011 S. Jolly
%       Removed error checking (contained in wrapper functions).
%
%=======================================================================

%% Check syntax 

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:loadFieldMap:insufficientInputArguments', ...
              'Too few input variables: syntax is fieldmap = loadFieldMap(inputFile)');
    end
    if nargin > 2 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:loadFieldMap:excessiveInputArguments', ...
              'Too many input variables: syntax is fieldmap = loadFieldMap(inputFile)');
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:loadFieldMap:insufficientOutputArguments', ...
%              'Too few output variables: syntax is fieldmap = loadFieldMap(inputFile)');
%    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:loadFieldMap:excessiveOutputArguments', ...
              'Too many output variables: syntax is fieldmap = loadFieldMap(inputFile)');
    end
    if exist(inputFile, 'file') ~= 2 %then throw error ModelRFQ:ComsolInterface:loadFieldMap:invalidFile 
        error('ModelRFQ:ComsolInterface:loadFieldMap:invalidFile', ...
             ['Invalid file: ' inputFile]);
    end

%% Load data 

    load(inputFile);
    fieldmap = fieldmap1;
    for i = 2:lastCellNo
        currentFieldMap = ['fieldmap' num2str(i)];
        eval(['fieldmap = [fieldmap; ' currentFieldMap '];']);
    end

    return
