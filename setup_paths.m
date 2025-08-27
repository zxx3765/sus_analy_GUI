function setup_paths(interactive)
%% 悬架分析项目路径设置
% 此函数自动添加项目所需的所有路径到MATLAB搜索路径中
% 请在使用项目功能前运行此函数
%
% 输入参数:
%   interactive - 是否显示交互式选项 (默认: true)

if nargin < 1
    interactive = true;
end

if interactive
    fprintf('正在设置悬架分析项目路径...\n');
end

% 获取项目根目录
project_root = fileparts(mfilename('fullpath'));

% 定义需要添加的路径
paths_to_add = {
    project_root;                                    % 根目录
    fullfile(project_root, 'src', 'models');        % 模型文件
    fullfile(project_root, 'src', 'analysis', 'core');      % 核心分析工具
    fullfile(project_root, 'src', 'analysis', 'plotting');  % 绘图函数
    fullfile(project_root, 'src', 'analysis', 'legacy');    % 原有绘图函数
    fullfile(project_root, 'src', 'scripts');       % 用户脚本
    fullfile(project_root, 'src', 'gui');           % GUI界面
    fullfile(project_root, 'tools');                % 诊断工具 (新增)
    fullfile(project_root, 'docs');                 % 文档和示例
    fullfile(project_root, 'tests');                % 测试脚本
};

% 添加路径
for i = 1:length(paths_to_add)
    if exist(paths_to_add{i}, 'dir')
        addpath(paths_to_add{i});
        if interactive
            fprintf('  ✓ 已添加: %s\n', paths_to_add{i});
        end
    else
        if interactive
            fprintf('  ⚠ 路径不存在: %s\n', paths_to_add{i});
        end
    end
end

if interactive
    fprintf('\n路径设置完成！现在可以使用所有项目功能。\n');
    fprintf('\n快速开始:\n');
    fprintf('  1. 启动GUI: launch_gui 或 suspension_analysis_gui\n');
    fprintf('  2. 运行测试: test_optimized_tools\n');
    fprintf('  3. 分析数据: analysis_half_v2\n');
    fprintf('  4. 查看示例: example_usage\n\n');

    % 保存路径（可选）
    save_paths = input('是否保存路径设置到MATLAB配置？(y/n): ', 's');
    if strcmpi(save_paths, 'y') || strcmpi(save_paths, 'yes')
        savepath;
        fprintf('路径设置已保存，下次启动MATLAB时自动生效。\n');
    end
end

end