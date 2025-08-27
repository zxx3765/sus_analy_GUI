function [Mag_def_tire,f_def_tire] = plot_frqe_mag_labels(sig_mat,xr_mat,labels,pic_text)
% 绘制轮胎动行程的幅频特性曲线
    nfft=4096*2;
    window=hanning(nfft);
    fs=1000;
    numoverlap=nfft*3/4;
    xMin = 0.4; % 最小值
    xMax = 25; % 最大值
    nPoints = 100; % 生成点的数量
    colors = lines(length(labels)); % 生成颜色矩阵
    colors(end,:) = [0,0,0];
    % 生成对数尺度上均匀分布的点
    logX = linspace(log10(1.5), log10(xMax), nPoints-10);
    f = [linspace(xMin, 1.5, 15),10.^logX]; % 转换回线性尺度
    % f = 10.^logX;
    Mag_def_tire_matrix = zeros(length(labels),length(f));
    figure
    for i=1:length(labels)
        def_tire =sig_mat(:,i);
        xr = xr_mat(:,i);
        [Txy_def_tire,f_def_tire] = tfestimate(xr,def_tire,window,numoverlap,f,fs);
        Mag_def_tire = 20*log10(Txy_def_tire);
        % soomthMag_def_tire = smoothdata(Mag_def_tire,"lowess",7);
        if i == 1
            semilogx(f_def_tire,Mag_def_tire,'--','LineWidth',1.5,'DisplayName',[labels{i}],'Color',colors(i,:));
        elseif i == length(labels)
            semilogx(f_def_tire,Mag_def_tire,'-','LineWidth',1.5,'DisplayName',[labels{i}],'Color',colors(i,:));
        else
            semilogx(f_def_tire,Mag_def_tire,'-','LineWidth',1,'DisplayName',[labels{i}],'Color',colors(i,:));
        end
        % semilogx(f_def_tire,soomthMag_def_tire,'-','LineWidth',1.5,'DisplayName',[labels{i}],'Color',colors(i,:));
        hold on;
        Mag_def_tire_matrix(i,:) = Mag_def_tire;
    end
    xlim([xMin,xMax])
    xlabel(pic_text{1})
    ylabel(pic_text{2})
    % title(pic_text{3})
    legend('Location','best');
    grid on
end

