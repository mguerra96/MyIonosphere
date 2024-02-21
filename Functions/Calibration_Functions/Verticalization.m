function vtec=Verticalization(stec,ele,Hipp)

vtec=stec.*cos(asin(6371/(6371+Hipp)*cosd(ele)));

end