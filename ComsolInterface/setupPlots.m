function [comsolModel] = setupPlots(comsolModel, selectionNames)
%
% function comsolModel = setupPlots(comsolModel, selectionNames)
%
%   SETUPPLOTS.M - set up RFQ study plots.
%
%   setupPlots(comsolModel)
%   setupPlots(comsolModel, selectionNames)
%   comsolModel = setupPlots(...)
%
%   setupPlots defines the plots for the given Comsol model.  4 different
%   plots are created: the electric potential within the whole air volume;
%   5 longitudinal slices through the air volume showing electrostatic
%   potential and field; the electrostatic potential and field in the air
%   domain at X=0; and the transverse electrostatic field on-axis ie. Z=0.
%
%   setupPlots(comsolModel) - set up plots for the Comsol model
%   COMSOLMODEL.  Default selection names are used for the air domains
%   ('sel7') and the beam boxes ('sel21').
%
%   setupPlots(comsolModel, selectionNames) - also specify the names
%   of the selections.  SELECTIONNAMES is a Matlab structure containing
%   strings of the names of various selections for the Comsol model:
%   selectionNames.airVolumes contains the name of the air domain selection
%   and selectionNames.beamBoxes the beam box selection (both inner and
%   outer).
%
%   comsolModel = setupPlots(...) - output the modified Comsol model
%   as the Matlab object COMSOLMODEL.
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
%   27-May-2011 S. Jolly
%       Removed error checking (contained in wrapper functions) and
%       streamlined input variable parsing.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:setupPlots:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:setupPlots:insufficientInputArguments', ...
              'Too few input variables: syntax is comsolModel = setupPlots(comsolModel)');
    end
    if nargin > 2 %then throw error ModelRFQ:ComsolInterface:setupPlots:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:setupPlots:excessiveInputArguments', ...
              'Too many input variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:setupPlots:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:setupPlots:insufficientOutputArguments', ...
%              'Too few output variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
%    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:setupPlots:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:setupPlots:excessiveOutputArguments', ...
              'Too many output variables: syntax is comsolModel = setupPlots(comsolModel, selectionNames)');
    end

    if nargin < 2 || isempty(selectionNames)
        selectionNames = struct ;
        selectionNames.airVolumes = 'sel7' ;
        selectionNames.beamBoxes = 'sel21' ;
    end        

%% Setup plots 

    comsolModel.result.dataset('dset1').selection.geom('geom1', 3);
    comsolModel.result.dataset('dset1').selection.named(selectionNames.airVolumes);
    comsolModel.result.dataset.create('dset2', 'Solution');
    comsolModel.result.dataset('dset2').selection.geom('geom1', 3);
    comsolModel.result.dataset('dset2').selection.named(selectionNames.beamBoxes);
    comsolModel.result.dataset.create('dset3', 'Solution');
    comsolModel.result.dataset('dset3').selection.geom('geom1', 2);
    comsolModel.result.dataset('dset3').selection.named(selectionNames.allTerminals);

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
    comsolModel.result('pg3').set('data', 'dset1');
    comsolModel.result('pg3').feature.create('slc1', 'Slice');
    comsolModel.result('pg3').feature('slc1').set('quickxmethod', 'coord');
    comsolModel.result('pg3').feature.create('arwv1', 'ArrowVolume');
    comsolModel.result('pg3').feature('arwv1').set('expr', {'es.Ex' 'es.Ey' 'es.Ez'});
    comsolModel.result('pg3').feature('arwv1').set('descr', 'Electric field');
    comsolModel.result('pg3').feature('arwv1').set('arrowxmethod', 'coord');
    comsolModel.result('pg3').feature('arwv1').set('xcoord', '0');
    comsolModel.result('pg3').feature('arwv1').set('arrowymethod', 'coord');
    comsolModel.result('pg3').feature('arwv1').set('ycoord', 'range(0,1[mm],boxWidth)');
    comsolModel.result('pg3').feature('arwv1').set('arrowzmethod', 'coord');
    comsolModel.result('pg3').feature('arwv1').set('zcoord', 'range(selectionStart,1[mm],selectionEnd)');

    comsolModel.result.create('pg4', 3);
    comsolModel.result('pg4').set('data', 'dset1');
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

    comsolModel.result.create('pg5', 3);
    comsolModel.result('pg5').set('data', 'dset3');
    comsolModel.result('pg5').feature.create('surf1', 'Surface');
    comsolModel.result('pg5').feature('surf1').set('expr', 'es.normE');
    comsolModel.result('pg5').feature('surf1').set('descr', 'Electric field norm');

    return
