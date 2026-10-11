enum FaseDescarga { ninguna, descargando, pausada, conErrores, lista }

const pasoAnuncioPorcentaje = 10;

int porcentajeAnunciable(int porcentaje) =>
    (porcentaje ~/ pasoAnuncioPorcentaje) * pasoAnuncioPorcentaje;
