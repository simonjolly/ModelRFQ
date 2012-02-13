function [comsolModel] = initialiseModel(modelPath)
%
% function comsolModel = initialiseModel(modelPath)
%
%   INITIALISEMODEL.M - create a Comsol model at the specified path.
%
%   initialiseModel(modelPath)
%   comsolModel = initialiseModel(modelPath)
%
%   initialiseModel creates a Comsol model at the specified path.  It is
%   the first function to be called as part of setting up a Comsol model
%   from within Matlab.  It also sets up an initial geometry object,
%   electrostatic physics and an initial mesh.
%
%   initialiseModel(modelPath) - intialise Comsol model in directory
%   MODELPATH.
%
%   comsolModel = initialiseModel(modelPath) - output the initialised
%   Comsol model to the object COMSOLMODEL.
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
%   27-May-2011 S. Jolly
%       Removed error checking (contained in wrapper functions) and
%       streamlined input variable parsing.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:initialiseModel:insufficientInputArguments', ...
              'Too few input variables: syntax is comsolModel = initialiseModel(modelPath)');
    end
    if nargin > 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:initialiseModel:excessiveInputArguments', ...
              'Too many input variables: syntax is comsolModel = initialiseModel(modelPath)');
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:initialiseModel:insufficientOutputArguments', ...
%              'Too few output variables: syntax is comsolModel = initialiseModel(modelPath)');
%    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:initialiseModel:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:initialiseModel:excessiveOutputArguments', ...
              'Too many output variables: syntax is comsolModel = initialiseModel(modelPath)');
    end

%% Initialise model: path, geometry, mesh, electrostatics and study 

    comsolModel = ModelUtil.create('RFQ');
    comsolModel.modelPath(modelPath);
    comsolModel.modelNode.create('mod1');
    comsolModel.geom.create('geom1', 3);
    comsolModel.mesh.create('mesh1', 'geom1');
    comsolModel.physics.create('es', 'Electrostatics', 'geom1');
    comsolModel.study.create('std1');
    comsolModel.study('std1').feature.create('stat', 'Stationary');
    comsolModel.sol.create('sol1');

    return
