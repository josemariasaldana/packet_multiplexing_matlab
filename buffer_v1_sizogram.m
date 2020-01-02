clear all
close all

%añadir retardo lognormal fijo y variable
%calcular delay y jitter para cada paquete original del juego: pensar cómo

IPv4_UDP_HEADER = 28 ; %cabecera IPv4/UDP
IPv6_UDP_HEADER = 48 ; %cabecera IPv6/UDP

%defino la matriz donde almacenaré los resultados de cada prueba con sus
%parámetros
resultados_buffer = zeros(0,0);

%pongo a 0 estas variables para evitar que dé error luego si alguna no se ha usado
kbps_tamano_fijo = 0;
pps_tamano_fijo = 0;
nativo = 0;
nativo_con_repeticiones = 0;
tiempo_limite_buffer = 0;

%lo utilizaré para crear el nombre de fichero
hora_inicio=now;

%abro un fichero en el que guardaré la matriz de resultados. Su nombre incluye día, hora y minuto
file_resultados_buffer = fopen(strcat('.\_resultados_buffer\resultados_buffer_',datestr(hora_inicio, 'yyyy-mm-dd_HH.MM'),'.txt'),'w');

%%% escribo el título de cada resultado %%%%%%%%%%%%%
fprintf(file_resultados_buffer,strcat('tipo_trafico\t kbps_tamano_fijo\t pps_tamano_fijo\t tamano_fijo\t num_jugadores\t PE (ms)\t TO (ms)\t NºPaq\t TH\t politica_buffer\t tamano_buffer (kbytes)\t tiempo_max_buffer(ms)\t kbits_por_segundo_buffer\t paq_por_segundo_buffer\t num_maximo_paq_en_buffer\t retardo_procesado (ms)\t IP_version\t duracion_prueba (seg)\t tanto_por_uno_desechar_inicio\t tanto_por_uno_desechar_final\t kbps_background\t distrib_fondo\t alfa_pareto\t ocupacion_media_bytes\t ocupacion_media_paquetes\t prob_loss_deseado\t prob_loss_total\t prob_loss_background_1\t prob_loss_background_2\t prob_loss_background_3\t prob_loss_background\t trafico_ofrecido_IP_deseado (kbps)\t trafico_ofrecido_IP_background(kbps)\t trafico_ofrecido_IP_bg_1(kbps)\t trafico_ofrecido_IP_bg_2(kbps)\t trafico_ofrecido_IP_bg_3(kbps)\t trafico_cursado_IP_deseado(kbps)\t trafico_cursado_IP_background(kbps)\t trafico_cursado_IP_bg_1(kbps)\t trafico_cursado_IP_bg_2(kbps)\t trafico_cursado_IP_bg_3(kbps)\t num_paq_deseado\t num_paq_bg1\t num_paq_bg2\t num_paq_bg3\t pps_deseado\t pps_bg1\t pps_bg2\t pps_bg3\t  delay_router_deseado(ms)\t delay_mux_router_deseado(ms)\t stdev_router_deseado\t stdev_mux+router_deseado\t stdev_bg1\t stdev_bg2\t stdev_bg3\t stdev_bg\t tamano_medio_IP_deseado','\n'));

%%% Cierro el fichero %%%%%%%%%%
fclose(file_resultados_buffer);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% PARAMETROS GENERALES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Porcentajes del tiempo que no se tendrán en cuenta para las estadísticas
porcentaje_desechar_inicio = 0.075;
porcentaje_desechar_final = 0.025;
%porcentaje_desechar_inicio = 0.001;
%porcentaje_desechar_final = 0.001;

%si se desea calcular el jitter conjunto del multiplexor y el buffer
%la stdev no se puede sumar directamente, porque existe correlación entre
%la stdev al multiplexar y la del buffer
%poniendo esta variable a 1, el programa calcula las diferencias entre el
%momento de llegada de cada paquete nativo al multiplexor y el momento de
%salida del paquete multiplexado del router
calcular_jitter_conjunto = 0;

%distribución estadística del tráfico de fondo
% 0 exponencial
% 1 pareto
distribucion_trafico_fondo = 0;
alfa_pareto = 0;
%alfa_pareto = 1.9;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Empiezan los bucles de pruebas anidados %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% Parámetros del tráfico deseado %%%%%%%%
%la variable "tipo_trafico" puede tener estos valores:
%los 900 lo reservo para juegos
%901 'hlcs_1_dedust';
%902 'hl2cs_dedust';
%903 'halo2';
%904 'quake2'; genera unos 13kbps por usuario
%905 'quake3';
%906 'quake4'; genera unos 40kbps por usuario
%907 'etpro_1_fueldump';
%908 'unreal1.0';

%101, 102 y 103 es el tráfico de fondo de cada tamaño
%201 tamaño fijo por kbps
%301 tamaño fijo por pps
for tipo_trafico=201:201

%%%%%%%%%%%%%%%%%%%% Parámetros del tráfico de tamaño fijo: elegir uno de los dos: kbps o pps
%si se está enviando tráfico de juegos, da igual lo que se ponga aquí

%kbps del tráfico de paquetes de tamaño fijo, con distribución de Poisson de tiempo entre paquetes
for kbps_tamano_fijo = 100:100:100
%for pps_tamano_fijo = 100:100:400

%tamaño en bytes de los paquetes de tamaño fijo
for tamano_fijo = 100:100:1500
%tamano_fijo

%%%%%%%%%%% Duración de la prueba %%%%%%%%%%%%%
%si se va a usar una duración fija
%duracion_prueba = 1000; %segundos

% Si se quiere usar una duracion para conseguir 12000 paquetes (Montecarlo) de un tamaño deseado y unos kbps deseados
%son los bps que tendrá el tráfico deseado
duracion_prueba = 12000 * 8 * tamano_fijo / (kbps_tamano_fijo * 1000)

%%%%%%%%%%%%%%%%%%% parámetros del tráfico de juegos %%%%%%%%%%%%%%%
%si se está enviando tamaño fijo, da igual lo que se ponga aquí.
%en caso de no usar los parámetros, hay que hacer que los bucles se ejecuten una sola vez
for num_jugadores=20:5:20 %número de jugadores

%%%%%%%%%%%%%%%%%%%%%%% Parámetros de la multiplexión de juegos %%%%%%%%%%%%%%%%%%%%%
%Si PE o TO o NP o TH valen 0, el tráfico es nativo

%for PE=0:5:50 %PERIOD que se ha usado para multiplexar
%valores_PE = [0 5 25 50];
%valores_PE = [0 5 15 25];
valores_PE = [0];
for w = 1:size(valores_PE,2)
PE = valores_PE(w);
%for TO=5:5:5 %TIMEOUT que se ha usado para multiplexar. 
TO = PE;

for NP=300:1:300 %Numero máximo de paquetes que se ha usado para multiplexar

for TH=1350:1:1350 %tamaño umbral que se ha usado para multiplexar

%%%%%%%%%%%% Parámetros del buffer %%%%%%%%%%%%%%%%

%si se pone a 1, se da prioridad en el buffer a los paquetes de tráfico deseado
for prioridad = 0:0

%política a usar
% 1 "strict": tamaño fijo estricto 
% 2 "one byte": si queda un byte libre en el buffer, el paquete se acepta 
% 3 "time limited": limitado en tiempo
% 4 "fixed number": cabe un número fijo de paquetes. Da igual lo demás 
for politica_buffer = 3:3

%Para poder hacer el tamaño logarítmico, o como me apetezca, pongo un bucle que coge los valores de un vector
%tamanos_buffer = [10000 20000 50000 100000 200000 500000 1000000];%tamaño del buffer en bytes
%tamanos_buffer = [20000 50000 100000];%tamaño del buffer en bytes
%tamanos_buffer = [10000 20000 50000 100000];%tamaño del buffer en bytes
%tamanos_buffer = [10000 50000 100000 500000 1000000];%tamaño del buffer en bytes
tamanos_buffer = [200000000];
for u=1:size(tamanos_buffer,2)
tamano_buffer = tamanos_buffer(u);

%for tamano_buffer=1000:1000:100000 
%for tamano_buffer=10000:1000:100000
    
for kbits_por_segundo_buffer = 10000:50:10000; %dividir por 1.000.000 para hallar los bits por microseg
bits_por_segundo_buffer = 1000 * kbits_por_segundo_buffer; 

for paq_por_segundo_buffer = 20000000:1:20000000; %si es muy grande, no limita
%for paq_por_segundo_buffer = 500:1:500; %si es muy grande, no limita

%número máximo de paquetes en el buffer. Sólo afecta a la política 3
%con un tamaño medio de 600bytes, 10kbytes equivalen a 16 paquetes
%para 1Mbps de BG y 20 players de QuakeIV con PE=5ms, se obtiene en media 601 bytes de tamaño de paquete
numeros_maximo_paq_en_buffer = [0];
%numeros_maximo_paq_en_buffer = [16 33 83 166];
for z=1:size(numeros_maximo_paq_en_buffer,2); 
num_maximo_paq_en_buffer = numeros_maximo_paq_en_buffer(z);

%milisegundos de límite de tiempo en el buffer. Va en ms. Afecta a la política 4
%tiempos_limite_buffer = [400];
tiempos_limite_buffer = [8 16 40 80];
for w=1:size(tiempos_limite_buffer,2)
%paso a ms el tiempo_limite_buffer
tiempo_limite_buffer = tiempos_limite_buffer(w);

for retardo_procesado = 0:1:0; %en microseg. Tiempo entre paquetes que salen seguidos. El buffer no es capaz de concatenarlos perfectamente

%%%%%%%%%%%% Versión de IP. Puede ser 4 o 6 %%%%%%%%%%%%%
for IP_version = 4:2:4;

%%%%%%% Cantidad de tráfico de fondo en kbps
for kbps_background = 10100:50:10100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% empieza una prueba %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    prueba_buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% termina una prueba %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% aqui empiezan los "end" de los bucles anidados %%%%%
end %termina el bucle de kbps_background
end %termina el bucle de IP_version
end %termina el bucle de retardo_procesado
end %termina el bucle de tiempo_limite_buffer
end %termina el bucle de num_maximo_paq_en_buffer
end %termina el bucle de paquetes_por_segundo
end %termina el bucle de bits_por_segundo_buffer
end %termina el bucle de tamano_buffer
end %termina el bucle de políticas de buffer
end %termina el bucle de prioridad
end %termina el bucle de TH
end %termina el bucle de NP
%end %termina el bucle de TO
end %termina el bucle de PE
end %termina el bucle de num_jugadores
end %termina el bucle del tamaño de los paquetes tamano_fijo
end %termina el bucle kbps_tamano_fijo o pps_tamano_fijo
end %termina el bucle de tipo_trafico

%%%% Terminan los bucles de pruebas anidados %%%%%%

