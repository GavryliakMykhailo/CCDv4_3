% Визначення діапазонів фаз для обробки
phase_ranges = [
    0, 2*pi, "0_2pi";
    0, 2*pi - 1*((2*pi - pi/2)/10), "0_2pi_minus_1step";
    0, 2*pi - 2*((2*pi - pi/2)/10), "0_2pi_minus_2steps";
    0, 2*pi - 3*((2*pi - pi/2)/10), "0_2pi_minus_3steps";
    0, 2*pi - 4*((2*pi - pi/2)/10), "0_2pi_minus_4steps";
    0, 2*pi - 5*((2*pi - pi/2)/10), "0_2pi_minus_5steps";
    0, 2*pi - 6*((2*pi - pi/2)/10), "0_2pi_minus_6steps";
    0, 2*pi - 7*((2*pi - pi/2)/10), "0_2pi_minus_7steps";
    0, 2*pi - 8*((2*pi - pi/2)/10), "0_2pi_minus_8steps";
    0, 2*pi - 9*((2*pi - pi/2)/10), "0_2pi_minus_9steps";
    0, 2*pi - 10*((2*pi - pi/2)/10), "0_2pi_minus_10steps";
    ];

base_path = 'D:\MyDoc\Programming\mathematik\MyProg\UshenkoOG\2025\MikeData\Міокард-20250909T093120Z-1-001\Міокард\2';

for range_idx = 1:size(phase_ranges, 1)
    phase_min = eval(phase_ranges(range_idx, 1));
    phase_max = eval(phase_ranges(range_idx, 2));
    range_name = phase_ranges(range_idx, 3);
    
    % Створення імені папки з діапазоном фаз
    folder_suffix = sprintf('phase_range_%s', range_name);
    folderName = fullfile(base_path, 'Results_30_10_test', folder_suffix);
    
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end
    
    % Фільтрація даних за діапазоном фаз
    [filtered_ex_0, filtered_ey_0] = filter_by_phase_range(ex_0, ey_0, phase_min, phase_max);
    [filtered_ex_90, filtered_ey_90] = filter_by_phase_range(ex_90, ey_90, phase_min, phase_max);
    [filtered_ex_45, filtered_ey_45] = filter_by_phase_range(ex_45, ey_45, phase_min, phase_max);
    [filtered_ex_135, filtered_ey_135] = filter_by_phase_range(ex_135, ey_135, phase_min, phase_max);
    [filtered_ex_prav, filtered_ey_prav] = filter_by_phase_range(ex_prav, ey_prav, phase_min, phase_max);
    [filtered_ex_liv, filtered_ey_liv] = filter_by_phase_range(ex_liv, ey_liv, phase_min, phase_max);
    
    amp_total = sqrt(abs(filtered_ex_0).^2 + abs(filtered_ey_0).^2);
    nearest_coords = find_contrast_nearest_neighbors(amp_total, 'first_non_nan');
    
    % Отримання векторів Стокса та параметрів поляризації
    [ST0, alpha0, beta0] = analyze_polarization_contrast(filtered_ex_0, filtered_ey_0, 0, nearest_coords);
    [ST90, alpha90, beta90] = analyze_polarization_contrast(filtered_ex_90, filtered_ey_90, 0, nearest_coords);
    [ST45, alpha45, beta45] = analyze_polarization_contrast(filtered_ex_45, filtered_ey_45, 0, nearest_coords);
    [ST135, alpha135, beta135] = analyze_polarization_contrast(filtered_ex_135, filtered_ey_135, 0, nearest_coords);
    [STRC, alphaRC, betaRC] = analyze_polarization_contrast(filtered_ex_prav, filtered_ey_prav, 0, nearest_coords);
    [STLC, alphaLC, betaLC] = analyze_polarization_contrast(filtered_ex_liv, filtered_ey_liv, 0, nearest_coords);
    
    % Обчислення елементів матриці Мюллера
    r = 0.5 * cat(3, ...
        cat(3, ST0(:,:,1) + ST90(:,:,1), ST0(:,:,1) - ST90(:,:,1), ST45(:,:,1) - ST135(:,:,1), STRC(:,:,1) - STLC(:,:,1)), ...
        cat(3, ST0(:,:,2) + ST90(:,:,2), ST0(:,:,2) - ST90(:,:,2), ST45(:,:,2) - ST135(:,:,2), STRC(:,:,2) - STLC(:,:,2)), ...
        cat(3, ST0(:,:,3) + ST90(:,:,3), ST0(:,:,3) - ST90(:,:,3), ST45(:,:,3) - ST135(:,:,3), STRC(:,:,3) - STLC(:,:,3)), ...
        cat(3, ST0(:,:,4) + ST90(:,:,4), ST0(:,:,4) - ST90(:,:,4), ST45(:,:,4) - ST135(:,:,4), STRC(:,:,4) - STLC(:,:,4)) ...
        );
    
    r = reshape(r, [size(ST0,1), size(ST0,2), 4, 4]);
    
    % Збереження елементів матриці Мюллера
    for i = 1:4
        for j = 1:4
            r_ij = r(:,:,i,j);
            % Аналіз ДІЙСНОЇ частини елемента матриці Мюллера
            data_real = abs(r_ij);
            filename_real = fullfile(folderName, sprintf('r_%d%d_module_analysis.png', i, j));
            create_2x2_plot_mueller(data_real, sprintf('r_{%d%d} (Module)', i, j), filename_real);
 
            % Аналіз УЯВНОЇ частини елемента матриці Мюллера
            data_imag = angle(r_ij);
            filename_imag = fullfile(folderName, sprintf('r_%d%d_arg_analysis.png', i, j));
            create_2x2_plot_mueller(data_imag, sprintf('r_{%d%d} (Arg)', i, j), filename_imag);
        end
    end
    
    % Збереження параметрів азимута та еліптичності
    polarization_params = {'alpha', 'beta'};
    polarization_sets = {'0', '90', '45', '135', 'RC', 'LC'};
    all_alphas = {alpha0, alpha90, alpha45, alpha135, alphaRC, alphaLC};
    all_betas = {beta0, beta90, beta45, beta135, betaRC, betaLC};
    
    for param_idx = 1:2
        param_name = polarization_params{param_idx};
        
        for set_idx = 1:length(polarization_sets)
            set_name = polarization_sets{set_idx};
            
            % Отримуємо дані для поточного набору
            if param_idx == 1
                current_data = all_alphas{set_idx};
            else
                current_data = all_betas{set_idx};
            end
            
            % Аналіз ДІЙСНОЇ частини модуля
            data_to_analyze_real = abs(current_data(:,:,1));
            filename_real = fullfile(folderName, sprintf('%s_%s_module_analysis.png', param_name, set_name));
            create_2x2_plot_mueller(data_to_analyze_real, sprintf('%s %s (Module)', param_name, set_name), filename_real);
            
            % Аналіз УЯВНОЇ частини модуля
            data_to_analyze_imag = angle(current_data(:,:,1));
            filename_imag = fullfile(folderName, sprintf('%s_%s_arg_analysis.png', param_name, set_name));
            create_2x2_plot_mueller(data_to_analyze_imag, sprintf('%s %s (Arg)', param_name, set_name), filename_imag);
        end
    end
    
    disp(['Оброблено діапазон фаз: ' num2str(phase_min) ' до ' num2str(phase_max)]);
    disp(['Результати збережено у: ' folderName]);
end