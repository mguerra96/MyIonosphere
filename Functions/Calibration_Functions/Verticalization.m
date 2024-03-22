function vtec=Verticalization(stec,ele,Hipp)
% SBAGLIATO NON CI DEVE ESSERE HIPP IN QUESTA FORMULA
vtec=stec.*cos(asin(6371/(6371+Hipp)*cosd(ele)));

end