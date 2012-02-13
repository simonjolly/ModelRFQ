function comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, lengthData, vaneVoltage, cadOffset, ...
                                 verticalCellHeight, rho, nExtraCells, nBeamBoxCells, modelFile, outputFile, shouldSaveSeparateCells)
% function comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, ...
%                                  lengthData, vaneVoltage, cadOffset, ...
%                                  verticalCellHeight, rho, nExtraCells, ...
%                                  nBeamBoxCells, modelFile, outputFile, ...
%                                  shouldSaveSeparateCells)
%
% buildCell builds and solves a section of the RFQ vane tip model in 
% Comsol.
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
%   22-Feb-2011 M. J. Easton
%       Split buildComsolModel into subroutines to allow unit testing of 
%       separate parts.
%
%=======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 14 %then throw error ModelRFQ:ComsolInterface:buildCell:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, lengthData, vaneVoltage, cadOffset, verticalCellHeight, rho, nExtraCells, nBeamBoxCells, modelFile, outputFile, shouldSaveSeparateCells)');
        end
        if nargin > 14 %then throw error ModelRFQ:ComsolInterface:buildCell:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, lengthData, vaneVoltage, cadOffset, verticalCellHeight, rho, nExtraCells, nBeamBoxCells, modelFile, outputFile, shouldSaveSeparateCells)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:buildCell:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, lengthData, vaneVoltage, cadOffset, verticalCellHeight, rho, nExtraCells, nBeamBoxCells, modelFile, outputFile, shouldSaveSeparateCells)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:buildCell:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, lengthData, vaneVoltage, cadOffset, verticalCellHeight, rho, nExtraCells, nBeamBoxCells, modelFile, outputFile, shouldSaveSeparateCells)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildCell:syntaxException';
        message.text = 'Syntax error calling buildCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Main block 

    try %to solve model 
        % Select cell from comsolModel by moving selection region
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:startCell';
            message.text = ['    > Cell ' num2str(cellNo)];
            comsolSubSectionTimer = tic;
            if ~mod(cellNo, 10) %then upgrade message priority every 10 cells
                message.priorityLevel = 3;
            else
                message.priorityLevel = 5;
            end
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:start';
            message.text = ['      Start time: ' currentTime() '\n' '       - Setting up selection region...'];
            comsolSubSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to set parameters 
            [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, isCrossingMatchingSection] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells);
            comsolModel.param.set('cellNo', num2str(cellNo,12));
            comsolModel.param.set('boxWidth', [num2str(boxWidth,12) '[m]']);
            comsolModel.param.set('cellStart', [num2str(cellStart,12) '[m]']);
            comsolModel.param.set('cellEnd', [num2str(cellEnd,12) '[m]']);
            comsolModel.param.set('selectionStart', [num2str(selectionStart,12) '[m]']);
            comsolModel.param.set('selectionEnd', [num2str(selectionEnd,12) '[m]']);
            comsolModel.param.set('vaneVoltage', [num2str(vaneVoltage,12) '[V]']);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:parameterException';
            errorMessage.text = 'Could not set parameters.';
            errorMessage.priorityLevel = 3;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end            
        try %to build geometry 
            comsolModel.geom('geom1').runAll;
            comsolModel.geom('geom1').run;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:geometryException';
            errorMessage.text = 'Could not build geometry.';
            errorMessage.priorityLevel = 3;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end     
        try %to set selections 
            comsolModel = setSelections(comsolModel, selectionNames, cellNo, nCells, isCrossingMatchingSection, boxWidth, verticalCellHeight, selectionStart, selectionEnd);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:selectionException';
            errorMessage.text = 'Could not set selections.';
            errorMessage.priorityLevel = 3;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end 
        % Mesh model
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:meshModel:start';
            message.text = '       - Rebuilding mesh...';
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;                
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:meshModel:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to mesh cell 
            comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:meshModel:runException';
            errorMessage.text = 'Could not rebuild mesh.';
            errorMessage.priorityLevel = 5;
            if ~shouldSaveSeparateCells %then crash with error 
                errorMessage.errorLevel = 'error';
            else
                errorMessage.errorLevel = 'warning';
            end                    
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end 
        % Set up solver
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSolver:start';
            message.text = '       - Setting up electrostatic solver...';
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;                
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSolver:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to set up solver 
            comsolModel.sol('sol1').feature.remove('s1') ;
            comsolModel.sol('sol1').feature.remove('v1') ;
            comsolModel.sol('sol1').feature.remove('st1') ;
            comsolModel = setupSolver(comsolModel) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSolver:runException';
            errorMessage.text = 'Could not set up electrostatic solver.';
            errorMessage.priorityLevel = 5;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        % Solve
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:solveModel:start';
            message.text = '       - Solving model...';
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;                
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:solveModel:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to solve model 
            comsolModel.sol('sol1').runAll ;
            comsolModel.result('pg1').run ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:solveModel:runException';
            errorMessage.text = 'Could not solve Comsol model.';
            errorMessage.priorityLevel = 5;
            if ~shouldSaveSeparateCells %then crash with error 
                errorMessage.errorLevel = 'error';
            else
                errorMessage.errorLevel = 'warning';
            end                
            errorMessage.exception = exception;
            logMessage(errorMessage);                
        end
        % Output
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:outputFieldMap:start';
            message.text = '       - Reading out field map data...';
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;                
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:outputFieldMap:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        try %to read out field map and output to file 
            if cellNo == nCells %then define start and end values accordingly 
                [y,x,z] = meshgrid(0:0.0005:0.005,0:0.0005:0.005,cellStart:lengthData(cellNo)/16:cellEnd);
            elseif cellNo == 1
                [y,x,z] = meshgrid(0:0.0005:0.005,0:0.0005:0.005,cellStart:lengthData(cellNo)/64:(cellEnd-lengthData(cellNo)/64));
            else
                [y,x,z] = meshgrid(0:0.0005:0.005,0:0.0005:0.005,cellStart:lengthData(cellNo)/16:(cellEnd-lengthData(cellNo)/16));
            end
            coordinates = [x(:),y(:),z(:)];
            fieldmap = getFieldMap(comsolModel, coordinates);
            fieldmap(:,3) = fieldmap(:,3) - cadOffset; %#ok
            currentFieldMap = ['fieldmap' num2str(cellNo)];
            eval([currentFieldMap ' = fieldmap;']);
            if cellNo == 1 %then create the file; otherwise append to it 
                save(outputFile, currentFieldMap);
            else
                save(outputFile, currentFieldMap, '-append');
            end
            lastCellNo = cellNo;  %#ok
            save(outputFile, 'lastCellNo', '-append');
            eval(['clear ' currentFieldMap]);
            clear x y z coordinates fieldmap lastCellNo currentFieldMap;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildComsolModel:solveFieldMap:outputFieldMap:runException';
            errorMessage.text = 'Could not export field map.';
            errorMessage.priorityLevel = 5;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        % Cell complete
        try %to notify end 
            sectionTimeSeconds = toc(comsolSubSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear comsolSubSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        if shouldSaveSeparateCells %then save current cell separately 
            try % to save Comsol model 
                comsolModel.save(fullfile(pwd, [modelFile(1:length(modelFile)-4) num2str(cellNo) '.mph']));
                message = struct;
                message.identifier = 'ModelRFQ:ComsolInterface:buildCell:saveCell';
                message.text = ['      Saved ' regexprep(fullfile(pwd, [modelFile(1:length(modelFile)-4) num2str(cellNo) '.mph']), '\\', '\\\\')]; 
                message.priorityLevel = 5;
                message.errorLevel = 'information';
                logMessage(message);
                clear message;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:saveCellException';
                errorMessage.text = 'Could not save cell for troubleshooting';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
        end
    catch exception
        try %to save model so user can manually find the problem 
            comsolModel.save(fullfile(pwd, modelFile));
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:saveModel';
            message.text = ['Comsol model saved as ' regexprep(fullfile(pwd, modelFile), '\\', '\\\\') ' for troubleshooting.']; 
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:saveModelException';
            errorMessage.text = 'Could not save model for troubleshooting';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        rethrow(exception);
    end
        
return