% copio desde 'entrada' hasta 'entrada_filtrada' las filas cuyo tama�o
% (columna 2) sea menor que 'tamano_filtrar'

% voy calculando el tama�o de las cabeceras mientras recorro la matriz
% 'entrada'
tamano_total_cabeceras = 0;
tamano_total_cabeceras_filtradas = 0;

% buscar el primer valor para poner la primera fila de la matriz filtrada
j=1;
while (entrada(j,2) > tamano_filtrar)
   j = j + 1;
   switch(entrada(j,8))
       case 0  % TCP
            tamano_total_cabeceras = tamano_total_cabeceras + IP_TCP_HEADER;
       case 1   % UDP
            tamano_total_cabeceras = tamano_total_cabeceras + IP_UDP_HEADER;
       case 2   % RTP
            tamano_total_cabeceras = tamano_total_cabeceras + IP_UDP_RTP_HEADER;  
   end
end
entrada_filtrada = entrada(j,:);
switch(entrada(j,8))
   case 0  % TCP
        tamano_total_cabeceras_filtradas = tamano_total_cabeceras_filtradas + IP_TCP_HEADER;
   case 1   % UDP
        tamano_total_cabeceras_filtradas = tamano_total_cabeceras_filtradas + IP_UDP_HEADER;
   case 2   % RTP
        tamano_total_cabeceras_filtradas = tamano_total_cabeceras_filtradas + IP_UDP_RTP_HEADER;  
end
% copiar el resto de valores
for i=j+1:length(entrada(:,1))
       switch(entrada(j,8))
           case 0  % TCP
                tamano_total_cabeceras = tamano_total_cabeceras + IP_TCP_HEADER;
           case 1   % UDP
                tamano_total_cabeceras = tamano_total_cabeceras + IP_UDP_HEADER;
           case 2   % RTP
                tamano_total_cabeceras = tamano_total_cabeceras + IP_UDP_RTP_HEADER;  
        end
    if entrada(i,2) <= tamano_filtrar
        entrada_filtrada = [entrada_filtrada ; entrada(i,:)];
        switch(entrada(j,8))
           case 0  % TCP
                tamano_total_cabeceras_filtradas = tamano_total_cabeceras_filtradas + IP_TCP_HEADER;
           case 1   % UDP
                tamano_total_cabeceras_filtradas = tamano_total_cabeceras_filtradas + IP_UDP_HEADER;
           case 2   % RTP
                tamano_total_cabeceras_filtradas = tamano_total_cabeceras_filtradas + IP_UDP_RTP_HEADER;  
        end
    end
end

% sacar las estad�sticas

% proporci�n de paquetes filtrados
proporcion_paquetes_pequenos = size(entrada_filtrada(:,1),1) / size(entrada(:,1),1)

% calcular la proporci�n de ancho de banda
proporcion_ancho_banda_paquetes_pequenos = ( sum(entrada_filtrada(:,2)) + tamano_total_cabeceras_filtradas ) / ( sum(entrada(:,2)) + tamano_total_cabeceras )

% sustituir 'entrada' con 'entrada_filtrada'
entrada = entrada_filtrada;