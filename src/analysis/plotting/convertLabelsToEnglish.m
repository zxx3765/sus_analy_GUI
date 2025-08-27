function english_labels = convertLabelsToEnglish(chinese_labels)
%% 将中文标签转换为英文标签
% 预定义的中英文标签映射
label_mapping = containers.Map(...
    {'被动悬架', '主动悬架', '天棚控制', '天棚观测器', 'PID控制', 'LQR控制', '模糊控制', '神经网络'}, ...
    {'Passive', 'Active', 'Skyhook', 'Skyhook Observer', 'PID', 'LQR', 'Fuzzy', 'Neural Network'});

english_labels = chinese_labels; % 默认使用原始标签

% 尝试映射每个标签
for i = 1:length(chinese_labels)
    if isKey(label_mapping, chinese_labels{i})
        english_labels{i} = label_mapping(chinese_labels{i});
    end
end
end