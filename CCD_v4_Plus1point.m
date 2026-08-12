% =========================================================================
% Назва файлу: CCD_v4_Combined.m
% Опис: Пакетна обробка поляризаційних даних з розрахунком як КЛАСИЧНИХ 
%       (одноточкових), так і УЗАГАЛЬНЕНИХ (контрастних) параметрів.
%       Генерує об'єднані картинки 1x3 для прямого порівняння.
% =========================================================================

clc; close all;
disp('Початок обробки: CCD_v4_Combined...');

% 1. Налаштування шляхів збереження
base_path ='D:\MyDoc\Programming\mathematik\MyProg\UshenkoOG\2025\temp'; % Зберігати в поточну папку (можете змінити на свій шлях)
main_folder_name = 'Results_Combined_1_Noise_G';

% 2. Визначення діапазонів фаз для обробки
phase_ranges = [
    0, 2*pi, "0_2pi";
%     0, 2*pi - 1*pi/10, "0_2pi_minus_1pi_10";
%     0, 2*pi - 2*pi/10, "0_2pi_minus_2pi_10";
%     0, 2*pi - 3*pi/10, "0_2pi_minus_3pi_10";
%     0, 2*pi - 4*pi/10, "0_2pi_minus_4pi_10";
%     0, 2*pi - 5*pi/10, "0_2pi_minus_5pi_10";
];

polarization_sets = {'0', '90', '45', '135', 'prav', 'liv'};

% 3. Головний цикл по діапазонах фаз
for range_idx = 1:size(phase_ranges, 1)
    p_min = str2double(phase_ranges(range_idx, 1));
    p_max = str2double(phase_ranges(range_idx, 2));
    range_label = phase_ranges(range_idx, 3);
    
    % Створення папки для поточного діапазону
    out_dir = fullfile(base_path, main_folder_name, range_label);
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    
    fprintf('\nОбробка діапазону: %s (%.2f - %.2f)\n', range_label, p_min, p_max);
    
    % --- ДОДАНО: Єдиний розрахунок nearest_coords на основі стану 0° ---
    % Беремо дані для 0 градусів
    ex_0_base = evalin('base', 'ex_0'); 
    ey_0_base = evalin('base', 'ey_0');
    % Фільтруємо їх
    [ex_0_f, ey_0_f] = filter_by_phase_range(ex_0_base, ey_0_base, p_min, p_max);
    % Рахуємо амплітуду та координати
    amp_total_0 = sqrt(abs(ex_0_f).^2 + abs(ey_0_f).^2);
    % Використовуємо 'first_non_nan' як в оригінальному CCD_v4
    nearest_coords = find_contrast_nearest_neighbors(amp_total_0, 'first_non_nan');
    % ---------------------------------------------------------------------

    % Цикл по 6 базових станах поляризації
    for set_idx = 1:length(polarization_sets)
        state_name = polarization_sets{set_idx};
        fprintf('  Аналіз стану: %s...\n', state_name);
        
        % Вибір відповідних вхідних матриць (які мають бути в Workspace)
        switch state_name
            case '0'
                ex = evalin('base', 'ex_0'); ey = evalin('base', 'ey_0');
            case '90'
                ex = evalin('base', 'ex_90'); ey = evalin('base', 'ey_90');
            case '45'
                ex = evalin('base', 'ex_45'); ey = evalin('base', 'ey_45');
            case '135'
                ex = evalin('base', 'ex_135'); ey = evalin('base', 'ey_135');
            case 'prav'
                ex = evalin('base', 'ex_prav'); ey = evalin('base', 'ey_prav');
            case 'liv'
                ex = evalin('base', 'ex_liv'); ey = evalin('base', 'ey_liv');
        end
        
        % --- КРОК А: Фільтрація фази ---
        [ex_f, ey_f] = filter_by_phase_range(ex, ey, p_min, p_max);
        
        % --- КРОК Б: Розрахунок КЛАСИЧНИХ параметрів (в 1 точці) ---
        [alpha_cl, beta_cl] = get_classical_polarization(ex_f, ey_f);
        
        % --- КРОК В: Розрахунок КОНТРАСТНИХ параметрів ---ще.
        [~, alpha_gen, beta_gen] = analyze_polarization_contrast(ex_f, ey_f, false, nearest_coords);

        % =================================================================
        % ЗБЕРЕЖЕННЯ ТА ВІЗУАЛІЗАЦІЯ ДЛЯ АЗИМУТА (ALPHA)
        % =================================================================
        % Збереження MAT файлів
%         save(fullfile(out_dir, sprintf('alpha_%s_classical.mat', state_name)), 'alpha_cl');
        alpha_gen_mod = real(alpha_gen(:,:,1));
        alpha_gen_arg = real(alpha_gen(:,:,2));
%         save(fullfile(out_dir, sprintf('alpha_%s_contrast_module.mat', state_name)), 'alpha_gen_mod');
%         save(fullfile(out_dir, sprintf('alpha_%s_contrast_arg.mat', state_name)), 'alpha_gen_arg');
        
        % Малювання 1x3 графіка для Alpha
        fig_alpha = figure('Visible', 'off', 'Position', [100 100 1500 400]);
        
        subplot(1,3,1); imagesc(alpha_cl); axis image off; colorbar; colormap(gca, 'jet');
        title(sprintf('Класичний Азимут (\\alpha)\nСтан: %s', state_name));
        
        subplot(1,3,2); imagesc(alpha_gen_mod); axis image off; colorbar; colormap(gca, 'jet');
        title(sprintf('Контрастний Азимут [Модуль]\nСтан: %s', state_name));
        
        subplot(1,3,3); imagesc(alpha_gen_arg); axis image off; colorbar; colormap(gca, 'jet');
        title(sprintf('Контрастний Азимут [Аргумент]\nСтан: %s', state_name));
        
        saveas(fig_alpha, fullfile(out_dir, sprintf('Alpha_Combined_%s.png', state_name)));
        close(fig_alpha);
        
        % =================================================================
        % ЗБЕРЕЖЕННЯ ТА ВІЗУАЛІЗАЦІЯ ДЛЯ ЕЛІПТИЧНОСТІ (BETA)
        % =================================================================
        % Збереження MAT файлів
%         save(fullfile(out_dir, sprintf('beta_%s_classical.mat', state_name)), 'beta_cl');
        beta_gen_mod = real(beta_gen(:,:,1));
        beta_gen_arg = real(beta_gen(:,:,2));
%         save(fullfile(out_dir, sprintf('beta_%s_contrast_module.mat', state_name)), 'beta_gen_mod');
%         save(fullfile(out_dir, sprintf('beta_%s_contrast_arg.mat', state_name)), 'beta_gen_arg');
        
        % Малювання 1x3 графіка для Beta
        fig_beta = figure('Visible', 'off', 'Position', [100 100 1500 400]);
        
        subplot(1,3,1); imagesc(beta_cl); axis image off; colorbar; colormap(gca, 'jet');
        title(sprintf('Класична Еліптичність (\\beta)\nСтан: %s', state_name));
        
        subplot(1,3,2); imagesc(beta_gen_mod); axis image off; colorbar; colormap(gca, 'jet');
        title(sprintf('Контрастна Еліптичність [Модуль]\nСтан: %s', state_name));
        
        subplot(1,3,3); imagesc(beta_gen_arg); axis image off; colorbar; colormap(gca, 'jet');
        title(sprintf('Контрастна Еліптичність [Аргумент]\nСтан: %s', state_name));
        
        saveas(fig_beta, fullfile(out_dir, sprintf('Beta_Combined_%s.png', state_name)));
        close(fig_beta);
    end
end
disp('Обробка успішно завершена! Перевірте папку Results_Combined.');

% =========================================================================
% ЛОКАЛЬНА ФУНКЦІЯ: Розрахунок класичних параметрів Стокса (одноточкових)
% =========================================================================
function [alpha_cl, beta_cl] = get_classical_polarization(ex, ey)
    % Розрахунок інтенсивностей (кореляція поля з самим собою)
    Wxx = abs(ex).^2;
    Wyy = abs(ey).^2;
    Wxy = conj(ex) .* ey;
    Wyx = conj(ey) .* ex;

    % Класичні параметри Стокса
    S1 = Wxx + Wyy;
    S2 = Wxx - Wyy;
    S3 = real(Wxy + Wyx);
    S4 = real(1i * (Wyx - Wxy));

    % Класичний Азимут (-pi/2 до pi/2)
    alpha_cl = 0.5 * atan2(S3, S2);

    % Класична Еліптичність (-pi/4 до pi/4)
    % Захист від ділення на нуль (шуму порожнього фону)
    S1_safe = S1;
    S1_safe(S1 == 0) = eps; 
    
    % Розрахунок із захистом виходу за межі [-1, 1] через похибки округлення
    beta_cl = 0.5 * asin(max(min(S4 ./ S1_safe, 1), -1)); 
end