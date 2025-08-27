function [outputArg1,outputArg2] = plot_time_labels(sig_mat,t_mat,labels,pic_text)
    figure
    colors = lines(length(labels)); % 生成颜色矩阵
    colors(end,:) = [0,0,0];
    for i=1:length(labels)
        def_tire =sig_mat(:,i);
        t = t_mat;
        if i == 1
            plot(t,def_tire,'--','LineWidth',1.5,'DisplayName',[labels{i}],'Color',colors(i,:));
        elseif i == length(labels)
            plot(t,def_tire,'-','LineWidth',1.5,'DisplayName',[labels{i}],'Color',colors(i,:));
        else
            plot(t,def_tire,'-','LineWidth',1,'DisplayName',[labels{i}],'Color',colors(i,:));
        end
        % semilogx(f_def_tire,soomthMag_def_tire,'-','LineWidth',1.5,'DisplayName',[labels{i}],'Color',colors(i,:));
        hold on;
    end
    xlabel(pic_text{1})
    ylabel(pic_text{2})
    % title(pic_text{3})
    legend('Location','best');
    grid on
end

