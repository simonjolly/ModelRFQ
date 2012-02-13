function fieldMap = getFieldMap(comsolModel, coordinates)
% 
% function fieldMap = getFieldMap(comsolModel, coordinates, dispmes)
%
%   getFieldMap - Extract the E-field from a Comsol model at given coordinates
%
%   Uses/Loads the Comsol model specified by comsolModel and extracts the
%   electrostatic field at the coordinates specified by coordinates.
%
%   Returns a fieldMap with X, Y, Z from coordinates, Ex, Ey, Ez from
%   Comsol and Bx = By = Bz = 0
%
%   To create the coordinates array, use the meshgrid command and convert
%   to a 3-dimensional array.
%       e.g. [x,y,z] = meshgrid([-0.005:0.0005:0.005],[-0.005:0.0005:0.005],[0.00015:0.0005:0.02165]);
%            coordinates = [x(:),y(:),z(:)];
%
%   See also: buildComsolModel, modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton.  
%
% File history
%
%   28-Jul-2010 M. J. Easton
%       Field map interpolation of Comsol E-fields
%
%   03-Aug-2010 S. Jolly
%       Added input variable parsing and more efficient creation of
%       'fieldMap' variable.
%
%   22-Nov-2010 M. J. Easton
%       Allowed passing of model or filename
%
%   18-Jan-2011 M. J. Easton
%       Adapted to include in ModelRFQ distribution.
%
%======================================================================

%% Check syntax 

    shouldSkipLoad = false;
    if nargin < 2 %then throw error ModelRFQ:ComsolInterface:getFieldMap:insufficientInputArguments 
        error('ModelRFQ:ComsolInterface:getFieldMap:insufficientInputArguments', ...
              'Too few input variables: syntax is fieldMap = getFieldMap(comsolModel, coordinates)');
    end
    if nargin > 2 %then throw error ModelRFQ:ComsolInterface:getFieldMap:excessiveInputArguments 
        error('ModelRFQ:ComsolInterface:getFieldMap:excessiveInputArguments', ...
              'Too many input variables: syntax is fieldMap = getFieldMap(comsolModel, coordinates)');
    end
    if nargout > 1 %then throw error ModelRFQ:ComsolInterface:getFieldMap:excessiveOutputArguments 
        error('ModelRFQ:ComsolInterface:getFieldMap:excessiveOutputArguments', ...
              'Too many output variables: syntax is fieldMap = getFieldMap(comsolModel, coordinates)');
    end
    if ~ischar(comsolModel) %then it's not a file name, so don't load it 
        shouldSkipLoad = true;
    elseif exist(comsolModel,'file') ~= 2 %then throw error ModelRFQ:ComsolInterface:getFieldMap:fileNotFound 
        error('ModelRFQ:ComsolInterface:getFieldMap:fileNotFound', ...
             ['Input file ' comsolModel ' cannot be found']);
    elseif ~strcmpi( comsolModel(end-2:end),'mph') %then throw error ModelRFQ:ComsolInterface:getFieldMap:invalidFile 
        error('ModelRFQ:ComsolInterface:getFieldMap:invalidFile', ...
             ['Input file ' comsolModel ' is not a Comsol model file']);
    end
    coordinatesSize = size(coordinates);
    nCoordinateDimensions = ndims(coordinates);
    [goodCoordinates, isGoodCoordinate] = find(coordinatesSize == 3);
    if nCoordinateDimensions ~= 2 %then throw error ModelRFQ:ComsolInterface:getFieldMap:invalidDimensions  
        error('ModelRFQ:ComsolInterface:getFieldMap:invalidDimensions', ...
              '[coordinates] must be an [N x 3] array of [x,y,z] data');
    elseif sum(goodCoordinates) < 1 %then throw error ModelRFQ:ComsolInterface:getFieldMap:invalidCoordinates  
        error('ModelRFQ:ComsolInterface:getFieldMap:invalidCoordinates', ...
              '[coordinates] must be an [N x 3] array of [x,y,z] data');
    end
    fieldMapLength = coordinatesSize;
    fieldMapLength(isGoodCoordinate) = [];

%% Load model 

    if ~shouldSkipLoad
        import com.comsol.model.*
        import com.comsol.model.util.*        
        model = ModelUtil.load('Model', comsolModel) ;
    else
        model = comsolModel;
    end %if

%% Interpolate field 

    fieldMap = zeros(fieldMapLength,9);
    fieldMap(:,1:3) = coordinates;
    [fieldMap(:,4),fieldMap(:,5),fieldMap(:,6)] = mphinterp(model, {'es.Ex','es.Ey','es.Ez'}, 'coord', coordinates.');

return