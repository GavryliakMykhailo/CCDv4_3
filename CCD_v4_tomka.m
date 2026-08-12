% Визначення діапазонів фаз для обробки

% 1. Налаштування
N = 30; % Задаємо бажану кількість кроків

start_phase = 0;
end_phase_max = 2*pi;
end_phase_min = pi/2; % Кінцева точка, до якої ми "стискаємо" діапазон

% 2. Розрахунок кроку
step_size = (end_phase_max - end_phase_min) / N;

% 3. Генерація діапазонів
phase_ranges = [];

for i = 0:N
    current_end_phase = end_phase_max - i * step_size;
    
    if i == 0
        label = "0_2pi";
    else
        label = sprintf("0_2pi_minus_%dsteps", i);
    end
    
    % Додаємо рядок до масиву
    phase_ranges = [phase_ranges; 
        start_phase, current_end_phase, label];
end

base_path = 'D:\MyDoc\Programming\mathematik\MyProg\UshenkoOG\2025\MikeData\Міокард-20250909T093120Z-1-001\Міокард\2';
folder_name = 'Results_10_30_tomka';

for range_idx = 1:size(phase_ranges, 1)
    phase_min = eval(phase_ranges(range_idx, 1));
    phase_max = eval(phase_ranges(range_idx, 2));
    range_name = phase_ranges(range_idx, 3);
    
    % Створення імені папки з діапазоном фаз
    folder_suffix = sprintf('phase_range_%s', range_name);
    folderName = fullfile(base_path, folder_name, folder_suffix);
    
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
    
    % Визначаємо розмір обрізаної області
    crop_size = 300;

    % Обрізаємо всі масиви з початку
    filtered_ex_0 = filtered_ex_0(1:crop_size, 1:crop_size);
    filtered_ey_0 = filtered_ey_0(1:crop_size, 1:crop_size);
    filtered_ex_90 = filtered_ex_90(1:crop_size, 1:crop_size);
    filtered_ey_90 = filtered_ey_90(1:crop_size, 1:crop_size);
    filtered_ex_45 = filtered_ex_45(1:crop_size, 1:crop_size);
    filtered_ey_45 = filtered_ey_45(1:crop_size, 1:crop_size);
    filtered_ex_135 = filtered_ex_135(1:crop_size, 1:crop_size);
    filtered_ey_135 = filtered_ey_135(1:crop_size, 1:crop_size);
    filtered_ex_prav = filtered_ex_prav(1:crop_size, 1:crop_size);
    filtered_ey_prav = filtered_ey_prav(1:crop_size, 1:crop_size);
    filtered_ex_liv = filtered_ex_liv(1:crop_size, 1:crop_size);
    filtered_ey_liv = filtered_ey_liv(1:crop_size, 1:crop_size);
    
    
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
    
    % Збереження елементів матриці Мюллера (амплітуда і фаза окремо)
    for i = 1:4
        for j = 1:4
            r_ij = r(:,:,i,j);
            if (i == 1 && j == 2) || (i == 2 && j == 3) || (i == 1 && j == 4) || (i == 2 && j == 4)
                % Амплітуда
                r_amp = abs(r_ij);
                save(fullfile(folderName, sprintf('r_%d%d_amplitude.mat', i, j)), 'r_amp');
                
                % Фаза
                r_phase = angle(r_ij);
                save(fullfile(folderName, sprintf('r_%d%d_phase.mat', i, j)), 'r_phase');
                
                % Зображення
                fig = figure('Visible', 'off', 'Position', [100 100 1000 400]);
                
                subplot(1, 2, 1);
                imagesc(r_amp);
                axis image off;
                colorbar;
                title(sprintf('Amplitude |r_{%d%d}|', i, j));
                
                subplot(1, 2, 2);
                imagesc(r_phase);
                axis image off;
                colorbar;
                title(sprintf('Phase angle(r_{%d%d})', i, j));
                
                filename = fullfile(folderName, sprintf('r_%d%d.png', i, j));
                saveas(fig, filename);
                close(fig);
            end
        end
    end
    
    % Збереження параметрів азимута та еліптичності
    polarization_params = {'alpha', 'beta'};
    polarization_sets = {'0', '45'};
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
            
            % Збереження даних окремо для модуля та аргументу
            % Модуль (дійсна частина)
            data_module = real(current_data(:,:,1));
            save(fullfile(folderName, sprintf('%s_%s_module.mat', param_name, set_name)), 'data_module');
            
            % Аргумент (уявна частина)
            data_argument = real(current_data(:,:,2));
            save(fullfile(folderName, sprintf('%s_%s_argument.mat', param_name, set_name)), 'data_argument');
            
            % Зображення
            fig = figure('Visible', 'off', 'Position', [100 100 1000 400]);
            
            subplot(1,2,1);
            imagesc(data_module);
            axis image off;
            colorbar;
            title(sprintf('%s %s: Real(Module)', param_name, set_name));
            
            subplot(1,2,2);
            imagesc(data_argument);
            axis image off;
            colorbar;
            title(sprintf('%s %s: Imag(Argument)', param_name, set_name));
            
            saveas(fig, fullfile(folderName, sprintf('%s_%s.png', param_name, set_name)));
            close(fig);
        end
    end
    
    disp(['Оброблено діапазон фаз: ' num2str(phase_min) ' до ' num2str(phase_max)]);
    disp(['Результати збережено у: ' folderName]);
end
disp('Все успішно завершено');