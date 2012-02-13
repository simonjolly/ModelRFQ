function comsolModel = initialiseModel(modelPath)
%
% function comsolModel = initialiseModel(modelPath)
%
%   initialiseModel creates a Comsol model at the specified path.
%
%   Credit for the majority of the modelling code must go to Simon Jolly of
%   Imperial College London.
%
%   See also setupModel, buildComsolModel, modelRfq, getModelParameters,
%   logMessage.


% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Nov-2010 S. Jolly
%       Initial creation of model in Comsol and setup of electrostatic
%       physics, mesh, geometry and study.
%
%   18-Feb-2011 M. J. Easton
%       Built function initialiseModel from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:initialiseModel:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = initialiseModel(modelPath)');
        end
        if nargin > 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:initialiseModel:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = initialiseModel(modelPath)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:initialiseModel:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = initialiseModel(modelPath)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:initialiseModel:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = initialiseModel(modelPath)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:initialiseModel:syntaxException';
        message.text = 'Syntax error calling initialiseModel';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Initialise model: path, geometry, mesh, electrostatics and study 

    comsolModel = ModelUtil.create('Model');
    comsolModel.modelPath(modelPath);
    comsolModel.modelNode.create('mod1');
    comsolModel.geom.create('geom1', 3);
    comsolModel.mesh.create('mesh1', 'geom1');
    comsolModel.physics.create('es', 'Electrostatics', 'geom1');
    comsolModel.study.create('std1');
    comsolModel.study('std1').feature.create('stat', 'Stationary');
    comsolModel.sol.create('sol1');

return