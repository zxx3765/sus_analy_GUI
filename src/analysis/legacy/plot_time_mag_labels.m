function plot_time_mag_labels(sig_mat, time_vec, labels, pic_text, legend_loc, colors, first_line_sty, last_line_width)
    arguments
        sig_mat (:,:) double    % 信号矩阵
        time_vec (:,:) double   % 时间向量
        labels (1,:) cell       % 标签元胞数组
        pic_text (1,:) cell     % 图片文本元胞数组
        legend_loc string = "best" % 默认值
        colors (:,:) = lines(length(labels)) % 生成颜色矩阵
        first_line_sty string = '-'
        last_line_width double = 1.5
    end
    
    figure
    hold on
    for i = 1:length(labels)
        if i == 1
            plot(time_vec(:,i), sig_mat(:,i), first_line_sty, 'LineWidth', 1.5, ...
                'DisplayName', labels{i}, 'Color', colors(i,:));
        elseif i == length(labels)
            plot(time_vec(:,i), sig_mat(:,i), '-', 'LineWidth', 1.5, ...
                'DisplayName', labels{i}, 'Color', colors(i,:));
        else
            plot(time_vec(:,i), sig_mat(:,i), '-', 'LineWidth', last_line_width, ...
                'DisplayName', labels{i}, 'Color', colors(i,:));
        end
    end
    
    xlabel(pic_text{1})  % 例如 'Time (s)'
    ylabel(pic_text{2})  % 例如 'Amplitude'
    legend('Location', legend_loc)
    grid on
end

