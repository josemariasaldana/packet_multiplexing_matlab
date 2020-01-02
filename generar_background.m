%genera tráfico de fondo de diferentes tamaños

%%%%%%%%%%%% PARAMETROS %%%%%%%%%%%%%%

%%%%%%%%%%%%%%% versión de IP que se usa %%%%%%
%elegir sólo una
IP_version = 4;
%IP_version = 6;

%%%%%%%%%%%% Vector para guardar los resultados y mostrarlos al final%%%%%%%%%%%%
resultados_y_errores = zeros (0,0);

%%%%%%%%%% Ancho de banda a generar %%%%%%%%%%
for kbps_background = 10000:50:10000;
bps=kbps_background*1000;
kbps_background

%%%%%%%%%%% Probabilidad de cada tamaño %%%%%%%%%%
probabilidad = [0.5 0.1 0.4]; %deben sumar 1

%%%%%%%%%%%% Duración de la traza a generar en segundos %%%%%%%%%%%%
%se puede hacer de duracion constante
%duracion = 400;

% Si se quiere generar la duracion para conseguir 12000 paquetes (Montecarlo) de un tamaño deseado y unos kbps deseados
%son los kbps que tendrá el tráfico deseado que se genera aparte
kbps_deseado = 100;
for tamano_deseado = 50:100:1450
%duracion = 12000 * 8 * tamano_deseado / (1000 * kbps_deseado)
duracion = 25000 * 8 * tamano_deseado / (1000 * kbps_deseado)
tamano_deseado

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Selecciono los tamaños en función de la versión de IP
if IP_version == 4 
    tamanos = [40 576 1500];
else
    tamanos = [60 596 1500]; %incremento 20, pero no para 1500, porque es el MTU
end


%sum(probabilidad .* tamanos) %tamaño medio paquete
pps = (bps/8)/sum(probabilidad .* tamanos); %frecuencia media paquete
%calculo el vector de pps de cada tamaño
pps_flujos = probabilidad * pps

%calculo el número estimado de paquetes, para hacer el vector de ese
%tamaño. Le añado un 5% de margen
num_paquetes = floor(1.05 * duracion * pps);

%esta variable almacena el tiempo en que estamos
instante = 0;

%genero un vector "back" con dos columnas
%columna 1: tiempo acumulado en microseg
%columna 2: tamaño a nivel IP
back = zeros(num_paquetes,3);
back(1,1) = instante;
back(1,2) = tamanos(1);
back(1,3) = 101; %Indicador de background

%for i=2:numero_valores
i=1;
while instante < duracion * 1000000
    i = i + 1;
    %back = [back; zeros(1,3)];
    %calculo el siguiente tiempo
    instante = instante + exprnd(1/pps,1,1) * 1000000;
    back(i,1) = instante;
    
    %genero valores de tamaños
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

%quito las filas vacías de "back"
back = back (1:i,:);

kbps_real = 8 * (sum(back(:,2))) / (1000*duracion)
porcentaje_error = 100 * (kbps_background - kbps_real ) /kbps_real
num_paquetes_real = length(back(:,1))

%Pongo diferente nombre según la versión de IP
if IP_version == 4
    nombre_background=strcat('.\_background\background_',num2str(kbps_background),'_kbps_',num2str(duracion),'_seg.txt');
else
    nombre_background=strcat('.\_background\background_IPv6_',num2str(kbps_background),'_kbps_',num2str(duracion),'_seg.txt'); 
end

%lo escribo en un fichero de texto con saltos de línea
dlmwrite(nombre_background,back,'precision','%.0f','delimiter', '\t','newline','pc')

resultados_y_errores = [resultados_y_errores ; kbps_background kbps_real porcentaje_error]

end %aqui acaba un valor de la duración

end %aquí acaba un valor de bps

resultados_y_errores