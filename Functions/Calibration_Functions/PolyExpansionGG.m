function pterms = PolyExpansionGG(modip, stationmodip, lon, station_lon, nmax)
    %input sono: vettore modip IPP, modip stazione, vettore lon, lon stazione, grado massimo polinomio, deltatime arco (sod-sod_initial)
    % il punto di tutto è che devo fittare questo modello ai miei dati, quindi l'incognita è i coefficenti (a1,a2,...), non i termini (x1,x2,...)

    xX = lon - station_lon; %crea vettore di longitudine centrato su longitudine
    yY = modip - stationmodip; %crea vettore di modip centrato su modip stazione
    yNy = 1 / (1 + abs(yY)^(nmax + 1)); %fattore moltiplicativo di tutto il polinomio che controlla la crescita del polinomio e la limiti a sqrt(x)
    pterms = yNy;
    pterms = [pterms, xX * yNy];

    for j = 1:nmax
        pterms = [pterms, yY ^ j * yNy]; %evita ciclo con vettorizzazione
    end
    
end