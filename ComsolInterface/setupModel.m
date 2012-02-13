function [comsolModel, selectionNames] ...
    = setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ...
                 cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, ...
                 beamBoxWidth, nBeamBoxCells)
%
% function [comsolModel, selectionNames] ...
%    = setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ...
%                 cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, ...
%                 beamBoxWidth, nBeamBoxCells)
%
% setupModel sets up an RFQ vane tip model in Comsol. Based on various mph
% functions by Simon Jolly.
%
% All input variables are required; these are:
%       modelPath       - path to Comsol model
%       modelFile       - filename to save Comsol model
%       cadFile         - CAD file containing Inventor vane model data
%       r0              - r0 for CAD model
%       rho             - rho for CAD model
%       vaneVoltage     - vane-to-vane voltage (normally 85kV)
%       initialCellNo   - number of cell used for setting up model (usually 4 or 5)
%       cellStart       - z-location of start of first cell to be solved
%       cellEnd         - z-location of end of first cell to be solved
%       selectionStart  - z-location of start of selection region
%       selectionEnd    - z-location of end of selection region
%       boxWidth       - transverse size of modelled volume
%       beamBoxWidth    - size of inner beam box air volume
%       nBeamBoxCells   - number of transverse mesh cells in inner beam box
%
% Credit for the majority of the modelling code must go to Simon Jolly of
% Imperial College London.
%
% See also buildComsolModel, modelRfq, getModelParameters, logMessage.


% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Nov-2010 S. Jolly
%       Initial creation of model in Comsol and setup of electrostatic
%       physics, mesh, geometry and study.
%
%   15-Feb-2011 M. J. Easton
%       Built function setupModel from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%   18-Feb-2011 M. J. Easton
%       Split setupComsolModel into setupModel and subroutines to allow
%       unit testing of separate parts.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 14 %then throw error ModelRFQ:ComsolInterface:setupModel:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:insufficientInputArguments', ...
                  'Too few input variables: syntax is setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, beamBoxWidth, nBeamBoxCells)');
        end
        if nargin > 14 %then throw error ModelRFQ:ComsolInterface:setupModel:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:excessiveInputArguments', ...
                  'Too many input variables: syntax is setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, beamBoxWidth, nBeamBoxCells)');
        end
        if nargout < 2 %then throw error ModelRFQ:ComsolInterface:setupModel:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:insufficientOutputArguments', ...
                  'Too few output variables: syntax is [comsolModel, selectionNames] = setupModel(...)');
        end
        if nargout > 2 %then throw error ModelRFQ:ComsolInterface:setupModel:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:excessiveOutputArguments', ...
                  'Too many output variables: syntax is [comsolModel, selectionNames] = setupModel(...)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setupModel:syntaxException';
        message.text = 'Syntax error calling setupModel';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Initialise model: path, geometry, mesh, electrostatics and study 

    try %to initialise model 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:setupModel:initialiseModel:start';
            message.text = '    > Initialising...';
            message.priorityLevel = 6;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:initialiseModel:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        comsolModel = initialiseModel(modelPath);
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:initialiseModel:runException';
        errorMessage.text = 'Could not initialise Comsol model';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    
%% Main block 
    
    try %to create model 
        try %to create parameters 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:createParameters:start';
                message.text = '    > Creating parameters...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createParameters:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            comsolModel = createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, cellStart, cellEnd, selectionStart, selectionEnd);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createParameters:runException';
            errorMessage.text = 'Could not create parameters in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to create geometry 
            [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createGeometry:runException';
            errorMessage.text = 'Could not create geometry in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to specify air volumes 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyAir:start';
                message.text = '    > Specifying air domain...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyAir:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end        
            comsolModel = specifyAirVolumes(comsolModel, selectionNames);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyAir:runException';
            errorMessage.text = 'Could not specify air volumes in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to specify electrostatic terminals 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyTerminals:start';
                message.text = '    > Specifying electrostatic terminals...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyTerminals:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            comsolModel = specifyTerminals(comsolModel, selectionNames);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyTerminals:runException';
            errorMessage.text = 'Could not specify electrostatic terminals in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to create mesh 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:createMesh:start';
                message.text = '    > Creating mesh...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createMesh:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createMesh:runException';
            errorMessage.text = 'Could not create mesh in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to setup solver 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupSolver:start';
                message.text = '    > Setting up electrostatic solver...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupSolver:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            comsolModel = setupSolver(comsolModel);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupSolver:runException';
            errorMessage.text = 'Could not set up Comsol solver';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to set up plots 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupPlots:start';
                message.text = '    > Creating plots...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupPlots:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            comsolModel = setupPlots(comsolModel, selectionNames);            
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupPlots:runException';
            errorMessage.text = 'Could not set up plots in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to save model 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:saveModel:start';
                message.text = '    > Saving model...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:saveModel:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            comsolModel.save(fullfile(modelPath, modelFile));
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupComsolModel:saveException';
            errorMessage.text = 'Could not save Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    catch exception
        try %to save model so user can manually find the problem 
            comsolModel.save([modelPath filesep modelFile]);
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:setupModel:saveModel';
            message.text = ['Comsol model saved as ' regexprep([modelPath filesep modelFile], '\\', '\\\\') ' for troubleshooting.'];
            message.priorityLevel = 6;
            message.errorLevel = 'information';
            logMessage(message);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:setupModel:saveModelException';
            errorMessage.text = 'Could not save model for troubleshooting';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        rethrow(exception);
    end

return