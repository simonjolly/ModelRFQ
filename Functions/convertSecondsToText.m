function text = convertSecondsToText(seconds)
%
% function text = convertSecondsToText(seconds)
%
%   convertSecondsToText takes a numerical time input and converts it to a
%   text description of the time, 
%    e.g. convertSecondsToText(120) = '2 minutes'
%
%   See also modelRfq, currentTime.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution.
%
% File history
%
%   20-Dec-2010 M. J. Easton
%       Created function convertSecondsToText as part of ModelRFQ
%       distribution.
%
%======================================================================

    % split seconds into minutes and seconds
    minutes = floor(seconds / 60);
    seconds = rem(seconds, 60);
    
    % split minutes into hours and minutes
    hours = floor(minutes / 60);
    minutes = rem(minutes, 60);
    
    % split hours into days and hours
    days = floor(hours / 24);
    hours = rem(hours, 24);
    
    % split days into weeks and days
    weeks = floor(days / 7);
    days = rem(days, 7);
    
    % create text string
    text = '';
    if weeks == 1
        text = '1 week, '; 
    elseif weeks > 1
        text = [num2str(weeks) ' weeks, ']; 
    end
    if days == 1
        text = [text '1 day, '];
    elseif days > 1 || weeks > 0
        text = [text num2str(days) ' days, ']; 
    end
    if hours == 1
        text = [text '1 hour, '];
    elseif hours > 1 || days > 0 || weeks > 0
        text = [text num2str(hours) ' hours, ']; 
    end
    if minutes == 1
        text = [text '1 minute, '];
    elseif minutes > 1 || hours > 0 || days > 0 || weeks > 0
        text = [text num2str(minutes) ' minutes, ']; 
    end
    if seconds == 1
        text = [text '1 second'];
    else
        text = [text num2str(seconds) ' seconds']; 
    end    

return