function signal = signalCropper(signal,n)
    sampleSize = [1024 512 256 128 64 32 16 8 4 2 1];
    if length(signal) ~= sampleSize(n+1)
        offset = length(signal) - sampleSize(n+1);
        if offset==1
            signal=signal(2:end);
        elseif offset>1
            if mod(offset,2) == 0
                signal = signal(offset/2+1:end-offset/2);            
            else
                index = floor(offset/2);
                signal = signal(index+1:end-index-1);
            end
        else
             if mod(offset,2) == 0
                offset=abs(offset);
                if  iscolumn(signal)
                    signal = [zeros(offset/2,1); signal; zeros(offset/2,1)];    
                else
                    signal = [zeros(1,offset/2) signal zeros(1,offset/2)];  
                    p=1;
                end
             else
                offset=abs(offset);
                index = floor(offset/2);
                if  iscolumn(signal)
                    signal = [zeros(index+1,1); signal; zeros(index-1,1)];
                else
                    signal = [zeros(1,index+1) signal zeros(1,index-1)];
                end
            end
        end
    end
end