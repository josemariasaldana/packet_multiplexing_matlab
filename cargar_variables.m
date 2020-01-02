%esta variable s�lo se usa en el modo period. Para evitar que d� error al guardar las estad�sticas en
%el modo timeout, la pongo a 0
num_periodos=0;

%la variable "entrada" se refiere al momento en que llega cada paquete nativo
%al multiplexor
%"entrada" tiene las siguientes columnas:

%las tres primeras columnas se leen directamente del fichero de entrada nombre_archivos,'_time_size_user.txt'
% 1 time absoluto de llegada en useg
% 2 size del payload UDP o TCP: o sea, el tama�o a nivel IP - IP_UDP_TCP_HEADER bytes
% 3 user es el �ltimo byte de la IP del usuario
%   Para SDN es 0 en caso de TCP, 1 en caso de UDP, y 2 en caso de RTP

%las otras columnas se calculan nada m�s empezar
% 4 size de la cabecera comprimida. Para IPHC es fijo en toda la traza.
%   Para SDN depende de si el tr�fico original es TCP, UDP o UDP/RTP
% 5 diftime: diferencia de tiempos con el paquete anterior en useg: el diftime del
%   paquete 4 es el time del paquete 5 menos el time del paquete 4
% 6 retention time en useg. Se rellena durante la ejecucion
% 7 instante del env�o en useg

% leo las tres primeras columnas
entrada=load(strcat(nombre_archivos,'_time_size_user.txt'));

%a�ado una columna de ceros para poner el tama�o de la cabecera comprimida
entrada=[entrada zeros(length(entrada(:,1)),1)];

%a�ado una columna de ceros para poner la diferencia de tiempos
entrada=[entrada zeros(length(entrada(:,1)),1)]; 

%la variable "salida" se refiere al momento en que sale cada paquete
%multiplexado
%"salida" tiene las siguientes columnas:
% 1 time absoluto de env�o en useg
% 2 size del payload UDP o TCP: o sea, el tama�o a nivel IP - IP_UDP_TCP_HEADER bytes
% 3 numero paquetes multiplexados
% 4 diftime: diferencia de tiempos con el paquete anterior en useg: el diftime del
%   paquete 4 es el time del paquete 5 menos el time del paquete 4


%ordeno el fichero de entrada seg�n la primera columna (tiempo)
entrada = sortrows (entrada,1);

%calculo las diferencias de tiempos (columna 5 de entrada)
for i=1:length(entrada(:,1))-1
    entrada(i,5)=entrada(i+1,1)-entrada(i,1);
end

if guardar_ficheros_entrada == 1
    %preparo la parte com�n del nombre de los ficheros de entrada
    %escribo el fichero de tiempos absolutos de env�o
    %dlmwrite(strcat(nombre_archivos,'_time.txt'),entrada(:,1),'newline', 'pc','precision','%i');
    %escribo el fichero de diferencias de tiempos de env�o
    dlmwrite(strcat(nombre_archivos,'_diftime.txt'),entrada(:,5),'newline', 'pc','precision','%i');
    %escribo el fichero de tama�os de salida (en payload UDP).
    % Hay que sumarle IP_UDP_HEADER para obtener el tama�o IP
    dlmwrite(strcat(nombre_archivos,'_size.txt'),entrada(:,2),'newline', 'pc');

    %escribo un fichero en el que pongo tres columnas:
    % 1 tiempo absoluto en useg
    % 2 tama�o del payload UDP
    % 3 usuario
    dlmwrite(strcat(nombre_archivos,'_time_size_flujo_ordenado.txt'),[entrada(:,1:2) id_traza*ones(length(entrada),1)],'delimiter', '\t','precision','%i');
end

%a�ado a entrada una sexta fila. la relleno con -1 para decir que ese
%paquete a�n no se ha enviado
entrada=[entrada -1*ones(length(entrada(:,1)),1)];

%a�ado una s�ptima fila para poner el momento del env�o
entrada(:,7)=zeros(length(entrada(:,1)),1);

% si el flujo es 1xx, la tercera columna no es el n�mero de usuario (porque el tr�fico es en general, no de un n�mero de usuarios). Tengo que
% poner todo 1 y poner su informaci�n en la octava columna
if ( id_traza < 600 )
    entrada(:,8)=entrada(:,3);
    entrada(:,3)=ones(length(entrada(:,1)),1);
else
    if floor(id_traza/100) == 9 %es UDP. Pongo 1 en toda la columna 8
        entrada(:,8)=ones(length(entrada(:,1)),1);
    else
        if floor(id_traza/100) == 8 %es TCP. Pongo 0 en toda la columna 8
            entrada(:,8)=zeros(length(entrada(:,1)),1);
        end
    end
end
