function outputModel = setupSolver(inputModel)
%
% function outputModel = setupSolver(inputModel)
%
%    setupSolver.m - Build mesh for RFQ vane quadrant
%
%    outputModel = setupSolver(inputModel)
%
%    setupSolver sets up the electrostatic solver for the Comsol RFQ
%    vane tip inputModel.  Nothing in setupSolver is inputModel specific, since
%    the commands are the same for any electrostatic inputModel: however, the
%    specified physics domain must have been specified and a study created.
%    In addition, a solver must have been created with the command:
%
%        inputModel.sol.create('sol1');
%
%   See also buildComsolModel, modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Simon Jolly.
%
% File history
%
%   23-Aug-2010 S. Jolly
%       Set up of electrostatic solver
%
%   18-Jan-2011 M. J. Easton
%       Adapted to include in ModelRFQ distribution.
%       All functional code unchanged.
%
%======================================================================

%% Check syntax 

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:setupSolver:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:setupSolver:insufficientInputArguments', ...
              'Too few input variables: syntax is outputModel = setupSolver(inputModel)');
    end
    if nargin > 1 %then throw error ModelRFQ:ComsolInterface:setupSolver:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:setupSolver:excessiveInputArguments', ...
              'Too many input variables: syntax is outputModel = setupSolver(inputModel)');
    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:setupSolver:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:setupSolver:excessiveOutputArguments', ...
              'Too many output variables: syntax is outputModel = setupSolver(inputModel)');
    end

%% Create solver study settings 

    inputModel.sol('sol1').feature.create('st1', 'StudyStep');
    inputModel.sol('sol1').feature('st1').set('study', 'std1');
    inputModel.sol('sol1').feature('st1').set('studystep', 'stat');
    inputModel.sol('sol1').feature.create('v1', 'Variables');
    inputModel.sol('sol1').feature.create('s1', 'Stationary');
    inputModel.sol('sol1').feature('s1').feature.create('fc1', 'FullyCoupled');
    inputModel.sol('sol1').feature('s1').feature.create('i1', 'Iterative');
    inputModel.sol('sol1').feature('s1').feature('i1').set('linsolver', 'cg');
    inputModel.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'i1');
    inputModel.sol('sol1').feature('s1').feature('i1').feature.create('mg1', 'Multigrid');
    inputModel.sol('sol1').feature('s1').feature('i1').feature('mg1').set('prefun', 'amg');
    inputModel.sol('sol1').feature('s1').feature.remove('fcDef');
    inputModel.sol('sol1').attach('std1');

%% Output model 

    outputModel = inputModel ;

    return
