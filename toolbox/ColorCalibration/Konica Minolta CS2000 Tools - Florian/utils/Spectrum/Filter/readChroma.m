function readChroma
root = 'https://www.chroma.com/products/';
category = {'single-bandpass-and-single-edge-filters/filter-type/', ...
    'multi-bandpass-and-multi-dichroic-filters/multiband-type/'};
product = {'single-bandpass-filters/', 'longpass-filters/', ...
    'shortpass-filters/', 'notch-rejection-filters/', ...
    'neutral-density-beamsplitters-50-50-etc/', ...
    'dichroic-beamsplitters/', 'neutral-density-filters/', ...
    'multi-bandpass-filter/', 'multi-dichroic-beamsplitter/'};
iCategory = [ones(1, 7), 2 * ones(1, 2)];
viewParam = ['type/parts_display?view=detail&search_within=&' ...
    'limit=all&sord=asc&sidx=wavelength'];

url = {};
isBeamSplitter = false(1, 0);
nProduct = numel(product);
b = TimeBar('Reading filter list...');
for i = 1 : nProduct
    x = urlread(sprintf('%s%s%s%s', root, category{iCategory(i)}, ...
        product{i}, viewParam));                                            %#ok
    j = strfind(x, 'https://www.chroma.com/products/parts/');               %url zu filter
    nj = numel(j);
    for k = 1 : nj
        dj = find(x(j(k) : end) == '"', 1, 'first');
        url{end + 1} = x(j(k) + (0 : dj - 2));                                 %#ok
    end
    isBeamSplitter = [isBeamSplitter, repmat(i == 6 || i == 9, [1, nj])];   %#ok
    b.update(i / nProduct);
end
[url, idx] = unique(url);
isBeamSplitter = isBeamSplitter(idx);
n = numel(isBeamSplitter);

target.title = 'class="active">';
target.aoi = '<td class="aoi center">';
target.spectrum = '">ASCII</a>';
l.title = numel(target.title);
l.aoi = numel(target.aoi);
chroma.id = cell(1, n);
chroma.aoi_deg = nan(1, n);
tmp = cell(1, n);
limWvl_ = nan(2, n);
valid = false(1, n);
b = TimeBar('Reading filter data...');
for i = 403 : n
    x = urlread(url{i});                                                    %#ok
    
    %read id
    j = strfind(x, target.title);
    dj = find(x(j(1) : end) == '<', 1, 'first') - 2;
    chroma.id{i} = x(j + (l.title : dj));
    
    %read aoi
    j = strfind(x, target.aoi);
    dj = find(x(j(1) : end) == '&', 1, 'first') - 2;
    chroma.aoi_deg(i) = str2double(x(j(1) + (l.aoi : dj)));
    
    %read spectrum url
    j2 = strfind(x, target.spectrum) - 1;
    valid(i) = ~isempty(j2);
    if valid(i)
        j1 = find(x(1 : j2) == '"', 1, 'last') + 1;
        tmp{i} = textscan(urlread(x(j1 : j2)), '%f\t%f');                       %#ok
        limWvl_(:, i) = Math.lim(tmp{i}{1})';
    end
    
    b.update(i / n);
end
chroma.id = chroma.id(valid);
chroma.aoi_deg = chroma.aoi_deg(valid);
chroma.isBeamSplitter = isBeamSplitter(valid);
tmp = tmp(valid);
limWvl_ = limWvl_(:, valid);
n = sum(valid);

chroma.wvl = (ceil(min(limWvl_(1, :))) : floor(max(limWvl_(2, :))))';
chroma.transmission = nan(numel(chroma.wvl), n);
b = TimeBar('Interpolating filter transmission...');
for i = 1 : n
    chroma.transmission(:, i) = interp1(tmp{i}{1}, tmp{i}{2}, chroma.wvl);
    b.update(i / n);
end

save chroma.mat chroma
end