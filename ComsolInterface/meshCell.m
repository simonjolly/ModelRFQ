function comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)
%
% function comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)
%
% meshCell remeshes the current cell in the Comsol model.
%
% Credit for the majority of the modelling code must go to Simon Jolly of
% Imperial College London.
%
% See also buildCell, buildComsolModel, modelRfq, getModelParameters, 
% logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Feb-2011 M. J. Easton
%       Split buildComsolModel into subroutines to allow unit testing of 
%       separate parts.
%
%=======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 3 %then throw error ModelRFQ:ComsolInterface:meshCell:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)');
        end
        if nargin > 3 %then throw error ModelRFQ:ComsolInterface:meshCell:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:meshCell:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:meshCell:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:meshCell:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:meshCell:syntaxException';
        message.text = 'Syntax error calling meshCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Main block 

    try %to mesh cell 
        % Set mesh for inner beam box: 32 steps for normal cell, 128 for matching section
        comsolModel.mesh('mesh1').feature('swe1').feature('dis1').set('numelem', '32') ;
        if cellNo == 1 %then increase mesh to 128 steps 
            comsolModel.mesh('mesh1').feature('swe1').feature('dis2').set('numelem', '128') ;
        else
            comsolModel.mesh('mesh1').feature('swe1').feature('dis2').set('numelem', '32') ;
        end
        comsolModel.mesh('mesh1').feature('swe1').feature('dis3').set('numelem', '32') ;
        comsolModel.mesh('mesh1').feature('map1').feature('dis1').set('numelem', num2str(nBeamBoxCells)) ;
        comsolModel.mesh('mesh1').run ;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:meshCell:meshModel:runException';
        errorMessage.text = 'Could not rebuild mesh. Reducing mesh density and retrying...';
        errorMessage.priorityLevel = 5;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
        comsolModel.mesh('mesh1').feature('map1').feature('dis1').set('numelem', num2str(nBeamBoxCells/2));
        comsolModel.mesh('mesh1').run;
    end
 
return