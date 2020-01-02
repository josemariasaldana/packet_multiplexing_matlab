%genera tr�fico de fondo de diferentes tama�os

%%%%%%%%%%%% PARAMETROS %%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%tama�o en bytes a nivel IP
for tamano = 50:25:1500

%%%%%%%%%% pps a generar %%%%%%%%%
for pps = 100:100:400
bps = pps * 8 * tamano;

%%%%%%%%%%%% Duraci�n de la traza a generar en segundos %%%%%%%%%%%%
%se puede hacer de duracion constante
%duracion = 400;

% Si se quiere generar la duracion para conseguir 12000 paquetes (Montecarlo) de un tama�o deseado y unos kbps deseados
%son los bps que tendr� el tr�fico deseado
duracion = 12000 * 8 * tamano / bps
tamano
bps

%calculo el n�mero estimado de paquetes, para hacer el vector de ese
%tama�o. Le a�ado un 5% de margen
num_paquetes = floor(1.05 * duracion * pps);

%esta variable almacena el tiempo en que estamos
instante = 0;

%genero un vector "back" con dos columnas
%columna 1: tiempo acumulado en microseg
%columna 2: tama�o a nivel IP
back = zeros(num_paquetes,3);
back(:,2) = tamano * ones(num_paquetes,1);%relleno la columna de tama�o
back(:,3) = 201 * ones(num_paquetes,1);%Indicador de tamano fijo

back(1,1) = instante;

i=1;
while instante < duracion * 1000000
    i = i + 1;
    %calculo el siguiente tiempo
    instante = instante + exprnd(1/pps,1,1) * 1000000;
    back(i,1) = instante;
end

%quito las filas vac�as de "back"
back = back (1:i,:);

kbps_background = bps / 1000;

bps_real = 8 * (sum(back(:,2))) / duracion
pps_real = length(back) / duracion
num_paquetes_real = length(back(:,1))

%Pongo diferente nombre seg�n la versi�n de IP
nombre_background=strcat('.\_fixed_size\fixed_size_',num2str(tamano),'_bytes_',num2str(pps),'_pps_',num2str(duracion),'_seg.txt');

%lo escribo en un fichero de texto con saltos de l�nea
dlmwrite(nombre_background,back,'precision','%.0f','delimiter', '\t','newline','pc')

end %aqu� acaba el valor de tamano
end %aqu� acaba un valor de bps