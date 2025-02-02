
%%%%%%%%%% terminan los bucles anidados %%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% aqu� empieza una prueba, que producir� una l�nea del fichero de resultados %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

media_mux_router_deseado = 0;
stdev_mux_router_deseado = 0;

%calculo el tiempo entre paquetes m�nimo en microseg
tiempo_entre_paquetes = 1000000 / paq_por_segundo_buffer;

%miro la versi�n de IP usada
if IP_version == 4
   %se usa IPv4
   IP_UDP_HEADER = IPv4_UDP_HEADER;
else
   %se usa IPv6
   IP_UDP_HEADER = IPv6_UDP_HEADER;
end


%%%%%%%%%%%%%%% BACKGROUND TRAFFIC %%%%%%%%%%%%%
%si se ha definido un tr�fico de fondo
if kbps_background ~= 0
    %el valor de la tercera columna est� entre 101 y 199: uno para cada flujo
    %paquetes de 40, 576 y 1500 bytes
    switch distribucion_trafico_fondo
        case 0 %exponencial
             if IP_version == 4
                %se usa IPv4
                IP_UDP_HEADER = IPv4_UDP_HEADER;
                nombre_archivos_background=strcat('.\_background\background_',num2str(kbps_background),'_kbps_',num2str(duracion_prueba),'_seg.txt');
            else
                %se usa IPv6
                IP_UDP_HEADER = IPv6_UDP_HEADER;
                nombre_archivos_background=strcat('.\_background\background_IPv6_',num2str(kbps_background),'_kbps_',num2str(duracion_prueba),'_seg.txt');
            end           
        case 1 %pareto
            if IP_version == 4
                %se usa IPv4
                IP_UDP_HEADER = IPv4_UDP_HEADER;
                nombre_archivos_background=strcat('.\_background\background_pareto_alfa_',num2str(alfa_pareto),'_',num2str(kbps_background),'_kbps_',num2str(duracion_prueba),'_seg.txt');
            else
                %se usa IPv6
                IP_UDP_HEADER = IPv6_UDP_HEADER;
                nombre_archivos_background=strcat('.\_background\background_IPv6_pareto_alfa_',num2str(alfa_pareto),'_',num2str(kbps_background),'_kbps_',num2str(duracion_prueba),'_seg.txt');
            end
    end
    %abro el fichero con el tr�fico de fondo
    background = load(nombre_archivos_background);
    %le a�ado una columna de ceros, para que tenga las mismas dimensiones que el tr�fico deseado. Esa cuarta columna no se utiliza
    background = [background zeros(size(background(:,1),1),1)];
else
    %si no hay tr�fico de fondo, pongo s�lo tres paquetes en el instante 0, uno de cada tama�o
    %que se descartar�n por los m�rgenes iniciales
    background = [0 50 101 0; 0 572 102 0; 0 1500 103 0];
end

%%%%%%%%%%%%%%% TRAFICO DESEADO %%%%%%%%%%%%%%%

%tr�fico de juegos
if tipo_trafico > 900
    switch(tipo_trafico)
    case 901
        nombre_juego = 'hlcs_1_dedust';
    case 902
        nombre_juego = 'hl2cs_dedust';
    case 903
        nombre_juego = 'halo2';
    case 904
        nombre_juego = 'quake2';
    case 905
        nombre_juego = 'quake3';
    case 906
        nombre_juego = 'quake4';
    case 907
        nombre_juego = 'etpro_1_fueldump';
    case 908
        nombre_juego = 'unreal1.0';
    end
    %nombre_archivos_deseado es la parte com�n del nombre de los ficheros
    nombre_archivos_deseado=strcat('.\',nombre_juego,'_',num2str(num_jugadores),'\',nombre_juego,'_',num2str(num_jugadores));
    
    %%%% cargo el tr�fico nativo del juego en la variable "nativo"
    % si el tr�fico ya es nativo, no lo calculo
    if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
        nativo = load(strcat(nombre_archivos_deseado,'_time_size_flujo_ordenado.txt'));
        %le a�ado una columna en blanco para guardar el instante en que sale del buffer
        nativo = [nativo zeros(length(nativo),1)];
    end
    
    %a�ado los dem�s par�metros para encontrar el nombre del juego
    if (PE==0) || (TO==0) || (NP == 0) || (TH == 0)
        %si no est� multiplexado
        nombre_archivos_deseado = strcat(nombre_archivos_deseado,'_time_size_flujo_ordenado');
    else 
        %si est� multiplexado
        nombre_archivos_deseado = strcat(nombre_archivos_deseado,'_PE_',num2str(PE),'_TO_',num2str(TO),'_NP_',num2str(NP),'_TH_',num2str(TH),'_FM_256');
    end

else
    if floor(tipo_trafico/100) == 5
        nombre_archivos_deseado=strcat('.\pplive_adsl_udp\pplive_adsl_udp_','time_size_user');
    else    
        %tama�o fijo por kbps
        if tipo_trafico == 201
            nombre_archivos_deseado=strcat('.\_fixed_size\fixed_size_',num2str(tamano_fijo),'_bytes_',num2str(kbps_tamano_fijo),'_kbps_',num2str(duracion_prueba),'_seg');
        else
            %tama�o fijo por pps
            if tipo_trafico == 301
                nombre_archivos_deseado=strcat('.\_fixed_size\fixed_size_',num2str(tamano_fijo),'_bytes_',num2str(pps_tamano_fijo),'_pps_',num2str(duracion_prueba),'_seg');
            end
        end
    end
end

paquetes_deseado = load(strcat(nombre_archivos_deseado,'.txt'));

%quito los nativos que no est�n en paquetes_deseado
if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
    %calculo la suma de la cuarta columna de los paquetes deseados, que es el n�mero de paquetes multiplexados
    nativo = nativo(1:sum(paquetes_deseado(:,4)),:);
end

%si el tr�fico es de juegos, sumo la cabecera IP/UDP a la segunda columna
if floor (tipo_trafico/100) == 9
    paquetes_deseado(:,2) = paquetes_deseado(:,2) + IP_UDP_HEADER;
end

num_paquetes_deseado = length(paquetes_deseado);

%descripci�n de la matriz "paquetes_deseado":
%columna 1: instante de llegada en microseg
%columna 2: tama�o en bytes a nivel IP
%columna 3: identificador del flujo
%columna 4: n�mero de paquetes multiplexados que lleva. Ser� 0 si no tiene paquetes multiplexados
%si el tr�fico original no lleva la cuarta columna, la a�ado
if size(paquetes_deseado,2)==3
    paquetes_deseado = [paquetes_deseado zeros(length(paquetes_deseado(:,1)),1)];
end


%%%%%%%%%%%%%% Repito el tr�fico deseado tantas veces como haga falta para completar la duraci�n de la prueba %%%%%%%%%%%%%%%%%%%%%%%%
duracion_deseado = paquetes_deseado (size(paquetes_deseado,1),1);
veces_repetir = ceil(1000000 * duracion_prueba / duracion_deseado);

%paquetes_con_repeticiones es la concatenacion de 'paquetes_deseado' varias veces, hasta pasarse de la duracion
paquetes_con_repeticiones = paquetes_deseado;

%hago lo mismo con el tr�fico nativo
if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
    nativo_con_repeticiones = nativo;
end


for i=2:veces_repetir - 1
    %sumo la duraci�n para que el tiempo absoluto sea correcto
    paquetes_deseado(:,1) = paquetes_deseado(:,1) + duracion_deseado;
    %lo concateno
    paquetes_con_repeticiones = [paquetes_con_repeticiones; paquetes_deseado];
    
    %hago la misma concatenaci�n con el tr�fico nativo
    if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
        %sumo la duraci�n para que el tiempo absoluto sea correcto
        nativo(:,1) = nativo(:,1) + duracion_deseado;
        %lo concateno
        nativo_con_repeticiones = [nativo_con_repeticiones; nativo];
    end
end

%concateno por �ltima vez sin pasarme de la duraci�n total
%sumo la duraci�n para que el tiempo absoluto sea correcto
paquetes_deseado(:,1) = paquetes_deseado(:,1) + duracion_deseado;
if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
    nativo(:,1) = nativo(:,1) + duracion_deseado;
end

%busco la posici�n en que se pasa de la duracion_prueba
i=1;%variable para contar paquetes multiplexados
j=1;%variable para contar paquetes nativos
while (paquetes_deseado(i,1) < duracion_prueba * 1000000)
    i=i+1;
    if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
       j=j+paquetes_deseado(i,4); 
    end
end

%recorto paquetes_deseado hasta que se pasa de duracion_prueba
paquetes_deseado = paquetes_deseado (1:i,:);
if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
    nativo = nativo (1:j,:);
end

%lo concateno
paquetes_con_repeticiones = [paquetes_con_repeticiones; paquetes_deseado];
if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
    nativo_con_repeticiones = [nativo_con_repeticiones; nativo];
end

%%%%%%%%%%%%%%%%% Junto el tr�fico background y el deseado %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%construyo "paquetes" como "paquetes_con_repeticiones" y "background"
paquetes = [paquetes_con_repeticiones ; background];

%elimino estas variables, que ya no hacen falta
clear paquetes_deseado;
clear nativo;
clear paquetes_con_repeticiones;
clear background;

%ordeno el fichero de paquetes seg�n la primera columna (tiempo)
paquetes = sortrows (paquetes,1);

%para pruebas sencillas, descomentar esto
%paquetes=[1 45 101 20;10 50 102 19;12 47 906 18;45 50 906 20;130 41 103 20;150 42 906 19;350 43 102 18;450 44 906 20;460 46 103 20;510 48 906 19;602 47 906 18;705 50 101 20;803 45 906 20;1150 50 102 19;1350 47 103 18;14500 50 102 20];


%a�ado una columna de ceros (columna 5)para poner el instante en que se empieza a enviar en microseg
paquetes=[paquetes zeros(length(paquetes(:,1)),1)]; 
%a�ado una columna de ceros (columna 6) para poner el instante en que se termina de enviar
paquetes=[paquetes zeros(length(paquetes(:,1)),1)];
%a�ado una columna de ceros (columna 7) para poner: 1: aceptado; 0: rechazado por no caber
paquetes=[paquetes zeros(length(paquetes(:,1)),1)];
%a�ado una columna de ceros (columna 8) para poner la ocupaci�n del buffer justo despu�s de llegar el paquete
paquetes=[paquetes zeros(length(paquetes(:,1)),1)];
%a�ado una columna de ceros (columna 9) para poner la ocupaci�n del buffer justo despu�s de llegar el paquete
paquetes=[paquetes zeros(length(paquetes(:,1)),1)];

%meto el primer paquete al buffer
%instante en que empieza a enviarse
paquetes(1,5) = retardo_procesado + paquetes(1,1);
%instante en que termina de enviarse
paquetes(1,6) = paquetes(1,5) + (paquetes(1,2)* 8 * 1000000 / bits_por_segundo_buffer); 
%aceptado o no
paquetes(1,7) = 1;
%ocupaci�n del buffer en bytes despu�s de llegar el paquete
paquetes(1,8) = paquetes(1,2);
%ocupaci�n del buffer en paquetes despu�s de llegar el paquete
paquetes(1,9) = 1;

%ocupaci�n del buffer en bytes
ocupacion = paquetes(1,2);
%n�mero de paquetes que hay en el buffer
numero_en_buffer = 1;
%posici�n del �ltimo paquete que se ha empezado a enviar
ultimo_enviado = 1;

primer_bg_sin_enviar = 0;
numero_bg_por_enviar = 0;

%j es el �ndice que se usa para ver el tiempo en que terminan de enviarse los paquetes
j=1;


%saco por pantalla los datos de la simulaci�n actual
nombre_archivos_deseado
prioridad
politica_buffer
kbits_por_segundo_buffer
kbps_background
switch politica_buffer
    case 1 %strict
        tamano_buffer
    case 2 %one byte
        tamano_buffer
    case 3 %fixed number
        num_maximo_paq_en_buffer
    case 4 %time-limited
        tiempo_limite_buffer
end


%%%%%%%%%%%%%%%% Bucle principal %%%%%%%%%%%%%%%%
for i=2:length(paquetes(:,1))
    
    %j va por detr�s de i. Se refiere a los paquetes en cola
    
    %quito del buffer todos los paquetes que est�n en el buffer y terminan de enviarse antes del instante de la llegada del nuevo paquete
    %el tiempo de final del paquete j debe ser anterior a la llegada del paquete i
    while (paquetes(j,6) <= paquetes(i,1)) && (j < i)
        if politica_buffer ~= 4 %si la pol�tica no es time-limited
            %miro si ha sido aceptado y lo env�o
            if paquetes(j,7) == 1
                %lo quito del buffer
                ocupacion = ocupacion - paquetes (j,2);
                numero_en_buffer = numero_en_buffer - 1;
            end

            
        %la pol�tica es 4 time-limited. Todos los paquetes se aceptan en principio
        else 
            %si el tiempo que ha pasado desde que lleg� hasta que le toca empezar a enviarse es mayor que el tiempo m�ximo
            if max(paquetes(ultimo_enviado,6), paquetes(ultimo_enviado,5)+tiempo_entre_paquetes) - paquetes(j,1) > 1000 * tiempo_limite_buffer
                %lo descarto
            else
                %se env�a
                paquetes(j,7) = 1;
                
                %relleno el momento en que empieza a enviarse
                paquetes(j,5) = retardo_procesado + max(max(paquetes(j,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
            
                %calculo el instante en que termina de enviarse
                paquetes(j,6) = paquetes(j,5) + (paquetes(j,2)* 8 * 1000000 / bits_por_segundo_buffer);

                %actualizo este paquete como el �ltimo enviado
                ultimo_enviado = j;
                
                %lo quito del buffer
                ocupacion = ocupacion - paquetes (j,2);
                numero_en_buffer = numero_en_buffer - 1;

            end
        end
        
        %paso al siguiente paquete
        j = j + 1;
    end


    %a�ado el nuevo paquete que llega, s�lo si cabe seg�n:
    %   politica 1: el paquete s�lo entra al buffer si cabe entero
    %   pol�tica 2: el paquete entra al buffer si hay un byte libre en el buffer
    %   pol�tica 3: seg�n el n�mero paquetes
    %   pol�tica 4: seg�n el tiempo que lleva en la cola
    switch( politica_buffer )
        case 1 %el paquete s�lo entra al buffer si cabe entero

        if (ocupacion + paquetes(i,2) <= tamano_buffer)
            %si no hay prioridades
            if prioridad == 0
            %calculo el instante en que empieza a enviarse
            %es el m�ximo entre - momento en que llega
            %                   - Final del �ltimo enviado
            %                   - Principio del �ltimo enviado + tiempo entre paquetes
            %
            %a�ado un retardo de procesado
            paquetes(i,5) = retardo_procesado + max(max(paquetes(i,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
            
            %calculo el instante en que termina de enviarse
            paquetes(i,6) = paquetes(i,5) + (paquetes(i,2)* 8 * 1000000 / bits_por_segundo_buffer);

            %actualizo este paquete como el �ltimo enviado
            ultimo_enviado = i;
        
            paquetes(i,8) = ocupacion + paquetes(i,2);
            paquetes(i,9) = numero_en_buffer + 1;
            ocupacion = ocupacion + paquetes(i,2);
            numero_en_buffer = numero_en_buffer + 1;
            paquetes(i,7)=1;
            
            %si hay prioridades !!!NO FUNCIONA TODAVIA
            else
                if floor(paquetes(i,3)/100) == 1 %es un paquete de tr�fico de fondo (sin prioridad)
                    %me lo salto y apunto que est� pendiente
                    numero_bg_por_enviar = numero_bg_por_enviar + 1;
                    
                    %si es el primero de bg, lo apunto en la variable
                    if primer_bg_sin_enviar == 0
                        primer_bg_sin_enviar = i;
                    end
                    
                else %es un paquete de tr�fico deseado (con prioridad)
   
                    %calculo cu�ndo empezar�a a enviarse el primer_bg_sin
                    %enviar
                    momento_empezaria = retardo_procesado + max(max(paquetes(primer_bg_sin_enviar,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
                    %env�o todos los paquetes de bg sin enviar que haya delante del �ltimo paquete deseado enviado
                    
                    while (primer_bg_sin_enviar < i) && (primer_bg_sin_enviar ~= 0) && (momento_empezaria < paquetes(i,1))
                        k = primer_bg_sin_enviar;
                        %lo env�o
                        paquetes(k,5) = retardo_procesado + max(max(paquetes(k,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
                        %calculo el instante en que termina de enviarse
                        paquetes(k,6) = paquetes(k,5) + (paquetes(k,2)* 8 * 1000000 / bits_por_segundo_buffer);
                                          
                        %actualizo este paquete como el �ltimo enviado
                        ultimo_enviado = k;
        
                        paquetes(k,8) = ocupacion + paquetes(k,2);
                        paquetes(k,9) = numero_en_buffer + 1;
                        ocupacion = ocupacion + paquetes(k,2);
                        numero_en_buffer = numero_en_buffer + 1;
                        paquetes(k,7)=1;
                        while (floor(paquetes(primer_bg_sin_enviar,3)/100)~=1) && (primer_bg_sin_enviar < i)
                            primer_bg_sin_enviar = primer_bg_sin_enviar + 1;
                        end
                    end
                    
                    %env�o el paquete con prioridad
                    paquetes(i,5) = retardo_procesado + max(max(paquetes(i,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
                    %calculo el instante en que termina de enviarse
                    paquetes(i,6) = paquetes(i,5) + (paquetes(i,2)* 8 * 1000000 / bits_por_segundo_buffer);

                    %actualizo este paquete como el �ltimo enviado
                    ultimo_enviado = i;
        
                    paquetes(i,8) = ocupacion + paquetes(i,2);
                    paquetes(i,9) = numero_en_buffer + 1;
                    ocupacion = ocupacion + paquetes(i,2);
                    numero_en_buffer = numero_en_buffer + 1;
                    paquetes(i,7)=1;
                 
                    
                end
            end 
        end
        
        case 2 %politica_buffer ==2. el paquete entra al buffer si hay un byte libre en el buffer
        if (ocupacion < tamano_buffer)
   
            %calculo el instante en que empieza a enviarse
            %a�ado un retardo de procesado
            paquetes(i,5) = retardo_procesado + max(max(paquetes(i,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
            
            %calculo el instante en que termina de enviarse
            paquetes(i,6) = paquetes(i,5) + (paquetes(i,2)* 8 * 1000000 / bits_por_segundo_buffer);

            %actualizo este paquete como el �ltimo enviado
            ultimo_enviado = i;
        
            paquetes(i,8) = ocupacion + paquetes(i,2);
            paquetes(i,9) = numero_en_buffer + 1;
            ocupacion = ocupacion + paquetes(i,2);
            numero_en_buffer = numero_en_buffer + 1;
            paquetes(i,7)=1;
        end

        case 3 %politica_buffer ==3. El paquete entra seg�n un l�mite en n�mero de paquetes, y no por tama�o
        if (numero_en_buffer < num_maximo_paq_en_buffer)
   
            %calculo el instante en que empieza a enviarse
            %a�ado un retardo de procesado
            paquetes(i,5) = retardo_procesado + max(max(paquetes(i,1),paquetes(ultimo_enviado,6)),paquetes(ultimo_enviado,5)+tiempo_entre_paquetes);
            
            %calculo el instante en que termina de enviarse
            paquetes(i,6) = paquetes(i,5) + (paquetes(i,2)* 8 * 1000000 / bits_por_segundo_buffer);

            %actualizo este paquete como el �ltimo enviado
            ultimo_enviado = i;
        
            paquetes(i,8) = ocupacion + paquetes(i,2);
            paquetes(i,9) = numero_en_buffer + 1;
            ocupacion = ocupacion + paquetes(i,2);
            numero_en_buffer = numero_en_buffer + 1;
            paquetes(i,7)=1;
        end
        
        case 4 %politica_buffer==4 pol�tica "time-limited". El paquete se acepta siempre
        
            paquetes(i,8) = ocupacion + paquetes(i,2);
            paquetes(i,9) = numero_en_buffer + 1;
            ocupacion = ocupacion + paquetes(i,2);
            numero_en_buffer = numero_en_buffer + 1;
        
    end    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% descomentar esto para pruebas
%paquetes

end


%%%%%%%%%%%%%%% C�lculo de estad�sticas %%%%%%%%%%%%%%%%%%

% Si tengo que calcular el jitter conjunto, relleno la 4� columna de nativo_con_repeticiones
%si el tr�fico es nativo (PE==0), no calculo esto, porque no hay jitter conjunto, sino s�lo el del router
if (calcular_jitter_conjunto == 1) && (PE~=0) && (TO~=0)
    %ordeno por tipo de tr�fico y por tiempo
    paquetes = sortrows(paquetes, [3 1]);
    
    posicion_paquetes = 1;
    %busco el primer paquete que no sea de background
    while floor(paquetes(posicion_paquetes,3)/100) == 1
        posicion_paquetes = posicion_paquetes + 1;
    end
    
    %variable para indexar la posicion en la matriz "nativo_con_repeticiones"
    posicion_nativo = 1;
    for i=posicion_paquetes:length(paquetes)
        %si tiene paquetes multiplexados
        if (paquetes(i,4)~=0)
            for j=1:paquetes(i,4)
                %pongo en la cuarta columna de "nativo_con_repeticiones" el momento en que sale del buffer
                nativo_con_repeticiones(posicion_nativo,4)=paquetes(i,6);
                posicion_nativo = posicion_nativo +1;
            end
        else %no tiene paquetes multiplexados
            posicion_nativo = posicion_nativo +1;
        end
    end
    %calculo las posiciones inicial y final para sacar las estad�sticas
    comienzo_estadisticas = floor(porcentaje_desechar_inicio*length(nativo_con_repeticiones(:,1)));
    final_estadisticas = floor((1-porcentaje_desechar_final)*length(nativo_con_repeticiones(:,1)));
    
    %recorto la matriz "nativo_con_repeticiones"
    nativo_con_repeticiones = nativo_con_repeticiones (comienzo_estadisticas:final_estadisticas,:);
    
    %quito de "nativo_con_repeticiones" los paquetes que no han entrado al buffer, o sea, los que tengan un valor 0 en la cuarta columna, porque
    %no tienen tiempo de env�o
    nativo_con_repeticiones = sortrows(nativo_con_repeticiones,4);
    %busco la posici�n en que no hay un cero en la cuarta columna
    i=1;
    while (i<length(nativo_con_repeticiones)) && (nativo_con_repeticiones(i,4)==0)
        i = i + 1;
    end
    %si ha acabado el while y ha habido alg�n aceptado, me quedo con el trozo correspondiente
    if i ~= size (nativo_con_repeticiones,1)
        nativo_con_repeticiones = nativo_con_repeticiones(i:size(nativo_con_repeticiones,1),:);
    end
    
    %calculo la stdev
    stdev_mux_router_deseado = (1/1000) * std(nativo_con_repeticiones(:,4) - nativo_con_repeticiones(:,1));
   
    media_mux_router_deseado = (1/1000) * mean(nativo_con_repeticiones(:,4) - nativo_con_repeticiones(:,1));
    %vuelvo a ordenar por tiempo
    paquetes = sortrows (paquetes, 1);
end

%calculo las posiciones inicial y final para sacar las estad�sticas
comienzo_estadisticas = floor(porcentaje_desechar_inicio*length(paquetes(:,1)));
final_estadisticas = floor((1-porcentaje_desechar_final)*length(paquetes(:,1)));

%cojo s�lo la parte interesante del resultado para las estad�sticas,
%quitando el principio y el final
paquetes_recortado = paquetes (comienzo_estadisticas:final_estadisticas,:);

clear paquetes;

tamano_paquetes_recortado = size(paquetes_recortado,1);

%calculo la media de ocupaci�n del buffer
%aproximo por la media de lo que encuentran los paquetes aceptados al llegar
prob_aceptado = mean(paquetes_recortado(:,7));
ocupacion_media_bytes = sum(paquetes_recortado(:,8) .* paquetes_recortado(:,7)) / sum(paquetes_recortado(:,7));
ocupacion_media_paquetes = sum(paquetes_recortado(:,9) .* paquetes_recortado(:,7)) / sum(paquetes_recortado(:,7));

%antiguo c�lculo de la ocupaci�n media. Estaba mal
%bytes_acumulado = 0;
%paquetes_acumulado = 0;
%for i=1:tamano_paquetes_recortado - 1
%    bytes_acumulado = bytes_acumulado + (paquetes_recortado(i,8) * (paquetes_recortado(i+1,5) - paquetes_recortado(i,5)));
%    paquetes_acumulado = paquetes_acumulado + (paquetes_recortado(i,9) * (paquetes_recortado(i+1,5) - paquetes_recortado(i,5)));
%end
%calculo la ocupaci�n media del buffer en bytes
%ocupacion_media_bytes = bytes_acumulado / (paquetes_recortado(tamano_paquetes_recortado,6) - paquetes_recortado(1,6))
%calculo la ocupaci�n media del buffer en n�mero de paquetes
%ocupacion_media_paquetes = paquetes_acumulado / (paquetes_recortado(tamano_paquetes_recortado,6) - paquetes_recortado(1,6))


%%%%%%%%%% calculo de los resultados para cada flujo %%%%%%%%%%%%%%5
%divido la matriz seg�n los flujos
%la ordeno por flujos
paquetes_recortado = sortrows (paquetes_recortado, 3);

if kbps_background ~= 0
    %el primer flujo ser� el 101: Background peque�o
    comienzo = 1;
    i=1;
    while paquetes_recortado (i+1,3) == paquetes_recortado(i,3)
        i=i+1;
    end
    %ha acabado un flujo
    paquetes_background_1 = paquetes_recortado(comienzo:i,:);

    %el segundo flujo ser� el 102: Background medio
    comienzo = i+1;
    i=i+1;
    while paquetes_recortado (i+1,3) == paquetes_recortado(i,3)
        i=i+1;
    end
    %ha acabado un flujo
    paquetes_background_2 = paquetes_recortado(comienzo:i,:);

    %el tercer flujo ser� el 103: Background grande
    comienzo = i+1;
    i=i+1;
    while paquetes_recortado (i+1,3) == paquetes_recortado(i,3)
        i=i+1;
    end
    %ha acabado un flujo
    paquetes_background_3 = paquetes_recortado(comienzo:i,:);

else
    %no hay tr�fico background
    paquetes_background_1 = [0 0 101 0 0 0 0 0 0];
    paquetes_background_2 = [0 0 102 0 0 0 0 0 0];
    paquetes_background_3 = [0 0 103 0 0 0 0 0 0];
    i = 0;
end
%hago una variable con todos los paquetes de fondo
paquetes_background = [paquetes_background_1 ; paquetes_background_2 ; paquetes_background_3];

%el cuarto flujo ser� el 999: tr�fico deseado. Ser� lo que quede
comienzo = i+1;
paquetes_resultado_deseado = paquetes_recortado(comienzo:size(paquetes_recortado,1),:);

%%%%%%%% fin de division de la matriz
%%%%%%%% calculo estadisticas

%prob loss
prob_loss_deseado = 1 - (sum(paquetes_resultado_deseado(:,7))/size(paquetes_resultado_deseado,1));
if kbps_background ~= 0
    prob_loss_background_1 = 1 - (sum(paquetes_background_1(:,7))/size(paquetes_background_1,1));
    prob_loss_background_2 = 1 - (sum(paquetes_background_2(:,7))/size(paquetes_background_2,1));
    prob_loss_background_3 = 1 - (sum(paquetes_background_3(:,7))/size(paquetes_background_3,1));
    prob_loss_background = 1 - (sum(paquetes_background(:,7))/size(paquetes_background,1));
else
    prob_loss_background_1 = 0;
    prob_loss_background_2 = 0;
    prob_loss_background_3 = 0;
    prob_loss_background = 0;
end
prob_loss_total = 1 - mean(paquetes_recortado(:,7));

%trafico a nivel IP kbps
trafico_ofrecido_IP_deseado = 8 * 1000 * sum(paquetes_resultado_deseado(:,2)) / (paquetes_resultado_deseado(size(paquetes_resultado_deseado,1),1) - paquetes_resultado_deseado(1,1));
trafico_cursado_IP_deseado = 8 * 1000 * sum(paquetes_resultado_deseado(:,2) .* paquetes_resultado_deseado(:,7)) / (paquetes_resultado_deseado(size(paquetes_resultado_deseado,1),1) - paquetes_resultado_deseado(1,1));

if kbps_background ~= 0
    trafico_ofrecido_IP_background_1 = 8 * 1000 * sum(paquetes_background_1(:,2)) / (paquetes_background_1(size(paquetes_background_1,1),1) - paquetes_background_1(1,1));
    trafico_cursado_IP_background_1 = 8 * 1000 * sum(paquetes_background_1(:,2) .* paquetes_background_1(:,7)) / (paquetes_background_1(size(paquetes_background_1,1),1) - paquetes_background_1(1,1));
    trafico_ofrecido_IP_background_2 = 8 * 1000 * sum(paquetes_background_2(:,2)) / (paquetes_background_2(size(paquetes_background_2,1),1) - paquetes_background_2(1,1));
    trafico_cursado_IP_background_2 = 8 * 1000 * sum(paquetes_background_2(:,2) .* paquetes_background_2(:,7)) / (paquetes_background_2(size(paquetes_background_2,1),1) - paquetes_background_2(1,1));
    trafico_ofrecido_IP_background_3 = 8 * 1000 * sum(paquetes_background_3(:,2)) / (paquetes_background_3(size(paquetes_background_3,1),1) - paquetes_background_3(1,1));
    trafico_cursado_IP_background_3 = 8 * 1000 * sum(paquetes_background_3(:,2) .* paquetes_background_3(:,7)) / (paquetes_background_3(size(paquetes_background_3,1),1) - paquetes_background_3(1,1));
    trafico_ofrecido_IP_background = 8 * 1000 * sum(paquetes_background(:,2)) / (paquetes_background(size(paquetes_background,1),1) - paquetes_background(1,1));
    trafico_cursado_IP_background = 8 * 1000 * sum(paquetes_background(:,2) .* paquetes_background(:,7)) / (paquetes_background(size(paquetes_background,1),1) - paquetes_background(1,1));
else
    trafico_ofrecido_IP_background_1 = 0;
    trafico_cursado_IP_background_1 = 0;
    trafico_ofrecido_IP_background_2 = 0;
    trafico_cursado_IP_background_2 = 0;
    trafico_ofrecido_IP_background_3 = 0;
    trafico_cursado_IP_background_3 = 0;
    trafico_ofrecido_IP_background = 0;
    trafico_cursado_IP_background = 0;
end

trafico_ofrecido_IP_total = 8 * 1000 * sum(paquetes_recortado(:,2)) / (paquetes_recortado(size(paquetes_recortado,1),1) - paquetes_recortado(1,1));
trafico_cursado_IP_total = 8 * 1000 * sum(paquetes_recortado(:,2) .* paquetes_recortado(:,7)) / (paquetes_recortado(size(paquetes_recortado,1),1) - paquetes_recortado(1,1));

%pps de cada tr�fico
pps_deseado = 1000000 * size(paquetes_resultado_deseado,1) / (paquetes_resultado_deseado(size(paquetes_resultado_deseado,1),1) - paquetes_resultado_deseado(1,1));
if kbps_background ~= 0
    pps_background_1 = 1000000 * size(paquetes_background_1,1) / (paquetes_background_1(size(paquetes_background_1,1),1) - paquetes_background_1(1,1));
    pps_background_2 = 1000000 * size(paquetes_background_2,1) / (paquetes_background_2(size(paquetes_background_2,1),1) - paquetes_background_2(1,1));
    pps_background_3 = 1000000 * size(paquetes_background_3,1) / (paquetes_background_3(size(paquetes_background_3,1),1) - paquetes_background_3(1,1));
else
    pps_background_1 = 0;
    pps_background_2 = 0;
    pps_background_3 = 0;
end
%%%% Construyo matrices s�lo de paquetes aceptados. Sirven para calcular las estad�sticas
%Ordeno paquetes_resultado_deseado por la fila 6(si ha sido aceptado) y luego por la 1(tiempo llegada)
paquetes_resultado_deseado = sortrows(paquetes_resultado_deseado,[7 1]);
%selecciono a partir de las filas que no son cero (utilizo para ello la suma de las que son 1
paquetes_resultado_deseado_aceptados = paquetes_resultado_deseado(1+size(paquetes_resultado_deseado,1)-sum(paquetes_resultado_deseado(:,7)):size(paquetes_resultado_deseado,1),:);
%lo vuelvo a ordenar como estaba
paquetes_resultado_deseado = sortrows(paquetes_resultado_deseado,1);

if kbps_background ~= 0
    paquetes_background_1 = sortrows(paquetes_background_1,[7 1]);
    paquetes_background_1_aceptados = paquetes_background_1(1+size(paquetes_background_1,1)-sum(paquetes_background_1(:,7)):size(paquetes_background_1,1),:);
    paquetes_background_1 = sortrows(paquetes_background_1,1);

    paquetes_background_2 = sortrows(paquetes_background_2,[7 1]);
    paquetes_background_2_aceptados = paquetes_background_2(1+size(paquetes_background_2,1)-sum(paquetes_background_2(:,7)):size(paquetes_background_2,1),:);
    paquetes_background_2 = sortrows(paquetes_background_2,1);

    paquetes_background_3 = sortrows(paquetes_background_3,[7 1]);
    paquetes_background_3_aceptados = paquetes_background_3(1+size(paquetes_background_3,1)-sum(paquetes_background_3(:,7)):size(paquetes_background_3,1),:);
    paquetes_background_3 = sortrows(paquetes_background_3,1);

    paquetes_background = sortrows(paquetes_background,[7 1]);
    paquetes_background_aceptados = paquetes_background(1+size(paquetes_background,1)-sum(paquetes_background(:,7)):size(paquetes_background,1),:);
    paquetes_background = sortrows(paquetes_background,1);
end

% calculo el delay en ms
%delay_router es el retardo total cola + transmision
%delay_transmision es el retardo de transmisi�n
%delay_buffer es el retardo s�lo en la cola
delay_router_deseado = (1/1000) * mean((paquetes_resultado_deseado_aceptados(:,6) - paquetes_resultado_deseado_aceptados(:,1)));
delay_transmision_deseado = (1/1000) * mean((paquetes_resultado_deseado_aceptados(:,6) - paquetes_resultado_deseado_aceptados(:,5)));
delay_buffer_deseado = (1/1000) * mean((paquetes_resultado_deseado_aceptados(:,5) - paquetes_resultado_deseado_aceptados(:,1)));

if kbps_background ~= 0
    delay_router_background_1 = (1/1000) * mean((paquetes_background_1_aceptados(:,6) - paquetes_background_1_aceptados(:,1)));
    delay_transmision_background_1 = (1/1000) * mean((paquetes_background_1_aceptados(:,6) - paquetes_background_1_aceptados(:,5)));
    delay_buffer_background_1 = (1/1000) * mean((paquetes_background_1_aceptados(:,5) - paquetes_background_1_aceptados(:,1)));

    delay_router_background_2 = (1/1000) * mean((paquetes_background_2_aceptados(:,6) - paquetes_background_2_aceptados(:,1)));
    delay_transmision_background_2 = (1/1000) * mean((paquetes_background_2_aceptados(:,6) - paquetes_background_2_aceptados(:,5)));
    delay_buffer_background_2 = (1/1000) * mean((paquetes_background_2_aceptados(:,5) - paquetes_background_2_aceptados(:,1)));

    delay_router_background_3 = (1/1000) * mean((paquetes_background_3_aceptados(:,6) - paquetes_background_3_aceptados(:,1)));
    delay_transmision_background_3 = (1/1000) * mean((paquetes_background_3_aceptados(:,6) - paquetes_background_3_aceptados(:,5)));
    delay_buffer_background_3 = (1/1000) * mean((paquetes_background_3_aceptados(:,5) - paquetes_background_3_aceptados(:,1)));

    delay_router_background = (1/1000) * mean((paquetes_background_aceptados(:,6) - paquetes_background_aceptados(:,1)));
    delay_transmision_background = (1/1000) * mean((paquetes_background_aceptados(:,6) - paquetes_background_aceptados(:,5)));
    delay_buffer_background = (1/1000) * mean((paquetes_background_aceptados(:,5) - paquetes_background_aceptados(:,1)));
else
    delay_router_background_1 = 0;
    delay_transmision_background_1 = 0;
    delay_buffer_background_1 = 0;

    delay_router_background_2 = 0;
    delay_transmision_background_2 = 0;
    delay_buffer_background_2 = 0;

    delay_router_background_3 = 0;
    delay_transmision_background_3 = 0;
    delay_buffer_background_3 = 0;

    delay_router_background = 0;
    delay_transmision_background = 0;
    delay_buffer_background = 0;
end

%calculo la desviaci�n est�ndar en ms
stdev_router_deseado = (1/1000) * std(paquetes_resultado_deseado_aceptados(:,6) - paquetes_resultado_deseado_aceptados(:,1));
%el tr�fico de fondo lo calculo s�lo si es diferente de 0
if kbps_background ~= 0
    stdev_router_background_1 = (1/1000) * std(paquetes_background_1_aceptados(:,6) - paquetes_background_1_aceptados(:,1));
    stdev_router_background_2 = (1/1000) * std(paquetes_background_2_aceptados(:,6) - paquetes_background_2_aceptados(:,1));
    stdev_router_background_3 = (1/1000) * std(paquetes_background_3_aceptados(:,6) - paquetes_background_3_aceptados(:,1));
    stdev_router_background = (1/1000) * std(paquetes_background_aceptados(:,6) - paquetes_background_aceptados(:,1));
else
    stdev_router_background_1 = 0;
    stdev_router_background_2 = 0;
    stdev_router_background_3 = 0;
    stdev_router_background = 0;
end

%si el tr�fico es nativo, entonces el jitter conjunto es s�lo el del router, porque no hay multiplexi�n
if media_mux_router_deseado == 0
    media_mux_router_deseado = delay_router_deseado;
end   
if stdev_mux_router_deseado == 0
    stdev_mux_router_deseado = stdev_router_deseado;
end


%tama�o medio de paquete del tr�fico deseado

tamano_medio_IP_deseado = mean(paquetes_resultado_deseado (:,2));

%%%%%%%%% pongo el resultado en la matriz de resultados_buffer
resultados_buffer = [tipo_trafico kbps_tamano_fijo pps_tamano_fijo tamano_fijo num_jugadores PE TO NP TH politica_buffer tamano_buffer/1000 tiempo_limite_buffer bits_por_segundo_buffer/1000 paq_por_segundo_buffer num_maximo_paq_en_buffer retardo_procesado/1000 IP_version duracion_prueba porcentaje_desechar_inicio porcentaje_desechar_final kbps_background distribucion_trafico_fondo alfa_pareto ocupacion_media_bytes ocupacion_media_paquetes prob_loss_deseado prob_loss_total prob_loss_background_1 prob_loss_background_2 prob_loss_background_3 prob_loss_background trafico_ofrecido_IP_deseado trafico_ofrecido_IP_background trafico_ofrecido_IP_background_1 trafico_ofrecido_IP_background_2 trafico_ofrecido_IP_background_3  trafico_cursado_IP_deseado trafico_cursado_IP_background trafico_cursado_IP_background_1 trafico_cursado_IP_background_2  trafico_cursado_IP_background_3 size(paquetes_resultado_deseado,1) size(paquetes_background_1,1) size(paquetes_background_2,1) size(paquetes_background_3,1) pps_deseado pps_background_1 pps_background_2 pps_background_3  delay_router_deseado media_mux_router_deseado stdev_router_deseado stdev_mux_router_deseado stdev_router_background_1 stdev_router_background_2 stdev_router_background_3 stdev_router_background tamano_medio_IP_deseado];

%%% Escribo la matriz de resultados en el fichero %%%%%%

%abro el fichero en modo "append" en el que se guardan los resultados
file_resultados_buffer = fopen(strcat('.\_resultados_buffer\resultados_buffer_',datestr(hora_inicio, 'yyyy-mm-dd_HH.MM'),'.txt'),'a');

%escribo el resultado de esta prueba
%for r=1:size(resultados_buffer,1) %para cada l�nea
    for s=1:size(resultados_buffer,2) %para cada dato
        fprintf(file_resultados_buffer,'%6.4f \t',resultados_buffer(1,s));
    end
    fprintf(file_resultados_buffer,'\n');
%end
%%% Cierro el fichero %%%%%%%%%%
fclose(file_resultados_buffer);