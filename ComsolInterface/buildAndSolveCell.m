function [comsolModel, cellfieldmap, outputParameters] = buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, ...
                                verticalCellHeight, rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
                                endFlangeThickness, xGridVals, yGridVals, zGridSteps, inputParameters)
% function [comsolModel, cellfieldmap, outputParameters] = buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, ...
%                                  verticalCellHeight, rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%                                  endFlangeThickness, xGridVals, yGridVals, zGridSteps, inputParameters)
%
%   BUILDANDSOLVECELL.M - Build and solve electrostatic RFQ Cell Comsol Model
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData,)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, rho)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, xGridVals, yGridVals, zGridSteps)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, xGridVals, yGridVals, zGridSteps, separateCellsFile)
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, xGridVals, yGridVals, zGridSteps, separateCellsFile, inputParameters)
%
%   [comsolModel] = buildAndSolveCell(...)
%   [comsolModel, cellfieldmap] = buildAndSolveCell(...)
%   [comsolModel, cellfieldmap, outputParameters] = buildAndSolveCell(...)
%
%   buildAndSolveCell builds and solves a section of the RFQ vane tip model in 
%   Comsol.  The model must already have been created using 'createModel'
%   or 'setupModel'.  buildAndSolveCell calls buildCell in order to build
%   the RFQ cell and solveCell to solve the electrostatic field map.
%
%   buildAndSolveCell builds a section of the RFQ vane tip model in 
%   Comsol.  The model must already have been created using 'createModel'
%   or 'setupModel'.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData)
%   - build electrostatic model of a single RFQ cell within the model
%   COMSOLMODEL.  The cell to be selected is given by CELLLIST: this can
%   either be a single value or a list of cells to analyse, which do not
%   have to be consecutive.  If cellList specifies a list of cells in this
%   way, each cell is solved in turn.  SELECTIONNAMES is a structure
%   containing the names of the selections for each of the domains in the
%   model: see setSelections for more details.  The lengths of each cell
%   are given by LENGTHDATA: as such, length(lengthData) must equal the
%   number of cells in the RFQ; lengthData must be an [N x 1] array of cell
%   length values, given in metres.  It is assumed that the first cell in
%   the list is the matching section, and that the start of the matching
%   section is at Z = 0.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells)
%   - specify the number of cells in the RFQ with NCELLS.  Note that there
%   is no default value for nCells: if this input variable is not
%   specified, or is left empty, buildAndSolveCell will attempt to read the
%   value out from the Comsol model.  If no value is found in the Comsol
%   model, an error is thrown.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight)
%   - also provides the transverse distance from the beam axis to the back
%   of the vane tip sections, referred to as the VERTICALCELLHEIGHT.
%   verticalCellHeight is given in metres: the default value is
%   specified in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, rho)
%   - also specify the mean radius of the vane tips in metres.  This is
%   necessary only if cellList includes the first or second cells ie.
%   selects part of the matching section.  This is because the transverse
%   distance of the CAD model at the matching section is larger than the
%   main vane sections as the matching section is a quarter circle.  The
%   default value is specified in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells) - specify the number of mesh cells in the inner
%   beam box with NBEAMBOXCELLS.  The default size of the inner beam box is
%   2.5 mm, so for a default width of 0.25 mm per mesh cell, 
%   nBeamBoxCells = 10; this is the default value.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells) - specify the number of extra
%   cells either side of each cell specified in cellList to be included in
%   the selection region with NEXTRACELLS: this is necessary to accurately
%   model the leakage of field between adjacent cells.  The default value
%   is specified in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset) - specifies the
%   Z-offset of the start of the CAD model with CADOFFSET.  cadOffset must 
%   be given in metres.  cadOffset is used primarily because the CAD models
%   usually have the origin at the end of the matching section, not the
%   start, so any coordinate selection must be shifted accordingly.  The
%   default value is specified in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos) -
%   specify the start location of the CAD model, VANEMODELSTARTPOS, in
%   metres.  This is used primarily when there are end plates or other
%   objects that need to be modelled that sit before the start of the
%   matching section and would otherwise get missed by the selection
%   region.  The default value is specified in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos)
%   - also specify the end location of the CAD model, VANEMODELENDPOS, in
%   metres, for the same reasons as above.  The default value is specified
%   in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness) - specify the thickness of any end flanges in
%   the model with ENDFLANGETHICKNESS, in metres.  This is used by
%   setSelections to accurately determine whether any end flanges exist in
%   the model.  The default value is specified in buildCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, xGridVals, yGridVals, zGridSteps)
%   - specify the grid point locations to read out the field map data.  The
%   default values are specified in solveCell.
%
%   buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, xGridVals, yGridVals, zGridSteps, inputParameters)
%   - also specify parameters to be passed to logMessage for information
%   logging and display, produced by getModelParameters.
%
%   [comsolModel] = buildAndSolveCell(...) - output solved model as
%   modified comsol model COMSOLMODEL.
%
%   [comsolModel, cellfieldmap] = buildAndSolveCell(...) - output field map
%   of solved field region to FIELDMAP.  If cellList specifies just a
%   single cell, fieldmap is a numeric array containing the electrostatic
%   field for that cell; if cellList specifies a list of cells, fieldmap is
%   a cell array containing one element for each RFQ cell, the same
%   dimensions as cellList.
%
%   [comsolModel, cellfieldmap, outputParameters] = buildAndSolveCell(...)
%   - returns the parameters from logMessage as the structure
%   outputParameters.
%
%   See also buildComsolModel, modelRfq, getModelParameters, setupModel,
%   setSelections, createModel, buildCell, solveCell, setupSolver,
%   logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   19-Jul 2011 S. Jolly
%       Combined buildCell and solveCell into single function
%
%=======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    if nargin < 16 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
    else % store parameters
        parameters = inputParameters ;
    end

    try %to test syntax 
        if nargin < 6 %then throw error ModelRFQ:ComsolInterface:buildCell:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:insufficientInputArguments', ...
                  ['Too few input variables: syntax is comsolModel = buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, nCells)']);
        end
        if nargin > 17 %then throw error ModelRFQ:ComsolInterface:buildCell:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:excessiveInputArguments', ...
                  ['Too many input variables: syntax is comsolModel = buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData, '...
                  'nCells, verticalCellHeight, rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, '...
                  'endFlangeThickness, xGridVals, yGridVals, zGridSteps, inputParameters)']);
        end
%        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:buildCell:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:buildCell:insufficientOutputArguments', ...
%                  ['Too few output variables: syntax is comsolModel = buildAndSolveCell(comsolModel, cellList, selectionNames, lengthData)']);
%        end
        if nargout > 3 %then throw error ModelRFQ:ComsolInterface:buildCell:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:excessiveOutputArguments', ...
                  ['Too many output variables: syntax is [comsolModel, cellfieldmap, outputParameters] = buildAndSolveCell(comsolModel, cellList, selectionNames, ' ...
                  'lengthData)']);
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:syntaxException';
        message.text = 'Syntax error calling buildAndSolveCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Default values 

    if nargin < 16 || isempty(zGridSteps)
        zGridSteps = [] ;
    end
    if nargin < 15 || isempty(yGridVals)
        yGridVals = [] ;
    end
    if nargin < 14 || isempty(xGridVals)
        xGridVals = [] ;
    end
    if nargin < 13 || isempty(endFlangeThickness)
        endFlangeThickness = [] ;
    end
    if nargin < 12 || isempty(vaneModelEndPos)
        vaneModelEnd = [] ;
    else
        vaneModelEnd = vaneModelEndPos ;
    end
    if nargin < 11 || isempty(vaneModelStartPos)
        vaneModelStart = [] ;
    else
        vaneModelStart = vaneModelStartPos ;
    end
    if nargin < 10 || isempty(cadOffset)
        cadOffset = [] ;
    end
    if nargin < 9 || isempty(nExtraCells)
        nExtraCells = [] ;
    end
    if nargin < 8 || isempty(nBeamBoxCells)
        nBeamBoxCells = [] ;
    end
    if nargin < 7 || isempty(rho)
        rho = [] ;
    end
    if nargin < 6 || isempty(verticalCellHeight)
        verticalCellHeight = [] ;
    end

    if nargin < 5 || isempty(nCells)
        varnames = comsolModel.param.varnames ;
        nCellsFound = false ;
        for i = 1:length(varnames)
            if strfind(char(varnames(i)),'nCells')
                nCellsFound = true ;
            end
        end
        if nCellsFound
            nCellsStr = comsolModel.param.get('nCells') ;
            nCells = str2num(nCellsStr) ;
        else
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:findnCells:runException';
            errorMessage.text = 'Could not find number of cells in Comsol model';
            errorMessage.priorityLevel = 5;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            parameters = logMessage(errorMessage, parameters) ;                
        end
    end

%% Rebuild cell in comsolModel by moving selection region

    if nargout > 1
        if length(cellList) > 1
            cellfieldmap = cell(size(cellList)) ;
        else
            cellfieldmap = [] ;
        end
    end

    for i = 1:length(cellList)

        try %to notify start
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:buildCell:startTime';
            message.text = ['      Start time: ' currentTime() '\n' '       - Rebuilding cell ' num2str(cellList(i)) '...'];
            comsolSubSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            parameters = logMessage(message, parameters) ;
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:buildCell:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            parameters = logMessage(errorMessage, parameters) ;
        end

        try %to build current cell
            comsolModel = buildCell(comsolModel, cellList(i), selectionNames, lengthData, verticalCellHeight, ...
                            rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStart, vaneModelEnd, endFlangeThickness, parameters) ;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:buildCell:buildException';
            errorMessage.text = 'Could not build model cell';
            errorMessage.priorityLevel = 3;
            errorMessage.errorLevel = 'error';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end

        try %to notify end 
            sectionTimeSeconds = toc(comsolSubSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' sectionTime '.'] ;
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:buildCell:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear comsolSubSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:buildCell:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end

        try %to notify start
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:start';
            message.text = ['      Start time: ' currentTime() '\n' '       - Solving cell ' num2str(cellList(i)) '...'];
            comsolSubSectionTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:startException';
            errorMessage.text = 'Could not notify start of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end

        try %to solve model
            if cellList(i) == 1
                [comsolModel, solvedfieldmap] = solveCell(comsolModel, cadOffset, -1, xGridVals, yGridVals, zGridSteps) ;
            elseif cellList(i) > nCells
                [comsolModel, solvedfieldmap] = solveCell(comsolModel, cadOffset, 1, xGridVals, yGridVals, zGridSteps) ;
            else
                [comsolModel, solvedfieldmap] = solveCell(comsolModel, cadOffset, 0, xGridVals, yGridVals, zGridSteps) ;
            end
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:runException';
            errorMessage.text = 'Could not solve Comsol model.';
            errorMessage.priorityLevel = 5;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end

        try %to notify end
            sectionTimeSeconds = toc(comsolSubSectionTimer);
            sectionTime = convertSecondsToText(sectionTimeSeconds);
            text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' sectionTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:endTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message, parameters) ;
            clear comsolSubSectionTimer sectionTimeSeconds sectionTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildAndSolveCell:solveCell:endTimeException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage, parameters) ;
        end

        if nargout > 1
            if numel(cellList) > 1
                cellfieldmap{i} = solvedfieldmap ;
            else
                cellfieldmap = solvedfieldmap ;
            end
        end

    end

    outputParameters = parameters ;
        
    return
