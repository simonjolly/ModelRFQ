function [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth, aData, maData, zData] ...
           = getModulationParameters(modulationsFile, boxWidthMod)
%
% function [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth, aData, maData, zData] ...
%            = getModulationParameters(modulationsFile, boxWidthMod)
%
%   getModulationParameters returns the modulation parameters required to
%   build and solve the Comsol model for each cell.
%
%   Credit for the majority of the modelling code must go to Simon Jolly of
%   Imperial College London.
%
%   See also buildComsolModel, modelRfq, getModelParameters, logMessage.


% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   19-Feb-2011 M. J. Easton
%       Created getModulationParameters from code previously in
%       buildComsolModel.
%       Included in ModelRFQ distribution.
%
%   30-May-2011 S. Jolly
%       Added improved help details.
%
%   09-Jan-2012 S. Jolly
%       Added boxWidthMod input parameter.
%
%======================================================================

%% Check syntax 

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:getModulationParameters:insufficientInputArguments', ...
              'Too few input variables: syntax is getModulationParameters(modulationsFile)');
    end
    if nargin > 2 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:getModulationParameters:excessiveInputArguments', ...
              'Too many input variables: syntax is getModulationParameters(modulationsFile, boxWidthMod)');
    end
    if nargout > 12 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:getModulationParameters:excessiveOutputArguments', ...
              ['Too many output variables: syntax is [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, ', ...
              'nBeamBoxCells, beamBoxWidth, aData, maData, zData] = getModulationParameters(...)']);
    end
    if nargin < 2 || isempty(boxWidthMod)
        boxWidthMod = 0 ;
    end

%% Get parameters 

    [numericData] = xlsread(modulationsFile, 'RFQVaneModData');
    nCells = numericData(36,16) + 1 ;
    aData = numericData(1:nCells,21).*1e-3;
    maData = numericData(1:nCells,22).*1e-3;
    zData = numericData(1:nCells,24).*1e-3;
    lengthData = numericData(1:nCells,20).*1e-3;
%    rho = (numericData(1,4)).*1e-3;
    rho = (numericData(38,16)).*1e-3;
%    r0 = (numericData(1,23)).*1e-3;
    r0 = (numericData(39,16)).*1e-3;
    vaneVoltage = (numericData(1,6)).*1e3;
    matchingSectionLength = lengthData(1);
    cadOffset = -matchingSectionLength;
    verticalCellHeight = 15e-3;
    nBeamBoxCells = floor( (min(aData) - abs(boxWidthMod)).*4e3 ) - 2 ;
%    nBeamBoxCells = floor( (min(aData) - abs(boxWidthMod)).*4e3 ) ;
    if nBeamBoxCells < 0
        nBeamBoxCells = 0 ;
    end
    beamBoxWidth = nBeamBoxCells/4e3 ;
    clear numericData ;

    return
