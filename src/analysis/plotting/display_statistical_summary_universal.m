function display_statistical_summary_universal(stats_results, labels, config)
%% 显示统计分析摘要

if strcmp(config.language, 'cn')
    fprintf('\n========== 统计分析摘要 ==========\n');
    header_format = '%-20s';
    for i = 1:length(labels)
        header_format = [header_format, '%-12s'];
    end
    fprintf([header_format, '\n'], '信号', labels{:});
    fprintf(repmat('-', 1, 20 + 12*length(labels)));
    fprintf('\n');
else
    fprintf('\n========== Statistical Analysis Summary ==========\n');
    header_format = '%-20s';
    for i = 1:length(labels)
        header_format = [header_format, '%-12s'];
    end
    fprintf([header_format, '\n'], 'Signal', labels{:});
    fprintf(repmat('-', 1, 20 + 12*length(labels)));
    fprintf('\n');
end

% 显示每个信号的RMS值
signal_names = fieldnames(stats_results);
for i = 1:length(signal_names)
    signal_name = signal_names{i};
    rms_values = stats_results.(signal_name).rms;
    
    % 格式化输出
    fprintf('%-20s', signal_name);
    for j = 1:length(rms_values)
        fprintf('%-12.6f', rms_values(j));
    end
    fprintf('\n');
end

% 保存统计摘要到文件
if config.save_plots
    summary_file = fullfile(config.output_folder, 'statistical_summary.txt');
    fileID = fopen(summary_file, 'w');
    
    if strcmp(config.language, 'cn')
        fprintf(fileID, '统计分析摘要\n');
        fprintf(fileID, '生成时间: %s\n\n', datestr(now));
    else
        fprintf(fileID, 'Statistical Analysis Summary\n');
        fprintf(fileID, 'Generated: %s\n\n', datestr(now));
    end
    
    % 写入详细统计信息
    for i = 1:length(signal_names)
        signal_name = signal_names{i};
        fprintf(fileID, '\n%s:\n', signal_name);
        fprintf(fileID, 'Label\t\tMean\t\tStd\t\tMax\t\tMin\t\tRMS\n');
        fprintf(fileID, '-----\t\t----\t\t---\t\t---\t\t---\t\t---\n');
        
        for j = 1:length(labels)
            fprintf(fileID, '%s\t\t%.6f\t\t%.6f\t\t%.6f\t\t%.6f\t\t%.6f\n', ...
                   labels{j}, ...
                   stats_results.(signal_name).mean(j), ...
                   stats_results.(signal_name).std(j), ...
                   stats_results.(signal_name).max(j), ...
                   stats_results.(signal_name).min(j), ...
                   stats_results.(signal_name).rms(j));
        end
    end

    fclose(fileID);
end

% 导出绘图数据到workspace和.mat文件
if config.save_to_workspace || config.save_mat_files
    % 遍历所有信号，为每个信号创建数据导出
    signal_names = fieldnames(stats_results);
    for i = 1:length(signal_names)
        signal_name = signal_names{i};

        % 创建信号信息（用于导出函数）
        if strcmp(config.language, 'cn')
            signal_label = signal_name;  % 使用信号名作为标签
            signal_info_local = {signal_name, '', 0, signal_label, signal_label, ''};
        else
            signal_label = signal_name;
            signal_info_local = {signal_name, '', 0, signal_label, signal_label, ''};
        end

        % 组织统计数据
        plot_data = struct();
        plot_data.stats_data = stats_results.(signal_name);

        export_plot_data(plot_data, signal_info_local, labels, config, 'stat');
    end
end

end