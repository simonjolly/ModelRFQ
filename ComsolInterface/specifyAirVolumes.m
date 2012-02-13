function [comsolModel] = specifyAirVolumes(comsolModel, selectionNames)
%
% function comsolModel = specifyAirVolumes(comsolModel, selectionNames)
%
%   SPECIFYAIRVOLUMES.M - define material properties for air domains.
%
%   specifyAirVolumes(comsolModel)
%   specifyAirVolumes(comsolModel, selectionNames)
%   comsolModel = specifyAirVolumes(...)
%
%   specifyAirVolumes defines the material values for the air domains in 
%   the given Comsol model.  These values are taken straight from Comsol
%   and are used to specify the electrostatic properties of the domains
%   that represent air.
%
%   specifyAirVolumes(comsolModel) - set air domain properties for the
%   Comsol model COMSOLMODEL.  The name of the selection of domains
%   containing all the air domains is assumed to be 'sel7'.
%
%   specifyAirVolumes(comsolModel, selectionNames) - also specify name of
%   the air domain selection.  SELECTIONNAMES is a Matlab structure
%   containing strings of the names of various selections for the Comsol
%   model: selectionNames.airVolumes contains the name of the air domain
%   selection.
%
%   comsolModel = specifyAirVolumes(...) - output the modified Comsol model
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
%       Built function specifyAirVolumes from mphrfqsetup and subroutines. 
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

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:specifyAirVolumes:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:specifyAirVolumes:insufficientInputArguments', ...
              'Too few input variables: syntax is comsolModel = specifyAirVolumes(comsolModel)');
    end
    if nargin > 2 %then throw error ModelRFQ:ComsolInterface:specifyAirVolumes:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:specifyAirVolumes:excessiveInputArguments', ...
              'Too many input variables: syntax is comsolModel = specifyAirVolumes(comsolModel, selectionNames)');
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:specifyAirVolumes:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:specifyAirVolumes:insufficientOutputArguments', ...
%              'Too few output variables: syntax is comsolModel = specifyAirVolumes(comsolModel, selectionNames)');
%    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:specifyAirVolumes:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:specifyAirVolumes:excessiveOutputArguments', ...
              'Too many output variables: syntax is comsolModel = specifyAirVolumes(comsolModel, selectionNames)');
    end

    if nargin < 2 || isempty(selectionNames)
        selectionNames = struct ;
        selectionNames.airVolumes = 'sel7' ;
    end

%% Specify air domains 

    comsolModel.material.create('mat1');
    comsolModel.material('mat1').name('Air');
    comsolModel.material('mat1').materialModel('def').set('relpermeability', '1');
    comsolModel.material('mat1').materialModel('def').set('relpermittivity', '1');
    comsolModel.material('mat1').materialModel('def').set('dynamicviscosity', 'eta(T[1/K])[Pa*s]');
    comsolModel.material('mat1').materialModel('def').set('ratioofspecificheat', '1.4');
    comsolModel.material('mat1').materialModel('def').set('electricconductivity', '0[S/m]');
    comsolModel.material('mat1').materialModel('def').set('heatcapacity', 'Cp(T[1/K])[J/(kg*K)]');
    comsolModel.material('mat1').materialModel('def').set('density', 'rho(pA[1/Pa],T[1/K])[kg/m^3]');
    comsolModel.material('mat1').materialModel('def').set('thermalconductivity', 'k(T[1/K])[W/(m*K)]');
    comsolModel.material('mat1').materialModel('def').set('soundspeed', 'cs(T[1/K])[m/s]');
    comsolModel.material('mat1').materialModel('def').func.create('eta', 'Piecewise');
    comsolModel.material('mat1').materialModel('def').func('eta').set('funcname', 'eta');
    comsolModel.material('mat1').materialModel('def').func('eta').set('arg', 'T');
    comsolModel.material('mat1').materialModel('def').func('eta').set('extrap', 'constant');
    comsolModel.material('mat1').materialModel('def').func('eta').set('pieces', {'200.0' '1600.0' '-8.38278E-7+8.35717342E-8*T^1-7.69429583E-11*T^2+4.6437266E-14*T^3-1.06585607E-17*T^4'});
    comsolModel.material('mat1').materialModel('def').func.create('Cp', 'Piecewise');
    comsolModel.material('mat1').materialModel('def').func('Cp').set('funcname', 'Cp');
    comsolModel.material('mat1').materialModel('def').func('Cp').set('arg', 'T');
    comsolModel.material('mat1').materialModel('def').func('Cp').set('extrap', 'constant');
    comsolModel.material('mat1').materialModel('def').func('Cp').set('pieces', {'200.0' '1600.0' '1047.63657-0.372589265*T^1+9.45304214E-4*T^2-6.02409443E-7*T^3+1.2858961E-10*T^4'});
    comsolModel.material('mat1').materialModel('def').func.create('rho', 'Analytic');
    comsolModel.material('mat1').materialModel('def').func('rho').set('funcname', 'rho');
    comsolModel.material('mat1').materialModel('def').func('rho').set('args', {'pA' 'T'});
    comsolModel.material('mat1').materialModel('def').func('rho').set('expr', 'pA*0.02897/8.314/T');
    comsolModel.material('mat1').materialModel('def').func('rho').set('dermethod', 'manual');
    comsolModel.material('mat1').materialModel('def').func('rho').set('argders', {'pA' 'd(pA*0.02897/8.314/T,pA)'; 'T' 'd(pA*0.02897/8.314/T,T)'});
    comsolModel.material('mat1').materialModel('def').func.create('k', 'Piecewise');
    comsolModel.material('mat1').materialModel('def').func('k').set('funcname', 'k');
    comsolModel.material('mat1').materialModel('def').func('k').set('arg', 'T');
    comsolModel.material('mat1').materialModel('def').func('k').set('extrap', 'constant');
    comsolModel.material('mat1').materialModel('def').func('k').set('pieces', {'200.0' '1600.0' '-0.00227583562+1.15480022E-4*T^1-7.90252856E-8*T^2+4.11702505E-11*T^3-7.43864331E-15*T^4'});
    comsolModel.material('mat1').materialModel('def').func.create('cs', 'Analytic');
    comsolModel.material('mat1').materialModel('def').func('cs').set('funcname', 'cs');
    comsolModel.material('mat1').materialModel('def').func('cs').set('args', {'T'});
    comsolModel.material('mat1').materialModel('def').func('cs').set('expr', 'sqrt(1.4*287*T)');
    comsolModel.material('mat1').materialModel('def').func('cs').set('dermethod', 'manual');
    comsolModel.material('mat1').materialModel('def').func('cs').set('argders', {'T' 'd(sqrt(1.4*287*T),T)'});
    comsolModel.material('mat1').materialModel('def').addInput('temperature');
    comsolModel.material('mat1').materialModel('def').addInput('pressure');
    comsolModel.material('mat1').selection.named(selectionNames.airVolumes);

    return
