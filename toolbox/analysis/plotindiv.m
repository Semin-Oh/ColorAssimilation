function h = plotindiv(data,col,lim,xl,yl)
% plot out individual observer data, compare two variables.
% Cohen's d is calculated after correcting for dependence between means,
% using Morris and DeShon (2002) equation 8.
% see also: http://www.yorku.ca/ncepeda/effectsize.html
% X axis - data(:,1);
% Y axis - data(:,2)
if nargin<4
    xl = 'X Value';
    yl = 'Y value';
end
if nargin<3
    m1 = min(data(:));
    m2 = max(data(:));
    lim = [m1 - 0.1*(m2-m1), m2+0.1*(m2-m1)];
elseif isnan(lim(1))
    m1 = min(data(:));
    m2 = max(data(:));
    lim = [m1 - 0.1*(m2-m1), m2+0.1*(m2-m1)];
end
[h,p,ci,stats]=ttest(data(:,1),data(:,2));
% Cohen's d
% m1 = mean(data(:,1));
% m2 = mean(data(:,2));
% sd1 = std(data(:,1));
% sd2 = std(data(:,2));
% r = corr(data);
% r = r(1,2);
% tmp1 = sd1*sqrt(2*(1-r));
% tmp2 = sd2*sqrt(2*(1-r));
% cohen_d=(m1-m2)/mean([tmp1 tmp2]);
m = data(:,1)-data(:,2);
dz = mean(m)/std(m);
disp(['t = ',num2str(stats.tstat), '; P = ',num2str(p),'; Cohen',char(39),'s d = ',num2str(dz)]);

% bootstrap


% a module for plotting, col 1 is x axis; col 2 is y axis
%figure;
% hold on;
% h = plot(data(:,1), data(:,2),'.','markersize',35,'linewidth',1,'color',[0 0 0]);%20
%set(gca,'fontsize',14);
% xlabel(xl);
% ylabel(yl);
%lim = [-0.5 1.5];
% axis([lim lim]);
% line(lim,lim,'linestyle','--','color',[0 0 0]);
% box on;
%set(gca,'ytick',-20:20:40);

% error bar
x_se = std(data(:,1))/sqrt(size(data,1));
y_se = std(data(:,2))/sqrt(size(data,1));
x = mean(data(:,1));
y = mean(data(:,2));
% line([x-x_se,x+x_se],[y y],'linewidth',1.5,'color',[0 0 0]);
% line([x,x],[y-y_se,y+y_se],'linewidth',1.5,'color',[0 0 0]);
% diogonal error bar
d_rotated = - data(:,1) ./ sqrt(2) + data(:,2) ./ sqrt(2);
d_se = std(d_rotated)/sqrt(size(data,1));
tmp = d_se / sqrt(2);
% line([x-tmp,x+tmp],[y+tmp y-tmp],'linewidth',1.5,'color',[0 0 0]);

% diognoal error bar, along the diogonal line
% d_r2 = data(:,1)/sqrt(2) + data(:,2)./sqrt(2);
% d_se2 = std(d_r2)/sqrt(size(data,1));
% tmp2 = d_se2/sqrt(2);
% line([x-tmp2,x+tmp2],[y-tmp2 y+tmp2],'linewidth',1.5,'color',[0 0 0]);


d = data(:,1) ./ sqrt(2) - data(:,2) ./ sqrt(2);
dd = data(:,1) ./ sqrt(2) + data(:,2) ./ sqrt(2);

% bootstrap to get 95% confidence interval of diognal
% n = 5000;
% m = zeros(1,n);
% for i = 1:n
% m(i) = mean(datasample(d, length(d)));
% end
% q = quantile(m,[0.025 0.5 0.975]);
% b = mean(dd);
% x = q./sqrt(2)+b/sqrt(2);
% y = -q./sqrt(2)+b/sqrt(2);
%


% one sample t-test on the data along the negative slope
% to get the confidence interval
[hh,p,ci] = ttest(d);
b = mean(dd);
x = [ci(1) mean(d) ci(2)]./sqrt(2)+b/sqrt(2);
y = -[ci(1) mean(d) ci(2)]./sqrt(2)+b/sqrt(2);


% Plot it.
if isempty(col)
    col = [0.5 0.5 0.5 0.5];
end    
    % Mean value.
    h =plot(x(2),y(2),'.','markersize',10,'color',col);%15

    % Diagonal line.
    line([x(1) x(3)],y([1 3]),'linewidth',2,'color',col);%2.5

end

