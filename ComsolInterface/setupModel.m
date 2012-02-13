function [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] ...
    = setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ...
                 nCells, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, ...
                 beamBoxWidth, nBeamBoxCells, fourQuad, inputParameters)
%
% function [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] ...
%    = setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ...
%                 nCells, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, ...
%                 beamBoxWidth, nBeamBoxCells, fourQuad, inputParameters)
%
%   SETUPMODEL.M - sets up an RFQ vane tip model in Comsol.
%
%   setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ...
%                 nCells, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, ...
%                 beamBoxWidth, nBeamBoxCells)
%   setupModel(..., inputParameters)
%
%   [comsolModel] = setupModel(...)
%   [comsolModel, selectionNames] = setupModel(...)
%   [comsolModel, selectionNames, vaneBoundBoxes] = setupModel(...)
%   [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox] = setupModel(...)
%   [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] = setupModel(...)
%
%   setupModel is used to import a CAD model of an RFQ vane tip model into
%   Comsol and create an electrostatic model of a positive quadrant of a
%   single RFQ cell ready for field mapping.  The nominal syntax is:
%
%   setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ...
%                 cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, ...
%                 beamBoxWidth, nBeamBoxCells)
%
%   All input variables are required; these are:
%       modelPath       - path to Comsol model
%       modelFile       - filename to save Comsol model
%       cadFile         - CAD file containing Inventor vane model data
%       r0              - r0 for CAD model
%       rho             - rho for CAD model
%       vaneVoltage     - vane-to-vane voltage (normally 85kV)
%       initialCellNo   - number of cell used for setting up model (usually 4 or 5)
%       nCells          - number of cells in entire CAD model
%       cellStart       - z-location of start of first cell to be solved
%       cellEnd         - z-location of end of first cell to be solved
%       selectionStart  - z-location of start of selection region
%       selectionEnd    - z-location of end of selection region
%       boxWidth        - transverse size of modelled volume
%       beamBoxWidth    - size of inner beam box air volume
%       nBeamBoxCells   - number of transverse mesh cells in inner beam box
%
%   [...] = setupModel(..., inputParameters) - also specify parameters to
%   be passed to logMessage for information logging and display, produced
%   by getModelParameters.
%
%   [comsolModel] = setupModel(...) - outputs the Comsol model object as
%   COMSOLMODEL.
%
%   [comsolModel, selectionNames] = setupModel(...) - provides a structure,
%   SELECTIONNAMES, containing the names of the selections for each of the
%   domains in the Comsol model.
%
%   [comsolModel, selectionNames, vaneBoundBoxes] = setupModel(...) -
%   return the Bounding Boxes of each of the 4 vane objects in the Comsol
%   model as VANEBOUNDBOXES.
%
%   [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox] = setupModel(...)
%   - also outputs the Bounding Box surrounding the whole model as
%   MODELBOUNDBOX.
%
%   [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] = setupModel(...)
%   - returns the parameters from logMessage as the structure
%   outputParameters.
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
%   24-May-2011 S. Jolly
%       Modified logMessage references to use "parameters" variable and
%       stop multiple accesses of log file.  Added passing of "parameters"
%       variable to all sub-functions.  Included references to bounding
%       boxes of individual vanes and complete model.
%
%   21-Nov-2011 S. Jolly
%       Added fourQuad variable to create 4-quadrant model.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    if nargin < 17 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
        warning('ModelRFQ:ComsolInterface:setupModel:incorrectParameters', ...
                'Invalid parameters structure. Using default parameters.') ;
    else % store parameters
        parameters = inputParameters ;
    end
    if nargin < 16 || isempty(fourQuad)
        fourQuad = false ;
    end

    if ~isfield(parameters, 'options') || ~isstruct(parameters.options)
        parameters.options = struct ;
    end
    if ~isfield(parameters.options, 'verbosity') || ~isstruct(parameters.options.verbosity)
        parameters.options.verbosity = struct ;
    end
    if ~isfield(parameters.options.verbosity, 'toPlots') || ~isnumeric(parameters.options.verbosity.toPlots)
        parameters.options.verbosity.toPlots = 0 ;
    end

    try %to test syntax
        if nargin < 15 %then throw error ModelRFQ:ComsolInterface:setupModel:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:insufficientInputArguments', ...
                  ['Too few input variables: syntax is setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, ' ...
                  'initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, beamBoxWidth, nBeamBoxCells)']);
        end
        if nargin > 17 %then throw error ModelRFQ:ComsolInterface:setupModel:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:excessiveInputArguments', ...
                  ['Too many input variables: syntax is setupModel(modelPath, modelFile, cadFile, r0, rho, vaneVoltage, initialCellNo, ' ...
                  'nCells, cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, beamBoxWidth, nBeamBoxCells, fourQuad, inputParameters)']);
        end
%        if nargout < 2 %then throw error ModelRFQ:ComsolInterface:setupModel:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:setupModel:insufficientOutputArguments', ...
%                  'Too few output variables: syntax is [comsolModel, selectionNames] = setupModel(...)');
%        end
        if nargout > 5 %then throw error ModelRFQ:ComsolInterface:setupModel:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:setupModel:excessiveOutputArguments', ...
                  'Too many output variables: syntax is [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] = setupModel(...)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setupModel:syntaxException';
        message.text = 'Syntax error calling setupModel';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Initialise model: path, geometry, mesh, electrostatics and study 

    try %to initialise model 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:setupModel:initialiseModel:start';
            message.text = '    > Initialising...';
            message.priorityLevel = 6;
            message.errorLevel = 'information';
            parameters = logMessage(message, parameters) ;
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:initialiseModel:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            parameters = logMessage(errorMessage, parameters) ;
        end
        comsolModel = initialiseModel(modelPath) ;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:initialiseModel:runException';
        errorMessage.text = 'Could not initialise Comsol model';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        parameters = logMessage(errorMessage, parameters) ;
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
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createParameters:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            comsolModel = createParameters(comsolModel, r0, rho, boxWidth, beamBoxWidth, vaneVoltage, initialCellNo, nCells, cellStart, cellEnd, selectionStart, selectionEnd) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createParameters:runException';
            errorMessage.text = 'Could not create parameters in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        try %to create geometry 
            [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox] = createGeometry(comsolModel, cadFile, fourQuad, parameters) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createGeometry:runException';
            errorMessage.text = 'Could not create geometry in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        try %to specify air volumes 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyAir:start';
                message.text = '    > Specifying air domain...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyAir:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end        
            comsolModel = specifyAirVolumes(comsolModel, selectionNames) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyAir:runException';
            errorMessage.text = 'Could not specify air volumes in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        try %to specify electrostatic terminals 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyTerminals:start';
                message.text = '    > Specifying electrostatic terminals...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyTerminals:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            comsolModel = specifyTerminals(comsolModel, selectionNames) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:specifyTerminals:runException';
            errorMessage.text = 'Could not specify electrostatic terminals in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        try %to create mesh 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:createMesh:start';
                message.text = '    > Creating mesh...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createMesh:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells, parameters) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:createMesh:runException';
            errorMessage.text = 'Could not create mesh in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        try %to setup solver 
            try %to notify start 
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupSolver:start';
                message.text = '    > Setting up electrostatic solver...';
                message.priorityLevel = 6;
                message.errorLevel = 'information';
                logMessage(message, parameters) ;
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupSolver:startException';
                errorMessage.text = 'Could not notify start of section';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage, parameters) ;
            end
            comsolModel = setupSolver(comsolModel) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupSolver:runException';
            errorMessage.text = 'Could not set up Comsol solver';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        try %to set up plots 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupPlots';
            message.text = '    > Creating plots...';
            message.priorityLevel = 6;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear message;
            comsolModel = setupPlots(comsolModel, selectionNames) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setupModel:setupPlots:runException';
            errorMessage.text = 'Could not set up plots in Comsol model';
            errorMessage.priorityLevel = 6;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
    catch exception
        try %to save model so user can manually find the problem
            comsolModel.save(fullfile(modelPath, modelFile));
%            comsolModel.save(modelFile);
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:setupModel:saveModel';
            message.text = ['Comsol model saved as ' regexprep(fullfile(modelPath, modelFile), '\\', '\\\\') ' for troubleshooting.'];
%            message.text = ['Comsol model saved as ' regexprep(modelFile, '\\', '\\\\') ' for troubleshooting.'];
            message.priorityLevel = 6;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:setupModel:saveModelException';
            errorMessage.text = 'Could not save model for troubleshooting';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end
        rethrow(exception);
    end

    outputParameters = parameters ;

    return

