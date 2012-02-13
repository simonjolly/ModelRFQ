function colours = tagColours(endData, tagging)
%
% function colours = tagColours(endData, [tagging])
%
%   tagColours provides colour-coding for particle trajectory data, based
%   on the z-position at which the particle was lost.  For N particles,
%   the input array endData needs to be an [N x 10] array as produced by
%   tagLosses - see help tagLosses for more details.
%
%   Based on gptlosscol code by Simon Jolly.
%
%   colours = tagColours(endData) 
%     - analyses particle data in array endData and creates an [N x 3] 
%       array of colour information of the form 'xk-'. 'Surviving' 
%       particles are determined by using zmax = max(endData(:,5) 
%       - particles with z=zmax are marked as surviving and are coloured 
%       black ('xk-'), while those with z<zmax do not and are coloured red 
%       ('xr-').
%
%   colours = tagColours(endData, tagging) 
%      - additionally specifies the range data in which to 'bin' the 
%        particle losses, the colour sequence and marker sequence.
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
%   choice of zmax, simply set ranges = zmax for the zmax of your choice.
%
%   tagColours extracts code from the function gptlosscol written 
%   by Simon Jolly and released under the GNU public licence. 
%   gptloscol can handle more output variables, and allows much more 
%   flexibility for analysing data. tagColours includes only the code 
%   required for the ModelRFQ distribution.
%
%   See also tagLosses, modelRfq, plotTrajectories, importGdf, 
%   getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from gptloscol by Simon Jolly, Imperial College London.
%
% File history
%
%   19-Dec-2010 M. J. Easton
%       Created tagColours as part of ModelRFQ distribution.
%
%======================================================================


%% Check syntax 

    try %to check syntax 
        if nargin > 2 %then throw error ModelRFQ:Functions:tagColours:excessiveInputArguments 
            error('ModelRFQ:Functions:tagColours:excessiveInputArguments', ...
                  'Can only specify 2 input arguments: tagColours(endData, [tagging])');
        end
        if nargin < 1 %then throw error ModelRFQ:Functions:tagColours:insufficientInputArguments 
            error('ModelRFQ:Functions:tagColours:insufficientInputArguments', ...
                  'Must specify at least 1 input argument: tagColours(endData, [tagging])');
        end
        if nargout > 1 %then throw error ModelRFQ:Functions:tagColours:excessiveOutputArguments 
            error('ModelRFQ:Functions:tagColours:excessiveOutputArguments', ... 
                  'Can only specify 1 output argument: colours = tagColours(endData, [tagging])');
        end
        if nargin < 2 %then create the tagging structure 
            tagging = struct;
            tagging.colourLoop = ('rgbcmy');         % colours to use
            tagging.markerLoop = ('x+*o.sd^v><ph');   % markers to use
        end
        if ~isstruct(tagging) %then throw error ModelRFQ:Functions:tagLosses:invalidInputArguments 
            error('ModelRFQ:Functions:tagLosses:invalidInputArguments', ... 
                  'Invalid tagging format');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagColours:syntaxException';
        message.text = 'Syntax error calling tagColours: correct syntax is colours = tagColours(endData, [tagging])';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Find last particle 
    
    try %to find last particle 
        lastParticle = max(endData(:,5));
        if nargin < 2 %then set ranges to last particle 
            tagging.ranges = lastParticle;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagColours:lastParticleException';
        message.text = 'Cannot find last particle';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Initialise variables 

    try %to initialise variables 
        nParticles = size(endData,1);
        colours = num2str(zeros(nParticles,2));
        colours(:,4:end) = [];
        zData = endData(:,5);
        ranges = [-Inf tagging.ranges Inf] ;
        lossBins = zeros(length(ranges)-1,1) ;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:tagColours:initialisationException';
        message.text = 'Cannot initialise variables';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end    
    
%% Main loop 

    iColour = 0 ;
    for i = 1:(length(ranges)-1) %then loop through each seperate colour range
        curentRange = ranges(i);
        nextRange = ranges(i+1);
        [isInCurrentRange] = find((zData >= curentRange) & (zData < nextRange));
        if ~isempty(isInCurrentRange) %then apply colours to current range
            iColour = iColour + 1;
            lossBins(i) = length(isInCurrentRange);
            if nextRange == Inf %then show finished particles in black 
                markerCode = '.k-';
            else %then use current loop colour
                markerCode = [tagging.markerLoop(fix((iColour-1)./6)+1) tagging.colourLoop(rem(iColour-1,6)+1) '-'];
            end
            for j = 1:length(isInCurrentRange) %apply current marker code to particle 
                colours(isInCurrentRange(j),:) = markerCode;
            end
        end
    end

return
