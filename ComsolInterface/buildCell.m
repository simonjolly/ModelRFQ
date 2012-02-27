function [comsolModel, outputParameters] = buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, rho, nBeamBoxCells, ...
                                 nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness, boxWidthMod, inputParameters)
% function [comsolModel, outputParameters] = buildCell(comsolModel, cellNo, selectionNames, ...
%                                  lengthData, verticalCellHeight, rho, nBeamBoxCells, nExtraCells, ...
%                                  cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness, boxWidthMod, inputParameters)
%
%   BUILDCELL.M - Build electrostatic RFQ cell Comsol Model
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, rho)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness, boxWidthMod)
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness, boxWidthMod, inputParameters)
%
%   [comsolModel] = buildCell(...)
%   [comsolModel, outputParameters] = buildCell(...)
%
%   buildCell builds a section of the RFQ vane tip model in 
%   Comsol.  The model must already have been created using 'createModel'
%   or 'setupModel'.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData) - build
%   electrostatic model of a single RFQ cell within the model COMSOLMODEL.
%   The cell to be selected is given by CELLNO: this must be a single
%   value.  SELECTIONNAMES is a structure containing the names of the
%   selections for each of the domains in the model: see setSelections for
%   more details.  The lengths of each cell are given by LENGTHDATA: as
%   such, length(lengthData) must equal the number of cells in the RFQ;
%   lengthData must be an [N x 1] array of cell length values, given in
%   metres.  It is assumed that the first cell in the list is the matching
%   section, and that the start of the matching section is at Z = 0.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight)
%   - also provides the transverse distance from the beam axis to the back
%   of the vane tip sections, referred to as the VERTICALCELLHEIGHT.
%   verticalCellHeight is given in metres: the default value is
%   verticalCellHeight = 15e-3 (15 mm).
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, rho)
%   - also specify the mean radius of the vane tips.  This is necessary
%   only if cellNo includes the first or second cells ie. selects part of
%   the matching section.  This is because the transverse distance of the
%   CAD model at the matching section is larger than the main vane sections
%   as the matching section is a quarter circle.  The default value is RHO
%   = 3.0986e-3 (3.0986 mm) and must be given in metres.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells) - specify the number of mesh cells in the inner
%   beam box with NBEAMBOXCELLS.  The default size of the inner beam box is
%   2.5 mm, so for a default width of 0.25 mm per mesh cell, 
%   nBeamBoxCells = 10; this is the default value.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells) - specify the number of extra
%   cells either side of cellNo to be included in the selection region with
%   NEXTRACELLS: this is necessary to accurately model the leakage of field
%   between adjacent cells.  The default value is nExtraCells = 1.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset) - specifies the
%   Z-offset of the start of the CAD model with CADOFFSET.  cadOffset must 
%   be given in metres.  cadOffset is used primarily because the CAD models
%   usually have the origin at the end of the matching section, not the
%   start, so any coordinate selection must be shifted accordingly.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos) -
%   specify the start location of the CAD model, VANEMODELSTARTPOS, in
%   metres.  This is used primarily when there are end plates or other
%   objects that need to be modelled that sit before the start of the
%   matching section and would otherwise get missed by the selection
%   region.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos)
%   - also specify the end location of the CAD model, VANEMODELENDPOS, in
%   metres, for the same reasons as above.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness)
%   - specify the thickness of any end flanges in the model with
%   ENDFLANGETHICKNESS, in metres.  This is used by setSelections to
%   accurately determine whether any end flanges exist in the model.  The
%   default value is endFlangeThickness = 14e-3 m.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, boxWidthMod)
%   - specify the width of the total volume being modelled: this is useful
%   when modelling vanes with offsets that cause meshing problems in small
%   gaps.  The default value of boxWidthMod is set by getCellParameters.
%
%   buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ...
%       rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, ...
%       endFlangeThickness, boxWidthMod, inputParameters)
%   - also specify parameters to be passed to logMessage for information
%   logging and display, produced by getModelParameters.
%
%   [comsolModel] = buildCell(...) - output solved model as modified comsol
%   model COMSOLMODEL.
%
%   [comsolModel, outputParameters] = buildCell(...) - returns the
%   parameters from logMessage as the structure outputParameters.
%
%   See also buildComsolModel, modelRfq, getModelParameters, setupModel,
%   setSelections, createModel, buildAndSolveCell, solveCell, setupSolver,
%   logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Feb-2011 M. J. Easton
%       Split buildComsolModel into subroutines to allow unit testing of 
%       separate parts.
%
%   31-May 2011 S. Jolly
%       Split off solveCell from buildCell.  Added extra checking of vane
%       model start and end positions.  Added help documentation.
%
%   11-Jan 2011 S. Jolly
%       Included boxWidthMod input variable.
%
%=======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    if nargin < 14 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
    else % store parameters
        parameters = inputParameters ;
    end

    try %to test syntax 
        if nargin < 4 %then throw error ModelRFQ:ComsolInterface:buildCell:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:insufficientInputArguments', ...
                  ['Too few input variables: syntax is comsolModel = buildCell(comsolModel, cellNo, selectionNames, lengthData)']) ;
        end
        if nargin > 14 %then throw error ModelRFQ:ComsolInterface:buildCell:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:excessiveInputArguments', ...
                  ['Too many input variables: syntax is comsolModel = buildCell(comsolModel, cellNo, selectionNames, lengthData, verticalCellHeight, ' ...
                  'rho, nBeamBoxCells, nExtraCells, cadOffset, vaneModelStartPos, vaneModelEndPos, endFlangeThickness, boxWidthMod, inputParameters)']) ;
        end
%        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:buildCell:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:buildCell:insufficientOutputArguments', ...
%                  ['Too few output variables: syntax is comsolModel = buildCell(comsolModel, cellNo, nCells, selectionNames, ' ...
%                  'lengthData, cadOffset, verticalCellHeight, rho, nExtraCells, nBeamBoxCells, modelFile, outputFile, shouldSaveSeparateCells)']);
%        end
        if nargout > 2 %then throw error ModelRFQ:ComsolInterface:buildCell:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:buildCell:excessiveOutputArguments', ...
                  ['Too many output variables: syntax is [comsolModel, outputParameters] = buildCell(comsolModel, cellNo, selectionNames, lengthData)']) ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:buildCell:syntaxException';
        message.text = 'Syntax error calling buildCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Default values 

    if nargin < 13 || isempty(boxWidthMod)
        boxWidthMod = [] ;
    end
    if nargin < 12 || isempty(endFlangeThickness)
        endFlangeThickness = 14e-3 ;
    end
    if nargin < 9 || isempty(cadOffset)
        cadOffset = 0 ;
    end
    if nargin < 8 || isempty(nExtraCells)
        nExtraCells = 1 ;
    else
        nExtraCells = round(nExtraCells) ;
    end
    if nargin < 7 || isempty(nBeamBoxCells)
        nBeamBoxCells = 10 ;
    end
    if nargin < 6 || isempty(rho)
        rho = 3.0986e-3 ;
    end
    if nargin < 5 || isempty(verticalCellHeight)
        verticalCellHeight = 15e-3 ;
    end

%% Rebuild cell in comsolModel by moving selection region

%    Get Model Start and End positions

    varnames = comsolModel.param.varnames ;
    goodModelStart = false ; goodModelEnd = false ;
    for i = 1:length(varnames)
        if strfind(char(varnames(i)),'vaneModelStart')
            goodModelStart = true ;
        elseif strfind(char(varnames(i)),'vaneModelEnd')
            goodModelEnd = true ;
        end
    end
    
    if nargin < 10 || isempty(vaneModelStartPos)
        if goodModelStart
            vaneModelStartStr = char(comsolModel.param.get('vaneModelStart')) ;
            metrepos = strfind(vaneModelStartStr,'[m]') ;
            vaneModelStart = str2num(vaneModelStartStr(1:metrepos-1)) ;
        else
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:setModelBoundBox:startException';
            message.text = 'Model does not contain bounding box start information: using default value';
            message.priorityLevel = 8;
            message.errorLevel = 'warning';
            parameters = logMessage(message, parameters) ;
            vaneModelStart = cadOffset ;
        end
    else
        vaneModelStart = vaneModelStartPos ;
    end
    
    if nargin < 11 || isempty(vaneModelEndPos)
        if goodModelEnd
            vaneModelEndStr = char(comsolModel.param.get('vaneModelEnd')) ;
            metrepos = strfind(vaneModelEndStr,'[m]') ;
            vaneModelEnd = str2num(vaneModelEndStr(1:metrepos-1)) ;
            clear metrepos ;
        else
            message = struct;
            message.identifier = 'ModelRFQ:ComsolInterface:buildCell:setModelBoundBox:endException';
            message.text = 'Model does not contain bounding box end information: using default value';
            message.priorityLevel = 8;
            message.errorLevel = 'warning';
            parameters = logMessage(message, parameters) ;
            vaneModelEnd = lengthData(end) + cadOffset ;
        end
    else
        vaneModelEnd = vaneModelEndPos ;
    end

    reshapedLengthData = reshape(lengthData,[],1) ;
    totalCells = [0; cumsum(reshapedLengthData)] ;
    totalCells = totalCells + cadOffset ;

    if vaneModelEnd < totalCells(end)
        vaneModelEnd = totalCells(end) ;
    end
    if vaneModelStart > totalCells(1)
        vaneModelStart = totalCells(1) ;
    end

%    Set cell parameters

    try % to set cell parameters
        message = struct ;
        message.identifier = 'ModelRFQ:ComsolInterface:buildCell:getCellParameters:run';
        message.text = '       - Adjusting cell parameters...';
        message.priorityLevel = 8;
        message.errorLevel = 'information';
        parameters = logMessage(message, parameters) ;
        clear message;
        [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] = ...
            getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells, ...
            vaneModelStart, vaneModelEnd, boxWidthMod) ;
        comsolModel.param.set('cellNo', num2str(cellNo,12));
        comsolModel.param.set('boxWidth', [num2str(boxWidth,12) '[m]']);
        comsolModel.param.set('cellStart', [num2str(cellStart,12) '[m]']);
        comsolModel.param.set('cellEnd', [num2str(cellEnd,12) '[m]']);
        comsolModel.param.set('selectionStart', [num2str(selectionStart,12) '[m]']);
        comsolModel.param.set('selectionEnd', [num2str(selectionEnd,12) '[m]']);
%        comsolModel.param.set('vaneVoltage', [num2str(vaneVoltage,12) '[V]']);
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:parameterException';
        errorMessage.text = 'Could not set parameters.';
        errorMessage.priorityLevel = 3;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        parameters = logMessage(errorMessage, parameters) ;
    end

%    Rebuild geometry

    try % to rebuild geometry
        message = struct ;
        message.identifier = 'ModelRFQ:ComsolInterface:buildCell:rebuildGeometry:run';
        message.text = '       - Rebuilding geometry...';
        message.priorityLevel = 8;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;
        comsolModel.geom('geom1').runAll;
        comsolModel.geom('geom1').run;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:geometryException';
        errorMessage.text = 'Could not rebuild geometry.';
        errorMessage.priorityLevel = 3;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end

%    Set new selections

    try % to adjust selections
        message = struct ;
        message.identifier = 'ModelRFQ:ComsolInterface:buildCell:setSelections:run';
        message.text = '       - Adjusting selections...';
        message.priorityLevel = 8;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;
        comsolModel = setSelections(comsolModel, selectionNames, endFlangeThickness, parameters) ;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:setUpSelectionRegion:selectionException';
        errorMessage.text = 'Could not set selections.';
        errorMessage.priorityLevel = 3;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end

%    Mesh cell

    try %to mesh cell
        message = struct ;
        message.identifier = 'ModelRFQ:ComsolInterface:buildCell:meshCell:run';
        message.text = '       - Rebuilding mesh...';
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;                
        comsolModel = meshCell(comsolModel, cellNo, nBeamBoxCells, parameters) ;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:buildCell:meshModel:runException';
        errorMessage.text = 'Could not rebuild mesh.';
        errorMessage.priorityLevel = 3;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end

    outputParameters = parameters ;
        
    return
