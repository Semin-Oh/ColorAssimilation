function b = contains(x, s)
    b = ~isempty(strfind(x, s));
end