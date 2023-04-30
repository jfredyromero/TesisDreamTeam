function signal = signalCropper(signal, finalSize)
    if length(signal) ~= finalSize
        offset = length(signal) - finalSize;
        if mod(offset,2) == 0
            signal = signal(offset/2+1:end-offset/2);
        else
            index = floor(offset/2);
            signal = signal(index+1:end-index-1);
        end
    end
end