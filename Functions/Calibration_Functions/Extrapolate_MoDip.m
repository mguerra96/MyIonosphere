function modip_vec = Extrapolate_MoDip(lon_vec, lat_vec, MoDip_Grid, lon_Grid , lat_Grid)

%Function that extrapolates the value of MoDip 
modip_vec = griddata(lon_Grid(:), lat_Grid(:), MoDip_Grid(:), lon_vec, lat_vec);

end