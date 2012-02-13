function [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, isAcrossMatchingSectionBoundary] ...
          = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells)
%
% function [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, isAcrossMatchingSectionBoundary] 
%           = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells)
%
%    getCellParameters.m - Output start and end cell locations
%
%    Based on rfqcellparams code written by Simon Jolly.
%
%    [cellStart, cellEnd] = getCellParameters(lengthData, cellNo)
%    [...] = getCellParameters(lengthData, cellNo, cadOffset)
%    [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight)
%    [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho)
%    [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells)
%    [cellStart, cellEnd, selectionStart, selectionEnd] = getCellParameters(...)
%    [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] = getCellParameters(...)
%    [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, isAcrossMatchingSectionBoundary] = getCellParameters(...)
%
%    getCellParameters outputs RFQ cell data based on a list of cell lengths
%    and a chosen number of cells.  This is mainly used to select
%    particular cells for the Comsol RFQ vane tip model.
%
%    [cellStart, cellEnd] = getCellParameters(lengthData, cellNo) - output the
%    z-positions of the start and end of a cell, or series of cells, to the
%    variables cellStart and cellEnd.  The lengths of each cell are given
%    by lengthData: as such, length(lengthData) must equal the number of cells in the
%    RFQ; lengthData must be an [N x 1] array of cell length values.  It is
%    assumed that the first cell in the list is the matching section, and
%    that the start of the matching section is at Z = 0.  The cell or cells
%    to be selected is given by cellNo: this can either be a single
%    integer value or a series of values of a number of consecutive cells
%    are desired.  Only the lowest and highest values in CELLNUM are taken:
%    all other values are superfluous.  As such, the following arrays are
%    equivalent:
%
%        cellNo = [2 12] ;
%        cellNo = [2:12] ;
%        cellNo = [2 3 4 5 6 7 8 9 10 11 12] ;
%        cellNo = [2 4 7 12] ;
%        cellNo = [2 12 6 9 3] ;
%
%    ...as they all give cellStart and cellEnd values for cells 2 to 12.
%    cellStart corresponds to the start of the lowest cell, and cellEnd to
%    the end of the highest cell.
%
%    lengthData must be given in metres.
%
%    [...] = getCellParameters(lengthData, cellNo, cadOffset) - also
%    specifies the Z-offset of the start of the CAD model.  cadOffset must
%    be given in metres.  cadOffset is used primarily because the CAD
%    models usually have the origin at the end of the matching section, not
%    the start, so any coordinate selection must be shifted accordingly.
%
%    [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight) - also
%    provides the transverse distance from the beam axis to the back of the
%    vane tip sections, referred to as the verticalCellHeight.  verticalCellHeight is given in
%    metres: the default value is verticalCellHeight = 15e-3 (15 mm).
%
%    [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho) - also
%    specify the mean radius of the vane tips.  This is necessary only if
%    cellNo includes the first or second cells ie. selects part of the
%    matching section.  This is because the transverse distance of the CAD
%    model at the matching section is larger than the main vane sections as
%    the matching section is a quarter circle.  The default value is
%    RHO = 3.1076e-3 (3.1076 mm) and must be given in metres.
%
%    [cellStart, cellEnd, selectionStart, selectionEnd] = getCellParameters(...) - outputs
%    the start and end of the selection region to the variables selectionStart
%    and selectionEnd.  The selection region is one cell longer at either end
%    than the selected number of cells.  For example, if cellNo = [2 5],
%    cellStart is the start of cell 2, cellEnd is the end of cell 5,
%    selectionStart is the start of cell 1 and selectionEnd is the end of cell 6.
%
%    [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells)
%    - specify the number of extra cells either side of those specified in
%    cellNo to be included in the selection region.  The defualt value is
%    nExtraCells = 1 ;
%
%    [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth] = getCellParameters(...)
%    - also output the transverse width of the selection box surrounding
%    the vane section to boxWidth.  This provides the transverse dimensions
%    (in X and Y) of the selection region surrounding the vanes in the
%    Comsol geometry: if the selection region includes the matching
%    section, boxWidth = lengthData(1) + rho; otherwise, boxWidth = verticalCellHeight.
%
%    [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, isAcrossMatchingSectionBoundary] = getCellParameters(...)
%    - outputs a binary value to isAcrossMatchingSectionBoundary.  If the selection region
%    crosses the border between the matching section and the start of the
%    main RFQ vane sections, isAcrossMatchingSectionBoundary = true; 
%    otherwise isAcrossMatchingSectionBoundary = false.
%
%   See also buildComsolModel, modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Simon Jolly.
%
% File history
%
%   23-Aug-2010 S. Jolly
%       Output of RFQ parameters based on cell numbers
%
%   18-Jan-2011 M. J. Easton
%       Adapted to include in ModelRFQ distribution.
%       All functional code unchanged.
%
%======================================================================

%% Check syntax 

    if nargin < 2 %then throw error ModelRFQ:ComsolInterface:getCellParameters:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:getCellParameters:insufficientInputArguments', ...
              'Too few input variables: syntax is [cellStart, cellEnd] = getCellParameters(lengthData, cellNo)');
    end
    if nargin > 6 %then throw error ModelRFQ:ComsolInterface:getCellParameters:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:getCellParameters:excessiveInputArguments', ...
              'Too many input variables: syntax is [...] = getCellParameters(lengthData, cellNo, cadOffset, verticalCellHeight, rho, nExtraCells)');
    end
    if nargout < 2 %then throw error ModelRFQ:ComsolInterface:getCellParameters:insufficientOutputArguments 
        error('ModelRFQ:ComsolInterface:getCellParameters:insufficientOutputArguments', ...
              'Too few output variables: syntax is [cellStart, cellEnd] = getCellParameters(lengthData, cellNo)');
    end
    if nargout > 6 %then throw error ModelRFQ:ComsolInterface:getCellParameters:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:getCellParameters:excessiveOutputArguments', ...
              'Too many output variables: syntax is [cellStart, cellEnd, selectionStart, selectionEnd, boxWidth, isAcrossMatchingSectionBoundary] = getCellParameters(...)');
    end

%% Default values 
    
    if nargin < 6 || isempty(nExtraCells)
        nExtraCells = 1 ;
    else
        nExtraCells = round(nExtraCells) ;
    end
    if nargin < 5 || isempty(rho)
        rho = 3.1076e-3 ;
    end
    if nargin < 4 || isempty(verticalCellHeight)
        verticalCellHeight = 15e-3 ;
    end
    if nargin < 3 || isempty(cadOffset)
        cadOffset = 0 ;
    end

%% Find start and end cell positions 

    firstCell = min(round(cellNo)) ;
    lastCell = max(round(cellNo)) ;

    reshapedLengthData = reshape(lengthData,[],1) ;

    totalCells = [0; cumsum(reshapedLengthData)] ;
    totalCells = totalCells + cadOffset ;

    if firstCell < 1
        error('ModelRFQ:ComsolInterface:getCellParameters:incorrectFirstCell', ...
              'Minimum cell number must be 1 or greater');
    elseif lastCell > length(lengthData)
        error('ModelRFQ:ComsolInterface:getCellParameters:incorrectLastCell', ...
              'Maxmimum cell number cannot be greater than the number of RFQ cells');
    else
        cellStart = totalCells(firstCell) ;
        cellEnd = totalCells(lastCell + 1) ;
    end

%% Find selection box boundaries 

    firstSelectionCell = firstCell - nExtraCells;
    lastSelectionCell = lastCell + nExtraCells;

    if firstSelectionCell <= 1
        boxWidth = lengthData(1) + rho;
    else
        boxWidth = verticalCellHeight;
    end

    if firstSelectionCell <= 1 && lastSelectionCell >= 2
        isAcrossMatchingSectionBoundary = 1 ;
    else
        isAcrossMatchingSectionBoundary = 0 ;
    end

    if firstSelectionCell < 1
        selectionStart = totalCells(1) - lengthData(1) ;
    else
        selectionStart = totalCells(firstSelectionCell) ;
    end

    if lastSelectionCell > length(lengthData)
        selectionEnd = totalCells(end) + lengthData(end) ;
    else
        selectionEnd = totalCells(lastSelectionCell + 1) ;
    end

    if isAcrossMatchingSectionBoundary
        selectionStart = selectionStart - lengthData(1)./10 ;
    end
    
    if firstSelectionCell < 1
        selectionStart = totalCells(1) - 7e-3;
    end

return