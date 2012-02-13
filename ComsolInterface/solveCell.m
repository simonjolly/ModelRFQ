function [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, isStartFinishCell, xGridVals, yGridVals, zGridSteps)
% function [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, isStartFinishCell, xGridVals, yGridVals, zGridSteps)
%
%   SOLVECELL.M - Solve electrostatic RFQ cell Comsol Model
%
%   solveCell(comsolModel)
%   [comsolModel] = solveCell(comsolModel)
%   [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, cellNo)
%   [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, isStartFinishCell)
%   [...] = solveCell(comsolModel, cadOffset, isStartFinishCell, xGridVals, yGridVals, zGridSteps)
%
%   solveCell solves a section of the RFQ vane tip model in Comsol.  The
%   model must already have been created using 'createModel' or
%   'setupModel' and an individual cell selected with 'buildCell'.
%   solveCell calls setupSolver in order to set up the electrostatic
%   solver.
%
%   solveCell(comsolModel) - solve electrostatic field for single RFQ cell
%   in model COMSOLMODEL.
%
%   [comsolModel] = solveCell(comsolModel) - output solved model as
%   modified comsol model COMSOLMODEL.
%
%   [comsolModel, fieldmap] = solveCell(comsolModel) - output field map of
%   solved field region to FIELDMAP.  This assumes that the CAD model
%   starts at Z=0.
%
%   [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset) - also
%   specify the offset of the start of the CAD model from zero in metres
%   using CADOFFSET.  While the default value is cadOffset = 0, normally
%   z=0 for the CAD model is at the END of the matching section, not the
%   start, so (for the FETS RFQ) cadOffset = 21.77mm.
%
%   [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, isStartFinishCell)
%   - also specify whether the current cell is the first or last cell with
%   ISSTARTFINISHCELL.  Setting isStartFinishCell = -1 specifies the first
%   cell (matching section) and increases the field map density by a factor
%   of 4 due to the extra length of the matching section; setting
%   isStartFinishCell = 1 specifies the last cell and adds a single extra
%   Z-position to the field map.  The default value is isStartFinishCell =
%   0, which specifies all the remaining RFQ cells.
%
%   [...] = solveCell(comsolModel, cadOffset, isStartFinishCell, xGridVals, yGridVals, zGridSteps)
%   - specify the grid point locations to read out the field map data.  The
%   default values are:
%       xGridVals = [0:0.0005:0.005] - X-positions (0-5mm in 0.5mm steps)
%       yGridVals = [0:0.0005:0.005] - Y-positions (0-5mm in 0.5mm steps)
%       zGridSteps = 16 - number of Z-positions (16 longitudinal steps per cell)
%   For a 4-quadrant RFQ model, the default values are:
%       xGridVals = [-0.005:0.0005:0.005] - X-positions (0-5mm in 0.5mm steps)
%       yGridVals = [-0.005:0.0005:0.005] - Y-positions (0-5mm in 0.5mm steps)
%       zGridSteps = 16 - number of Z-positions (16 longitudinal steps per cell)
%
%   See also buildComsolModel, modelRfq, getModelParameters, setupModel,
%   createModel, buildCell, setupSolver.

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
%       Split off solveCell from buildCell.  Added conditional calculation
%       of fieldmap depending on output variables.
%
%=======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:solveCell:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:solveCell:insufficientInputArguments', ...
              ['Too few input variables: syntax is [comsolModel] = solveCell(comsolModel)']) ;
    end
%    if nargout > 1 && nargin < 2 %then throw error ModelRFQ:ComsolInterface:solveCell:insufficientInputArguments 
%        error('ModelRFQ:ComsolInterface:solveCell:insufficientInputArguments', ...
%              ['Too few input variables: syntax is [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset)']) ;
%    end
    if nargin > 6 %then throw error ModelRFQ:ComsolInterface:solveCell:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:solveCell:excessiveInputArguments', ...
              ['Too many input variables: syntax is [comsolModel, fieldmap] = solveCell(comsolModel, ' ...
              'cadOffset, isStartFinishCell, xGridVals, yGridVals, zGridSteps)']) ;
    end
%    if nargout < 1 %then throw error ModelRFQ:ComsolInterface:solveCell:insufficientOutputArguments 
%        error('ModelRFQ:ComsolInterface:solveCell:insufficientOutputArguments', ...
%              ['Too few output variables: syntax is [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, isStartFinishCell)']);
%    end
    if nargout > 2 %then throw error ModelRFQ:ComsolInterface:solveCell:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:solveCell:excessiveOutputArguments', ...
              ['Too many output variables: syntax is [comsolModel, fieldmap] = solveCell(comsolModel, cadOffset, isStartFinishCell)']) ;
    end

    fourQuad = false ;
    modelBoundBox = comsolModel.geom('geom1').getBoundingBox ;
    minX = modelBoundBox(1) ;
    maxX = modelBoundBox(2) ;
    minY = modelBoundBox(3) ;
    maxY = modelBoundBox(4) ;
    if ( abs(minX) > ( maxX./2) ) && ( abs(minY) > ( maxY./2) )
        fourQuad = true ;
    end

    if nargin < 6 || isempty(zGridSteps)
        zGridSteps = 16 ;
    end
    if nargin < 5 || isempty(yGridVals)
        if fourQuad
            yGridVals = [-0.005:0.0005:0.005] ;
        else
            yGridVals = [0:0.0005:0.005] ;
        end
    end
    if nargin < 4 || isempty(xGridVals)
        if fourQuad
            xGridVals = [-0.005:0.0005:0.005] ;
        else
            xGridVals = [0:0.0005:0.005] ;
        end
    end
    if nargin < 3 || isempty(isStartFinishCell)
        isStartFinishCell = 0 ;
    end
    if nargin < 2 || isempty(cadOffset)
        cadOffset = 0 ;
    end

%% Solve Model

    comsolModel.sol('sol1').feature.remove('s1') ;
    comsolModel.sol('sol1').feature.remove('v1') ;
    comsolModel.sol('sol1').feature.remove('st1') ;

    comsolModel = setupSolver(comsolModel) ;

    comsolModel.sol('sol1').runAll ;

%    comsolModel.result('pg2').run ;

%% Output field map

    if nargout > 1

        cellStartStr = comsolModel.param.get('cellStart') ;
        metrepos = strfind(cellStartStr,'[m]') ;
        cellStart = str2num(cellStartStr(1:metrepos-1)) ;
        clear metrepos ;

        cellEndStr = comsolModel.param.get('cellEnd') ;
        metrepos = strfind(cellEndStr,'[m]') ;
        cellEnd = str2num(cellEndStr(1:metrepos-1)) ;
        clear metrepos ;

        cellLength = cellEnd - cellStart ;

        if isStartFinishCell >= 1 %then define start and end values accordingly
            [y,x,z] = meshgrid(yGridVals,xGridVals,cellStart:cellLength/zGridSteps:cellEnd) ;
        elseif isStartFinishCell <= -1
            [y,x,z] = meshgrid(yGridVals,xGridVals,cellStart:cellLength/(4.*zGridSteps):(cellEnd-cellLength/(4.*zGridSteps))) ;
        else
            [y,x,z] = meshgrid(yGridVals,xGridVals,cellStart:cellLength/zGridSteps:(cellEnd-cellLength/zGridSteps)) ;
        end
        
        coordinates = [x(:),y(:),z(:)] ;
        fieldmap = getFieldMap(comsolModel, coordinates) ;
        fieldmap(:,3) = fieldmap(:,3) - cadOffset ;

    end

    clear x y z coordinates ;

    return
