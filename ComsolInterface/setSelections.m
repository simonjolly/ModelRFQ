function comsolModel = setSelections(comsolModel, selectionNames, cellNo, nCells, isCrossingMatchingSection, boxWidth, verticalCellHeight, selectionStart, selectionEnd)
%
% function comsolModel = setSelections(comsolModel, selectionNames, cellNo, ...
%                                      nCells, isCrossingMatchingSection, ...
%                                      boxWidth, verticalCellHeight, ...
%                                      selectionStart, selectionEnd)
%
% setSelections searches for the correct domain number for the air bag in
% the Comsol model and defines all the rest of the selections from knowing
% this value. It assumes the geometry is not significantly different to the
% FETS model.
%
% Credit for the majority of the modelling code must go to Simon Jolly of
% Imperial College London.
%
% See also buildCell, buildComsolModel, modelRfq, getModelParameters,
% logMessage.

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
        if nargin < 9 %then throw error ModelRFQ:ComsolInterface:setSelections:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = setSelections(comsolModel, selectionNames, cellNo, nCells, isCrossingMatchingSection, boxWidth, verticalCellHeight, selectionStart, selectionEnd)');
        end
        if nargin > 9 %then throw error ModelRFQ:ComsolInterface:setSelections:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = setSelections(comsolModel, selectionNames, cellNo, nCells, isCrossingMatchingSection, boxWidth, verticalCellHeight, selectionStart, selectionEnd)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:setSelections:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = setSelections(comsolModel, selectionNames, cellNo, nCells, isCrossingMatchingSection, boxWidth, verticalCellHeight, selectionStart, selectionEnd)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:setSelections:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:setSelections:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = setSelections(comsolModel, selectionNames, cellNo, nCells, isCrossingMatchingSection, boxWidth, verticalCellHeight, selectionStart, selectionEnd)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:setSelections:syntaxException';
        message.text = 'Syntax error calling buildCell';
        message.priorityLevel = 5;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Find domsin numbers 

    try %to find airbag domain number 
        try %attempt 1 
            airbagDomainNo = mphselectcoords(comsolModel,'geom1',[boxWidth, boxWidth, selectionStart],'domain');
            if ~(airbagDomainNo == 6 || airbagDomainNo == 7 || airbagDomainNo == 8) %then try again 
                error('ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:firstException', ...
                      'Invalid airbag domain number.');
            end
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:firstException';
            errorMessage.text = 'First attempt to find domains failed. Attempting to continue...';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage); 
            try %attempt 2 
                airbagDomainNo = mphselectcoords(comsolModel,'geom1',[boxWidth, boxWidth, selectionEnd],'domain');
                if ~(airbagDomainNo == 6 || airbagDomainNo == 7 || airbagDomainNo == 8) %then try again 
                    error('ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:secondException', ...
                          'Invalid airbag domain number.');
                end
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:secondException';
                errorMessage.text = 'Second attempt to find domains failed. Attempting to continue...';
                errorMessage.priorityLevel = 8;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage); 
                try %attempt 3 
                    airbagDomainNo = mphselectcoords(comsolModel,'geom1',[verticalCellHeight, verticalCellHeight, selectionStart],'domain');
                    if ~(airbagDomainNo == 6 || airbagDomainNo == 7 || airbagDomainNo == 8) %then try again 
                        error('ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:thirdException', ...
                              'Invalid airbag domain number.');
                    end
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:thirdException';
                    errorMessage.text = 'Third attempt to find domains failed. Attempting to continue...';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage); 
                    try %attempt 4 
                        airbagDomainNo = mphselectcoords(comsolModel,'geom1',[verticalCellHeight, verticalCellHeight, selectionEnd],'domain');
                        if ~(airbagDomainNo == 6 || airbagDomainNo == 7 || airbagDomainNo == 8) %then give up 
                            error('ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:fourthException', ...
                                  'Invalid airbag domain number.');
                        end
                    catch exception
                        errorMessage = struct;
                        errorMessage.identifier = 'ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:fourthException';
                        errorMessage.text = 'Final attempt to find domains failed.';
                        errorMessage.priorityLevel = 8;
                        errorMessage.errorLevel = 'warning';
                        errorMessage.exception = exception;
                        logMessage(errorMessage);
                        rethrow(exception);
                    end                                
                end                            
            end                        
        end                    
    catch exception
        if cellNo >= 200 && cellNo < nCells %then change domain numbering 
            airbagDomainNo = 8 ;
        elseif isCrossingMatchingSection
            airbagDomainNo = 6 ;
        else
            airbagDomainNo = 7 ;
        end
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:setSelections:findAirbagDomainNo:failed';
        errorMessage.text = ['Unable to determine correct domain numbers. Reverting to airbagDomainNo = ' num2str(airbagDomainNo)];
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);                    
    end  
    switch airbagDomainNo %define other domains 
        case 6 
            yVaneTipDomainNo = 5; yVaneBackDomainNo = 7;
            xVaneTipDomainNo = 8; xVaneBackDomainNo = 9;
        case 7 
            yVaneTipDomainNo = 5; yVaneBackDomainNo = 6;
            xVaneTipDomainNo = 8; xVaneBackDomainNo = 9;
        case 8 
            yVaneTipDomainNo = 5; yVaneBackDomainNo = 6;
            xVaneTipDomainNo = 7; xVaneBackDomainNo = 9;
        otherwise %default to FETS values 
            if cellNo >= 200 && cellNo < nCells %then change domain numbering 
                yVaneTipDomainNo = 5; yVaneBackDomainNo = 6;
                xVaneTipDomainNo = 7; xVaneBackDomainNo = 9;
                airbagDomainNo = 8;
            elseif isCrossingMatchingSection
                yVaneTipDomainNo = 5; yVaneBackDomainNo = 7;
                xVaneTipDomainNo = 8; xVaneBackDomainNo = 9;
                airbagDomainNo = 6;
            else
                yVaneTipDomainNo = 5; yVaneBackDomainNo = 6;
                xVaneTipDomainNo = 8; xVaneBackDomainNo = 9;
                airbagDomainNo = 7;
            end
    end
    
%% Set selections 

    comsolModel.selection(selectionNames.allVanes).set([yVaneTipDomainNo yVaneBackDomainNo xVaneTipDomainNo xVaneBackDomainNo]);
    comsolModel.selection(selectionNames.horizontalVanes).set([xVaneTipDomainNo xVaneBackDomainNo]);
    comsolModel.selection(selectionNames.verticalVanes).set([yVaneTipDomainNo yVaneBackDomainNo]);
    comsolModel.selection(selectionNames.allTerminals).set([yVaneTipDomainNo yVaneBackDomainNo xVaneTipDomainNo xVaneBackDomainNo]);
    comsolModel.selection(selectionNames.horizontalTerminals).set([xVaneTipDomainNo xVaneBackDomainNo]);
    comsolModel.selection(selectionNames.verticalTerminals).set([yVaneTipDomainNo yVaneBackDomainNo]);
    comsolModel.selection(selectionNames.airVolumes).set([1 2 3 4 airbagDomainNo]);
    comsolModel.selection(selectionNames.airBag).set(airbagDomainNo);
    comsolModel.selection(selectionNames.airBagBoundaries).set(airbagDomainNo);
    
return