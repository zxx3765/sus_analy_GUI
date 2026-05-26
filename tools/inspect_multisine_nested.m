% Inspect nested structure
input_file = 'D:\Project\SynologyDrive\analysis_GUI\HILData\HILData0525\MultiSine_0A.mat';

data = load(input_file);
s = data.MultiSine_0A;

fprintf('Fields in MultiSine_0A:\n');
fprintf('================================\n');

field_names = fieldnames(s);
for i = 1:length(field_names)
    field = s.(field_names{i});
    fprintf('%d. %s\n', i, field_names{i});
    fprintf('   Size: %s, Class: %s\n', mat2str(size(field)), class(field));

    if isnumeric(field) && ~isempty(field)
        fprintf('   Range: [%.6f, %.6f]\n', min(field(:)), max(field(:)));
    end
    fprintf('\n');
end
