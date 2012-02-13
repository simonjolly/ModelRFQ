function comsolModel = specifyTerminals(comsolModel, selectionNames)
%
% function comsolModel = specifyTerminals(comsolModel, selectionNames)
%
%   specifyTerminals defines the electrostatic terminals for the given 
%   Comsol model.
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
%       Built function specifyTerminals from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 2 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:specifyTerminals:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
        end
        if nargin > 2 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:specifyTerminals:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:specifyTerminals:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:specifyTerminals:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:specifyTerminals:syntaxException';
        message.text = 'Syntax error calling specifyTerminals';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Specify electrostatic terminals 

    comsolModel.physics('es').feature.create('term1', 'Terminal', 2);
    comsolModel.physics('es').feature('term1').selection.named(selectionNames.horizontalTerminals);
    comsolModel.physics('es').feature('term1').set('TerminalType', 1, 'Voltage');
    comsolModel.physics('es').feature('term1').set('V0', 1, 'vaneVoltage/2');
    comsolModel.physics('es').feature('term1').set('TerminalName', 1, 'Positive Vanes');
    comsolModel.physics('es').feature('term1').name('Positive Terminal');
    comsolModel.physics('es').feature.create('term2', 'Terminal', 2);
    comsolModel.physics('es').feature('term2').selection.named(selectionNames.verticalTerminals);
    comsolModel.physics('es').feature('term2').set('TerminalType', 1, 'Voltage');
    comsolModel.physics('es').feature('term2').set('V0', 1, '-vaneVoltage/2');
    comsolModel.physics('es').feature('term2').set('TerminalName', 1, 'Negative Vanes');
    comsolModel.physics('es').feature('term2').name('Negative Terminal');
    comsolModel.physics('es').selection.named(selectionNames.airVolumes);

return