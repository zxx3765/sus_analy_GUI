# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Common Commands

### Project Initialization
```matlab
main                          % Interactive setup and launcher
setup_paths                   % Add all project paths to MATLAB
setup_paths(false)           % Non-interactive path setup
```

### GUI Applications
```matlab
launch_gui                   % Launch GUI with dependency checks
suspension_analysis_gui      % Direct GUI startup
```

### Analysis Tools
```matlab
analysis_half_v2            % Auto-detect and analyze simulation data
suspension_analysis_tool(data_sets, labels)  % Core analysis function with custom data
```

### Testing and Diagnostics
```matlab
quick_data_check           % Quick data structure verification
diagnose_data_structure    % Detailed data format diagnosis
test_data_role_mapping     % Test data role mapping functionality
```

### Data Conversion
```matlab
convert_simulink_output     % Convert Simulink.SimulationOutput to struct format
convert_your_data          % Convert specific data files (edit paths first)
```

## Code Architecture

### Core Structure
- **src/models/**: Mathematical models, state-space representations, observers
- **src/analysis/core/**: Main analysis engine and configuration management
- **src/analysis/plotting/**: Universal plotting functions with multi-language support
- **src/analysis/legacy/**: Original analysis functions for backwards compatibility
- **src/gui/**: Modular GUI components (data manager, config manager, results viewer)
- **src/scripts/**: User-facing analysis scripts
- **tools/**: Data conversion and diagnostic utilities

### Key Components

#### Analysis Engine
The core analysis is handled by `suspension_analysis_tool.m` which uses a configuration-driven approach:
- `suspension_analysis_config.m`: Defines analysis parameters for half/quarter car models
- `quick_config.m`: Provides preset configurations
- Universal plotting functions support both Chinese and English labels
- Recent features include extreme value plotting, custom plotting order, and legend control

#### GUI Architecture (Modular)
The GUI is built with a modular architecture:
- `main_gui.m`: Main interface framework
- `gui_data_manager.m`: Data import/export management
- `gui_config_manager.m`: Analysis parameter configuration
- `gui_signal_analysis.m`: Signal selection and analysis control
- `gui_results_viewer.m`: Results visualization and export
- `gui_log_viewer.m`: Analysis log display

#### Data Flow
1. Simulink models output data as either struct or `Simulink.SimulationOutput` format
2. Conversion tools normalize data to expected struct format with time vectors
3. Analysis tools process multiple datasets with configurable parameters
4. Results are saved to timestamped folders in `results/` directory

### Language Support
The system supports both Chinese (default) and English interfaces. Most functions accept a `'Language'` parameter ('cn' or 'en').

### File Naming Conventions
- Analysis scripts: `analysis_*.m`
- GUI modules: `gui_*.m`
- Universal functions: `*_universal.m` (support multiple languages)
- Legacy functions: Located in `src/analysis/legacy/`
- Control functions: `*_control.m` (legend control, style management)

### Configuration Management
Analysis behavior is controlled through configuration structs that define:
- Signal selection and processing parameters
- Plotting preferences and output formats
- Language settings and label translations
- Model-specific parameters (half vs quarter car)

### Data Requirements
Expected simulation data format:
```matlab
data_struct.signals.values    % Signal data matrix
data_struct.time             % Time vector
```

For Simulink outputs, use conversion tools in `tools/` directory to convert to this format.