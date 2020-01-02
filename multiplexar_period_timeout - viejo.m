%versi�n 4/11/2011

salida=[];
num_acumulados=0;    %numero paquetes en espera de ser enviados
tam_acumulado=0;     %tama�o acumulado del payload del paquete a multiplexar
ultimo_envio=0;      %instante ultimo env�o

%a�ado a entrada una sexta fila. la relleno con -1 para decir que ese
%paquete a�n no se ha enviado
entrada=[entrada -1*ones(length(entrada(:,1)),1)];

%a�ado una s�ptima fila para poner el momento del env�o
entrada(:,7)=zeros(length(entrada(:,1)),1);

periodos_vacios_acum = 0;    %almaceno el n�mero de periodos vac�os

%para cada paquete
for i=1:length(entrada(:,1))
   instante=entrada(i,1);   %momento de llegada del paquete actual 
   
   if (instante >= ultimo_envio + PERIOD)
       %el paquete ha llegado despu�s de PERIOD
       %se env�a lo acumulado, pero en el instante ultimo_envio + PERIOD
       %este paquete no se env�a. se enviar� en la siguiente tanda
       
       %si s�lo hay un paquete, no se comprime. Se env�a tal cual
       if num_acumulados == 1
           %a�ado a la salida un nuevo paquete
           salida = [salida ; ultimo_envio+PERIOD entrada(i,2) num_acumulados];
           %guardo el retention time para todos los paquetes que se env�an
           %el paquete que desencadena el env�o tiene retention time nulo
           entrada(i-1,6)=ultimo_envio-entrada(i-1,1)+PERIOD;
           %se escribe el momento del env�o en la 7� columna
           entrada(i-1,7)=ultimo_envio+PERIOD;
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
       
   else
       %ha llegado fuera del timeout, o completa NUMPAQUETES o el tama�o
       %se env�a el que llega y todos los acumulados
       if ((instante > ultimo_envio + TIMEOUT)||(NUMPAQUETES == num_acumulados)||(tam_acumulado+(num_acumulados*PPPMux_HEADER)+COMMON_HEADER >= PACKET_SIZE_TRESHOLD))
            %acumular el paquete
            tam_acumulado=tam_acumulado + entrada(i,2) + entrada(i,4);%se acumula el tama�o del payload UDP o TCP y de la cabecera
            num_acumulados=num_acumulados + 1;%incremento el n�mero de paquetes acumulados
            
            %enviar
            %si s�lo hay un paquete, no se comprime. Se env�a tal cual
            if num_acumulados == 1
                %a�ado a la salida un nuevo paquete
                salida = [salida ; instante entrada(i,2) num_acumulados];
                %el paquete que desencadena el env�o tiene retention time nulo
                entrada(i,6)=0;
                %escribo el instante de env�o
                entrada(i,7)=instante;
            else
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
            end
            %actualizo variables despu�s de enviar
            ultimo_envio=instante;
            num_acumulados=0;
            tam_acumulado=0;    
       
       else %no se env�a nada
            %acumular el paquete
            tam_acumulado=tam_acumulado + entrada(i,2) + entrada(i,4);%se acumula el tama�o del payload UDP o TCP y de la cabecera
            num_acumulados=num_acumulados + 1;%incremento el n�mero de paquetes acumulados   
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
nombre_archivos_salida = strcat(nombre_archivos,'_PE_',num2str(PERIOD/1000),'_TO_',num2str(TIMEOUT/1000),'_NP_',num2str(NUMPAQUETES),'_TH_',num2str(PACKET_SIZE_TRESHOLD),'_FM_',num2str(F_MAX_PERIOD));
%escribo el fichero de tiempos absolutos de env�o
%dlmwrite(strcat(nombre_archivos_salida,'_time.txt'),salida(:,1),'newline', 'pc','precision','%i');
%escribo el fichero de diferencias de tiempos de env�o
dlmwrite(strcat(nombre_archivos_salida,'_diftime.txt'),salida(:,4),'newline', 'pc','precision','%i');
%escribo el fichero de tama�os de salida (en payload UDP o TCP).
% Hay que sumarle IP_UDP_TCP_HEADER para obtener el tama�o IP
dlmwrite(strcat(nombre_archivos_salida,'_size.txt'),salida(:,2),'newline', 'pc');


%escribo otro fichero con cuatro columnas:
%1  tiempo absoluto
%2  tama�o del payload UDP o TCP
%3  identificador del flujo
%4  n�mero de paquetes multiplexados. Ser� 0 si el tr�fico es nativo

%creo la matriz "salida_adaptada"
%tendr� el mismo tama�o que "salida" (4 columnas)
salida_adaptada = zeros(size(salida));
%las dos primeras columnas coinciden. Las copio
salida_adaptada (:,1:2) = salida (:,1:2);
%la tercera columna es el identificador del flujo
switch(nombre_juego)
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