function nearest_coords = find_contrast_nearest_neighbors(amp_total, mode, step)
    % Перевірка режиму за замовчуванням (якщо передано лише 1 аргумент)
    if nargin < 2 || isempty(mode)
        mode = "full";
    end

    [M, N] = size(amp_total);
    nearest_coords = NaN(M, N, 2); % Ініціалізація матриці координат [y, x]

    switch mode
        case "row_step"
            % Якщо для цього режиму крок не задано, ставимо 1 за замовчуванням
            if nargin < 3 || isempty(step)
                step = 1;
            end
            
            % Координата Y (рядок) залишається незмінною
            nearest_coords(:,:,1) = repmat((1:M)', 1, N);
            
            % Координата X (стовпчик) зміщується на величину step
            X_indices = repmat(1:N, M, 1);
            target_X = X_indices + step;
            
            % Перевірка виходу за межі матриці
            valid_mask = (target_X >= 1) & (target_X <= N);
            
            % Запис координат X та занулення (у NaN) виходів за межі
            nearest_coords(:,:,2) = target_X;
            nearest_coords(~repmat(valid_mask, [1, 1, 2])) = NaN;

        case "col_step"
            % Зміщення по вертикалі (аналогічно row_step, але по колонам)
            % Якщо для цього режиму крок не задано, ставимо 1 за замовчуванням
            if nargin < 3 || isempty(step)
                step = 1;
            end
            
            % Координата X (стовпчик) залишається незмінною
            nearest_coords(:,:,2) = repmat(1:N, M, 1);
            
            % Координата Y (рядок) зміщується на величину step
            Y_indices = repmat((1:M)', 1, N);
            target_Y = Y_indices + step;
            
            % Перевірка виходу за межі матриці
            valid_mask = (target_Y >= 1) & (target_Y <= M);
            
            % Запис координат Y та занулення (у NaN) виходів за межі
            nearest_coords(:,:,1) = target_Y;
            nearest_coords(~repmat(valid_mask, [1, 1, 2])) = NaN;

        case "full"
            delta_A = 1.0 * std(amp_total(:), 'omitnan');
            max_r = 50;
            out_y = NaN(M, N);
            out_x = NaN(M, N);

            for i = 1:M
                for j = 1:N
                    if isnan(amp_total(i,j)), continue; end
                    val = amp_total(i,j);
                    found = false;
                    
                    for r = 1:max_r
                        dr_i = [-r:r,  r*ones(1,2*r-1), r:-1:-r, -r*ones(1,2*r-1)];
                        dr_j = [r*ones(1,2*r), r-1:-1:-r, -r*ones(1,2*r-1), -r+1:r-1];
                        
                        for k = 1:length(dr_i)
                            ii = i + dr_i(k);
                            jj = j + dr_j(k);
                            
                            if ii >= 1 && ii <= M && jj >= 1 && jj <= N
                                if ~isnan(amp_total(ii,jj)) && abs(val - amp_total(ii,jj)) > delta_A
                                    out_y(i,j) = ii;
                                    out_x(i,j) = jj;
                                    found = true;
                                    break;
                                end
                            end
                        end
                        if found, break; end
                    end
                end
            end
            nearest_coords(:,:,1) = out_y;
            nearest_coords(:,:,2) = out_x;

        case "row_simple"
            nearest_coords(:,:,1) = repmat((1:M)', 1, N);
            nearest_coords(:,:,2) = 1;

        case "central"
            nearest_coords(:,:,1) = round(M / 2);
            nearest_coords(:,:,2) = round(N / 2);

        case "first_non_nan"
            idx = find(~isnan(amp_total), 1, 'first');
            if isempty(idx)
                warning('Не знайдено жодної не-NaN точки в amp_total.');
                return;
            end
            [ref_i, ref_j] = ind2sub([M, N], idx);
            nearest_coords(:,:,1) = ref_i;
            nearest_coords(:,:,2) = ref_j;

        otherwise
            error("Unknown mode: %s", mode);
    end
end