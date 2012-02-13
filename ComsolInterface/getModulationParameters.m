function [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
           = getModulationParameters(modulationsFile)
%
% function [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] ...
%            = getModulationParameters(modulationsFile)
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
%======================================================================

%% Check syntax 

    try %to test syntax 
        if nargin < 1 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:getModulationParameters:insufficientInputArguments', ...
                  'Too few input variables: syntax is getModulationParameters(modulationsFile)');
        end
        if nargin > 1 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:getModulationParameters:excessiveInputArguments', ...
                  'Too many input variables: syntax is getModulationParameters(modulationsFile)');
        end
        if nargout < 9 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:getModulationParameters:insufficientOutputArguments', ...
                  'Too few output variables: syntax is [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] = getModulationParameters(modulationsFile)');
        end
        if nargout > 9 %then throw error ModelRFQ:ComsolInterface:getModulationParameters:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:getModulationParameters:excessiveOutputArguments', ...
                  'Too many output variables: syntax is [nCells, lengthData, rho, r0, vaneVoltage, cadOffset, verticalCellHeight, nBeamBoxCells, beamBoxWidth] = getModulationParameters(modulationsFile)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:getModulationParameters:syntaxException';
        message.text = 'Syntax error calling getModulationParameters';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Get parameters 

    try %to get modulation parameters 
        [numericData] = xlsread(modulationsFile, 'RFQVaneModData');
        nCells = numericData(36,16);
        aData = numericData(1:nCells,21).*1e-3;
        lengthData = numericData(1:nCells,20).*1e-3;
        rho = (numericData(1,4)).*1e-3;
        r0 = (numericData(1,23)).*1e-3;
        vaneVoltage = (numericData(1,6)).*1e3;
        matchingSectionLength = lengthData(1);
        cadOffset = -matchingSectionLength;
        verticalCellHeight = 15e-3;
        nBeamBoxCells = floor(min(aData).*4e3);% - 2;
        beamBoxWidth = nBeamBoxCells/4e3;
        clear numericData aData zData;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:getModulationParameters:exception';
        message.text = 'Cannot retrieve modulation parameters';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
return