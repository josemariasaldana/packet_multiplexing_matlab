%calculo la duración del fichero de entrada y salida
duracion_entrada = entrada(length(entrada))-entrada(1,1);
duracion_salida = salida(length(salida))-salida(1,1);

%calculo el ancho de banda del fichero de entrada en bps a nivel IP.
%Sumo IP_UDP_TCP_HEADER al payload, por las cabeceras IP y UDP o TCP
%multiplico por 1000000 porque el tiempo son microsegundos
%multiplico por 8 para pasar de bytes a bits
BW_entrada = 8*1000000*sum(IP_UDP_TCP_HEADER + entrada(:,2))/duracion_entrada;
BW_salida = 8*1000000*sum(IP_UDP_TCP_HEADER + salida(:,2))/duracion_salida;

%calculo el BW a nivel 2: ETH
BW_entrada_eth = 8*1000000*sum(ETH_HEADER + ETH_CRC + IP_UDP_TCP_HEADER + entrada(:,2))/duracion_entrada;
BW_salida_eth = 8*1000000*sum(ETH_HEADER + ETH_CRC + IP_UDP_TCP_HEADER + salida(:,2))/duracion_salida;

%calculo los paquetes por segundo de entrada y salida
pps_entrada = 1000000*length(entrada(:,1))/duracion_entrada;
pps_salida = 1000000*length(salida(:,1))/duracion_salida;

%calculo el tamaño medio a nivel IP del paquete de entrada y salida
tam_paq_IP_entrada = IP_UDP_TCP_HEADER + mean (entrada(:,2));
tam_paq_IP_salida = IP_UDP_TCP_HEADER + mean (salida(:,2));

%calculamos el número de periodos, y el numero de periodos sin enviar
%para sacar el número de periodos sin enviar hacemos
% duracion_entrada / PERIOD = nun_periodos
% la proporcion de ciclos sin enviar será
% (num_periodos - num_paquetes_salida) / num_periodos =
% = 1 - (num_paquetes_salida / num_periodos)
num_periodos = entrada(length(entrada(:,1)),1) / PERIOD;
proporcion_sin_enviar = periodos_vacios_acum / num_periodos;

% Escribo en un fichero las estadísticas
file_estadisticas = fopen(strcat(nombre_archivos_salida,'_estadisticas.txt'),'w');

%escribo los parámetros de entrada
fprintf(file_estadisticas,strcat('PERIOD: \t',num2str(PERIOD),'\n'));
fprintf(file_estadisticas,strcat('TIMEOUT: \t',num2str(TIMEOUT),'\n'));
fprintf(file_estadisticas,strcat('NUMPAQUETES: \t',num2str(NUMPAQUETES),'\n'));
fprintf(file_estadisticas,strcat('PACKET_SIZE_TRESHOLD: \t',num2str(PACKET_SIZE_TRESHOLD),'\n'));
fprintf(file_estadisticas,strcat('F_MAX_PERIOD: \t',num2str(F_MAX_PERIOD),'\n'));

%escribo los resultados que salen
fprintf(file_estadisticas,strcat('num paq entrada: \t',num2str(length(entrada(:,1))),'\n'));
fprintf(file_estadisticas,strcat('num paq salida: \t',num2str(length(salida(:,1))),'\n'));
fprintf(file_estadisticas,strcat('relación num paq (tanto por uno): \t',num2str(length(salida(:,1))/length(entrada(:,1))),'\n'));
fprintf(file_estadisticas,strcat('media num paq multiplexados: \t',num2str(sum(salida(:,3))/num_periodos),'\n'));
fprintf(file_estadisticas,strcat('duracion entrada (useg): \t',num2str(duracion_entrada),'\n'));
fprintf(file_estadisticas,strcat('duracion salida (useg): \t',num2str(duracion_salida),'\n'));
fprintf(file_estadisticas,strcat('paq/seg entrada: \t',num2str(pps_entrada),'\n'));
fprintf(file_estadisticas,strcat('paq/seg salida: \t',num2str(pps_salida),'\n'));
fprintf(file_estadisticas,strcat('relación paq/seg: \t',num2str(pps_salida/pps_entrada),'\n'));
fprintf(file_estadisticas,strcat('tamaño medio paq IP entrada: \t',num2str(tam_paq_IP_entrada),'\n'));
fprintf(file_estadisticas,strcat('tamaño medio paq IP salida: \t',num2str(tam_paq_IP_salida),'\n'));
fprintf(file_estadisticas,strcat('BW entrada bps nivel IP: \t',num2str(BW_entrada),'\n'));
fprintf(file_estadisticas,strcat('BW salida bps nivel IP: \t',num2str(BW_salida),'\n'));
fprintf(file_estadisticas,strcat('BW entrada bps nivel eth: \t',num2str(BW_entrada_eth),'\n'));
fprintf(file_estadisticas,strcat('BW salida bps nivel eth: \t',num2str(BW_salida_eth),'\n'));
fprintf(file_estadisticas,strcat('relación BW nivel IP(tanto por uno): \t',num2str(BW_salida/BW_entrada),'\n'));
fprintf(file_estadisticas,strcat('relación BW nivel eth(tanto por uno): \t',num2str(BW_salida_eth/BW_entrada_eth),'\n'));
fprintf(file_estadisticas,strcat('Retention time medio (useg): \t',num2str(mean(entrada(:,6))),'\n'));
fprintf(file_estadisticas,strcat('Stdev del retention time (useg): \t',num2str(sqrt(var(entrada(:,6)))),'\n'));
fprintf(file_estadisticas,strcat('retention time maximo (useg): \t',num2str(max(entrada(:,6))),'\n'));
fprintf(file_estadisticas,strcat('percentil 95: \t',num2str(prctile(entrada(:,6),95)),'\n'));
fprintf(file_estadisticas,strcat('percentil 99: \t',num2str(prctile(entrada(:,6),99)),'\n'));
fprintf(file_estadisticas,strcat('percentil 99.5: \t',num2str(prctile(entrada(:,6),99.5)),'\n'));
fprintf(file_estadisticas,strcat('percentil 99.9: \t',num2str(prctile(entrada(:,6),99.9)),'\n'));
fprintf(file_estadisticas,strcat('percentil 100: \t',num2str(prctile(entrada(:,6),100)),'\n'));
fprintf(file_estadisticas,strcat('limite paquete pequeno: \t',num2str(tamano_filtrar),'\n'));
fprintf(file_estadisticas,strcat('proporcion_num_paquetes_pequenos: \t',num2str(proporcion_paquetes_pequenos),'\n'));
fprintf(file_estadisticas,strcat('proporcion_ancho_banda_paquetes_pequenos: \t',num2str(proporcion_ancho_banda_paquetes_pequenos),'\n'));

%Sacamos la proporción de ciclos con 0, 1,2,3,4... paquetes

fprintf(file_estadisticas,strcat('proporcion ciclos sin enviar: \t',num2str(proporcion_sin_enviar),'\n'));

%escribo el número de ciclos en que se ha enviado un número de paquetes
for u=1:numero_maximo_paquetes_estadisticas
    fprintf(file_estadisticas,strcat('proporcion ciclos con  ',num2str(u),' paq enviados: \t',num2str(length(find(salida(:,3)==u))/num_periodos),'\n'));
end

fclose(file_estadisticas);

%relleno la matriz estadisticas. Añado una columna
%la variable 'estadisticas' se define en bucle_multiplexar_games
%ahí se define también su tamaño
estadisticas=[estadisticas zeros(tamano_estadisticas,1)];

%escribo los parámetros de entrada en esa columna
estadisticas(1,size(estadisticas,2)) = PERIOD;
estadisticas(2,size(estadisticas,2)) = TIMEOUT;
estadisticas(3,size(estadisticas,2)) = NUMPAQUETES;
estadisticas(4,size(estadisticas,2)) = PACKET_SIZE_TRESHOLD;
estadisticas(5,size(estadisticas,2)) = F_MAX_PERIOD;

%escribo los resultados que salen
estadisticas(6,size(estadisticas,2)) = length(entrada(:,1));
estadisticas(7,size(estadisticas,2)) = length(salida(:,1));
estadisticas(8,size(estadisticas,2)) = length(salida(:,1))/length(entrada(:,1));
estadisticas(9,size(estadisticas,2)) = length(entrada(:,1))/length(salida(:,1));
estadisticas(10,size(estadisticas,2)) = duracion_entrada;
estadisticas(11,size(estadisticas,2)) = duracion_salida;
estadisticas(12,size(estadisticas,2)) = pps_entrada;
estadisticas(13,size(estadisticas,2)) = pps_salida;
estadisticas(14,size(estadisticas,2)) = pps_salida/pps_entrada;
estadisticas(15,size(estadisticas,2)) = tam_paq_IP_entrada;
estadisticas(16,size(estadisticas,2)) = tam_paq_IP_salida;
estadisticas(17,size(estadisticas,2)) = BW_entrada;
estadisticas(18,size(estadisticas,2)) = BW_salida;
estadisticas(19,size(estadisticas,2)) = BW_entrada_eth;
estadisticas(20,size(estadisticas,2)) = BW_salida_eth;
estadisticas(21,size(estadisticas,2)) = BW_salida/BW_entrada;
estadisticas(22,size(estadisticas,2)) = BW_salida_eth/BW_entrada_eth;
estadisticas(23,size(estadisticas,2)) = mean(entrada(:,6));
estadisticas(24,size(estadisticas,2)) = sqrt(var(entrada(:,6)));
estadisticas(25,size(estadisticas,2)) = max(entrada(:,6));

%Percentiles
estadisticas(26,size(estadisticas,2)) = prctile(entrada(:,6),95);
estadisticas(27,size(estadisticas,2)) = prctile(entrada(:,6),99);
estadisticas(28,size(estadisticas,2)) = prctile(entrada(:,6),99.5);
estadisticas(29,size(estadisticas,2)) = prctile(entrada(:,6),99.9);
estadisticas(30,size(estadisticas,2)) = prctile(entrada(:,6),100);

% parámetros de filtrado de paquetes pequeños
estadisticas(31,size(estadisticas,2)) = tamano_filtrar;
estadisticas(32,size(estadisticas,2)) = proporcion_paquetes_pequenos;
estadisticas(33,size(estadisticas,2)) = proporcion_ancho_banda_paquetes_pequenos;

%Proporción ciclos sin enviar
estadisticas(34,size(estadisticas,2)) = proporcion_sin_enviar;
%escribo la proporción de ciclos en que se ha enviado un número de paquetes
for u=1:numero_maximo_paquetes_estadisticas
    %sumo u+numero_estadisticas para que escriba a partir de la posición correspondiente de estadísticas
    estadisticas(u+numero_estadisticas,size(estadisticas,2)) =length(find(salida(:,3)==u))/num_periodos;
end

estadisticas
