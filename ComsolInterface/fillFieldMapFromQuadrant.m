function fieldMap = fillFieldMapFromQuadrant(fieldMap)
% 
% function fieldMap = fillFieldMapFromQuadrant(fieldMap)
%
%   fillFieldMapFromQuadrant - Convert a quadrant into a full fieldMap
%
%   Takes the fieldMap section and mirrors in x and y to produce a full map.
%   Also removes non-physical on-axis transverse fields.
%
%   Expects and returns a 9D fieldMap (x, y, z, Ex, Ey, Ez, Bx, By, Bz)
%
%   See also buildComsolModel, modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton.  
%
% File history
%
%   29-Nov-2010 M. J. Easton
%       File created
%
%   18-Jan-2011 M. J. Easton
%       Adapted to include in ModelRFQ distribution.
%
%======================================================================

%% Check syntax 

    if nargin < 1 %then throw error ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:insufficientInputArguments', ...
              'Too few input variables: syntax is fieldMap = fillFieldMapFromQuadrant(fieldMap)');
    end
    if nargin > 1 %then throw error ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:excessiveInputArguments', ...
              'Too many input variables: syntax is fieldMap = fillFieldMapFromQuadrant(fieldMap)');
    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:excessiveOutputArguments', ...
              'Too many output variables: syntax is fieldMap = fillFieldMapFromQuadrant(fieldMap)');
    end
    if size(fieldMap,2) ~= 9 %then throw error ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:invalidFieldMap 
        error('ModelRFQ:ComsolInterface:fillFieldMapFromQuadrant:invalidFieldMap', ...
              'Fieldmap must be in the form (x, y, z, Ex, Ey, Ez, Bx, By, Bz)');
    end
    
%% Zero on axis 
%  Using a quadrant model can leave non-zero transverse fields on the axis
%  that are non-physical. We remove them here.

    axis = fieldMap(:,1) == 0 & fieldMap(:,2) == 0;
    fieldMap(axis,4) = 0;
    fieldMap(axis,5) = 0;
    
%% Mirror in X 

    include = fieldMap(:,1) ~= 0;       % don't include points along the x-axis
    temp = fieldMap(include,:);
    temp(:,1) = -temp(:,1);             % mirror x
    temp(:,4) = -temp(:,4);             % mirror Ex
    temp(:,7) = -temp(:,7);             % mirror Bx
    fieldMap = cat(1,fieldMap, temp);   % concatenate fieldMap and its mirror together

%% Mirror in Y 

    include = fieldMap(:,2) ~= 0;       % don't include points along the y-axis
    temp = fieldMap(include,:);
    temp(:,2) = -temp(:,2);             % mirror y
    temp(:,5) = -temp(:,5);             % mirror Ey
    temp(:,8) = -temp(:,8);             % mirror By
    fieldMap = cat(1,fieldMap, temp);   % concatenate fieldMap and its mirror together

return