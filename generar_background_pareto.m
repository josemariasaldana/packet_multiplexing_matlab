%genera tr�fico de fondo de diferentes tama�os

%%%%%%%%%%%% PARAMETROS %%%%%%%%%%%%%%

%%%%%%%%%%%%%%% versi�n de IP que se usa %%%%%%
%elegir s�lo una
IP_version = 4;
%IP_version = 6;

%%%%%%%%%%%% Vector para guardar los resultados y mostrarlos al final%%%%%%%%%%%%
resultados_y_errores = zeros (0,0);

%%%%%%%%%% par�metros de pareto %%%%%%%%%%%%%%%
%alfa debe variar entre 1 y 2
alfa_pareto = 1.9;
shape_pareto = 1/alfa_pareto;

%%%%%%%%%% Ancho de banda a generar %%%%%%%%%%
for kbps_background = 1800:50:1800;
bps=kbps_background*1000;
kbps_background

%%%%%%%%%%% Probabilidad de cada tama�o %%%%%%%%%%
probabilidad = [0.5 0.1 0.4]; %deben sumar 1

%%%%%%%%%%%% Duraci�n de la traza a generar en segundos %%%%%%%%%%%%
%se puede hacer de duracion constante
duracion = 1000;

% Si se quiere generar la duracion para conseguir 12000 paquetes (Montecarlo) de un tama�o deseado y unos kbps deseados
%son los bps que tendr� el tr�fico deseado
%bps_deseado = 100000;
for tamano_deseado = 1500:100:1500
%duracion = 12000 * 8 * tamano_deseado / bps_deseado
%tamano_deseado

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Selecciono los tama�os en funci�n de la versi�n de IP
if IP_version == 4 
    tamanos = [40 576 1500];
else
    tamanos = [60 596 1500]; %incremento 20, pero no para 1500, porque es el MTU
end


%sum(probabilidad .* tamanos) %tama�o medio paquete
pps = (bps/8)/sum(probabilidad .* tamanos); %frecuencia media paquete
%calculo el vector de pps de cada tama�o
pps_flujos = probabilidad * pps

sigma_pareto = (1/pps) * shape_pareto * (1 - shape_pareto);
theta_pareto = sigma_pareto / shape_pareto;

%calculo el n�mero estimado de paquetes, para hacer el vector de ese
%tama�o. Le a�ado un 5% de margen
num_paquetes = floor(1.05 * duracion * pps);

%esta variable almacena el tiempo en que estamos
instante = 0;

%genero un vector "back" con dos columnas
%columna 1: tiempo acumulado en microseg
%columna 2: tama�o a nivel IP
back = zeros(num_paquetes,3);
back(1,1) = instante;
back(1,2) = tamanos(1);
back(1,3) = 101; %Indicador de background

%for i=2:numero_valores
i=1;
while instante < duracion
    i = i + 1;
    %back = [back; zeros(1,3)];
    %calculo el siguiente tiempo
    instante = instante + gprnd(shape_pareto,sigma_pareto,theta_pareto,1,1);
    back(i,1) = instante * 1000000;
    
    %genero valores de tama�os
    prob = unifrnd(0,1);
    if prob < probabilidad(1)
        back(i,2) = tamanos(1);
        back(i,3) = 101;
    else
        if prob < probabilidad(1)+probabilidad(2)
            back(i,2) = tamanos(2);
            back(i,3) = 102;
        else
            back(i,2) = tamanos(3);
            back(i,3) = 103;
        end
    end
end

%quito las filas vac�as de "back"
back = back (1:i,:);

kbps_real = 8 * (sum(back(:,2))) / (1000*duracion)
porcentaje_error = 100 * (kbps_background - kbps_real ) / kbps_real
num_paquetes_real = length(back(:,1));

%Pongo diferente nombre seg�n la versi�n de IP
if IP_version == 4
    nombre_background=strcat('.\_background\background_pareto_alfa_',num2str(alfa_pareto),'_',num2str(kbps_background),'_kbps_',num2str(duracion),'_seg.txt');
else
    nombre_background=strcat('.\_background\background_IPv6_pareto_alfa_',num2str(alfa_pareto),'_',num2str(kbps_background),'_kbps_',num2str(duracion),'_seg.txt'); 
end

%lo escribo en un fichero de texto con saltos de l�nea
dlmwrite(nombre_background,back,'precision','%.0f','delimiter', '\t','newline','pc')

resultados_y_errores = [resultados_y_errores ; kbps_background kbps_real porcentaje_error]

end %aqui acaba un valor de la duraci�n

end %aqu� acaba un valor de bps

resultados_y_errores