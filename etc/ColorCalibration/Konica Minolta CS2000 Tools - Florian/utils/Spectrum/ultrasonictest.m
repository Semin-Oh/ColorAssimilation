s = serial('COM3');
fopen(s);
d = nan(1, 1e3);
i = 1;
Misc.dockedFigure
while 1
    d(i) = str2double(fscanf(s));
    plot(1 : 1000, d), drawnow
    if i == 1e3, i = 1;
    else, i = i + 1;
    end
end
fclose(s)
