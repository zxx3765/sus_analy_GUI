function preset_config = legend_style_presets(preset_name, language)
%% 图例样式预设管理器
% 提供预定义的图例样式配置
%
% 输入参数:
%   preset_name: 预设名称
%   language: 语言设置 ('cn' 或 'en')
%
% 输出参数:
%   preset_config: 图例预设配置结构体
%
% 可用预设:
%   'default'     - 默认样式
%   'compact'     - 紧凑样式
%   'presentation'- 演示样式
%   'paper'       - 论文样式
%   'colorful'    - 彩色样式
%   'minimal'     - 极简样式

if nargin < 1
    preset_name = 'default';
end

if nargin < 2
    language = 'cn';
end

preset_config = struct();

switch lower(preset_name)
    case 'default'
        % 默认样式 - 平衡的通用设置
        preset_config.show_legend = true;
        preset_config.location = 'best';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 10;
        preset_config.font_weight = 'normal';
        preset_config.box = 'on';
        preset_config.edge_color = [0.15, 0.15, 0.15];
        preset_config.text_color = [0, 0, 0];
        preset_config.background_color = [1, 1, 1];
        preset_config.alpha = 0.9;
        preset_config.interpreter = 'none';
        preset_config.item_token_size = [30, 18];
        
    case 'compact'
        % 紧凑样式 - 节省空间
        preset_config.show_legend = true;
        preset_config.location = 'northeast';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 8;
        preset_config.font_weight = 'normal';
        preset_config.box = 'on';
        preset_config.edge_color = [0.3, 0.3, 0.3];
        preset_config.text_color = [0.2, 0.2, 0.2];
        preset_config.background_color = [0.98, 0.98, 0.98];
        preset_config.alpha = 0.85;
        preset_config.interpreter = 'none';
        preset_config.item_token_size = [20, 12];
        
    case 'presentation'
        % 演示样式 - 适合大屏幕显示
        preset_config.show_legend = true;
        preset_config.location = 'eastoutside';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 14;
        preset_config.font_weight = 'bold';
        preset_config.box = 'on';
        preset_config.edge_color = [0, 0, 0];
        preset_config.text_color = [0, 0, 0];
        preset_config.background_color = [1, 1, 1];
        preset_config.alpha = 0.95;
        preset_config.interpreter = 'none';
        preset_config.item_token_size = [40, 24];
        
    case 'paper'
        % 论文样式 - 适合学术出版
        preset_config.show_legend = true;
        preset_config.location = 'best';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 11;
        preset_config.font_weight = 'normal';
        preset_config.box = 'on';
        preset_config.edge_color = [0, 0, 0];
        preset_config.text_color = [0, 0, 0];
        preset_config.background_color = [1, 1, 1];
        preset_config.alpha = 1.0;
        preset_config.interpreter = 'tex';  % 支持数学符号
        preset_config.item_token_size = [25, 15];
        
    case 'colorful'
        % 彩色样式 - 带彩色背景
        preset_config.show_legend = true;
        preset_config.location = 'northwest';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 10;
        preset_config.font_weight = 'bold';
        preset_config.box = 'on';
        preset_config.edge_color = [0.2, 0.4, 0.8];
        preset_config.text_color = [0.1, 0.1, 0.1];
        preset_config.background_color = [0.95, 0.98, 1.0];
        preset_config.alpha = 0.9;
        preset_config.interpreter = 'none';
        preset_config.item_token_size = [32, 20];
        
    case 'minimal'
        % 极简样式 - 无边框透明背景
        preset_config.show_legend = true;
        preset_config.location = 'best';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 9;
        preset_config.font_weight = 'normal';
        preset_config.box = 'off';
        preset_config.edge_color = [1, 1, 1];
        preset_config.text_color = [0.3, 0.3, 0.3];
        preset_config.background_color = [1, 1, 1];
        preset_config.alpha = 0.7;
        preset_config.interpreter = 'none';
        preset_config.item_token_size = [25, 15];
        
    case 'hidden'
        % 隐藏图例
        preset_config.show_legend = false;
        preset_config.location = 'none';
        preset_config.orientation = 'vertical';
        preset_config.font_size = 10;
        preset_config.font_weight = 'normal';
        preset_config.box = 'off';
        preset_config.edge_color = [1, 1, 1];
        preset_config.text_color = [0, 0, 0];
        preset_config.background_color = [1, 1, 1];
        preset_config.alpha = 1.0;
        preset_config.interpreter = 'none';
        preset_config.item_token_size = [30, 18];
        
    otherwise
        warning('LEGEND:UnknownPreset', '未知的图例预设: %s，使用默认设置', preset_name);
        preset_config = legend_style_presets('default', language);
        return;
end

% 添加预设标识
preset_config.preset_name = preset_name;
preset_config.language = language;

% 根据语言设置默认位置描述
if strcmp(language, 'cn')
    preset_config.location_description = getLegendLocationDescription_CN(preset_config.location);
else
    preset_config.location_description = getLegendLocationDescription_EN(preset_config.location);
end

fprintf('  📊 应用图例预设: %s (%s)\n', preset_name, preset_config.location_description);

end

%% 辅助函数 - 中文位置描述
function desc = getLegendLocationDescription_CN(location)
    location_map = containers.Map({
        'best', 'north', 'south', 'east', 'west', ...
        'northeast', 'northwest', 'southeast', 'southwest', ...
        'northoutside', 'southoutside', 'eastoutside', 'westoutside'
    }, {
        '最佳位置', '顶部', '底部', '右侧', '左侧', ...
        '右上角', '左上角', '右下角', '左下角', ...
        '图外顶部', '图外底部', '图外右侧', '图外左侧'
    });
    
    if location_map.isKey(location)
        desc = location_map(location);
    else
        desc = location;
    end
end

%% 辅助函数 - 英文位置描述
function desc = getLegendLocationDescription_EN(location)
    location_map = containers.Map({
        'best', 'north', 'south', 'east', 'west', ...
        'northeast', 'northwest', 'southeast', 'southwest', ...
        'northoutside', 'southoutside', 'eastoutside', 'westoutside'
    }, {
        'Best', 'North', 'South', 'East', 'West', ...
        'Northeast', 'Northwest', 'Southeast', 'Southwest', ...
        'North Outside', 'South Outside', 'East Outside', 'West Outside'
    });
    
    if location_map.isKey(location)
        desc = location_map(location);
    else
        desc = location;
    end
end
