%este programa genera un fichero .txt con el tráfico de varios juegos FPS,
%según unas distribuciones estadísticas.
%
% genera un solo fichero para un solo juego y un solo número de jugadores
%
%el resultado es un fichero quake2_time_size_user.txt
%ese fichero tiene tres columnas: tiempo absoluto de generación del paquete
%en useg; tamaño del payload UDP (sin contar cabecera IP ni UDP) y número
%de usuario que lo genera

%para HALO2 sigo el paper de Zander 2005
%se refiere al tráfico para la Xbox
%inter packet time: normal (40,1)
%packet size a nivel IP: extreme(71.2,5.7)
%supongo un solo jugador por consola

%para Unreal Tournament 1.0 sigo a Ratti
%inter packet time: cada 25
%packet size a nivel IP: uniforme[50 65]

%para Quake 2 sigo a Lakkakorpi

clear all
close all

%número de paquetes por jugador
numero_valores = 5000;

%%%%%%%%%%%%%%%% NUMERO JUGADORES %%%%%%%%%%%%%%%%%
jugadores = 20;

%%%%%%%%%%%%%%% JUEGO QUE SE GENERA %%%%%%%%%%%%%%%
nombre_juego = 'halo2'; %con 3000 valores da 120 seg
%nombre_juego = 'unreal1.0'; %con 5000 valores da 125 seg
%nombre_juego = 'quake2'; %con 5000 valores da 160 seg

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IPv4_HEADER = 20 ; %cabecera IPv4/UDP
UDP_HEADER = 8;
IP_UDP_HEADER = IPv4_HEADER + UDP_HEADER; %Tengo que restarla porque los datos me los dan siempre para IPv4

for u=1:jugadores
    switch(nombre_juego)
        case 'halo2'
            %calculo los tiempos en microseg
            tiempos = 1000 * random('Normal',40,1,numero_valores,1);

            %calculo los tamaños en bytes
            tamanos = random('Extreme Value',71.2,5.7,numero_valores,1);

            %lo redondeo como dice el paper de referencia
            tamanos = round((tamanos - 52)/8)*8 +52;
        
        case 'unreal1.0'
            %calculo los tiempos en microseg
            %tiempos = 1000 * 25 .* ones(numero_valores,1); %en teoría es
            %25 fijo. Le pongo varianza 0.5
            tiempos = 1000 * random('Normal',25,0.5,numero_valores,1);
            
            %calculo los tamaños en bytes
            tamanos = floor(random('unif',50,66,numero_valores,1));
    
        case 'quake2'
            tamanos = zeros(numero_valores,1);
            for i=1:numero_valores
                
                %calculo los tiempos en microseg
                %tiro el dado. Si es menor que 4.5 uso una distribución. Si
                %es mayor, uso otra
                dado = unifrnd(0,100);
                if dado < 4.5
                    tiempos(i) = 1000 * random('Extreme Value',6.57,0.517,1,1);
                else
                    tiempos(i) = 1000 * random('Extreme Value',37.9,7.22,1,1);
                end
                
                %calculo los tamaños en bytes, según el paper de referencia
                dado = unifrnd(0,100);
                if dado < 10.6
                    tamanos(i) = 56;
                else
                    if dado < 37
                        tamanos(i) = 62;
                    else
                        if dado < 43.26
                            tamanos(i) = 64;
                        else
                            if dado < 57.16
                                tamanos(i) = 65;
                            else
                                if dado < 62.11
                                    tamanos(i) = 66;
                                else
                                    if dado < 78.41
                                        tamanos(i) = 68;
                                    else
                                        tamanos(i) = 71;
                                    end
                                end
                            end
                        end
                    end
                end                                          
            end        
    end
    %le quito la cabecera IP/UDP
    tamanos = tamanos - IP_UDP_HEADER;
    
    %genero un vector "game" con dos columnas
    %columna 1: tiempo acumulado en microseg
    %columna 2: tamaño a nivel IP
    game = zeros(numero_valores,1);
    game(1) = 1000 * unifrnd(0,40);
    for i=2:numero_valores
        %calculo el tiempo acumulado
        game(i) = game(i-1) + tiempos(i);
    end

    game = [game tamanos u*ones(numero_valores,1)];
    
    %añado el tráfico de ese jugador al total
    if u==1
        game_total = game;
    else
        game_total = [game_total;game];
    end
end

segundos_totales = max(game_total(:,1))/1000000

game_total = sortrows(game_total,1);

nombre_game=strcat('.\',nombre_juego,'_',num2str(jugadores),'\',nombre_juego,'_',num2str(jugadores),'_time_size_user.txt');
%lo escribo en un fichero de texto con saltos de línea
dlmwrite(nombre_game,game_total,'delimiter','\t','newline','pc','precision', '%.0f')