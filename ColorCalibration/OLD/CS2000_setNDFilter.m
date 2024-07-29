function CS2000_setNDFilter(filter)
global s

fprintf(s,['NDFS,', num2str(filter)]);
ErrorCheckCode = fscanf(s);
[tf, errOutput] = CS2000_errMessage(ErrorCheckCode);
if tf == 1
    disp(['Filter ', num2str(filter), ' has been set.']);
else
    disp(errOutput);
end