function [comsolModel] = specifyTerminals(comsolModel, selectionNames)
%
% function comsolModel = specifyTerminals(comsolModel, selectionNames)
%
%   SPECIFYTERMINALS.M - define electrostatic terminals.
%
%   specifyTerminals(comsolModel)
%   specifyTerminals(comsolModel, selectionNames)
%   comsolModel = specifyTerminals(...)
%
%   specifyTerminals sets up the electrostatic terminals for the Comsol RFQ
%   vane tip simulation.  The vane tip voltages are set using the Comsol
%   parameter 'vaneVoltage'.
%
%   specifyTerminals(comsolModel) - set electrostatic terminals for the
%   Comsol model COMSOLMODEL.  Default selection names are used for the
%   horizontal vane/terminal ('sel5'), the vertical vane/terminal ('sel6')
%   and the air domains ('sel7').
%
%   specifyTerminals(comsolModel, selectionNames) - also specify the names
%   of the selections.  SELECTIONNAMES is a Matlab structure containing
%   strings of the names of various selections for the Comsol model:
%   selectionNames.horizontalTerminals contains the name of the horizontal
%   vane/terminal selection, selectionNames.verticalTerminals contains the
%   vertical vane/terminal selection and selectionNames.airVolumes the air
%   domain selection.
%
%   comsolModel = specifyTerminals(...) - output the modified Comsol model
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
%       Built function specifyTerminals from mphrfqsetup and subroutines. 
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

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:specifyTerminals:insufficientInputArguments', ...
              'Too few input variables: syntax is comsolModel = specifyTerminals(comsolModel)');
    end
    if nargin > 2 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:specifyTerminals:excessiveInputArguments', ...
              'Too many input variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:specifyTerminals:insufficientOutputArguments', ...
%              'Too few output variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
%    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:specifyTerminals:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:specifyTerminals:excessiveOutputArguments', ...
              'Too many output variables: syntax is comsolModel = specifyTerminals(comsolModel, selectionNames)');
    end

    if nargin < 2 || isempty(selectionNames)
        selectionNames = struct ;
        selectionNames.horizontalTerminals = 'sel5' ;
        selectionNames.verticalTerminals = 'sel6' ;
        selectionNames.airVolumes = 'sel7' ;
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

%% Specify end flange grounded surface

    comsolModel.physics('es').feature.create('gnd1', 'Ground', 2);
    comsolModel.physics('es').feature('gnd1').name('End Flange Surface Ground');
    comsolModel.physics('es').feature('gnd1').selection.named(selectionNames.endFlangeGrounded);
    comsolModel.physics('es').feature('gnd1').active(false);

    return
