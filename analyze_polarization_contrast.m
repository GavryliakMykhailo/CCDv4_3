function [S, alpha, beta] = analyze_polarization_contrast(ex, ey, visualize, nearest_coords)
% ANALYZE_POLARIZATION_CONTRAST Обчислює Стоксові компоненти для
% кожної точки з урахуванням контрастної найближчої точки за амплітудою
%
% Вхід:
%   ex, ey     — комплексні матриці (M x N), компоненти поля
%   visualize  — логічний параметр: true = виводити візуалізацію
%
% Вихід:
%   S — масив розміром [M, N, 4], компоненти узагальненої матриці Стокса

    % Побудова нових масивів найближчих точок
    amp_total = sqrt(abs(ex).^2 + abs(ey).^2);
    [M, N] = size(amp_total);
    ex_nearest = NaN(size(ex));
    ey_nearest = NaN(size(ey));

    for i = 1:M
        for j = 1:N
            ii = nearest_coords(i,j,1);
            jj = nearest_coords(i,j,2);
            if ~isnan(ii) && ~isnan(jj)
                ii = round(ii);
                jj = round(jj);
                if ii >= 1 && ii <= M && jj >= 1 && jj <= N
                    ex_nearest(i,j) = ex(ii, jj);
                    ey_nearest(i,j) = ey(ii, jj);
                end
            end
        end
    end

    S = compute_stokes_components(ex, ey, ex_nearest, ey_nearest);

    % Ініціалізація масивів для азимута та еліптичності
    alpha = zeros(M, N, 2); % [модуль, аргумент]
    beta = zeros(M, N, 2);  % [модуль, аргумент]
    
    % Розрахунок азимута поляризації (формули 10,11)
    A = real(S(:,:,1)); B = imag(S(:,:,1));
    C = real(S(:,:,3)); D = imag(S(:,:,3));
    
    denominator_alpha = sqrt(A.^2 + B.^2);
    valid_alpha = denominator_alpha > 0;
    
    alpha(:,:,1) = 0.5 * atan(sqrt((C.^2 + D.^2)./(A.^2 + B.^2)));  % Обчислення модуля
    alpha(:,:,1) = alpha(:,:,1) .* valid_alpha;  % Маскування невалідних точок
    
    numerator_omega_alpha = A.*D - B.*C;
    denominator_omega_alpha = A.*C + B.*D;
    alpha(:,:,2) = 0.5 * atan2(numerator_omega_alpha, denominator_omega_alpha);
    
    % Розрахунок еліптичності поляризації (формули 14,15)
    F = real(S(:,:,4)); H = imag(S(:,:,4));
    
    denominator_beta = sqrt(A.^2 + B.^2);
    valid_beta = denominator_beta > 0;
    
    beta(:,:,1) = 0.5 * asin(sqrt((F.^2 + H.^2)./(A.^2 + B.^2)));
    beta(:,:,1) = beta(:,:,1) .* valid_beta;

    numerator_omega_beta = A.*H - B.*F;
    denominator_omega_beta = A.*F + B.*H;
    beta(:,:,2) = 0.5 * atan2(numerator_omega_beta, denominator_omega_beta);
    
    % Візуалізація, якщо дозволена
    if visualize
        step = visualize;
        [Y, Xq] = ndgrid(1:step:M, 1:step:N);
        U = zeros(size(Xq));
        V = zeros(size(Y));
        for idx = 1:numel(Xq)
            i = Y(idx);
            j = Xq(idx);
            if ~isnan(nearest_coords(i,j,1))
                ii = nearest_coords(i,j,1);
                jj = nearest_coords(i,j,2);
                V(idx) = ii - i;
                U(idx) = jj - j;
            end
        end

        figure;
        imagesc(amp_total);
        axis image;
        hold on;
        quiver(Xq, Y, U, V, 0, 'r');
        title('Напрямки до контрастних точок');
        xlabel('X'); ylabel('Y');
    end
end
