function fileName = fdei_save_config(fileName, cfg)
%FDEI_SAVE_CONFIG Save a reusable FDEI configuration MAT file.

if nargin < 2 || ~isstruct(cfg) || ~isscalar(cfg)
    error('fdei_save_config:InvalidConfig', 'cfg 必须是标量结构体。');
end
fileName = char(string(fileName));
if isempty(strtrim(fileName))
    error('fdei_save_config:InvalidFile', '配置文件路径不能为空。');
end
[folder, ~, extension] = fileparts(fileName);
if isempty(extension)
    fileName = [fileName '.mat'];
elseif ~strcmpi(extension, '.mat')
    error('fdei_save_config:InvalidExtension', 'FDEI 配置文件必须使用 .mat 扩展名。');
end
if ~isempty(folder) && exist(folder, 'dir') ~= 7
    mkdir(folder);
end

fdeiConfig = cfg; %#ok<NASGU>
fdeiConfigMetadata = struct( ... %#ok<NASGU>
    'schemaVersion', 1, ...
    'exportedAt', datestr(now, 30), ...
    'source', 'analysis_GUI');
save(fileName, 'fdeiConfig', 'fdeiConfigMetadata', '-mat');
end
