% Inspect MultiSine_0A.mat structure
input_file = 'D:\Project\SynologyDrive\analysis_GUI\HILData\HILData0525\MultiSine_0A.mat';

fprintf('Loading file: %s\n', input_file);
data = load(input_file);

var_names = fieldnames(data);
fprintf('\nFound %d variables:\n', length(var_names));
fprintf('================================\n');

for i = 1:length(var_names)
    var = data.(var_names{i});
    fprintf('%d. %s\n', i, var_names{i});
    fprintf('   Size: %s\n', mat2str(size(var)));
    fprintf('   Class: %s\n', class(var));

    if isnumeric(var) && ~isempty(var)
        fprintf('   Range: [%.6f, %.6f]\n', min(var(:)), max(var(:)));
    end
    fprintf('\n');
end
