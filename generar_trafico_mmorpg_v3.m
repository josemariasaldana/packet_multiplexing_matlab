%% Modelo de trafico de juegos MMORPG
%este programa genera un fichero .txt con el tráfico de varios juegos MMORPG,
%según unas distribuciones estadísticas.
%
% genera un solo fichero para un solo juego y un solo número de jugadores
%
%el resultado es un fichero wow_sc_20_time_size_user.txt
%ese fichero tiene tres columnas: tiempo absoluto de generación del paquete
%en useg; tamaño del payload TCP (sin contar cabecera IP ni TCP) y número
%de usuario que lo genera

%  World of Warcraft segun Svoboda

clear all
close all

%% Datos
%parametros que da svoboda:
eq1_lambda=426;
eq1_k=0.8196;
eq1_l=3010;
eq2_a=218.3e-3; %en segundos
eq2_b=251.2e-3; %en segundos
eq2_c=1500e-3;  %en segundos
eq3_a=6;
eq3_b=19;
eq3_c=43;
eq1_lambda_t_sesion=4321;
eq1_k_t_sesion=0.7813;
eq4_mu=5.512;
eq4_theta=2.434;

%cantidad de APDU a generar por cada usuario. Los paquetes totales serán más, porque también se generan ACKs
cantidad_paquetes = 5000;

IPv4_HEADER = 20 ; %cabecera IPv4/UDP
TCP_HEADER = 20;
IP_TCP_HEADER = IPv4_HEADER + TCP_HEADER; %Tengo que restarla porque los datos me los dan siempre para IPv4
MTU = 1500; %maximo tamano que permite la red
maximo_payload = MTU - IP_TCP_HEADER;

%Algunos paquetes (a nivel de aplicación) son mayores de 1500 bytes. Si se
%pone "fragmentar=1", los parte de forma que su maximo tamaño a nivel IP
%sea de 1500 bytes. Añade un retardo "retardo_fragmentar" a cada paquete
%fragmentado
fragmentar=1; % 0:No fragmentar  1:fragmentar
retardo_fragmentar=50e-6;

generar_ack = 1; %Si vale 1, además del tráfico, genero ACKs con una proporción determinada


%%%%%%%%%%%%%%%% NUMERO JUGADORES %%%%%%%%%%%%%%%%%
jugadores = 10;

%%%%%%%%%%%%%%% JUEGO QUE SE GENERA %%%%%%%%%%%%%%%
sentido_trafico = 'sc'; %servidor a cliente
%sentido_trafico = 'cs'; %cliente a servidor
nombre_juego = strcat('wow_',sentido_trafico); %World of Warcraft 
%nombre_juego = strcat('rom',sentido_trafico); %Runes of Magic

%el vector tamanos_grande incluye:
% -columna 1: tamaño del paquete en bytes. Es el payload, sin contar la cabecera IP ni TCP
% -columna 2: tiempo respecto al paquete anterior en microsegundos

for u=1:jugadores
    switch(nombre_juego)
        case 'wow_sc'
            %% Server to Client

            % Generando tamanos de paquetes completos de hasta 3010 bytes en columna 1
            tamanos_grande(:,1)=floor(wblrnd(eq1_lambda,eq1_k,[1 cantidad_paquetes]));
            for i=1:cantidad_paquetes
                if tamanos_grande(i,1)>3010
                    while tamanos_grande(i,1)>3010
                        tamanos_grande(i,1)=floor(wblrnd(eq1_lambda,eq1_k)); %distribución Weibull
                    end
                end
                if tamanos_grande(i,1)==0
                    while tamanos_grande(i,1)==0
                        tamanos_grande(i,1)=floor(wblrnd(eq1_lambda,eq1_k));
                    end
                end
            end

            % Generando los tiempos entre paquetes en columna 2 (en microsegundos)
            for i=1:length(tamanos_grande)
                cont1=random('unif',0,1);
                if cont1<=0.123
                    tamanos_grande(i,2)=random('unif',eq2_b,eq2_c);
                else
                    if cont1<0.38
                        tamanos_grande(i,2)=random('unif',eq2_a,eq2_b);
                    else
                        if cont1<1
                            tamanos_grande(i,2)=random('unif',0,eq2_a);
                        end
                    end
                end
            end
            % Paso los tiempos a microseg
            tamanos_grande(:,2)=tamanos_grande(:,2)*1e6;
        case 'wow_cs'
            %% Client to Server

            % Generando tamanos de paquetes en columna 1
            tamanos_grande=zeros(cantidad_paquetes,2);
            for i=1:length(tamanos_grande)
                cont1=random('unif',0,1);
                if cont1<=0.14
                tamanos_grande(i)=eq3_b;
                else
                    if cont1<0.48
                        tamanos_grande(i)=eq3_c;
                    else
                        if cont1<1
                            tamanos_grande(i)=eq3_a;
                        end
                    end
                end
            end

            % Generando los tiempos entre paquetes en columna 2
            for i=1:length(tamanos_grande)
                cont1=random('unif',0,1);
                if cont1<=0.123
                    tamanos_grande(i,2)=random('unif',eq2_b,eq2_c);
                else
                    if cont1<0.38
                        tamanos_grande(i,2)=random('unif',eq2_a,eq2_b);
                    else
                        if cont1<1
                            tamanos_grande(i,2)=random('unif',0,eq2_a);
                        end
                    end
                end
            end
            % Paso los tiempos a microseg
            tamanos_grande(:,2)=tamanos_grande(:,2)*1e6;
    end %fin del switch(nombre_juego)

    %% Fragmentacion de paquetes
    %En tamanos_grande hay paquetes de más de 1500 bytes.
    %En tamanos todos tienen como máximo 1500 bytes
    tamanos=zeros(cantidad_paquetes,2);
    if fragmentar==1     
        j=1;
        for i=1:length(tamanos_grande)
            if tamanos_grande(i,1)<maximo_payload
                tamanos(j,1)=tamanos_grande(i,1);
                tamanos(j,2)=tamanos_grande(i,2);
                j=j+1;
            else
                if tamanos_grande(i,1)-maximo_payload<=maximo_payload 
                    tamanos(j,1)=maximo_payload;
                    tamanos(j+1,1)=tamanos_grande(i,1)-maximo_payload;
                    tamanos(j,2)=tamanos_grande(i,2);
                    tamanos(j+1,2)=tamanos_grande(i,2)+retardo_fragmentar; % Los fragmentos llevan un reterdo de 50 mico segundos entre ellos
                    j=j+2;
                else
                    tamanos(j,1)=maximo_payload;
                    tamanos(j+1,1)=maximo_payload;
                    tamanos(j+2,1)=tamanos_grande(i,1)-maximo_payload-maximo_payload;
                    tamanos(j,2)=tamanos_grande(i,2);
                    tamanos(j+1,2)=tamanos_grande(i,2)+retardo_fragmentar; % Los fragmentos llevan un reterdo de 50 mico segundos entre ellos
                    tamanos(j+2,2)=tamanos_grande(i,2)+retardo_fragmentar+retardo_fragmentar; % Los fragmentos llevan un reterdo de 50 mico segundos entre ellos
                    j=j+3;
                end
            end
        end

    else %fragmentar=0
        tamanos = tamanos_grande;
    end

    % el resultado está en el vector "tamanos"
    
    %%% Generación de los ACK
    % Tengo que añadir un número de ACK de forma que
    % En el tráfico client-server los ACK sean el 57% de los paquetes totales
    % En el tráfico server-client los ACK sean el 28% de los paquetes totales
    
    proporcion_ack_client_server = 0.57; %Genera un numero de ACK en el sentido client-server de forma que sean el 57% de los paquetes
    proporcion_ack_server_client = 0.28; %Genera un numero de ACK en el sentido server-client de forma que sean el 28% de los paquetes
 
    if generar_ack == 1
        % para calcular la proporción del tráfico, hago que num_ack / (num_ack + num_paquetes_normales) = 0.57
        % esto hace que p.ej. la relación de ACK client-server sea 0.57 / (1- 0.57)
        if sentido_trafico == 'cs'
            relacion_ack = proporcion_ack_client_server / (1 - proporcion_ack_client_server);
        else
            relacion_ack = proporcion_ack_server_client/ (1 - proporcion_ack_server_client);     
        end
        
        % la primera columna del vector de ACK es de ceros, porque no tienen payload
        tamanos_ack(:,1) = zeros (length(tamanos_grande)*relacion_ack);
        
        % ahora tengo que generar relacion_ack * pps del modelo de tiempo entre paquetes
        % Generando los tiempos entre paquetes en columna 2
        for i=1:(length(tamanos_grande)*relacion_ack)
            cont1=random('unif',0,1);
            if cont1 <= 0.123
                tamanos_ack(i,2)=random('unif',eq2_b / relacion_ack , eq2_c / relacion_ack);
            else
                if cont1 < 0.38
                    tamanos_ack(i,2)=random('unif',eq2_a / relacion_ack ,eq2_b / relacion_ack );
                else
                    if cont1 < 1
                        tamanos_ack(i,2)=random('unif',0  ,eq2_a / relacion_ack );
                    end
                end
            end
        end
        % Paso los tiempos a microseg
        tamanos_ack(:,2)=tamanos_ack(:,2)*1e6;
    end
    
    %recorto el vector para que sólo tenga cantidad_paquetes. Al fragmentar y añadir ACK se ha aumentado la cantidad
    tamanos = tamanos(1:cantidad_paquetes,:);
        
    %ahora incluyo todos los paquetes de todos los usuarios en un vector "game" con dos columnas
    % -columna 1: tiempo acumulado en microseg
    % -columna 2: tamaño a nivel IP, sin contar las cabeceras IP ni TCP
    game = zeros(cantidad_paquetes,1);
    game(1) = 1000 * unifrnd(0,40); %el retardo del primer paquete en microsegundos
    for i=2:cantidad_paquetes
        %calculo el tiempo acumulado
        game(i) = game(i-1) + tamanos(i,2);
    end

    
    game = [game tamanos(:,1) u*ones(cantidad_paquetes,1)];
    
    %añado el tráfico de ese jugador al total
    if u==1
        game_total = game;
    else
        game_total = [game_total;game];
    end
end %bucle de cada jugador

segundos_totales = max(game_total(:,1))/1000000

paquetes_por_segundo_totales = cantidad_paquetes / segundos_totales

ack_por_segundo

%% Creando archivos
% ordeno la matriz total
game_total = sortrows(game_total,1);

%si genero ACK, añado las letras "_ACK" al final del nombre
if generar_ack == 1
    nombre_juego = strcat(nombre_juego,'_ACK');
end

%lo escribo en un fichero de texto con saltos de línea
nombre_game=strcat('.\',nombre_juego,'_',num2str(jugadores),'\',nombre_juego,'_',num2str(jugadores),'_time_size_user.txt');
dlmwrite(nombre_game,game_total,'delimiter','\t','newline','pc','precision', '%.0f')

%lo escribo también en la carpeta IPv6 de ese juego
nombre_game=strcat('.\',nombre_juego,'_IPv6_',num2str(jugadores),'\',nombre_juego,'_IPv6_',num2str(jugadores),'_time_size_user.txt');
dlmwrite(nombre_game,game_total,'delimiter','\t','newline','pc','precision', '%.0f')
%dlmwrite('trafico_sever_client.txt',tamanos,'delimiter','\t','newline', 'pc','precision','%.0f');
%dlmwrite('trafico_client_server.txt',tamanos,'delimiter','\t','newline', 'pc','precision','%.0f');

%% Graficos para comprobacion de los archivos generados
figure(1);wblplot(tamanos(:,2))
figure(2);cdfplot(tamanos(:,2))
figure(3);wblplot(tamanos(:,2))
figure(4);cdfplot(tamanos(:,2))
