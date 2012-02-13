function endObjectName = findVaneEnd(comsolModel, geometryName, featureName, point)
%
% function endObjectName = findVaneEnd(comsolModel, geometryName, featureName, point)
%
%   findVaneEnd looks at the given Comsol model geometry feature, and 
%   finds which of the objects contains the given point.
%   To find the matching section, give a point that is only found in the
%   matching section, such as 
%       [matchingSectionLength + r0, rho, matchingSectionLength - cadOffset]
%
%   See also findVaneObjects, setupComsolModel, buildComsolModel, modelRfq.


% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history
%
%   16-Feb-2011 M. J. Easton
%       Created function to find end of vane.
%       Included in ModelRFQ distribution.
%
%======================================================================

%% Check syntax 

    try %to test syntax 
        if nargin < 4 %then throw error ModelRFQ:ComsolInterface:findVaneEnd:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:findVaneEnd:insufficientInputArguments', ...
                  'Too few input variables: syntax is endObjectName = findVaneEnd(comsolModel, geometryName, featureName, point)');
        end
        if nargin > 4 %then throw error ModelRFQ:ComsolInterface:findVaneEnd:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:findVaneEnd:excessiveInputArguments', ...
                  'Too many input variables: syntax is endObjectName = findVaneEnd(comsolModel, geometryName, featureName, point)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:findVaneEnd:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:findVaneEnd:insufficientOutputArguments', ...
                  'Too few output variables: syntax is endObjectName = findVaneEnd(comsolModel, geometryName, featureName, point)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:findVaneEnd:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:findVaneEnd:excessiveOutputArguments', ...
                  'Too many output variables: syntax is endObjectName = findVaneEnd(comsolModel, geometryName, featureName, point)');
        end
        if min(size(point) == [1 3]) < 1 && min(size(point) == [3 1]) < 1 %then throw error ModelRFQ:ComsolInterface:findVaneEnd:incorrectInputPoint 
            error('ModelRFQ:ComsolInterface:findVaneEnd:incorrectInputPoint', ...
                  'Incorrect point value: point should have the form [x, y, z]');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:findVaneEnd:syntaxException';
        message.text = 'Syntax error calling findVaneEnd';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Reshape point 

    if min(size(point) == [1 3]) == 1 %then reshape the point to a column vector 
        point = reshape(point, 3, 1);
    end
    
%% Find end object 

    objectList = comsolModel.geom(geometryName).feature(featureName).objectNames;
    for i = 1:length(objectList) %check if it is the one we want 
        vertices = comsolModel.geom(geometryName).feature(featureName).object(objectList(i)).getVertexCoord;
        for j = 1:size(vertices, 2)
            if min(round(vertices(:,j)*1e4)/1e4 == round(point*1e4)/1e4) > 0 %then this object is either the matching section or the one next to it
                if min(vertices(3,:)) < point(3) %then this must be the matching section
                    endObjectName = objectList(i);
                end
            end
        end
    end
    
%% Clean up 

    clear objectList vertices i j;
    
return