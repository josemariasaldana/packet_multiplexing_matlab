%este programa necesita que exista una carpeta con el nombre del juego y el número de jugadores, para cada número de jugadores a probar:
% \quake2_5\
% \quake2_10\
% etc.
%
%en cada carpeta debe haber un fichero llamado quake2_5_time_size_user.txt
%ese fichero tiene tres columnas: tiempo absoluto de generación del paquete
%en useg; tamaño del payload UDP (sin contar cabecera IP ni UDP) y número
%de usuario que lo genera
%
%las pruebas se realizan para
%   una versión de IP: v4 o v6
%   un juego
%   protocolo TCP o UDP: depende del juego
%   un número máximo de paquetes a multiplexar
%   un tamaño máximo de paquete
%   bucles anidados:
%       un rango de números de jugadores
%           un rango de tiempos de PERIOD o TIMEOUT (sólo varía uno de los dos parámetros)

%el programa genera los siguientes ficheros:
%
%   para cada número de jugadores, en la carpeta con el nombre del juego seguido por el número de jugadores:
%       quake2_5_size.txt       tamaños de los payload UDP de los paquetes
%       quake2_5_diftime.txt    diferencias de tiempos entre paquetes en useg
%       quake2_5.txt            tiene cuatro columnas:
%                               1 tiempo absoluto de generación en useg
%                               2 tamaño del payload UDP
%                               3 identificador del flujo
%                               4 número de paquetes multiplexados
%
%       quake2_5_histogramas_tiempo_entrada.txt
%       quake2_5_histogramas_tamano_entrada.txt
%
%       fichero ...._bucle.txt   contiene en cada columna un valor de TIMEOUT o PERIOD. Se puede pegar en excel una vez cambiados los puntos por comas
%       
%       para cada valor de TIMEOUT o PERIOD
%               fichero ..._size.txt            tamaños de los paquetes generados
%               fichero ..._diftime.txt         diferencias de tiempo entre paquetes generados
%               fichero ..._estadisticas.txt    estadisticas de ese valor
%
%               quake2_5_histograma_retention_PE_10_TO_10_NP_300_TH_1350.txt
%               quake2_5_histogramas_tamano_salida_PE_5_TO_5_NP_300_TH_1350.txt
%               quake2_5_histogramas_tiempo_salida_PE_5_TO_5_NP_300_TH_1350.txt

close all
clear all

%%%%%%%%%%%%%%%%%% CONSTANTES %%%%%%%%%%%%%%%%%%
IPv4_HEADER = 20 ; %cabecera IPv4/UDP
IPv6_HEADER = 40 ; %cabecera IPv6/UDP
UDP_HEADER = 8;
TCP_HEADER = 20;
L2TP_HEADER = 4; %va en cada paquete multiplexado
PPP_HEADER = 1; %va en cada paquete multiplexado
PPPMux_HEADER = 2; %cabecera que va delante de la cabecera comprimida de cada paquete dentro de uno multiplexado
ETH_HEADER=14; %tamaño en bytes de la cabecera ethernet. es 14. si de usa 802.1Q serían 18.
ETH_CRC=4;      %size of the CRC field of the Ethernet frame
ETH_GAP=12;     %inter-frame GAP of ethernet
MTU = 1500; %máximo tamaño de los paquetes a nivel IP
RTP_HEADER = 12;

%%%%%%%%%%%%%%%% PARAMETROS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% MODO DE COMPRESION %%%%%%%%%%%%%%%
%compression = 'IPHC';
compression = 'SDN';

%%%%%%%%%%%%%%% versión de IP que se usa %%%%%%
for IP_version = 4:2:4;

    %%%%%%%%%%%%%%% FLUJOS QUE SE USAN %%%%%%%%%%%%%%%

    %si es 1xx, 2xx, 3xx, 4xx o 5xx, se trata de tráficos que no son todo TCP o
    %UDP. La tercera columna en ese caso no es el usuario, sino el tipo de tráfico
    %101 'chicago'  !! no usar con compresión IPHC. No tiene sentido el resultado!!
    %102 'education_downlink'   !! no usar con compresión IPHC. No tiene sentido el resultado!!
    %103 'education_uplink'   !! no usar con compresión IPHC. No tiene sentido el resultado!!
    %104 'dsl_uplink'   !! no usar con compresión IPHC. No tiene sentido el resultado!!
     
    %Si es 8xx, es MMORPG, y usa TCP
    %801 'wow_cs' World of Warcraft cliente_a_servidor
    %802 'wow_sc' World of Warcraft servidor_a_cliente

    %Si es 9xx, es FPS, y usa UDP
    %901 'hlcs_1_dedust';
    %902 'hl2cs_dedust';
    %903 'halo2';
    %904 'quake2';
    %905 'quake3';
    %906 'quake4';
    %907 'etpro_1_fueldump';
    %908 'unreal1.0';
    id_traza_inicial = 101;
    id_traza_final = 101;

    %%%%%%%%%%%%%% NUMERO JUGADORES %%%%%%%%%%%%%%%%%%%%%
    %las pruebas se realizan para un rango de números de jugadores
    % el número no importa para las trazas 1xx
    num_jugadores_inicial = 10;
    num_jugadores_final = 10;
    paso_num_jugadores = 5;

    %para seleccionar la política PERIOD o TIMEOUT, ir al comienzo del bucle

    %si PERIOD_TIMEOUT = 0, usaré PERIOD
    %si PERIOD_TIMEOUT = 1, usaré TIMEOUT
    PERIOD_TIMEOUT = 0;

    %Valores de PERIOD O TIMEOUT que voy a usar en este bucle
    %va en useg
    minimo=100000; %el primer valor a calcular. Debe ser múltiplo de "paso"
    maximo=100000; %el último valor a calcular. Debe ser múltiplo de "paso"
    paso=10000; %useg 

    %parte que se refiere a PE y TO del nombre del fichero de
    %estadísticas del bucle para cada número de jugadores
    %rellenarlo a mano para que sea coherente con el Numero de jugadores y el
    %rango de PERIOD o TIMEOUT
    if (PERIOD_TIMEOUT == 0)
        nombre_fichero_estadisticas_bucle=strcat('_PE_de_',num2str(minimo/1000),'_a_',num2str(maximo/1000),'_');
    else
        nombre_fichero_estadisticas_bucle=strcat('_TO_de_',num2str(minimo/1000),'_a_',num2str(maximo/1000),'_');
    end
    %Valores de número máximo de paquetes o tamaño
    NUMPAQUETES=300;   %numero maximo de paquetes a agrupar
    PACKET_SIZE_TRESHOLD=1450;  %numero de bytes maximos del paquete. Cuando se supera, envía

    %definir si se quieren sacar por pantalla los histogramas
    %poner a 1 si se quieren ver, y a 0 si no se quieren ver
    histogramas_por_pantalla = 0;

    %definir si se quieren guardar los ficheros de entrada para tener ordenado
    %cada paquete de entrada
    % _time_size_user_ordenado.txt
    % _diftime.txt
    % _size.txt
    guardar_ficheros_entrada = 1;
    %guardar_ficheros_entrada = 0;

    % indica si debo filtrar o no los paquetes pequeños.
    % si tamano_filtrar es 0, no hace nada
    % si es mayor que 0, borra de "entrada" todos los paquetes mayores de
    % 'tamano_filtrar' antes de comprimir
    % guarda las estadísticas en el fichero 'estadisticas_filtrar.txt'
    %tamano_filtrar = 0;
    %tamano_filtrar = 1500;
    paso_filtrar = 50;
    tamano_filtrar_inicial = 1000;
    tamano_filtrar_final = 1000;

    %%%%%%%%%%%%%%%%%% FIN PARAMETROS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%% DEFINIR VARIABLE ESTADISTICAS %%%%%%%%%%%%%%%%%%
    %inicializo estas dos variables
    proporcion_paquetes_pequenos = 0;
    proporcion_ancho_banda_paquetes_pequenos = 0;
    
    %matriz para almacenar las estadísticas    
    numero_estadisticas = 34;
    %cada columna es un valor de PERIOD o TIMEOUT
    %defino el número máximo de paquetes a multiplexar que voy a almacenar en
    %las estadísticas
    numero_maximo_paquetes_estadisticas = 20;

    %hay numero_estadisticas estadísticas de salida, aparte del número de paquetes multiplexados
    tamano_estadisticas = numero_estadisticas + numero_maximo_paquetes_estadisticas;


    for id_traza = id_traza_inicial:1:id_traza_final
        id_traza
        
        
        %%%%%%%%%%%% CALCULO TAMAÑOS CABECERAS %%%%%%%%%%%%%%%%%%
        if IP_version == 4 %se usa IPv4 
            IP_UDP_HEADER = IPv4_HEADER + UDP_HEADER;
            IP_TCP_HEADER = IPv4_HEADER + TCP_HEADER;
            IP_UDP_RTP_HEADER = IPv4_HEADER + UDP_HEADER + RTP_HEADER;
        else
            if IP_version == 6
                IP_UDP_HEADER = IPv6_HEADER + UDP_HEADER;
                IP_TCP_HEADER = IPv6_HEADER + TCP_HEADER;
                IP_UDP_RTP_HEADER = IPv6_HEADER + UDP_HEADER + RTP_HEADER;              
            end
        end
        % la compresión es IPHC. En este caso sólo se comprimen flujos de un tipo
        % de tráfico (todo WoW, todo Quake, etc). No usar para trazas variadas
        % cogidas de Internet
        if (strcmp (compression, 'IPHC') == 1)
            IPv4_COMPR_HEADER = 2; %cabecera comprimida IPHC IPv4
            IPv6_COMPR_HEADER = 2; %cabecera comprimida IPHC IPv6
            UDP_COMPR_HEADER = 2; %cabecera comprimida IPHC UDP
            RTP_COMPR_HEADER = 12; %cabecera comprimida RTP
            %TCP_COMPR_HEADER =   ; %cabecera comprimida TCP. es variable

            if floor(id_traza/100) == 8 %es TCP
            % Para WoW no utilizo un tamaño fijo de cabecera comprimida,sino que en "comprimir.m" se calcula en función 
            % de unas estadísticas que dependen de la frecuencia con que aparece cada tamaño de cabecera
                if IP_version == 4 %se usa IPv4 
                    IP_UDP_TCP_HEADER = IPv4_HEADER + TCP_HEADER;
                    COMMON_HEADER = IPv4_HEADER + L2TP_HEADER + PPP_HEADER;
                    %COMPR_HEADER = IPv4_COMPR_HEADER + TCP_COMPR_HEADER;
                else %se usa IPv6
                    IP_UDP_TCP_HEADER = IPv6_HEADER + TCP_HEADER;
                    COMMON_HEADER = IPv6_HEADER + L2TP_HEADER + PPP_HEADER;
                    %COMPR_HEADER = IPv6_COMPR_HEADER + TCP_COMPR_HEADER;
                end

            else %es UDP
                if IP_version == 4 %se usa IPv4 
                    IP_UDP_TCP_HEADER = IPv4_HEADER + UDP_HEADER;
                    COMMON_HEADER = IPv4_HEADER + L2TP_HEADER + PPP_HEADER;
                    COMPR_HEADER = IPv4_COMPR_HEADER + UDP_COMPR_HEADER;
                else %se usa IPv6
                    IP_UDP_TCP_HEADER = IPv6_HEADER + UDP_HEADER;
                    COMMON_HEADER = IPv6_HEADER + L2TP_HEADER + PPP_HEADER;
                    COMPR_HEADER = IPv6_COMPR_HEADER + UDP_COMPR_HEADER;
                end
            end
        else
            % la compresión es la definida en el paper Japan, o sea, quitar
            % campos de las cabeceras sin usar IPHC
            if (strcmp (compression, 'SDN') == 1)
                IPv4_COMPR_HEADER = 6 ; %cabecera comprimida IPHC IPv4
                IPv6_COMPR_HEADER = 2 ; %cabecera comprimida IPHC IPv6
                UDP_COMPR_HEADER =  2 ; %cabecera comprimida IPHC UDP
                RTP_COMPR_HEADER =  6 ; %cabecera comprimida RTP
                TCP_COMPR_HEADER = 13  ; %cabecera comprimida TCP
                if IP_version == 4 %IPv4
                    IP_TCP_COMPR_HEADER = IPv4_COMPR_HEADER + TCP_COMPR_HEADER;                   
                    IP_UDP_COMPR_HEADER = IPv4_COMPR_HEADER + UDP_COMPR_HEADER; 
                    IP_UDP_RTP_COMPR_HEADER = IPv4_COMPR_HEADER + UDP_COMPR_HEADER + RTP_COMPR_HEADER; 
                    COMMON_HEADER = IPv4_HEADER + L2TP_HEADER + PPP_HEADER;
                else %IPv6
                    IP_TCP_COMPR_HEADER = IPv6_COMPR_HEADER + TCP_COMPR_HEADER;                   
                    IP_UDP_COMPR_HEADER = IPv6_COMPR_HEADER + UDP_COMPR_HEADER; 
                    IP_UDP_RTP_COMPR_HEADER = IPv6_COMPR_HEADER + UDP_COMPR_HEADER + RTP_COMPR_HEADER;                    
                    COMMON_HEADER = IPv6_HEADER + L2TP_HEADER + PPP_HEADER;
                end

            end
        end

        switch(id_traza)
            case 101
                nombre_traza = 'chicago_1';  %el número de jugadores da igual
            case 102
                nombre_traza = 'education_downlink';
            case 103
                nombre_traza = 'education_uplink';
            case 104
                nombre_traza = 'dsl_uplink';
            %case 601
                %nombre_traza = 'video_TS';
            case 801
                nombre_traza = 'wow_cs';
            case 802
                nombre_traza = 'wow_sc';
            case 901
                nombre_traza = 'hlcs_1_dedust';
            case 902
                nombre_traza = 'hl2cs_dedust';
            case 903
                nombre_traza = 'halo2';
            case 904
                nombre_traza = 'quake2';
            case 905
                nombre_traza = 'quake3';
            case 906
                nombre_traza = 'quake4';
            case 907
                nombre_traza = 'etpro_1_fueldump';
            case 908
                nombre_traza = 'unreal1.0';
        end


        %añado al nombre del juego 'IPv6' si los cálculos son para IPv6
        if(IP_version == 6) 
            nombre_traza = strcat(nombre_traza,'_IPv6');
        end

        for num_jugadores=num_jugadores_inicial:paso_num_jugadores:num_jugadores_final
            num_jugadores

            %%%%%%%%%%% Política PERIOD_TIMEOUT %%%%%%%%%%%%

            %reinicio las estadísticas
            estadisticas=[];

            if ( id_traza >= 600 )
                %para cada valor del número de jugadores
                nombre_archivos = strcat('.\',nombre_traza,'_',num2str(num_jugadores),'\',nombre_traza,'_',num2str(num_jugadores))
            else
                nombre_archivos = strcat('.\',nombre_traza,'\',nombre_traza);
            end

            %para cada valor de PERIOD o TIMEOUT desde paso*minimo hasta paso*maximo
            %cada valor añade una columna a estadisticas
            for y = minimo/paso:maximo/paso
                    
                for tamano_filtrar = tamano_filtrar_inicial:paso_filtrar:tamano_filtrar_final
                    tamano_filtrar
                    %PERIOD significa que en cuanto pasa ese tiempo se envía lo que haya
                    %TIMEOUT significa que a partir del TIMEOUT, se espera a que llegue
                    %el siguiente paquete y entonces se envía ese y todos los que haya.
                    %Las políticas podrían mezclarse

                    if (PERIOD_TIMEOUT == 0) 
                        %política PERIOD pura: igualo TIMEOUT y PERIOD
                        PERIOD = paso*y
                        TIMEOUT = PERIOD;
                    else
                        %política TIMEOUT pura: hago PERIOD mucho mayor que TIMEOUT. Así sólo importa TIMEOUT
                        TIMEOUT = paso*y
                        PERIOD = 100*TIMEOUT;
                    end

                    %%%%%%%%%%%%%%%%%%% BUCLE PRINCIPAL %%%%%%%%%%%%%%%%%
                    cargar_variables %carga las variables del programa
                    if tamano_filtrar > 0
                        filtrar %deja en 'entrada' sólo los paquetes de tamaño menor que tamano_fitrar
                    end
                    comprimir %calcula la cabecera comprimida de cada paquete original y la guarda en "entrada"
                    multiplexar_period_timeout %calcula qué paquetes nativos van en cada paquete multiplexado y genera "salida"
                    guardar_estadisticas
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    %Calculamos y dibujamos el histograma del retention time
                    %pongo el doble del intervalo, porque puede tener colas
                    if (PERIOD_TIMEOUT == 0)
                        eje_x=0:100:PERIOD*2;
                    else
                        eje_x=0:100:TIMEOUT*2;
                    end

                    %si se ha decido que los histogramas salgan por pantalla
                    if histogramas_por_pantalla ==1
                        figure; %crea otra ventana
                        hist(entrada(:,6),eje_x);
                    end
                    histograma_retention_salida=hist(entrada(:,6),eje_x);

                    %escribo el histograma_retention en un fichero, para poder pegarlo directamente en excel
                    file_histograma_retention_salida = fopen(strcat(nombre_archivos,'_histograma_retention_PE_',num2str(PERIOD/1000),'_TO_',num2str(TIMEOUT/1000),'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'_sizelimit_',num2str(tamano_filtrar),'.txt'),'w');
                    for u=1:length(histograma_retention_salida)
                        fprintf(file_histograma_retention_salida,strcat(num2str(eje_x(u)),'\t'));
                        fprintf(file_histograma_retention_salida,strcat(num2str(histograma_retention_salida(u)),'\n'));
                    end
                    fclose(file_histograma_retention_salida);

                    %calculamos los percentiles
                    prctile(entrada(:,6),[95,99,99.5,99.9,100])

                    %%%%%%%%histograma de tiempos y tamaños de salida

                    %creo la primera columna con los tiempos del histograma de tiempos
                    eje_x_tiempo=0:100:max(max(salida(:,4))); %max calcula una línea, no un valor
                    histograma_tiempo_salida=zeros(length(eje_x_tiempo),2);
                    histograma_tiempo_salida(:,1)=eje_x_tiempo;

                    %creo la primera columna con los tiempos del histograma de tamaños
                    eje_x_tamano=0:10:max(max(salida(:,2)));
                    histograma_tamano_salida=zeros(length(eje_x_tamano),2);
                    histograma_tamano_salida(:,1)=eje_x_tamano;

                    histograma_tiempo_salida (:,2)= hist(salida(:,4),eje_x_tiempo);
                    histograma_tamano_salida (:,2)= hist(salida(:,2),eje_x_tamano);

                    %al acabar con todos los valores, escribo la matriz de histogramas en un
                    %fichero, para poder pegarlo directamente en excel

                    file_histogramas_tiempo_salida = fopen(strcat(nombre_archivos,'_histogramas_tiempo_salida_PE_',num2str(PERIOD/1000),'_TO_',num2str(TIMEOUT/1000),'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'_sizelimit_',num2str(tamano_filtrar),'.txt'),'w');
                    for i=1:size(histograma_tiempo_salida,1)
                        for u=1:2
                            fprintf(file_histogramas_tiempo_salida,strcat(num2str(histograma_tiempo_salida(i,u)),'\t'));
                        end
                        fprintf(file_histogramas_tiempo_salida,'\n');
                    end
                    fclose(file_histogramas_tiempo_salida);

                    %al acabar con todos los valores, escribo la matriz de histogramas en un
                    %fichero, para poder pegarlo directamente en excel
                    file_histogramas_tamano_salida = fopen(strcat(nombre_archivos,'_histogramas_tamano_salida_PE_',num2str(PERIOD/1000),'_TO_',num2str(TIMEOUT/1000),'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'_sizelimit_',num2str(tamano_filtrar),'.txt'),'w');
                    for i=1:size(histograma_tamano_salida,1)
                        for u=1:size(histograma_tamano_salida,2)
                            fprintf(file_histogramas_tamano_salida,strcat(num2str(histograma_tamano_salida(i,u)),'\t'));
                        end
                        fprintf(file_histogramas_tamano_salida,'\n');
                    end
                    fclose(file_histogramas_tamano_salida);
                end%final tamano_filtrar
            end % final paso
        end %final de num_jugadores
    end %final de id_traza
end %final IP_version               

%al acabar con todos los valores, escribo la matriz estadísticas en un
%fichero, para poder pegarlo directamente en excel
file_estadisticas_bucle = fopen(strcat(nombre_archivos,nombre_fichero_estadisticas_bucle,'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'_sizelimit_',num2str(tamano_filtrar),'_bucle.txt'),'w');
%file_estadisticas_bucle = fopen(strcat(nombre_archivos,'_PE_TO_estadis_bucle_',num2str(minimo),'_',num2str(maximo),'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'.txt'),'w');

%para cada fila
for h=1:tamano_estadisticas
    %para cada columna
    for g=1:size(estadisticas,2)
        fprintf(file_estadisticas_bucle,strcat(num2str(estadisticas(h,g)),'\t'));
    end
    %salto de línea después de cada fila
    fprintf(file_estadisticas_bucle,'\n');
end
fclose(file_estadisticas_bucle);