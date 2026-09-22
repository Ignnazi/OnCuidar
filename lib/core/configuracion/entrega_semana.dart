const int semanaEntrega = int.fromEnvironment('SEMANA', defaultValue: 3);

bool habilitadaDesdeSemana(int n) => semanaEntrega >= n;
