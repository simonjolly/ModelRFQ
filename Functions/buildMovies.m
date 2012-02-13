function buildMovies(timeData)
%
% function buildMovies(timeData)
%
%   buildMovies creates a number of movie files from the GPT particle
%   tracking data. These movies include longitudinal motion, transverse
%   motion, phase space motion in x, y and z (Energy).
%   
%   timeData contains the particle tracking data, organised by time slices.
%
%   buildMovies also makes use of the parameters global variable, which
%   contains plot options and particle data. This is defined by
%   getModelParameters and called by modelRfq. Options on which movies to
%   make are set in getModelParameters.
%
%   See also modelRfq, getModelParameters, enhanceFigure, saveFigure,
%   plotEnergies, plotTrajectories.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution.
%
% File history
%
%   20-Dec-2010 M. J. Easton
%       Created function buildMovies as part of ModelRFQ distribution
%
%=========================================================================

%% Declarations 

    global parameters
    
%% Check syntax 

    try %to check syntax 
        if nargin > 1 %then throw error ModelRFQ:Functions:buildMovies:excessiveInputArguments 
            error('ModelRFQ:Functions:buildMovies:excessiveInputArguments', ...
                  'Can only specify 1 input argument: buildMovies(timeData)');
        end
        if nargin < 1 %then throw error ModelRFQ:Functions:buildMovies:insufficientInputArguments 
            error('ModelRFQ:Functions:buildMovies:insufficientInputArguments', ...
                  'Must specify 1 input argument: buildMovies(timeData)');
        end
        if nargout > 0 %then throw error ModelRFQ:Functions:buildMovies:excessiveOutputArguments 
            error('ModelRFQ:Functions:buildMovies:excessiveOutputArguments', ... 
                  'buildMovies does accept output arguments: buildMovies(timeData)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:buildMovies:syntaxException';
        message.text = 'Syntax error calling buildMovies: correct syntax is buildMovies(timeData)';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Setup movie figures 

    try %to setup movie figures 
        movieFigureNo = figure;
        loops = [0:parameters.plot.maxMovieSize:parameters.tracking.endSliceNo parameters.tracking.endSliceNo] ;
        maxJ = length(loops) - 1;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:buildMovies:seyupException';
        message.text = 'Cannot create environment for movie creation';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Find median particle 

    if parameters.options.shouldMakeBunchLongitudinalMovie || parameters.options.shouldMakeEnergyMovie %then find the particle
        try %to find median particle 
            endSlice = timeData(parameters.tracking.endSliceNo);
            isInBunch = endSlice.z > parameters.tracking.rfqLength;
            rightEnergies = endSlice.E(isInBunch);
            if mod(length(rightEnergies), 2) == 0 %then adjust median so it exists 
                medianEnergy = median(rightEnergies(1:length(rightEnergies)-1));
            else            
                medianEnergy = median(rightEnergies);
            end
            isMedianEnergy = endSlice.E == medianEnergy;
            medianParticleNo = endSlice.ID(isMedianEnergy);
            clear endSlice isInBunch rightEnergies medianEnergy isMedianEnergy;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:medianException';
            errorMessage.text = 'Could not fins median particle. Attempting to continue...';
            errorMessage.priorityLevel = 3;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end
    
%% Full longitudinal profile 

    if parameters.options.shouldMakeFullLongitudinalMovie %then make the movie 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startFullLongitudinal';
            if maxJ == 1 %then don't split into sections 
                message.text = ' - Building full longitudinal movie...';
            else
                message.text = ' - Building full longitudinal movies... ';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startFullLongitudinalTime';
            message.text = ['   Start time: ' currentTime()];
            movieTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startFullLongitudinalException';
            errorMessage.text = 'Could not notify start of movie';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        minZ = 0; 
        maxZ = parameters.tracking.rfqLength + 0.05;
        for j = 1:maxJ %build movies in sections 
            if maxJ > 1 %then notify start of part file 
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startFullLongitudinalSection';
                    message.text = ['    - Part ' num2str(j) '...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startFullLongitudinalSectionTime';
                    message.text = ['      Start time: ' currentTime()];
                    partTimer = tic;
                    message.priorityLevel = 7;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startFullLongitudinalSectionException';
                    errorMessage.text = 'Could not notify start of movie';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
            try %to make the movie 
                if parameters.options.shouldSaveMovies %then create movie files 
                    if maxJ == 1 %then don't split into sections 
                        currentMovieFile = avifile([parameters.files.fullLongitudinalMovie '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');                 %#ok - need avifile in the loop for multiple movie files
                    else
                        currentMovieFile = avifile([parameters.files.fullLongitudinalMovie '-' num2str(j) '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');      %#ok - need avifile in the loop for multiple movie files
                    end
                end
                for i = (loops(j) + 1):loops(j+1) %build each frame 
                    figure(movieFigureNo), hold off;
                    set(movieFigureNo,'color','white');
                    set(movieFigureNo,'Position',[50 50 1000 150]);
                    isInMovie = find(timeData(i).z >= minZ & timeData(i).z <= maxZ);
                    figure(movieFigureNo), hold on;
                    plot(timeData(i).z(isInMovie),timeData(i).y(isInMovie).*1e3,'xk');
                    xlabel('z (m)'), ylabel('y (mm)'), ...
                        title('\bf RFQ Longitudinal Beam Profile');
                    axis([minZ maxZ -5 5]);
                    enhanceFigure(movieFigureNo);
                    hold off;
                    if parameters.options.shouldSaveMovies %then add frame to movie file
                        F = getframe(movieFigureNo);
                        currentMovieFile = addframe(currentMovieFile,F);
                    elseif parameters.options.shouldPause % then pause 
                        display('Press a key to continue...');
                        pause;
                    end
                    close(movieFigureNo);
                    clear isInMovie F;
                end
                if parameters.options.shouldSaveMovies %then close movie files 
                    currentMovieFile = close(currentMovieFile);
                end
                clear i currentMovieFile;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:buildFullLongitudinalException';
                errorMessage.text = 'Could not build full longitudinal movie';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if maxJ > 1 %then notify end of part file 
                try %to notify end 
                    partTimeSeconds = toc(partTimer);
                    partTime = convertSecondsToText(partTimeSeconds);
                    text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' partTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:endFullLongitudinalSectionTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear partTimer partTimeSeconds partTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endFullLongitudinalSectionException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
        end
        clear minZ maxZ j;
        try %to notify end 
            movieTimeSeconds = toc(movieTimer);
            movieTime = convertSecondsToText(movieTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' movieTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:endFullLongitudinalTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear movieTimer movieTimeSeconds movieTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endFullLongitudinalException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end

%% Bunch longitudinal profile 

    if parameters.options.shouldMakeBunchLongitudinalMovie %then make the movie 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startBunchLongitudinal';
            if maxJ == 1 %then don't split into sections 
                message.text = ' - Building bunch longitudinal movie...';
            else
                message.text = ' - Building bunch longitudinal movies... ';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startBunchLongitudinalTime';
            message.text = ['   Start time: ' currentTime()];
            movieTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startBunchLongitudinalException';
            errorMessage.text = 'Could not notify start of movie';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end        
        for j = 1:maxJ %build movies in sections 
            if maxJ > 1 %then notify start of part file 
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startBunchLongitudinalSection';
                    message.text = ['    - Part ' num2str(j) '...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startBunchLongitudinalSectionTime';
                    message.text = ['      Start time: ' currentTime()];
                    partTimer = tic;
                    message.priorityLevel = 7;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startBunchLongitudinalSectionException';
                    errorMessage.text = 'Could not notify start of movie';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
            try %to make the movie 
                if parameters.options.shouldSaveMovies %then create movie files 
                    if maxJ == 1 %then don't split the files 
                        currentMovieFile = avifile([parameters.files.bunchLongitudinalMovie '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');                %#ok - need avifile in the loop for multiple movie files
                    else
                        currentMovieFile = avifile([parameters.files.bunchLongitudinalMovie '-' num2str(j) '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');     %#ok - need avifile in the loop for multiple movie files
                    end
                end
                for i = (loops(j) + 1):loops(j+1) %build each frame 
                    figure(movieFigureNo), hold off;
                    set(movieFigureNo,'color','white');
                    set(movieFigureNo,'Position',[50 50 900 600]);
                    currentMedianParticle = find(timeData(i).ID == medianParticleNo);
                    bLength = (timeData(i).Bz(currentMedianParticle).*parameters.particle.lightSpeed)./parameters.beam.frequency;
                    pictureLength = bLength*5;
                    halfPictureLength = pictureLength/2;
                    minZ = timeData(i).z(currentMedianParticle) - halfPictureLength;
                    maxZ = minZ + pictureLength;
                    isInMovie = find(timeData(i).z >= minZ & timeData(i).z <= maxZ);
                    figure(movieFigureNo), hold on;
                    plot(timeData(i).z(isInMovie),timeData(i).y(isInMovie).*1e3,'xk');
                    xlabel('z (m)'), ylabel('y (mm)'), ...
                        title('\bf RFQ Longitudinal Bunch Profile');
                    axis([minZ maxZ -3 3]);
                    enhanceFigure(movieFigureNo);
                    hold off;
                    if parameters.options.shouldSaveMovies %save each frame to movie file
                        F = getframe(movieFigureNo);
                        currentMovieFile = addframe(currentMovieFile,F);
                    elseif parameters.options.shouldPause %then pause 
                        display('Press a key to continue...');
                        pause ;
                    end
                    close(movieFigureNo);
                    clear isInMovie F currentMedianParticle bLength pictureLength halfPictureLength minZ maxZ;
                end
                if parameters.options.shouldSaveMovies %then close movie files 
                    currentMovieFile = close(currentMovieFile) ;
                end
                clear i currentMovieFile;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:buildBunchLongitudinalException';
                errorMessage.text = 'Could not build bunch longitudinal movie';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if maxJ > 1 %then notify end of part file 
                try %to notify end 
                    partTimeSeconds = toc(partTimer);
                    partTime = convertSecondsToText(partTimeSeconds);
                    text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' partTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:endBunchLongitudinalSectionTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear partTimer partTimeSeconds partTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endBunchLongitudinalSectionException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end            
        end
        clear j;
        try %to notify end 
            movieTimeSeconds = toc(movieTimer);
            movieTime = convertSecondsToText(movieTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' movieTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:endBunchLongitudinalTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear movieTimer movieTimeSeconds movieTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endBunchLongitudinalException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end
                
%% Transverse motion 

    if parameters.options.shouldMakeTransverseMovie %then make the movie 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startTransverse';
            if maxJ == 1 %then don't split into sections 
                message.text = ' - Building transverse movie...';
            else
                message.text = ' - Building transverse movies... ';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startTransverseTime';
            message.text = ['   Start time: ' currentTime()];
            movieTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startTransverseException';
            errorMessage.text = 'Could not notify start of movie';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        minX = -3.6;
        maxX = 3.6;
        for j = 1:maxJ %build movies in sections
            if maxJ > 1 %then notify start of part file 
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startTransverseSection';
                    message.text = ['    - Part ' num2str(j) '...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startTransverseSectionTime';
                    message.text = ['      Start time: ' currentTime()];
                    partTimer = tic;
                    message.priorityLevel = 7;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startTransverseSectionException';
                    errorMessage.text = 'Could not notify start of movie';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
            try %to make the movie 
                if parameters.options.shouldSaveMovies %then create movie files 
                    if maxJ == 1 %then don't split the files 
                        currentMovieFile = avifile([parameters.files.transverseMovie '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');               %#ok - need avifile in the loop for multiple movie files
                    else
                        currentMovieFile = avifile([parameters.files.transverseMovie '-' num2str(j) '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');    %#ok - need avifile in the loop for multiple movie files
                    end
                end
                for i = (loops(j) + 1):loops(j+1) %build each frame 
                    figure(movieFigureNo), hold off;
                    set(movieFigureNo,'color','white');
                    set(movieFigureNo,'Position',[50 50 900 600]);
                    isInMovie = find(timeData(i).x >= minX & timeData(i).x <= maxX);
                    figure(movieFigureNo), hold on;
                    plot(timeData(i).x(isInMovie).*1e3,timeData(i).y(isInMovie).*1e3,'xk');
                    xlabel('x (mm)'), ylabel('y (mm)'), ...
                        title('\bf RFQ Transverse Beam Profile');
                    axis([-3.6 3.6 -3.6 3.6]); 
                    enhanceFigure(movieFigureNo);
                    hold off;
                    if parameters.options.shouldSaveMovies %then save each frame to the movie file 
                        F = getframe(movieFigureNo);
                        currentMovieFile = addframe(currentMovieFile,F);
                    elseif parameters.options.shouldPause %then pause 
                        display('Press a key to continue...');
                        pause;
                    end
                    close(movieFigureNo);
                    clear isInMovie F;
                end
                if parameters.options.shouldSaveMovies %then close the movie files 
                    currentMovieFile = close(currentMovieFile);
                end
                clear i currentMovieFile;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:buildTransverseException';
                errorMessage.text = 'Could not build transverse movie';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if maxJ > 1 %then notify end of part file 
                try %to notify end 
                    partTimeSeconds = toc(partTimer);
                    partTime = convertSecondsToText(partTimeSeconds);
                    text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' partTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:endTransverseSectionTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear partTimer partTimeSeconds partTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endTransverseSectionException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
        end
        clear j minX maxX;
        try %to notify end 
            movieTimeSeconds = toc(movieTimer);
            movieTime = convertSecondsToText(movieTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' movieTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:endTransverseTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear movieTimer movieTimeSeconds movieTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endTransverseException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end
    
%% X phase space 

    if parameters.options.shouldMakeXPhaseMovie %then make the movie 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startXPhase';
            if maxJ == 1 %then don't split into sections 
                message.text = ' - Building x phase movie...';
            else
                message.text = ' - Building x phase movies... ';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startXPhaseTime';
            message.text = ['   Start time: ' currentTime()];
            movieTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startXPhaseException';
            errorMessage.text = 'Could not notify start of movie';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        minX = -3;
        maxX = 3;
        for j = 1:maxJ %build movies in sections 
            if maxJ > 1 %then notify start of part file 
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startXPhaseSection';
                    message.text = ['    - Part ' num2str(j) '...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startXPhaseSectionTime';
                    message.text = ['      Start time: ' currentTime()];
                    partTimer = tic;
                    message.priorityLevel = 7;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startXPhaseSectionException';
                    errorMessage.text = 'Could not notify start of movie';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
            try %to make the movie 
                if parameters.options.shouldSaveMovies %then create movie files 
                    if maxJ == 1 %then don't split the files
                        currentMovieFile = avifile([parameters.files.xPhaseMovie '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');               %#ok - need avifile in the loop for multiple movie files
                    else
                        currentMovieFile = avifile([parameters.files.xPhaseMovie '-' num2str(j) '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');    %#ok - need avifile in the loop for multiple movie files
                    end
                end
                for i = (loops(j) + 1):loops(j+1) %build each frame 
                   figure(movieFigureNo), hold off;
                   set(movieFigureNo,'color','white');
                   set(movieFigureNo,'Position',[50 50 900 600]);
                   isInMovie = find(timeData(i).x >= minX & timeData(i).x <= maxX);
                   figure(movieFigureNo), hold on ;
                   plot(timeData(i).x(isInMovie).*1e3,timeData(i).xp(isInMovie).*1e3,'xk') ;
                   xlabel('x (mm)'), ylabel('x'' (mrad)'), ...
                       title('\bf RFQ X Phase Space');
                   axis([-5 5 -100 100]);
                   enhanceFigure(movieFigureNo);
                   hold off ;
                   if parameters.options.shouldSaveMovies %then save each frame to movie 
                       F = getframe(movieFigureNo);
                       currentMovieFile = addframe(currentMovieFile, F);
                   elseif parameters.options.shouldPause %then pause
                       pause;
                   end
                   close(movieFigureNo);
                   clear isInMovie F;
                end
                if parameters.options.shouldSaveMovies %then close movie files 
                   currentMovieFile = close(currentMovieFile);
                end
                clear i currentMovieFile;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:buildXPhaseException';
                errorMessage.text = 'Could not build x phase movie';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if maxJ > 1 %then notify end of part file 
                try %to notify end 
                    partTimeSeconds = toc(partTimer);
                    partTime = convertSecondsToText(partTimeSeconds);
                    text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' partTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:endXPhaseSectionTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear partTimer partTimeSeconds partTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endXPhaseSectionException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
        end
        clear j minX maxX;
        try %to notify end 
            movieTimeSeconds = toc(movieTimer);
            movieTime = convertSecondsToText(movieTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' movieTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:endXPhaseTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear movieTimer movieTimeSeconds movieTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endXPhaseException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end
    
%% Y phase space 

    if parameters.options.shouldMakeYPhaseMovie %then make the movie 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startYPhase';
            if maxJ == 1 %then don't split into sections 
                message.text = ' - Building y phase movie...';
            else
                message.text = ' - Building y phase movies... ';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startYPhaseTime';
            message.text = ['   Start time: ' currentTime()];
            movieTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startYPhaseException';
            errorMessage.text = 'Could not notify start of movie';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        minY = -3;
        maxY = 3;
        for j = 1:maxJ %build movies in sections 
            if maxJ > 1 %then notify start of part file 
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startYPhaseSection';
                    message.text = ['    - Part ' num2str(j) '...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startYPhaseSectionTime';
                    message.text = ['      Start time: ' currentTime()];
                    partTimer = tic;
                    message.priorityLevel = 7;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startYPhaseSectionException';
                    errorMessage.text = 'Could not notify start of movie';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
            try %to make the movie 
                if parameters.options.shouldSaveMovies %then create movie files 
                    if maxJ == 1 %then don't split the files 
                        currentMovieFile = avifile([parameters.files.yPhaseMovie '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');               %#ok - need avifile in the loop for multiple movie files
                    else
                        currentMovieFile = avifile([parameters.files.yPhaseMovie '-' num2str(j) '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');    %#ok - need avifile in the loop for multiple movie files
                    end
                end
                for i = (loops(j) + 1):loops(j+1) %build each frame 
                   figure(movieFigureNo), hold off;
                   set(movieFigureNo,'color','white');
                   set(movieFigureNo,'Position',[50 50 900 600]);
                   isInMovie = find(timeData(i).y >= minY & timeData(i).y <= maxY);
                   figure(movieFigureNo), hold on;
                   plot(timeData(i).y(isInMovie).*1e3,timeData(i).yp(isInMovie).*1e3,'xk');
                   xlabel('y (mm)'), ylabel('y'' (mrad)'), ...
                       title('\bf RFQ Y Phase Space');
                   axis([-5 5 -100 100]);
                   enhanceFigure(movieFigureNo);
                   hold off;
                   if parameters.options.shouldSaveMovies %then save each frame to movie
                       F = getframe(movieFigureNo);
                       currentMovieFile = addframe(currentMovieFile, F);
                   elseif parameters.options.shouldPause %then pause
                       pause;
                   end
                   close(movieFigureNo);
                   clear isInMovie F;
                end
                if parameters.options.shouldSaveMovies %then close movie files 
                    currentMovieFile = close(currentMovieFile) ;
                end
                clear i currentMovieFile;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:buildYPhaseException';
                errorMessage.text = 'Could not build y phase movie';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if maxJ > 1 %then notify end of part file 
                try %to notify end 
                    partTimeSeconds = toc(partTimer);
                    partTime = convertSecondsToText(partTimeSeconds);
                    text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' partTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:endYPhaseSectionTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear partTimer partTimeSeconds partTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endYPhaseSectionException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
        end
        clear j minY maxY;
        try %to notify end 
            movieTimeSeconds = toc(movieTimer);
            movieTime = convertSecondsToText(movieTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' movieTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:endYPhaseTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear movieTimer movieTimeSeconds movieTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endYPhaseException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end

%% Energy 

    if parameters.options.shouldMakeEnergyMovie %then make the movie 
        try %to notify start 
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startEnergy';
            if maxJ == 1 %then don't split into sections 
                message.text = ' - Building energy movie...';
            else
                message.text = ' - Building energy movies... ';
            end
            message.priorityLevel = 3;
            message.errorLevel = 'information';
            logMessage(message);
            clear message;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:startEnergyTime';
            message.text = ['   Start time: ' currentTime()];
            movieTimer = tic;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startEnergyException';
            errorMessage.text = 'Could not notify start of movie';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
        for j = 1:maxJ %build movies in sections 
            if maxJ > 1 %then notify start of part file 
                try %to notify start 
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startEnergySection';
                    message.text = ['    - Part ' num2str(j) '...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:startEnergySectionTime';
                    message.text = ['      Start time: ' currentTime()];
                    partTimer = tic;
                    message.priorityLevel = 7;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:startEnergySectionException';
                    errorMessage.text = 'Could not notify start of movie';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
            try %to make the movie 
                if parameters.options.shouldSaveMovies %then create movie files 
                    if maxJ == 1 %then don't split the files 
                        currentMovieFile = avifile([parameters.files.energyMovie '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');               %#ok - need avifile in the loop for multiple movie files
                    else                            
                        currentMovieFile = avifile([parameters.files.energyMovie '-' num2str(j) '.avi'], 'fps', parameters.plot.framesPerSecond, 'compression', 'None');    %#ok - need avifile in the loop for multiple movie files
                    end
                end
                for i = (loops(j) + 1):loops(j+1) %build each frame
                    figure(movieFigureNo), hold off ;
                    set(movieFigureNo,'color','white') ;
                    set(movieFigureNo,'Position',[50 50 900 600]);
                    currentMedianParticle = find(timeData(i).ID == medianParticleNo);
                    bLength = (timeData(i).Bz(currentMedianParticle).*parameters.particle.lightSpeed)./parameters.beam.frequency;
                    pictureLength = bLength.*5;
                    halfPictureLength = pictureLength./2;
                    minZ = timeData(i).z(currentMedianParticle) - halfPictureLength;
                    maxZ = minZ + pictureLength;
                    isInMovie = find(timeData(i).z >= minZ & timeData(i).z <= maxZ);
                    figure(movieFigureNo), hold on;
                    plot(timeData(i).z(isInMovie),timeData(i).E(isInMovie).*1e-3/parameters.particle.nNucleons,'xk');
                    xlabel('Longitudinal Position (m)'), ylabel('Particle Energy (keV/u)'), ...
                        title('\bf RFQ Longitudinal Emittance');
                    axis tight;
                    custax = axis;
                    custax(1) = minZ;
                    custax(2) = maxZ;
                    axis(custax);
                    enhanceFigure(movieFigureNo);
                    hold off;
                    if parameters.options.shouldSaveMovies %then save each frame to movie
                        F = getframe(movieFigureNo);
                        currentMovieFile = addframe(currentMovieFile, F);
                    elseif parameters.options.shouldPause %then pause
                        pause;
                    end
                    close(movieFigureNo);
                    clear isInMovie F currentMedianParticle bLength pictureLength halfPictureLength minZ maxZ custax;
                end
                if parameters.options.shouldSaveMovies %then close movie files 
                    currentMovieFile = close(currentMovieFile);
                end
                clear i currentMovieFile;
            catch exception
                errorMessage = struct;
                errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:buildEnergyException';
                errorMessage.text = 'Could not build energy movie';
                errorMessage.priorityLevel = 3;
                errorMessage.errorLevel = 'warning';
                errorMessage.exception = exception;
                logMessage(errorMessage);
            end
            if maxJ > 1 %then notify end of part file 
                try %to notify end 
                    partTimeSeconds = toc(partTimer);
                    partTime = convertSecondsToText(partTimeSeconds);
                    text = ['      End time: ' currentTime() '\n' '      Elapsed time: ' partTime '.'];
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:buildMovies:endEnergySectionTime';
                    message.text = text;
                    message.priorityLevel = 5;
                    message.errorLevel = 'information';
                    logMessage(message);
                    clear partTimer partTimeSeconds partTime text message;
                catch exception
                    errorMessage = struct;
                    errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endEnergySectionException';
                    errorMessage.text = 'Could not notify end of section';
                    errorMessage.priorityLevel = 8;
                    errorMessage.errorLevel = 'warning';
                    errorMessage.exception = exception;
                    logMessage(errorMessage);
                end
            end
        end
        clear j;
        try %to notify end 
            movieTimeSeconds = toc(movieTimer);
            movieTime = convertSecondsToText(movieTimeSeconds);
            text = ['   End time: ' currentTime() '\n' '   Elapsed time: ' movieTime '.'];
            message = struct;
            message.identifier = 'ModelRFQ:Functions:buildMovies:endEnergyTime';
            message.text = text;
            message.priorityLevel = 5;
            message.errorLevel = 'information';
            logMessage(message);
            clear movieTimer movieTimeSeconds movieTime text message;
        catch exception
            errorMessage = struct;
            errorMessage.identifier = 'ModelRFQ:Functions:buildMovies:endEnergyException';
            errorMessage.text = 'Could not notify end of section';
            errorMessage.priorityLevel = 8;
            errorMessage.errorLevel = 'warning';
            errorMessage.exception = exception;
            logMessage(errorMessage);
        end
    end
    
%% Clean up 

    clear variables;

return