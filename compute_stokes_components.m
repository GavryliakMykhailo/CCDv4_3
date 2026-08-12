function S = compute_stokes_components(ex1, ey1, ex2, ey2)
% COMPUTE_STOKES_COMPONENTS Обчислює узагальнені Стоксові параметри
% між полем та його контрастною точкою
%
% Вхід:
%   ex1, ey1 — комплексні матриці поля
%   ex2, ey2 — відповідні поля у найближчій контрастній точці
%
% Вихід:
%   S — масив [M, N, 4] з компонентами S1, S2, S3, S4

    Wxx = conj(ex1) .* ex2;
    Wyy = conj(ey1) .* ey2;
    Wxy = conj(ex1) .* ey2;
    Wyx = conj(ey1) .* ex2;

    S1 = Wxx + Wyy;
    S2 = Wxx - Wyy;
    S3 = Wxy + Wyx;
    S4 = 1i * (Wyx - Wxy);

    S = cat(3, S1, S2, S3, S4);
end
