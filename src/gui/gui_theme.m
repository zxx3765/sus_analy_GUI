function theme = gui_theme()
%% GUI_THEME 统一界面视觉主题
% 集中维护颜色与字体，供主页面、批量页面和弹窗共同使用。

theme = struct();
theme.font = 'Microsoft YaHei UI';
theme.monoFont = 'Consolas';

theme.canvas = [0.945, 0.957, 0.976];
theme.surface = [1.000, 1.000, 1.000];
theme.surfaceAlt = [0.965, 0.975, 0.990];
theme.input = [0.995, 0.998, 1.000];

theme.primary = [0.105, 0.255, 0.475];
theme.primaryHover = [0.125, 0.335, 0.650];
theme.primarySoft = [0.885, 0.925, 0.975];
theme.primarySoftText = [0.765, 0.850, 0.960];
theme.onPrimary = [1.000, 1.000, 1.000];

theme.accent = [0.040, 0.535, 0.545];
theme.success = [0.105, 0.505, 0.315];
theme.successSoft = [0.900, 0.965, 0.925];
theme.warning = [0.855, 0.485, 0.115];
theme.danger = [0.725, 0.205, 0.245];
theme.dangerSoft = [0.985, 0.915, 0.925];

theme.text = [0.105, 0.145, 0.205];
theme.mutedText = [0.390, 0.445, 0.530];
theme.border = [0.785, 0.825, 0.885];

theme.console = [0.035, 0.055, 0.075];
theme.consoleText = [0.350, 0.900, 0.650];
end
