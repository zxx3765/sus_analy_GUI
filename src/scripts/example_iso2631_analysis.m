%% ISO2631-1加权RMS分析示例
% 演示如何使用ISO2631-1加权RMS计算功能

clear; clc;

% 添加路径
setup_paths(false);

%% 1. 生成示例数据（或加载实际数据）
fs = 100; % 采样频率 100Hz
t = 0:1/fs:10; % 10秒数据
t = t(:);

% 模拟车身垂直加速度信号
f1 = 2; % 2Hz主频
f2 = 8; % 8Hz次频
signal1 = 0.5*sin(2*pi*f1*t) + 0.3*sin(2*pi*f2*t) + 0.1*randn(size(t));

% 模拟另一个加速度信号
signal2 = 0.6*sin(2*pi*f1*t) + 0.2*sin(2*pi*f2*t) + 0.15*randn(size(t));

sig_mat = [signal1, signal2];
labels = {'车身垂直加速度', '座椅垂直加速度'};

%% 2. 配置参数
config.language = 'cn';

%% 3. 计算ISO2631-1加权RMS
[weighted_rms, original_rms] = calculate_weighted_rms_iso2631(sig_mat, t, config);

%% 4. 显示结果
fprintf('\n========== ISO2631-1分析结果 ==========\n');
for i = 1:length(labels)
    fprintf('%s:\n', labels{i});
    fprintf('  原始RMS: %.4f m/s²\n', original_rms(i));
    fprintf('  加权RMS: %.4f m/s²\n', weighted_rms(i));
    fprintf('  舒适度评价: %s\n', evaluate_comfort(weighted_rms(i)));
end

%% 5. 绘制对比图
plot_weighted_rms_comparison_iso2631(weighted_rms, original_rms, labels, config);

%% 辅助函数：舒适度评价
function comfort_level = evaluate_comfort(awrms)
    % 根据ISO2631-1标准评价舒适度
    if awrms < 0.315
        comfort_level = '舒适';
    elseif awrms < 0.63
        comfort_level = '较舒适';
    elseif awrms < 1.0
        comfort_level = '不太舒适';
    elseif awrms < 1.6
        comfort_level = '不舒适';
    else
        comfort_level = '极不舒适';
    end
end
