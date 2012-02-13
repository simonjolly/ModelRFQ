function vaneObjectNames = findVaneObjects(comsolModel, geometryName, featureName, endObjectName)
%
% function vaneObjectNames = findVaneObjects(comsolModel, geometryName, featureName, endObjectName)
%
%   findVaneObjects looks at the given Comsol model geometry feature, and 
%   finds all of the objects in the same vane as the given end object.
%   Use findVaneEnds to find the endObjectName.
%
%   See also findVaneEnd, setupComsolModel, buildComsolModel, modelRfq.


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
        if nargin < 4 %then throw error ModelRFQ:ComsolInterface:findVaneObjects:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:findVaneObjects:insufficientInputArguments', ...
                  'Too few input variables: syntax is vaneObjectNames = findVaneObjects(comsolModel, geometryName, featureName, endObjectName)');
        end
        if nargin > 4 %then throw error ModelRFQ:ComsolInterface:findVaneObjects:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:findVaneObjects:excessiveInputArguments', ...
                  'Too many input variables: syntax is vaneObjectNames = findVaneObjects(comsolModel, geometryName, featureName, endObjectName)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:findVaneObjects:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:findVaneObjects:insufficientOutputArguments', ...
                  'Too few output variables: syntax is vaneObjectNames = findVaneObjects(comsolModel, geometryName, featureName, endObjectName)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:findVaneObjects:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:findVaneObjects:excessiveOutputArguments', ...
                  'Too many output variables: syntax is vaneObjectNames = findVaneObjects(comsolModel, geometryName, featureName, endObjectName)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:findVaneObjects:syntaxException';
        message.text = 'Syntax error calling findVaneObjects';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Find objects 

    objectNameList = comsolModel.geom(geometryName).feature(featureName).objectNames;
    vaneObjectNames = {char(endObjectName)};
    currentObjectName = endObjectName;
    nextObjectName = endObjectName;
    lastObjectName = '';    
    
    while ~strcmpi(nextObjectName, '') %continue until there are no more adjacent objects 
        nextObjectName = '';
        currentObjectVertices = comsolModel.geom(geometryName).feature(featureName).object(currentObjectName).getVertexCoord;
        for i = 1:length(objectNameList) %find adjacent object by checking coordinates 
            loopObjectName = objectNameList(i);
            if ~strcmpi(loopObjectName, currentObjectName) && ~strcmpi(loopObjectName, lastObjectName) %exclude current and last object           
                loopObjectVertices = comsolModel.geom(geometryName).feature(featureName).object(loopObjectName).getVertexCoord;
                for j = 1:size(currentObjectVertices, 2) %loop through all vertices on current object 
                    for k = 1:size(loopObjectVertices, 2) %compare with vertices on loop object 
                        if min(round(loopObjectVertices(:,k)*1e4)/1e4 == round(currentObjectVertices(:,j)*1e4)/1e4) > 0 %then this object is adjacent to the current object
                            nextObjectName = loopObjectName;
                        end
                    end
                end
            end
        end
        lastObjectName = currentObjectName;
        currentObjectName = nextObjectName;
        if ~strcmpi(nextObjectName, '') %then save object name to list
            vaneObjectNames{length(vaneObjectNames)+1} = char(currentObjectName);
        end
    end
    
%% Clean up 

    clear objectNameList currentObjectName nextObjectName lastObjectName loopObjectName currentObjectVertices loopObjectVertices i j k;
    
return