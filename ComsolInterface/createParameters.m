function comsolModel = createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd)
%
% function comsolModel = createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd)
%
%   createParameters creates parameters in the given Comsol model with the
%   values from the other variables passed to the function.
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
%       Built function createParameters from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 11 %then throw error ModelRFQ:ComsolInterface:createParameters:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:createParameters:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd)');
        end
        if nargin > 11 %then throw error ModelRFQ:ComsolInterface:createParameters:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:createParameters:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:createParameters:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:createParameters:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = createParameters(...)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:createParameters:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:createParameters:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = createParameters(...)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createParameters:syntaxException';
        message.text = 'Syntax error calling createParameters';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Create parameters 

    comsolModel.param.set('r0', [num2str(r0.*1e3) '[mm]']);
    comsolModel.param.set('rho', [num2str(rho.*1e3) '[mm]']);
    comsolModel.param.set('boxWidth', [num2str(boxWidth) '[m]']);
    comsolModel.param.set('beamBoxWidth', [num2str(beamBoxWidth) '[m]']);
    comsolModel.param.set('vaneVoltage', [num2str(vaneVoltage) '[V]']);
    comsolModel.param.set('cellNo', num2str(initialCellNo));
    comsolModel.param.set('cellStart', [num2str(cellStart) '[m]']);
    comsolModel.param.set('cellEnd', [num2str(cellEnd) '[m]']);
    comsolModel.param.set('cellLength', 'cellEnd-cellStart');
    comsolModel.param.set('cellMiddle', '(cellLenth/2)+cellStart');
    comsolModel.param.set('selectionStart', [num2str(selectionStart) '[m]']);
    comsolModel.param.set('selectionEnd', [num2str(selectionEnd) '[m]']);
    comsolModel.param.set('selectionLength', 'selectionEnd-selectionStart');
    comsolModel.param.set('selectionMiddle', '(selectionLength/2)+selectionStart');

return