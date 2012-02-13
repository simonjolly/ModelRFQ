function currentTime = currentTime()
%
% function currentTime = currentTime()
%
%   Return current date and time as a string
%
%   See also modelRfq, convertSecondsToText.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   24-Nov-2010 M. J. Easton
%       Created function to return current time as a string
%
%   21-Dec-2010 M. J. Easton
%       Included in ModelRFQ distribution
%
%=========================================================================

    timeVector = clock;

    if timeVector(4) < 10 %then add zero in front of hours 
        hours = ['0' num2str(timeVector(4))];
    else
        hours = num2str(timeVector(4));
    end
    if timeVector(5) < 10 %then add zero in front of minutes 
        minutes = ['0' num2str(timeVector(5))];
    else
        minutes = num2str(timeVector(5));
    end
    if timeVector(6) < 10 %then add zero in front of seconds 
        seconds = ['0' num2str(timeVector(6))];
    else
        seconds = num2str(timeVector(6));
    end

    currentTime = [num2str(timeVector(3)) '/' num2str(timeVector(2)) '/' num2str(timeVector(1)) ' ' ...
        hours ':' minutes ':' seconds];

return