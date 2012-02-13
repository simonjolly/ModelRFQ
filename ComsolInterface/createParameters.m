function [comsolModel] = ...
    createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd)
%
% function comsolModel = 
%    createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd)
%
%   CREATEPARAMETERS.M - create parameters in RFQ Comsol model.
%
%   createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd)
%   comsolModel = createParameters(...)
%
%   createParameters creates parameters in the given Comsol model with the
%   values from the other variables passed to the function.  This is used
%   to set up the necessary parameters within the Comsol model for the RFQ
%   vane tip model.
%
%   createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd)
%   - create parameters within the Comsol model COMSOLMODEL.  All input
%   variables are required; these are:
%
%       r0              - r0 for CAD model
%       rho             - rho for CAD model
%       boxWidth        - transverse size of modelled volume
%       beamBoxWidth    - size of inner beam box air volume
%       vaneVoltage     - vane-to-vane voltage (normally 85kV)
%       initialCellNo   - number of cell used for setting up model (usually 4 or 5)
%       nCells          - number of cells in entire CAD model
%       cellStart       - z-location of start of first cell to be solved
%       cellEnd         - z-location of end of first cell to be solved
%       selectionStart  - z-location of start of selection region
%       selectionEnd    - z-location of end of selection region
%
%   comsolModel = createParameters(...) - output the Comsol model to the
%   object COMSOLMODEL.
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
%       Built function createParameters from mphrfqsetup and subroutines. 
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

    if nargin < 12 %then throw error ModelRFQ:ComsolInterface:createParameters:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:createParameters:insufficientInputArguments', ...
              ['Too few input variables: syntax is comsolModel = createParameters(comsolModel, r0, rho, boxWidth, ' ...
              'beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd)']) ;
    end
    if nargin > 12 %then throw error ModelRFQ:ComsolInterface:createParameters:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:createParameters:excessiveInputArguments', ...
              ['Too many input variables: syntax is comsolModel = ', ...
              'createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd)']);
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:createParameters:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:createParameters:insufficientOutputArguments', ...
%              'Too few output variables: syntax is comsolModel = createParameters(...)');
%    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:createParameters:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:createParameters:excessiveOutputArguments', ...
              'Too many output variables: syntax is comsolModel = createParameters(...)');
    end

%% Create parameters 

    comsolModel.param.set('r0', [num2str(r0.*1e3) '[mm]']);
    comsolModel.param.set('rho', [num2str(rho.*1e3) '[mm]']);
    comsolModel.param.set('boxWidth', [num2str(boxWidth) '[m]']);
    comsolModel.param.set('beamBoxWidth', [num2str(beamBoxWidth) '[m]']);
    comsolModel.param.set('vaneVoltage', [num2str(vaneVoltage) '[V]']);
    comsolModel.param.set('cellNo', num2str(initialCellNo));
    comsolModel.param.set('nCells', num2str(nCells));
    comsolModel.param.set('cellStart', [num2str(cellStart) '[m]']);
    comsolModel.param.set('cellEnd', [num2str(cellEnd) '[m]']);
    comsolModel.param.set('cellLength', 'cellEnd-cellStart');
    comsolModel.param.set('cellMiddle', '(cellLength/2)+cellStart');
    comsolModel.param.set('selectionStart', [num2str(selectionStart) '[m]']);
    comsolModel.param.set('selectionEnd', [num2str(selectionEnd) '[m]']);
    comsolModel.param.set('selectionLength', 'selectionEnd-selectionStart');
    comsolModel.param.set('selectionMiddle', '(selectionLength/2)+selectionStart');

    return
