close all
clear all

%%%%%%%%%%%%%%%%%% CONSTANTES %%%%%%%%%%%%%%%%%%
IPv4_HEADER = 20 ; %cabecera IPv4/UDP
IPv6_HEADER = 40 ; %cabecera IPv6/UDP
UDP_HEADER = 8;

%%%%%%%%%%%%%%%% PARAMETROS %%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% JUEGO QUE SE USA %%%%%%%%%%%%%%%
%nombre_juego = 'hlcs_1_dedust';
%nombre_juego = 'hl2cs_dedust';
%nombre_juego = 'halo2';
%nombre_juego = 'quake2';
%nombre_juego = 'quake3';
%nombre_juego = 'quake4';
%nombre_juego = 'etpro_1_fueldump';
nombre_juego = 'unreal1.0';

%%%%%%%%%%%%%% NUMERO JUGADORES %%%%%%%%%%%%%%%%%%%%%
%numero de jugadores para el que se hace el histograma.
%es suficiente con hacerlo para el de 5, porque se separa por jugador
num_jugadores = 5;

%versi�n de IP que se usa
IP_version = 4;
%IP_version = 6;

%%%%%%%%%%%% CALCULO TAMA�OS CABECERAS %%%%%%%%%%%%%%%%%%

if IP_version == 4 %se usa IPv4 
    IP_UDP_HEADER = IPv4_HEADER + UDP_HEADER;
else %se usa IPv6
    IP_UDP_HEADER = IPv6_HEADER + UDP_HEADER;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nombre_archivos=strcat('.\',nombre_juego,'_',num2str(num_jugadores),'\',nombre_juego,'_',num2str(num_jugadores))

cargar_variables


%ordeno el fichero de entrada seg�n la tercera columna (usuario)
entrada = sortrows (entrada,3);

%creo otra matriz fila, para almacenar los identificadores de cada usuario
usuarios=zeros(1);

%recorro la matriz buscando nuevos usuarios. A�ado una columna por cada
%usuario

%u se utiliza para contar los usuarios distintos que hay
u=1;

usuarios(u)=entrada(1,3);
for(i=1:length(entrada(:,1))-1)
    if usuarios(u)==entrada(i+1,3) %no cambia el usuario
    else %cambia el usuario
        u=u+1;
        usuarios=[usuarios entrada(i+1,3)];
    end
end

%creo una matriz tiempos_separados. En cada columna pondr� los tiempos
%entre paquetes de un usuario
tiempos_separados=zeros(1,length(usuarios));
tamanos_separados=zeros(1,length(usuarios));

%variable para almacenar el n�mero de paquetes de cada usuario
num_paquetes=zeros(length(usuarios));

u=1;
j=1;

%calculo las diferencias de tiempos y tamanos
for(i=1:length(entrada(:,1))-1)
    if usuarios(u)==entrada(i+1,3) %no cambia el usuario
        %apunto el tiempo en la columna correspondiente
        tiempos_separados(j,u)=entrada(i+1,1)-entrada(i,1);
        %apunto el tama�o en la columna correspondiente
        tamanos_separados(j,u)=entrada(i,2) + IP_UDP_HEADER;
        %aumento el contador
        j=j+1;
    else %cambia el usuario
        %almaceno el n�mero de paquetes de ese usuario
        num_paquetes(u)=j;
        %cambio de usuario
        u=u+1;
        %vuelvo a empezar la cuenta
        j=1;
    end
end
%almaceno el n�mero de paquetes del �ltimo usuario
num_paquetes(u)=j;

%creo la primera columna con los tiempos del histograma de tiempos
eje_x_tiempo=0:200:max(max(tiempos_separados)); %max calcula una l�nea, no un valor
histograma_tiempo_entrada=zeros(length(eje_x_tiempo),length(usuarios)+1);
histograma_tiempo_entrada(:,1)=eje_x_tiempo;

%creo la primera columna con los tiempos del histograma de tama�os
eje_x_tamano=1:1:max(max(tamanos_separados));
histograma_tamano_entrada=zeros(length(eje_x_tamano),length(usuarios)+1);
histograma_tamano_entrada(:,1)=eje_x_tamano;

for(u=1:length(usuarios))
    histograma_tiempo_entrada (:,u+1)= hist(tiempos_separados(1:num_paquetes(u)-1,u),eje_x_tiempo);
    %para normalizar se podr�a hacer
    %suma = sum(histograma_tiempo_entrada (:,u+1));
    %histograma_tiempo_entrada = histograma_tiempo_entrada ./ suma;
    
    histograma_tamano_entrada (:,u+1)= hist(tamanos_separados(1:num_paquetes(u)-1,u),eje_x_tamano);
end

%a�ado una primera fila con los nombres de los usuarios
histograma_tiempo_entrada=[0 usuarios; histograma_tiempo_entrada];
histograma_tamano_entrada=[0 usuarios; histograma_tamano_entrada];

%al acabar con todos los valores, escribo la matriz de histogramas en un
%fichero, para poder pegarlo directamente en excel
file_histogramas_tiempo_entrada = fopen(strcat(nombre_archivos,'_histogramas_tiempo_entrada.txt'),'w');
for(i=1:size(histograma_tiempo_entrada,1))
    for(u=1:size(histograma_tiempo_entrada,2))
        fprintf(file_histogramas_tiempo_entrada,strcat(num2str(histograma_tiempo_entrada(i,u)),'\t'));
    end
    fprintf(file_histogramas_tiempo_entrada,'\n');
end
fclose(file_histogramas_tiempo_entrada);

%al acabar con todos los valores, escribo la matriz de histogramas en un
%fichero, para poder pegarlo directamente en excel
file_histogramas_tamano_entrada = fopen(strcat(nombre_archivos,'_histogramas_tamano_entrada.txt'),'w');
for(i=1:size(histograma_tamano_entrada,1))
    for(u=1:size(histograma_tamano_entrada,2))
        fprintf(file_histogramas_tamano_entrada,strcat(num2str(histograma_tamano_entrada(i,u)),'\t'));
    end
    fprintf(file_histogramas_tamano_entrada,'\n');
end
fclose(file_histogramas_tamano_entrada);
