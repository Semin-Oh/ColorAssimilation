function readSemrock

%read filter IDs
urlRoot = 'https://www.semrock.com/';
urlFilterRoot = '/FilterDetails.aspx?id=';
target = sprintf('href="%s', urlFilterRoot);
lTarget = numel(target);
id = {};
b = TimeBar('Reading filter list...');
nPage = 16;
for i = 1 : nPage
    urlList = sprintf(['%sfiltersRefined.aspx?page=%d&so=0&recs=50'], ...
        urlRoot, i);
    x = urlread(urlList);                                                   %#ok
    j = strfind(x, target);
    for k = 1 : numel(j)
        dj = find(x(j(k) : end) == '"', 2, 'first');
        id_ = x(j(k) + (lTarget : dj(2) - 2));
        if isempty(id), id{1} = id_;
        elseif ~isequal(id_, id{end}), id{end + 1} = id_;                   %#ok
        end
    end
    b.update(i / nPage);
end

%read AOI
semrock.id = unique(id);
n = numel(semrock.id);
urlSpectrum = cell(1, n);
semrock.aoi_deg = struct('nom', nan(1, n), 'tol', nan(1, n));
valid = false(1, n);
b = TimeBar('Reading filter specifications...');
for i = 1 : n
    x = urlread(sprintf('%s%s%s', urlRoot, urlFilterRoot, semrock.id{i}));  %#ok
    
    %read AOI
    j = strfind(x, 'Angle of Incidence');
    dj1 = find(x(j(1) : end) == '±', 1, 'first');
    dj2 = strfind(x(j(1) : end), 'degree');
    dj0 = find(x(j(1) + (0 : dj2)) == '>', 1, 'last');
    if isempty(dj1) || dj1 > dj2(1)
        semrock.aoi_deg.nom(i) = str2double(x(j(1) + (dj0 : (dj2 - 2))));
    else
        semrock.aoi_deg.nom(i) = str2double(x(j(1) + (dj0 : (dj1 - 2))));
        semrock.aoi_deg.tol(i) = str2double(x(j(1) + ...
            (dj1 : (dj2(1) - 2))));
    end
    b.update(i / n);
    
    valid(i) = ~isnan(semrock.aoi_deg.nom(i));
    if valid(i)
        %read url of spectrum txt file
        j = strfind(x, 'href="/_ProductData/Spectra/');
        dj = find(x(j(1) : end) == '"', 2, 'first');
        urlSpectrum{i} = x(j(1) + (7 : dj(2) - 2));
    end
end
fprintf('Note: %d of %d filters were ignored.\n', sum(~valid), n);          %most likely tunable filters that do not have a single nominal AOI (or transmission spectrum)
semrock.id = semrock.id(valid);
semrock.aoi_deg.nom = semrock.aoi_deg.nom(valid);
semrock.aoi_deg.tol = semrock.aoi_deg.tol(valid);
urlSpectrum = urlSpectrum(valid);
n = sum(valid);

%read spectra
limWvl_ = nan(2, n);
tmp = cell(1, n);
b = TimeBar('Reading spectra...');
for i = 1 : n
    x = urlread(sprintf('%s%s%s_Spectrum.txt', urlRoot, urlSpectrum{i}));   %#ok
    inl = [0, find(x == newline)] + 1;                                      %index of first character in each line
    c = x(inl(1 : end - 1) + 1);                                            %first character of each line
    ifl = inl(find(c >= 48 & c <= 57, 1, 'first'));                         %index of first char in first line containing numerical data
    tmp{i} = textscan(x(ifl : end), '%f\t%f');
    valid = tmp{i}{1}(2 : end) > tmp{i}{1}(1 : end - 1);
    if any(~valid)
        [~, i500] = min(abs(tmp{i}{1} - 500));
        iStart = find(~valid(1 : i500 - 1), 1, 'last') + 1;
        if isempty(iStart), iStart = 1; end
        iEnd = find(~valid(i500 : end), 1, 'first');
        if isempty(iEnd), iEnd = numel(tmp{i}{1}); end
        tmp{i}{1} = tmp{i}{1}(iStart : iEnd);
        tmp{i}{2} = tmp{i}{2}(iStart : iEnd);
    end
    limWvl_(:, i) = [tmp{i}{1}(1); tmp{i}{1}(end)]; 
    b.update(i / n);
end

%copy tmp to field wvl and transmission
limWvl = [min(ceil(limWvl_(1, :))); max(floor(limWvl_(2, :)))];
semrock.wvl = (limWvl(1) : limWvl(2))';
semrock.transmission = nan(numel(semrock.wvl), n);
b = TimeBar('Interpolating spectra...');
for i = 1 : n
    valid = tmp{i}{1} >= limWvl_(1, i) & tmp{i}{1} <= limWvl_(2, i);
    semrock.transmission(:, i) = interp1(tmp{i}{1}(valid), ...
        tmp{i}{2}(valid), semrock.wvl);
    b.update(i / n);
end

%save data
save semrock.mat semrock
end
