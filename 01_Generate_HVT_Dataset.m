%% ========================================================================
% HYBRID LEARNING AND MULTI-STRUCTURE ANALYSIS OF HARMONIC CHARACTERISTICS
% AND VIBRATION PROPERTIES IN HIGH-VOLTAGE TRANSFORMERS (150 KVA)
% =========================================================================
% Dataset Generation Script
% Generates synthetic but realistic transformer condition monitoring data
% =========================================================================

clear all; close all; clc;

%% 1. TRANSFORMER SPECIFICATIONS
fprintf('========== TRANSFORMER DATASET GENERATION (150 KVA) ==========\n');
fprintf('Step 1: Defining Transformer Specifications...\n\n');

% Transformer Parameters
transformer.rating = 150; % kVA
transformer.primary_voltage = 11; % kV
transformer.secondary_voltage = 0.4; % kV
transformer.frequency = 50; % Hz
transformer.rated_current_primary = transformer.rating * 1000 / (transformer.primary_voltage * 1000); % A
transformer.rated_current_secondary = transformer.rating * 1000 / (transformer.secondary_voltage * 1000); % A
transformer.core_type = 'Laminated Core';
transformer.cooling_type = 'ONAN';
transformer.impedance = 5.5; % %

fprintf('Transformer Rating: %d kVA\n', transformer.rating);
fprintf('Primary Voltage: %d kV\n', transformer.primary_voltage);
fprintf('Secondary Voltage: %.1f kV\n', transformer.secondary_voltage);
fprintf('Operating Frequency: %d Hz\n', transformer.frequency);
fprintf('Rated Current (Primary): %.2f A\n', transformer.rated_current_primary);
fprintf('Rated Current (Secondary): %.2f A\n', transformer.rated_current_secondary);
fprintf('Core Type: %s\n', transformer.core_type);
fprintf('Cooling Type: %s\n\n', transformer.cooling_type);

%% 2. DATASET CONFIGURATION
fprintf('Step 2: Configuring Dataset Parameters...\n\n');

% Dataset size
num_samples = 5000; % Total samples
fs = 10000; % Sampling frequency (Hz)
duration = 1; % Duration of each measurement (seconds)
samples_per_record = fs * duration;

% Fault conditions
fault_labels = {
    'Healthy',
    'Winding_Short_Circuit',
    'Core_Damage',
    'Insulation_Degradation',
    'Overheating',
    'Mechanical_Looseness',
    'Resonance_Condition'
};

num_faults = length(fault_labels);
samples_per_fault = floor(num_samples / num_faults);

% Harmonic orders to analyze
harmonic_orders = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25];
num_harmonics = length(harmonic_orders);

% Vibration measurement locations
vibration_locations = {
    'Core_Vibration',
    'Tank_Vibration',
    'Winding_Vibration',
    'Bushing_Vibration'
};
num_vibration_channels = length(vibration_locations);

fprintf('Dataset Size: %d samples\n', num_samples);
fprintf('Sampling Frequency: %d Hz\n', fs);
fprintf('Record Duration: %d second(s)\n', duration);
fprintf('Number of Harmonic Orders: %d\n', num_harmonics);
fprintf('Harmonic Orders: %s\n', mat2str(harmonic_orders));
fprintf('Vibration Measurement Locations: %s\n\n', strjoin(vibration_locations, ', '));

%% 3. FEATURE EXTRACTION PARAMETERS
fprintf('Step 3: Defining Feature Extraction Parameters...\n\n');

% Harmonic Features: Magnitude and Phase
num_harmonic_features = num_harmonics * 2; % Magnitude + Phase for each harmonic

% Vibration Features: Statistical features for each channel
vibration_features_per_channel = 8; % RMS, Peak, Crest Factor, Skewness, Kurtosis, Mean, Std, Energy
num_vibration_features = num_vibration_channels * vibration_features_per_channel;

% Temperature and Other Parameters
num_misc_features = 5; % Winding Temp, Oil Temp, Load%, THD, Impedance

total_features = num_harmonic_features + num_vibration_features + num_misc_features;

fprintf('Harmonic Features: %d (Magnitude + Phase for %d harmonics)\n', num_harmonic_features, num_harmonics);
fprintf('Vibration Features: %d (%d channels × %d features/channel)\n', num_vibration_features, num_vibration_channels, vibration_features_per_channel);
fprintf('Miscellaneous Features: %d\n', num_misc_features);
fprintf('Total Features: %d\n\n', total_features);

%% 4. INITIALIZE DATA STORAGE
fprintf('Step 4: Initializing Data Storage...\n\n');

% Preallocate arrays
X_data = zeros(num_samples, total_features);
y_labels = zeros(num_samples, 1);
fault_names = {};
record_info = table();

feature_names = {};
idx = 1;

% Harmonic feature names
for h = 1:num_harmonics
    feature_names{idx} = sprintf('H%d_Magnitude', harmonic_orders(h));
    idx = idx + 1;
end
for h = 1:num_harmonics
    feature_names{idx} = sprintf('H%d_Phase', harmonic_orders(h));
    idx = idx + 1;
end

% Vibration feature names
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_RMS', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_Peak', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_CrestFactor', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_Skewness', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_Kurtosis', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_Mean', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_Std', vibration_locations{c});
    idx = idx + 1;
end
for c = 1:num_vibration_channels
    feature_names{idx} = sprintf('%s_Energy', vibration_locations{c});
    idx = idx + 1;
end

% Miscellaneous feature names
feature_names{idx} = 'Winding_Temperature'; idx = idx + 1;
feature_names{idx} = 'Oil_Temperature'; idx = idx + 1;
feature_names{idx} = 'Load_Percentage'; idx = idx + 1;
feature_names{idx} = 'THD_Percentage'; idx = idx + 1;
feature_names{idx} = 'Impedance_Percentage'; idx = idx + 1;

fprintf('Feature names defined: %d features\n\n', length(feature_names));

%% 5. GENERATE SYNTHETIC DATA
fprintf('Step 5: Generating Synthetic Transformer Condition Data...\n\n');

sample_idx = 1;
rng(42); % For reproducibility

for fault_idx = 1:num_faults
    fprintf('Generating %s condition data... ', fault_labels{fault_idx});
    
    for sample = 1:samples_per_fault
        % ===== HARMONIC FEATURES =====
        % Fundamental (50 Hz)
        fundamental_magnitude = 100 * (0.8 + 0.2*rand()); % Varies with load
        fundamental_phase = 2*pi*rand();
        
        % Generate harmonics based on fault condition
        switch fault_idx
            case 1 % Healthy
                % Low THD, primarily odd harmonics
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.5 .* (0.5 + 0.3*rand(1, num_harmonics));
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 5 + 2*rand(); % Low THD
                
            case 2 % Winding Short Circuit
                % Increased high-frequency content
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.2 .* (0.8 + 0.5*rand(1, num_harmonics));
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 15 + 5*rand(); % Moderate-High THD
                
            case 3 % Core Damage
                % Increased 3rd and 5th harmonics
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.3 .* (1.0 + 0.6*rand(1, num_harmonics));
                harmonic_magnitudes([2, 3]) = harmonic_magnitudes([2, 3]) * 2; % 3rd and 5th harmonics
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 18 + 6*rand();
                
            case 4 % Insulation Degradation
                % Increased odd harmonics especially higher orders
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.1 .* (0.9 + 0.5*rand(1, num_harmonics));
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 20 + 7*rand();
                
            case 5 % Overheating
                % Moderate harmonic distortion
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.4 .* (0.7 + 0.4*rand(1, num_harmonics));
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 12 + 4*rand();
                
            case 6 % Mechanical Looseness
                % Increased even harmonics
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.3 .* (0.8 + 0.4*rand(1, num_harmonics));
                harmonic_magnitudes(1:2:end) = harmonic_magnitudes(1:2:end) * 1.5; % Even harmonics
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 14 + 5*rand();
                
            case 7 % Resonance Condition
                % Very high specific harmonics
                harmonic_magnitudes = fundamental_magnitude ./ harmonic_orders.^1.2 .* (1.2 + 0.7*rand(1, num_harmonics));
                harmonic_magnitudes([5, 7]) = harmonic_magnitudes([5, 7]) * 3; % Resonant harmonics
                harmonic_phases = 2*pi*rand(1, num_harmonics);
                thd = 25 + 8*rand();
        end
        
        % ===== VIBRATION FEATURES =====
        % Generate vibration signals for each location
        vibration_data = [];
        
        for ch = 1:num_vibration_channels
            % Create base vibration signal
            t = linspace(0, duration, samples_per_record);
            
            % Base acceleration (m/s²)
            base_acceleration = 0.5 * sin(2*pi*50*t); % 50 Hz fundamental
            
            % Add harmonics to vibration
            for h = 2:num_harmonics
                base_acceleration = base_acceleration + (harmonic_magnitudes(h)/100) * sin(2*pi*harmonic_orders(h)*50*t);
            end
            
            % Add noise
            noise = 0.05 * randn(1, samples_per_record);
            signal = base_acceleration + noise;
            
            % Fault-specific vibration modulation
            switch fault_idx
                case 1 % Healthy - low vibration
                    signal = signal * 0.3;
                case 2 % Winding Short Circuit - high frequency content
                    signal = signal * 1.5 + 0.3 * sin(2*pi*500*t);
                case 3 % Core Damage - increased vibration
                    signal = signal * 2.0;
                case 4 % Insulation Degradation - moderate increase
                    signal = signal * 1.3;
                case 5 % Overheating - slight increase
                    signal = signal * 0.8;
                case 6 % Mechanical Looseness - impulsive vibration
                    impulses = zeros(1, samples_per_record);
                    impulse_positions = sort(randperm(samples_per_record, 50));
                    impulses(impulse_positions) = 5;
                    signal = signal * 1.2 + impulses;
                case 7 % Resonance - large amplitude
                    signal = signal * 2.5;
            end
            
            vibration_data = [vibration_data; signal];
        end
        
        % Extract vibration features
        vib_features = [];
        for ch = 1:num_vibration_channels
            vib_signal = vibration_data(ch, :);
            
            % RMS
            rms_val = sqrt(mean(vib_signal.^2));
            
            % Peak
            peak_val = max(abs(vib_signal));
            
            % Crest Factor
            crest_factor = peak_val / (rms_val + eps);
            
            % Skewness
            skewness_val = skewness(vib_signal);
            
            % Kurtosis
            kurtosis_val = kurtosis(vib_signal);
            
            % Mean
            mean_val = mean(vib_signal);
            
            % Standard Deviation
            std_val = std(vib_signal);
            
            % Energy
            energy_val = sum(vib_signal.^2);
            
            vib_features = [vib_features, rms_val, peak_val, crest_factor, skewness_val, kurtosis_val, mean_val, std_val, energy_val];
        end
        
        % ===== MISC FEATURES =====
        winding_temp = 50 + (fault_idx - 1) * 5 + 10*rand(); % Increases with fault severity
        oil_temp = 40 + (fault_idx - 1) * 4 + 8*rand();
        load_percentage = 50 + 30*rand();
        impedance_percentage = transformer.impedance + 0.5*rand();
        
        % ===== ASSEMBLE FEATURE VECTOR =====
        feature_vector = [...
            harmonic_magnitudes, ...       % Harmonic magnitudes
            harmonic_phases, ...           % Harmonic phases
            vib_features, ...              % Vibration features
            winding_temp, ...              % Winding temperature
            oil_temp, ...                  % Oil temperature
            load_percentage, ...           % Load percentage
            thd, ...                       % THD
            impedance_percentage           % Impedance
        ];
        
        % Store data
        X_data(sample_idx, :) = feature_vector;
        y_labels(sample_idx) = fault_idx;
        fault_names{sample_idx} = fault_labels{fault_idx};
        
        sample_idx = sample_idx + 1;
    end
    
    fprintf('[Complete]\n');
end

fprintf('\nDataset generation complete!\n');
fprintf('Total samples: %d\n', size(X_data, 1));
fprintf('Total features: %d\n', size(X_data, 2));

%% 6. SAVE DATASET
fprintf('\nStep 6: Saving Dataset...\n\n');

% Create dataset structure
dataset.X = X_data;
dataset.y = y_labels;
dataset.feature_names = feature_names;
dataset.fault_labels = fault_labels;
dataset.fault_names = fault_names;
dataset.harmonic_orders = harmonic_orders;
dataset.vibration_locations = vibration_locations;
dataset.transformer_specs = transformer;
dataset.num_samples = num_samples;
dataset.num_features = total_features;
dataset.num_faults = num_faults;

% Create directory if it doesn't exist
if ~exist('data', 'dir')
    mkdir('data');
end

% Save dataset
save('data/HVT_150KVA_Dataset.mat', 'dataset', 'X_data', 'y_labels', 'feature_names', 'fault_labels');

fprintf('Dataset saved to: data/HVT_150KVA_Dataset.mat\n');
fprintf('Dataset structure variables:\n');
fprintf('  - X_data: [%d × %d] feature matrix\n', size(X_data, 1), size(X_data, 2));
fprintf('  - y_labels: [%d × 1] label vector\n', size(y_labels, 1));
fprintf('  - feature_names: cell array of %d feature names\n', length(feature_names));
fprintf('  - fault_labels: cell array of %d fault types\n', length(fault_labels));

%% 7. DISPLAY DATASET SUMMARY
fprintf('\n========== DATASET SUMMARY ==========\n');
fprintf('Fault Class Distribution:\n');
for f = 1:num_faults
    count = sum(y_labels == f);
    percentage = (count / num_samples) * 100;
    fprintf('  %s: %d samples (%.1f%%)\n', fault_labels{f}, count, percentage);
end

fprintf('\n========== DATASET GENERATION COMPLETE ==========\n');

% Return to workspace
clear sample_idx samples_per_fault idx sample ch h t signal base_acceleration noise impulses impulse_positions;
