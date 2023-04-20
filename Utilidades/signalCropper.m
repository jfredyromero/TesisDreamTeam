function signal = signalCropper(signal)
    sampleSize = 2^round(log2(length(signal)));
    if length(signal) ~= sampleSize
        offset = length(signal) - sampleSize;
        if mod(offset,2) == 0
            signal = signal(offset/2+1:end-offset/2);
        else
            index = floor(offset/2);
            signal = signal(index+1:end-index-1);
        end
    end
end