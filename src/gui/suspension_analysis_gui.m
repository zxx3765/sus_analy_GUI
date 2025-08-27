function suspension_analysis_gui()
%% 悬架分析GUI - 统一启动入口
% 这是模块化悬架分析GUI的主要启动函数
%
% 使用方法:
%   suspension_analysis_gui()  % 启动GUI
%
% 新的模块化架构:
%   - main_gui.m                - 主界面框架
%   - gui_data_manager.m        - 数据管理模块
%   - gui_config_manager.m      - 配置管理模块  
%   - gui_signal_analysis.m     - 信号选择和分析控制模块
%   - gui_log_viewer.m          - 日志查看器模块
%   - gui_results_viewer.m      - 结果查看器模块
%   - gui_utils.m               - 工具函数模块
%
% 作者: Claude Code Assistant
% 日期: 2024
% 版本: 2.0 (模块化重构版)

fprintf('启动悬架分析GUI...\n');

try
    % 确保路径设置正确
    if exist('setup_paths', 'file')
        setup_paths(false);
    end
    
    % 检查GUI模块文件是否存在
    required_files = {
        'main_gui.m',
        'gui_data_manager.m', 
        'gui_config_manager.m',
        'gui_signal_analysis.m',
        'gui_log_viewer.m',
        'gui_results_viewer.m',
        'gui_utils.m'
    };
    
    missing_files = {};
    for i = 1:length(required_files)
        if ~exist(required_files{i}, 'file')
            missing_files{end+1} = required_files{i};
        end
    end
    
    if ~isempty(missing_files)
        error('缺少GUI模块文件: %s', strjoin(missing_files, ', '));
    end
    
    % 启动主GUI
    main_gui();
    
    fprintf('✓ 悬架分析GUI启动成功\n');
    fprintf('版本: 2.0 (模块化架构)\n');
    
catch ME
    fprintf('✗ GUI启动失败: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('错误位置: %s (第%d行)\n', ME.stack(1).file, ME.stack(1).line);
    end
    
    % 提供诊断信息
    fprintf('\n诊断信息:\n');
    fprintf('- 当前路径: %s\n', pwd);
    fprintf('- MATLAB版本: %s\n', version);
    
    % 检查关键文件
    fprintf('- 关键文件检查:\n');
    for i = 1:length(required_files)
        if exist(required_files{i}, 'file')
            fprintf('  ✓ %s\n', required_files{i});
        else
            fprintf('  ✗ %s (缺失)\n', required_files{i});
        end
    end
    
    rethrow(ME);
end

end