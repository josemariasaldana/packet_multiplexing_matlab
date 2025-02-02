%%%%%%%%%%%%%%% PARAMETROS DE IPHC %%%%%%%%%%%%%%%%%%

F_MAX_PERIOD=256; %numero maximo de compressed headers entre dos full headers
F_MAX_TIME=5000000; %en microseg, el tiempo max entre full headers
MAXUSUARIOS=99;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C_NUM=zeros(MAXUSUARIOS); %numero de cabeceras comprimidas desde la ultima full header
F_LAST=-10000000*ones(MAXUSUARIOS); %instante en que envi� la �ltima full header
F_PERIOD=ones(MAXUSUARIOS); %num paquetes comprimidos que puede mandar

%%% Compresi�n IPHC
if (strcmp (compression, 'IPHC') == 1)
% la compresi�n es IPHC. En este caso s�lo se comprimen flujos de un tipo
% de tr�fico (todo WoW, todo Quake, etc).
% No usar para trazas variadas cogidas de Internet (las 1xx)
    if floor(id_traza/100) == 8 %es TCP
        if IP_version == 4 %se usa IPv4 
            if id_traza == 801 %es wow client-to-server
                tamanos_posibles = [4 5 6 7 8 9 10 11 12 13 14];
                frecuencias_posibles = [0 5.061 12.347 27.066 20.977 1.882 1.222 10.953 3.276 14.278 2.938]; %debe sumar 100
            else
                if id_traza == 802 %es wow server-to-client
                    tamanos_posibles = [4 5 6 7 8 9 10 11 12 13 14];
                    frecuencias_posibles = [0.220 14.547 37.334 16.894 0 0 19.46 11.545 0 0 0]; %debe sumar 100
                end
            end
        else %se usa IPv6
            if id_traza == 801 %es wow client-to-server
                tamanos_posibles = [4 5 6 7 8 9 10 11 12 13 14];
                frecuencias_posibles = [5.061 12.347 27.066 20.977 1.882 1.222 10.953 3.276 14.278 2.938 0]; %debe sumar 100
            else
                if id_traza == 802 %es wow server-to-client
                    tamanos_posibles = [3 4 5 6 7 8 9 10 11 12 13 14];
                    frecuencias_posibles = [0.220 14.547 37.334 16.894 0 0 19.46 11.545 0 0 0 0 ]; %debe sumar 100
                end
            end   
        end
        %compruebo que los tama�os de los vectores son iguales
        if size(tamanos_posibles)~=size(frecuencias_posibles)
            error_tamanos_vectores_diferentes = 1
        end
        %compruebo que las frecuencias suman 100
        if (sum(frecuencias_posibles) > 100.01) || (sum(frecuencias_posibles) < 99.99)
            error_frecuencias_no_suman_100 = 1
            sum(frecuencias_posibles)
        end

        %Calculo un vector con las frecuencias posibles acumuladas
        frecuencias_posibles_acum = zeros(1,length(frecuencias_posibles));
        frecuencias_posibles_acum (1) = frecuencias_posibles (1);
        for jj=2:length(frecuencias_posibles)
           frecuencias_posibles_acum (jj)=frecuencias_posibles_acum(jj-1) + frecuencias_posibles(jj); 
        end
        %para cada paquete, calculo la cabecera comprimida
        %en este caso no me importa de qu� jugador sea el paquete
        for i=1:length(entrada(:,1))
            %tiro un dado para decidir el tama�o de cabecera
            dado_wow = random('unif',0,100);
            %calculo el valor de la cabecera seg�n los valores del histograma
            jj=1;
            while dado_wow > frecuencias_posibles_acum(jj)
                jj = jj + 1;       
            end
            %escribo el tama�o de la cabecera
            entrada(i,4)=tamanos_posibles(jj);
        end

        if histogramas_por_pantalla == 1
            hist(entrada(:,4),tamanos_posibles);
        end

    else %es UDP
        if floor(id_traza/100) == 9 %es UDP
            for i=1:length(entrada(:,1))
                instante=entrada(i,1);   %momento actual
                jugador=entrada(i,3);    %jugador al que corresponde este paquete
                %env�o full header de acuerdo a un periodo y a un tiempo m�ximo
                if(C_NUM(jugador)>=F_PERIOD(jugador)) %a este flujo le toca enviar full header
                    C_NUM(jugador)=0;
                    F_LAST(jugador)=instante;
                    F_PERIOD(jugador)=min(2*F_PERIOD(jugador),F_MAX_PERIOD);
                    entrada(i,4)=IP_UDP_TCP_HEADER;
                else
                    if (instante>F_LAST(jugador)+F_MAX_TIME) %lleva mucho tiempo sin enviar full header
                        C_NUM(jugador)=0;
                        F_LAST(jugador)=instante;
                        entrada(i,4)=IP_UDP_TCP_HEADER;
                    else
                        C_NUM(jugador)=C_NUM(jugador)+1;
                        entrada(i,4)=COMPR_HEADER;
                    end
                end
            end
        end
    end
else
    
    % compresi�n SDN. Miro la columna 8 de 'entrada' y aplico el tama�o correspondiente
    if (strcmp (compression, 'SDN') == 1)
        for i=1:length(entrada(:,1))
            switch entrada(i,8)
                case 0
                    entrada(i,4) = IP_TCP_COMPR_HEADER;
                case 1
                    entrada(i,4) =  IP_UDP_COMPR_HEADER;
                case 2
                    entrada(i,4) =  IP_UDP_RTP_COMPR_HEADER;
            end
        end
    end
end