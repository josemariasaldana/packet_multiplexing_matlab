%versi�n 20/11/2014

salida=[];
num_acumulados=0;    %numero paquetes en espera de ser enviados
tam_acumulado=0;     %tama�o acumulado del payload del paquete a multiplexar
ultimo_envio=0;      %instante ultimo env�o

periodos_vacios_acum = 0;    %almaceno el n�mero de periodos vac�os

instante = entrada(1,1);
%para cada paquete
for i=1:length(entrada(:,1))-1
     
    if (instante >= ultimo_envio + PERIOD)
        %el paquete ha llegado despu�s de PERIOD
        %se env�a lo acumulado, pero en el instante ultimo_envio + PERIOD
        %este paquete no se env�a. se enviar� en la siguiente tanda
       
        %si s�lo hay un paquete, y el tr�fico es UDP, no se comprime. Se env�a tal cual
        if num_acumulados == 1
            if floor(id_traza/100) == 9 %es UDP
                %a�ado a la salida un nuevo paquete, sin comprimir
                salida = [salida ; ultimo_envio+PERIOD entrada(i-1,2) num_acumulados];
                %guardo el retention time para todos los paquetes que se env�an
                %el paquete que desencadena el env�o tiene retention time nulo
                entrada(i-1,6)=ultimo_envio-entrada(i-1,1)+PERIOD;
                %se escribe el momento del env�o en la 7� columna
                entrada(i-1,7)=ultimo_envio+PERIOD;
            else %es TCP, y en este caso s� se comprime
                %a�ado a la salida un nuevo paquete: [instante tama�o n�mero]
                salida = [salida ; ultimo_envio+PERIOD entrada(i-1,2)+entrada(i-1,4)+COMMON_HEADER+PPPMux_HEADER-IP_UDP_TCP_HEADER num_acumulados];
                %guardo el retention time para todos los paquetes que se env�an
                %el paquete que desencadena el env�o tiene retention time nulo
                entrada(i-1,6)=ultimo_envio-entrada(i-1,1)+PERIOD;
                %se escribe el momento del env�o en la 7� columna
                entrada(i-1,7)=ultimo_envio+PERIOD;              
            end
        else
            %si hay varios, se env�an todos
            salida = [salida ; ultimo_envio+PERIOD tam_acumulado+(num_acumulados*PPPMux_HEADER)+COMMON_HEADER-IP_UDP_TCP_HEADER num_acumulados];
            %el resto de paquetes acumulados salen en ese instante y hay que
            %calcular su retention time y momento de env�o
            for l=1:num_acumulados
                %calculo el retention time de cada paquete y lo pongo en la sexta
                %columna de entrada               
                entrada(i-l,6)= ultimo_envio+PERIOD - entrada(i-l,1);
                %tambi�n calculo el momento del env�o y lo pongo en la s�ptima
                %columna de entrada
                entrada(i-l,7)= ultimo_envio+PERIOD;
            end
        end
        %calculamos el n�mero de periodos vac�os que ha habido hasta que ha
        %llegado el paquete
        periodos_vacios = floor(((instante - ultimo_envio) / PERIOD)) - 1;
        periodos_vacios_acum = periodos_vacios_acum + periodos_vacios;
        %apunto el instante de este env�o como el �ltimo
        ultimo_envio = ultimo_envio + PERIOD + (PERIOD * periodos_vacios);
        %se acumula el tama�o del payload UDP o TCP y de la cabecera
        tam_acumulado= entrada(i,2) + entrada(i,4);
        %s�lo queda un paquete acumulado
        num_acumulados= 1;
        %momento de llegada del paquete siguiente
        instante=entrada(i+1,1);   
        
    else %ha llegado fuera del timeout, o completa NUMPAQUETES o el tama�o m�ximo, o nada
       
        %acumular el paquete
        tam_acumulado=tam_acumulado + entrada(i,2) + entrada(i,4);%se acumula el tama�o del payload UDP o TCP y de la cabecera
        num_acumulados=num_acumulados + 1;%incremento el n�mero de paquetes acumulados
       
        % calculo el tama�o de la cabecera original IP/UDP, IP/TCP o IP/UDP/RTP que tengo que restar
        if IP_version == 4 %se usa IPv4              
            switch entrada(i,8)
                case 0
                    IP_UDP_TCP_HEADER = IPv4_HEADER + TCP_HEADER;
                case 1
                    IP_UDP_TCP_HEADER = IPv4_HEADER + UDP_HEADER;
                case 2
                    IP_UDP_TCP_HEADER = IPv4_HEADER + UDP_HEADER + RTP_HEADER;
            end
        else %IPv6
            switch entrada(i,8)
                case 0
                    IP_UDP_TCP_HEADER = IPv6_HEADER + TCP_HEADER;
                case 1
                    IP_UDP_TCP_HEADER = IPv6_HEADER + UDP_HEADER;
                case 2
                    IP_UDP_TCP_HEADER = IPv6_HEADER + UDP_HEADER + RTP_HEADER;
            end          
        end
        
        if ((instante > ultimo_envio + TIMEOUT)||(NUMPAQUETES == num_acumulados)||(tam_acumulado+(num_acumulados*PPPMux_HEADER)+COMMON_HEADER >= PACKET_SIZE_TRESHOLD))
            %enviar
            %si s�lo hay un paquete, y el tr�fico es UDP,  no se comprime. Se env�a tal cual
            if num_acumulados == 1
                if floor(id_traza/100) == 9 %es UDP
                    %a�ado a la salida un nuevo paquete
                    salida = [salida ; instante entrada(i,2) num_acumulados];
                    %el paquete que desencadena el env�o tiene retention time nulo
                    entrada(i,6)=0;
                    %escribo el instante de env�o
                    entrada(i,7)=instante;
                else %es TCP. s� se comprime
                    %a�ado a la salida un nuevo paquete: [instante tama�o n�mero]
                    salida = [salida ; instante entrada(i,2)+entrada(i,4)+COMMON_HEADER+PPPMux_HEADER-IP_UDP_TCP_HEADER num_acumulados];
                    %el paquete que desencadena el env�o tiene retention time nulo
                    entrada(i,6)=0;
                    %escribo el instante de env�o
                    entrada(i,7)=instante;     
                end
                %actualizo variables despu�s de enviar
                ultimo_envio=instante;
                num_acumulados=0;
                tam_acumulado=0;
                instante=entrada(i+1,1);   %momento de llegada del paquete siguiente
            else
                %si no se pasa del MTU
                if tam_acumulado + IP_UDP_TCP_HEADER < MTU
                    %si hay varios, se env�an todos
                    salida = [salida ; instante tam_acumulado+(num_acumulados*PPPMux_HEADER)+COMMON_HEADER-IP_UDP_TCP_HEADER num_acumulados];
                    %el paquete que desencadena el env�o tiene retention time nulo
                    entrada(i,6)=0;
                    %escribo el instante de env�o
                    entrada(i,7)=instante;
                    %el resto de paquetes acumulados salen en ese instante y hay que
                    %calcular su retention time
                    for l=1:num_acumulados-1
                        %calculo el retention time de cada paquete y lo pongo en la sexta
                        %columna de entrada
                        entrada(i-l,6)= instante - entrada(i-l,1);
                        %tambi�n calculo el momento del env�o y lo pongo en la s�ptima
                        %columna de entrada
                        entrada(i-l,7)= instante;
                    end
                    %actualizo variables despu�s de enviar
                    ultimo_envio=instante;
                    num_acumulados=0;
                    tam_acumulado=0;
                    instante=entrada(i+1,1);   %momento de llegada del paquete siguiente
                    
                else %se pasa del MTU. Env�o los paquetes que hab�a, pero no el �ltimo que ha llegado
                    salida = [salida ; instante tam_acumulado-entrada(i,2)-entrada(i,4)+((num_acumulados-1)*PPPMux_HEADER)+COMMON_HEADER-IP_UDP_TCP_HEADER num_acumulados-1];
                    %salida = [salida ; instante entrada(i,2)+entrada(i,4)+PPPMux_HEADER+COMMON_HEADER-IP_UDP_TCP_HEADER 1];
                    %el paquete que desencadena el env�o tiene retention time nulo
                    %entrada(i,6)=0;
                    %escribo el instante de env�o
                    %entrada(i,7)=instante;
                    %el resto de paquetes acumulados salen en ese instante y hay que
                    %calcular su retention time
                    for l=1:num_acumulados-1
                        %calculo el retention time de cada paquete y lo pongo en la sexta
                        %columna de entrada
                        entrada(i-l,6)= instante - entrada(i-l,1);
                        %tambi�n calculo el momento del env�o y lo pongo en la s�ptima
                        %columna de entrada
                        entrada(i-l,7)= instante;
                    end
                    %actualizo variables despu�s de enviar
                    ultimo_envio=instante;
                    num_acumulados = 1;
                    tam_acumulado = entrada(i,2) + entrada(i,4);
                    instante=entrada(i+1,1);   %momento de llegada del paquete siguiente
                end
            end    
            
        else %no se env�a nada
            instante=entrada(i+1,1);   %momento de llegada del paquete siguiente
        end
        
    end
    
end

%ya he recorrido toda la matriz de paquetes de entrada
%a�ado a salida una columna de ceros para poner la diferencia de tiempos
salida=[salida zeros(length(salida(:,1)),1)]; 
for i=1:length(salida(:,1))-1
    salida(i,4)=salida(i+1,1)-salida(i,1);
end

%Evito que queden valores -1 en entrada(:,6), borrando los �ltimos
%paquetes, que no se env�an
entrada = entrada (1:size(entrada)-num_acumulados,:);
    

%preparo la parte com�n del nombre de los ficheros de salida
nombre_archivos_salida = strcat(nombre_archivos,'_PE_',num2str(PERIOD/1000),'_TO_',num2str(TIMEOUT/1000),'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'_FM_',num2str(F_MAX_PERIOD),'_size',num2str(tamano_filtrar));
%escribo el fichero de tiempos absolutos de env�o
%dlmwrite(strcat(nombre_archivos_salida,'_time.txt'),salida(:,1),'newline', 'pc','precision','%i');
%escribo el fichero de diferencias de tiempos de env�o
dlmwrite(strcat(nombre_archivos_salida,'_diftime.txt'),salida(:,4),'newline', 'pc','precision','%i');
%escribo el fichero de tama�os de salida (tama�o a nivel IP).
dlmwrite(strcat(nombre_archivos_salida,'_size.txt'),salida(:,2),'newline', 'pc');


%escribo otro fichero con cuatro columnas:
%1  tiempo absoluto
%2  tama�o a nivel IP
%3  identificador del flujo
%4  n�mero de paquetes multiplexados. Ser� 0 si el tr�fico es nativo

%creo la matriz "salida_adaptada"
%tendr� el mismo tama�o que "salida" (4 columnas)
salida_adaptada = zeros(size(salida));
%las dos primeras columnas coinciden. Las copio
salida_adaptada (:,1:2) = salida (:,1:2);
%la tercera columna es el identificador del flujo
switch(nombre_traza)
    case 'hlcs_1_dedust'
        salida_adaptada(:,3) = 901 * ones(length(salida_adaptada(:,3)),1);
    case 'hl2cs_dedust'
        salida_adaptada(:,3) = 902 * ones(length(salida_adaptada(:,3)),1);
    case 'halo2'
        salida_adaptada(:,3) = 903 * ones(length(salida_adaptada(:,3)),1);
    case 'quake2'
        salida_adaptada(:,3) = 904 * ones(length(salida_adaptada(:,3)),1);
    case 'quake3'
        salida_adaptada(:,3) = 905 * ones(length(salida_adaptada(:,3)),1);
    case 'quake4'
        salida_adaptada(:,3) = 906 * ones(length(salida_adaptada(:,3)),1);
    case 'etpro_1_fueldump'
        salida_adaptada(:,3) = 907 * ones(length(salida_adaptada(:,3)),1);
    case 'unreal1.0'
        salida_adaptada(:,3) = 908 * ones(length(salida_adaptada(:,3)),1);
end

%la cuarta columna es el n�mero de paquetes multiplexados
salida_adaptada (:,4) = salida (:,3);

%escribo el fichero. Solamente le a�ado .txt.Quedar� por ejemplo: "hlcs_1_dedust_20_PE_40_TO_40_NP_300_TH_1350_FM_256.txt"
dlmwrite(strcat(nombre_archivos_salida,'.txt'),salida_adaptada,'precision','%6.9f','delimiter', '\t','newline','pc');