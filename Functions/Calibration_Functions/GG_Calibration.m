function [offset, LoUA] = GG_Calibration(CleanOutputs, Station_Coord, interval, nmax, HIPP)


MoDip_Values_Grid = load(fullfile('C:\Users\MarcoGuerra\Documents\MATLAB\Prove_Calibration\modip_files/', [num2str(year(CleanOutputs.Time(1))), '.txt']));
[MoDip_Lon_Grid, MoDip_Lat_Grid] = meshgrid(-180:0.5:180, -90:0.5:90);
CleanOutputs.MoDip=Extrapolate_MoDip(CleanOutputs.Lon,CleanOutputs.Lat,MoDip_Values_Grid,MoDip_Lon_Grid,MoDip_Lat_Grid);
CleanOutputs.MappingFunction=cos(asin(6371/(6371+HIPP)*cosd(CleanOutputs.Ele)));
CleanOutputs.GFLC_Vert=CleanOutputs.GFLC.*CleanOutputs.MappingFunction;
CleanOutputs.StatName=char(CleanOutputs.ArcID);
CleanOutputs.StatName=string(CleanOutputs.StatName(:,1:4));
CleanOutputs=join(CleanOutputs,Station_Coord,"Keys","StatName");
CleanOutputs.ArcID=string(CleanOutputs.ArcID);

new_dict = containers.Map; %come sopra
dict_ArcList = containers.Map; %come sopra
LoUA = []; %inizializza lista di archi utilizzati

times = unique(CleanOutputs.Time); %lista univoca dei tempi del dataframe

% per ogni istante e per ogni prn crei modello 2D del TEC come polinomiale 2D con grado 1 su longitudine e 2 su modip

for sampling_time = 30:interval:length(times) %modificare perchè così da problemi con time res di 1s e fiza indici python che partono da 0

    % sampling time è un indice che considera step di 15 minuti (30 samples)

    ArcList = [];       % inizializza
    b = [];             % vettore dei termini noti stec biassato verticalizzato
    count = 0;          % per concatenare
    row = [];           %
    col = [];           %
    data = [];          %

    for sec = sampling_time - interval+1:sampling_time %crea indice per considerare uno ad uno tutti gli istanti di tempo dentro l'intervallo
        app_df = CleanOutputs(CleanOutputs.Time == times(sec),:); %crea tabella con osservazioni del dato istante di tempo
        PRN_list = unique(app_df.ArcID); %qui uso ArcID perchè la calibrazione va fatta su ogni coppia stazione-satellite

        for prn = 1:length(PRN_list) %cambia prn in arco, perchè lo script di pietro considera una stazione alla volta
            df_prn = app_df(app_df.ArcID == PRN_list(prn), :); %prendi valori della tabella per il dato tempo e id arco (coppia stazione satellite)
            ArcID = PRN_list(prn); %prendi nome arco

            if ~isempty(ArcID)

                pterms = PolyExpansionGG(df_prn.MoDip(1),df_prn.StaMoDip(1), df_prn.Lon(1), df_prn.StaLon(1), nmax); %questa funzione ti tira fuori i termini del polinomio

                if count == 0 %count conta a quale # numero di intervallod a 15 minuti siamo
                    A = pterms;
                elseif count > 0
                    A = [A; pterms];
                end

                if ~any(strcmp(ArcList, ArcID)) %se non c'è ID arco nella lista di ID archi, aggiungi ID arco
                    ArcList = [ArcList,ArcID];
                end

                if ~any(strcmp(LoUA, ArcID)) %se non c'è ID arco nella lista di ID archi usati, aggiungilo alla lista degli ID
                    LoUA=[LoUA,ArcID];
                end

                col(end + 1) = find(strcmp(ArcList, ArcID)); %lista con indice che rappresenta la posizione del dato ID arco (ArcID) dentro la losta degli ID archi (ArcLisr)
                data(end + 1) = df_prn.MappingFunction(1); %lista con dentro il valore di 1/sec(chi) dove chi=90-ele per il dato arco al dato tempo
                b(end + 1) = df_prn.GFLC_Vert(1);  %lista con dentro il valore di stec_biased*MappingFunction per il dato arco al dato tempo

            end
            count = count + 1; %questo serve per creare matrice dei coefficenti del polinomio
        end

    end

    if ~exist('A', 'var') %se nei quindici minuti non hai creato la matrice coi polinomi skippa step
        continue;
    end

    beta = full(sparse(1:size(A,1), col, data, size(A,1), length(ArcList))); % qui creati da una matrice sparsa una matrice full, dove valori non assegnati sono 0. I valori diversi da zero sono in posizione row,col con valore data e la matrice ha dimensione shape_row (numero polinomi) x numero di archi
    BB = [beta, b.']; % affianca alla matrice il vettore termine noto
    AA = [A, BB]; % affianca alla matrice dei polinomi la matrice di verticalizzazione (matrice sparsa con 1/sec(chi)) e termini noti (valore di stec_biased per MappingFunction)
    [~,r] = qr(AA); %finzione che triangolarizza la matrice AA in r, ed a me interessa solo la matrice tringolare e non l'identità
    new_dict(num2str(sampling_time-30))= r; %crea dizionario con la matrice triangolare dentro e come chiave l'identificativo dell'intervallo da 15 minuti
    dict_ArcList(num2str(sampling_time - 30)) = ArcList; %crea dizionario con la lista degli ID archi con come chiave l'identificativo dell'intervallo da 15 minuti

end

NT = length(new_dict); %numero di matrici triangolari da 15 minuti
NB = length(LoUA); %lista degli ID archi unici utilizzati su tutto il periodo (quinid non negli intervalli)
Wrighe = 0; %Numero di righe totali di tutte le matrici
NCoeffs = (nmax + 2); %Numero coefficenti polinomio
new_dict_keys = keys(new_dict); %lista delle chiavi di new_dict, le chiavi sono ID degli intervalli da 15 minuti

%questo ciclo for calcola il numero di righe per tutte le matrice di 15 minuti
for i = 1:NT
    key = new_dict_keys{i};
    ArcList1 = dict_ArcList(key);
    Wrighe = Wrighe + length(ArcList1);
end

BB = zeros(Wrighe, NB); %Ricrea la matrice BB ma con tutti 0
CC = zeros(Wrighe, 1); %Ricrea la matrice dei termini noti ma con tutti 0

irow = 0;

for i = 0:NT-1

    key=num2str(i*30); %crea chiavi di accesso alla mtrice corrisponde alla key
    ArcList2 = dict_ArcList(key); %accedi a lista degli ID archi per iD 15 minuti
    R = new_dict(key);  % Accedi a matrice triangolare per dato intervallo di 15 min
    UR = find(R(:, end), 1, 'last'); %trova indice ultimo elemento diverso da zero nell'ultima colonna di R
    RR = R(NCoeffs+1:UR , NCoeffs+1:end); %Considera la parte di matrice coi termini noti e MappingFunction(bias verticalizzato) che quindi non è composta da soli 0
    URR = find(RR(:, end), 1, 'last'); %trova indice ultimo elemento diverso da zero nell'ultima colonna di RR

    % si guarda sempre ultima colonna della matrice R, perchè dove finsice la matrice triangolare iniziano ad essere 0

    % UR indice dell'ultima riga della matrice che si riferisce ai termini noti (GFLC_Vert)
    % URR indice dell'ultima riga della matrice RR(matrice di partenza fino ad UR) che si riferisce ai bias
    % RR matrice di soli termini riferiti ai bias+termini noti
    % CC vettore dei termini noti (ultima colonna di RR)

    % questo ciclo serve a ritrovare a quale arco corrisponde la linee di URR
    % in questo modo sai a quale arco corrisponde il dato bias ricavato dalla riga ix

    for ix = 1:URR-1
        irow = irow +1;
        CC(irow) = RR(ix, URR); %CC vettore con solo i termini noti
        for j = ix:URR-1 %Parti da ix perchè essendo matrice triangolare sai che alla riga x i primi x-1 valori saranno tutti 0
            ib = find(strcmp(LoUA,ArcList2(j)));
            BB(irow, ib) = RR(ix, j); %Tutto tranne i termini noti (URR-1), quindi i coefficenti relativi ai biass
        end
    end

end

BB_CC = [BB, CC]; %affianca BB e CC - BB è RR riscritta in modo da sapere a quale arco si riferisce la data colonna (ib)
disp(length(BB_CC ));
[~, r_BC] = qr(BB_CC); %traingolarizza BB_CC
UR_BC = find(r_BC(:, end), 1, 'last'); %trova ultima riga che non ha tutti zero
RRBC = r_BC(1:UR_BC-1, 1:UR_BC-1); %considera solo la parte triangolare della matrice, rimuovendo riga e colonna dove hai solo 1 elemento diverso da 0
bb = r_BC(1:UR_BC-1, end); %prendi ultima colonna dei GFLC_Vert
offset = RRBC \ bb; %risolvi sistema di equazioni

% bCorrs = [];
% LRes = [];
%
% for bbCorr = [-20,0,20]
%     R_Res = r_BC*[offset + bbCorr; -1];
%     bCorrs = [bCorrs,bbCorr];
%     LRes = [LRes,sum(R_Res.^2)];
% end
%
% a = parabola_vertex(bCorrs, LRes);
% bCorr = sqrt(1 + a(3) / a(1));

end