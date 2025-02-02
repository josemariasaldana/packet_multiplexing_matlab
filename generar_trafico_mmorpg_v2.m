%% Modelo de trafico de juegos MMORPG
%este programa genera un fichero .txt con el tr�fico de varios juegos MMORPG,
%seg�n unas distribuciones estad�sticas.
%
% genera un solo fichero para un solo juego y un solo n�mero de jugadores
%
%el resultado es un fichero wow_sc_20_time_size_user.txt
%ese fichero tiene tres columnas: tiempo absoluto de generaci�n del paquete
%en useg; tama�o del payload TCP (sin contar cabecera IP ni TCP) y n�mero
%de usuario que lo genera

%  World of Warcraft segun Svoboda

clear all
close all

%% Datos
%parametros que da svoboda:
eq1_lambda=426;
eq1_k=0.8196;
eq1_l=3010;
eq2_a=218.3e-3;
eq2_b=251.2e-3;
eq2_c=1500e-3;
eq3_a=6;
eq3_b=19;
eq3_c=43;
eq1_lambda_t_sesion=4321;
eq1_k_t_sesion=0.7813;
eq4_mu=5.512;
eq4_theta=2.434;

%cantidad de paquetes a generar
cantidad_paquetes=5000;

IPv4_HEADER = 20 ; %cabecera IPv4/UDP
TCP_HEADER = 20;
IP_TCP_HEADER = IPv4_HEADER + TCP_HEADER; %Tengo que restarla porque los datos me los dan siempre para IPv4
MTU = 1500; %maximo tamano que permite la red
maximo_payload = MTU - IP_TCP_HEADER;

%Algunos paquetes (a nivel de aplicaci�n) son mayores de 1500 bytes. Si se
%pone "fragmentar=1", los parte de forma que su maximo tama�o a nivel IP
%sea de 1500 bytes. A�ade un retardo "retardo_fragmentar" a cada paquete
%fragmentado
fragmentar=1; % 0:No fragmentar  1:fragmentar
retardo_fragmentar=50e-6;

%%%%%%%%%%%%%%%% NUMERO JUGADORES %%%%%%%%%%%%%%%%%
jugadores = 10;

%%%%%%%%%%%%%%% JUEGO QUE SE GENERA %%%%%%%%%%%%%%%
nombre_juego = 'wow_sc'; %World of Warcraft servidor a cliente
%nombre_juego = 'wow_cs'; %World of Warcraft cliente a servidor 
%nombre_juego = 'rom'; %Runes of Magic


for u=1:jugadores
    switch(nombre_juego)
        case 'wow_sc'
            %% Server to Client

            % Generando tamanos de paquetes completos de hasta 3010 bytes en columna 1
            tamanos_grande(:,1)=floor(wblrnd(eq1_lambda,eq1_k,[1 cantidad_paquetes]));
            for i=1:cantidad_paquetes
                if tamanos_grande(i,1)>3010
                    while tamanos_grande(i,1)>3010
                        tamanos_grande(i,1)=floor(wblrnd(eq1_lambda,eq1_k));
                    end
                end
                if tamanos_grande(i,1)==0
                    while tamanos_grande(i,1)==0
                        tamanos_grande(i,1)=floor(wblrnd(eq1_lambda,eq1_k));
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
    end %fin del switch(nombre_juego)

    %% Fragmentacion de paquetes
    %En tamanos_grande hay paquetes de m�s de 1500 bytes.
    %En tamanos todos tienen como m�ximo 1500 bytes
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
        %recorto el vector para que s�lo tenga cantidad_paquetes. Al
        %fragmentar se ha aumentado la cantidad
        tamanos = tamanos(1:cantidad_paquetes,:);
        
    else %fragmentar=0
        tamanos=tamanos_grande;
    end

    %en la segunda columna est�n los tiempos. Los paso a microseg
    tamanos(:,2)=tamanos(:,2)*1e6;
    
    %genero un vector "game" con dos columnas
    %columna 1: tiempo acumulado en microseg
    %columna 2: tama�o a nivel IP
    game = zeros(cantidad_paquetes,1);
    game(1) = 1000 * unifrnd(0,40); %el retardo del primer paquete
    for i=2:cantidad_paquetes
        %calculo el tiempo acumulado
        game(i) = game(i-1) + tamanos(i,2);
    end

    game = [game tamanos(:,1) u*ones(cantidad_paquetes,1)];
    
    %a�ado el tr�fico de ese jugador al total
    if u==1
        game_total = game;
    else
        game_total = [game_total;game];
    end
end %bucle de cada jugador

segundos_totales = max(game_total(:,1))/1000000

game_total = sortrows(game_total,1);

%% Creando archivos

%lo escribo en un fichero de texto con saltos de l�nea
nombre_game=strcat('.\',nombre_juego,'_',num2str(jugadores),'\',nombre_juego,'_',num2str(jugadores),'_time_size_user.txt');
dlmwrite(nombre_game,game_total,'delimiter','\t','newline','pc','precision', '%.0f')

%lo escribo tambi�n en la carpeta IPv6 de ese juego
nombre_game=strcat('.\',nombre_juego,'_IPv6_',num2str(jugadores),'\',nombre_juego,'_IPv6_',num2str(jugadores),'_time_size_user.txt');
dlmwrite(nombre_game,game_total,'delimiter','\t','newline','pc','precision', '%.0f')
%dlmwrite('trafico_sever_client.txt',tamanos,'delimiter','\t','newline', 'pc','precision','%.0f');
%dlmwrite('trafico_client_server.txt',tamanos,'delimiter','\t','newline', 'pc','precision','%.0f');

%% Graficos para comprobacion de archivos

figure(1);wblplot(tamanos(:,2))
figure(2);cdfplot(tamanos(:,2))
figure(3);wblplot(tamanos(:,2))
figure(4);cdfplot(tamanos(:,2))
