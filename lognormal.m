%genero valores de una lognormal
%genero mu y sigma a partir de la media y la varianza
numero_valores=1000000
media=50
varianza=20
mu=log((media^2)/(sqrt(varianza+(media^2))))
sigma=sqrt(log(varianza/(media^2)+1))
tiempos=lognrnd(mu,sigma,numero_valores,1)
mean(tiempos)
var(tiempos)
%lo escribo en un fichero de texto con saltos de l�nea
dlmwrite('tiempos_lognormal.txt',tiempos,'newline','pc')