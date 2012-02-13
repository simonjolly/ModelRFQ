function comsolModel = setupPlots(comsolModel, selectionNames)
%
% function comsolModel = setupPlots(comsolModel, selectionNames)
%
%   setupPlots defines the plots for the given Comsol model.
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
%   21-Feb-2011 M. J. Easton
%       Built function setupPlots from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 2 %then throw error ModelRFQ:ComsolInterface:setupPlots:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:setupPlots:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
        end
        if nargin > 2 %then throw error ModelRFQ:ComsolInterface:setupPlots:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:setupPlots:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:setupPlots:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:setupPlots:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:setupPlots:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:setupPlots:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setupPlots:syntaxException';
        message.text = 'Syntax error calling setupPlots';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Setup plots 

    comsolModel.result.dataset('dset1').selection.geom('geom1', 3);
    comsolModel.result.dataset('dset1').selection.named(selectionNames.airVolumes);
    comsolModel.result.dataset.create('dset2', 'Solution');
    comsolModel.result.dataset('dset2').selection.geom('geom1', 3);
    comsolModel.result.dataset('dset2').selection.named(selectionNames.beamBoxes);
    comsolModel.result.create('pg1', 3);
    comsolModel.result('pg1').set('data', 'dset1');
    comsolModel.result('pg1').feature.create('surf1', 'Surface');
    comsolModel.result.create('pg2', 3);
    comsolModel.result('pg2').set('data', 'dset2');
    comsolModel.result('pg2').feature.create('slc1', 'Slice');
    comsolModel.result('pg2').feature('slc1').set('quickplane', 'xy');
    comsolModel.result('pg2').feature.create('arwv1', 'ArrowVolume');
    comsolModel.result('pg2').feature('arwv1').set('expr', {'es.Ex' 'es.Ey' 'es.Ez'});
    comsolModel.result('pg2').feature('arwv1').set('descr', 'Electric field');
    comsolModel.result('pg2').feature('arwv1').set('arrowxmethod', 'coord');
    comsolModel.result('pg2').feature('arwv1').set('xcoord', 'range(-10,1,10)[mm]');
    comsolModel.result('pg2').feature('arwv1').set('arrowymethod', 'coord');
    comsolModel.result('pg2').feature('arwv1').set('ycoord', 'range(-10,1,10)[mm]');
    comsolModel.result('pg2').feature('arwv1').set('znumber', '5');
    comsolModel.result.create('pg3', 3);
    comsolModel.result('pg3').set('data', 'dset2');
    comsolModel.result('pg3').feature.create('slc1', 'Slice');
    comsolModel.result('pg3').feature('slc1').set('quickxmethod', 'coord');
    comsolModel.result('pg3').feature.create('arwv1', 'ArrowVolume');
    comsolModel.result('pg3').feature('arwv1').set('expr', {'es.Ex' 'es.Ey' 'es.Ez'});
    comsolModel.result('pg3').feature('arwv1').set('descr', 'Electric field');
    comsolModel.result('pg3').feature('arwv1').set('arrowxmethod', 'coord');
    comsolModel.result('pg3').feature('arwv1').set('xcoord', '0');
    comsolModel.result('pg3').feature('arwv1').set('arrowymethod', 'coord');
    comsolModel.result('pg3').feature('arwv1').set('ycoord', 'range(-10,1,10)[mm]');
    comsolModel.result('pg3').feature('arwv1').set('arrowzmethod', 'coord');
    comsolModel.result('pg3').feature('arwv1').set('zcoord', 'range(selectionStart,1[mm],selectionEnd)');
    comsolModel.result.create('pg4', 3);
    comsolModel.result('pg4').feature.create('slc1', 'Slice');
    comsolModel.result('pg4').feature('slc1').set('expr', 'es.Ez');
    comsolModel.result('pg4').feature('slc1').set('descr', 'Electric field, z component');
    comsolModel.result('pg4').feature('slc1').set('quickxmethod', 'coord');
    comsolModel.result('pg4').feature.create('arwv1', 'ArrowVolume');
    comsolModel.result('pg4').feature('arwv1').set('expr', {'es.Ex' 'es.Ey' 'es.Ez'});
    comsolModel.result('pg4').feature('arwv1').set('descr', 'Electric field');
    comsolModel.result('pg4').feature('arwv1').setIndex('expr', '0', 2);
    comsolModel.result('pg4').feature('arwv1').set('arrowxmethod', 'coord');
    comsolModel.result('pg4').feature('arwv1').set('xcoord', '0');
    comsolModel.result('pg4').feature('arwv1').set('arrowymethod', 'coord');
    comsolModel.result('pg4').feature('arwv1').set('ycoord', '0');
    comsolModel.result('pg4').feature('arwv1').set('znumber', '15');

return