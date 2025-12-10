function [ellipseParams, ellipsePoints] = fitEllipse(x, y)

    x0 = mean(x);
    y0 = mean(y);
    xc = x - x0;
    yc = y - y0;
    
    D = [xc.^2, xc.*yc, yc.^2, xc, yc, ones(length(xc), 1)];
    C = zeros(6, 6);
    C(1, 3) = -2;
    C(2, 2) = 1;
    C(3, 1) = -2;
    
    [V, ~] = eig(D' * D, C);
    cond = diag(V' * C * V) < 0;
    if any(cond)
        a = V(:, cond);
        a = a(:, 1);
    else
        error('Ellipse fitting başarısız');
    end
    
    a_coeff = a(1);
    b_coeff = a(2);
    c_coeff = a(3);
    d_coeff = a(4);
    e_coeff = a(5);
    f_coeff = a(6);
    
    denom = b_coeff^2 - 4*a_coeff*c_coeff;
    cx = (2*c_coeff*d_coeff - b_coeff*e_coeff) / denom;
    cy = (2*a_coeff*e_coeff - b_coeff*d_coeff) / denom;
    
    center = [cx + x0, cy + y0];
    
    num = 2 * (a_coeff*e_coeff^2 + c_coeff*d_coeff^2 - b_coeff*d_coeff*e_coeff + ...
               denom*f_coeff);
    factor = sqrt((a_coeff - c_coeff)^2 + b_coeff^2);
    
    semiMajorAxis = sqrt(-num / (denom * (a_coeff + c_coeff + factor)));
    semiMinorAxis = sqrt(-num / (denom * (a_coeff + c_coeff - factor)));
    
    if semiMajorAxis < semiMinorAxis
        temp = semiMajorAxis;
        semiMajorAxis = semiMinorAxis;
        semiMinorAxis = temp;
    end
    
    if abs(b_coeff) < 1e-10
        if a_coeff < c_coeff
            angle = 0;
        else
            angle = pi/2;
        end
    else
        angle = 0.5 * atan2(b_coeff, a_coeff - c_coeff);
    end
    
    ellipseParams = struct();
    ellipseParams.center = center;
    ellipseParams.semiMajorAxis = semiMajorAxis;
    ellipseParams.semiMinorAxis = semiMinorAxis;
    ellipseParams.angle = angle;
    
    t = linspace(0, 2*pi, 100);
    ellipseX = center(1) + semiMajorAxis * cos(t) * cos(angle) - ...
               semiMinorAxis * sin(t) * sin(angle);
    ellipseY = center(2) + semiMajorAxis * cos(t) * sin(angle) + ...
               semiMinorAxis * sin(t) * cos(angle);
    
    ellipsePoints = [ellipseX(:), ellipseY(:)];
end

