function colours = tagLosses(trajectoryData, tagging)
%
% function colours = tagLosses(trajectoryData, [tagging])
%
%	tagLosses is used to analyse GPT trajectory data and colour code each
%   particle according to the z-position at which the particle was lost.
%   The input data, trajectoryData, needs to be a Matlab structure array
%   containing trajectory data created by the function importGdf.
%
%   Based on gptlosses code by Simon Jolly.
%
%   colours = tagLosses(trajectoryData)
%     - analyses particle data in array  LASTDAT and creates an [ N x 3 ] 
%       array of colour information of the form 'xk-'. 'Surviving' 
%       particles are determined by using ZMAX = max(LASTDAT(:,5)
%       - particles with Z==ZMAX are marked as surviving and are coloured 
%       black ('xk-'), while those with Z<ZMAX do not and are coloured 
%       red ('xr-').
%
%    colours = tagLosses(trajectoryData, tagging) 
%     - additionally specifies the range data in which to 'bin' the 
%       particle losses, and the colours and markers to use.
%
%   For example, to colour code particle losses in units of 10cm, from
%   0-50cm, set tagging.ranges = [0:0.1:0.5].  As such, particles lost 
%   before 0cm are coloured red, those between 0-10cm green, between 
%   10-20cm blue etc. and those that survive beyond 50cm are coloured 
%   black.  The colours cycle through [R G B C M Y] for consecutive bins: 
%   when colours start to repeat, different marker shapes are used.  
%   Surviving particles are always coloured black.
%
%   When specifying ranges, zmax = ranges(end): hence it is possible that
%   no particle survives (and none are coloured black).  To change the
%   choice of zmax, simply set ranges = zmax for the zman of your choice.
%
%   tagLosses extracts code from the function gptlosses written 
%   by Simon Jolly and released under the GNU public licence. 
%   gptlosses can handle more input and output variables, and 
%   allows much more flexibility for analysing data. 
%   tagLosses includes only the code required for the ModelRFQ 
%   distribution.
%
%   See also tagColours, modelRfq, plotTrajectories, importGdf, 
%   getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from gptlosses by Simon Jolly, Imperial College London.
%
% File history
%
%   18-Dec-2010 M. J. Easton
%       Created tagLosses as part of ModelRFQ distribution.
%
%======================================================================

%% Check syntax 

    try %to check syntax 
        if nargin > 2 %then throw error ModelRFQ:Functions:tagLosses:excessiveInputArguments 
            error('ModelRFQ:Functions:tagLosses:excessiveInputArguments', ...
                  'Can only specify 2 input arguments: tagLosses(trajectoryData, [tagging])');
        end
        if nargin < 1 %then throw error ModelRFQ:Functions:tagLosses:insufficientInputArguments 
            error('ModelRFQ:Functions:tagLosses:insufficientInputArguments', ...
                  'Must specify at least 1 input argument: tagLosses(trajectoryData, [tagging])');
        end
        if nargout > 1 %then throw error ModelRFQ:Functions:tagLosses:excessiveOutputArguments 
            error('ModelRFQ:Functions:tagLosses:excessiveOutputArguments', ... 
                  'Can only specify 1 output argument: colours = tagLosses(trajectoryData, [tagging])');
        end
        if nargin < 2 %then create the tagging structure 
            tagging = struct;
            tagging.colourLoop = ('rgbcmy');         % colours to use
            tagging.markerLoop = ('x+o*sd^v><ph');   % markers to use
        end
        if ~isstruct(tagging) %then throw error ModelRFQ:Functions:tagLosses:invalidInputArguments 
            error('ModelRFQ:Functions:tagLosses:invalidInputArguments', ... 
                  'Invalid tagging format');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagLosses:syntaxException';
        message.text = 'Syntax error calling tagLosses: correct syntax is colours = tagLosses(trajectoryData, [tagging])';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Initialise variables 

    nParticles = length(trajectoryData);
    startData = zeros(nParticles,10);                                                       %#ok - this is used in eval string commands
    endData = zeros(nParticles,10);
    fields = {'x';'xp';'y';'yp';'z';'Bx';'By';'Bz';'rxy';'time'} ;

%% Main loop 

    try %to find the start and end values for each particle 
        for i = 1:nParticles %find the start and end values 
            % check particle is there
            eval(['check = trajectoryData(i).' fields{1} ' ;']);
            % save start and end data
            if ~isempty(check) %then particle exists for saving 
                for j = 1:length(fields) %save start and end data 
                    eval(['startData(i,j) = trajectoryData(i).' fields{j} '(1) ;']);
                    eval(['endData(i,j) = trajectoryData(i).' fields{j} '(end) ;']);
                end
            end
            % display status every 1000 particles
            try %to display status 
                if rem(i,1000) == 0 %then display status 
                message = struct;
                message.identifier = 'ModelRFQ:Functions:tagLosses:statusMessage';
                message.text = ['Reading particle ' num2str(i) ' ... '];
                message.priorityLevel = 5;
                message.errorLevel = 'information';
                logMessage(message);
                end
            catch exception
                message = struct;
                message.identifier = 'ModelRFQ:Functions:tagLosses:displayException';
                message.text = 'Cannot display tagging status';
                message.priorityLevel = 5;
                message.errorLevel = 'warning';
                message.exception = exception;
                logMessage(message);
            end
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagLosses:runException';
        message.text = 'Cannot find start and end points for particles';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Define default ranges 

    try % to define default ranges 
        if nargin < 2
            tagging.ranges = max(endData(:,5));
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagLosses:rangesException';
        message.text = 'Cannot define default ranges. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
        try
            tagging.ranges = max(endData(:,5));
        catch %#ok
        end
    end
    
%% Define particle tracking colours 

    try %to define colours 
        colours = tagColours(endData, tagging);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagLosses:colourException';
        message.text = 'Cannot define particle tracking colours';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

return