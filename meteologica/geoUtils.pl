#!/usr/bin/perl
use GD;
use gdal;
use gdalconst;
use ogr;
use Carp;
use Benchmark;

do "/var/www/meteosig/cgi-bin/defs.pl";

use Memoize;
memoize('getAvgPointInfo');
memoize('leerConLibGDAL');
memoize('getMeteoInfoArea');
memoize('getMeteoInfoRadio');
memoize('getAvgMeteoInfoArea');
memoize('getAvgMeteoInfoRadio');
memoize('media');
memoize('reproyecta');


$ogrinfo='ogrinfo -ro';
$ogrinfoturbo='/usr/local/FWTools/bin_safe/ogrinfo -ro';
$DEFAULT_RADIO=250;
$LIMITE_SUPERIOR_RADIO=100; #100 veces mayor que el radio minimo



sub perforarMatriz()
{
	my @data = @_;
	my $num_data = scalar(@data);
	#print STDERR "INICIO Perforando($num_data) @data\n";
	my @new_data=();
	for (my $i=0;$i<$num_data;$i++)
	{
		push (@new_data,$data[$i]) if ($i % 2 == 0);
	}
	my $num_new_data=scalar(@new_data);
	#print STDERR "FIN Perforando($num_new_data) @new_data\n";
	return @new_data;
}


sub leerConLibGDAL()
{

	my $tiempo_inicial = new Benchmark;

	my ($xmin,$xmax,$ymin,$ymax,$file_raster) = @_;

	return undef if (not -e $file_raster);

	
	my $dataset = gdal::Open($file_raster, $gdalconst::GA_ReadOnly);
	my ($minX, $dx, undef, $maxY, undef, $dy) = @{$dataset->GetGeoTransform()};
	my $ancho = $dataset->{RasterXSize};		#Numero de pixeles de ancho
	my $alto = $dataset->{RasterYSize};		#Numero de pixeles de alto	
	#my $proj = $dataset->GetProjectionRef();	#Un chorizo de datos de proyeccion (creo que inusable)
	#my $num_bandas = $dataset->{RasterCount};
	my $band = $dataset->GetRasterBand(1);          #Fallara con los raster de mas de una banda?
	my $nodata = $band->GetNoDataValue();
	my $type_char = get_type_char($band->{DataType});

#	print STDERR "Tamaño (X,Y): ($ancho,$alto) File: $file_raster\n";
#	print STDERR "Datos GetGeoTransform: $minX,$dx,$maxY,$dy\n";
#	print STDERR "Esquinas: $xmin,$xmax,$ymin,$ymax\n";
	
	# Calculamos el ancho y alto de la ventana pedida
	my $inc_x = abs($xmax)-abs($xmin);
	my $inc_y = abs($ymax)-abs($ymin);
	$inc_x = sprintf("%.8f", abs($inc_x));
	$inc_y = sprintf("%.8f", abs($inc_y));
	$inc_x = int abs($inc_x / $dx);   # Pasa de metros o grados a celdas del raster
	$inc_y = int abs($inc_y / $dy);   # Pasa de metros o grados a celdas del raster
	
#	print STDERR "Tamaño de la ventana: ($inc_x,$inc_y)";

	# Calculamos la esquina superior izquierda de la ventana pedida
	$xoff=int abs(($minX-$xmin) / $dx);
	$yoff=int abs(($maxY-$ymin) / $dy);

	# Comprobamos ventana
	if ($inc_x<1){$inc_x = 1;}
	if ($inc_y<1){$inc_y = 1;}

	# Con los 4 datos anteriores, leemos el raster
	my $buf = $band->ReadRaster($xoff,$yoff,$inc_x,$inc_y);     #($xoff,$yoff,$xsize,$ysize);
	#print STDERR "buf: $buf\n";
        my @data = unpack($type_char."[$ancho]", $buf);    # TODO esto del ancho aun no lo veo claro.
	
	#print STDERR "Datos: @data\n";
	
	# Si tenemos mucha cantidad de datos, perforamos la matriz
	my $numdata = scalar(@data);
	@data=&perforarMatriz(@data) if ($numdata > 100);
	
	#my @matriz_datos=();
	foreach my $dato (@data)
	{
		$dato = defined $nodata ? ($dato == $nodata ? undef : $dato) : $dato;
		#$dato *= $factor if (defined $factor);
		#print STDERR "LeerConGDAL: dato=$dato \n";
		#push (@matriz_datos,$dato);
	}
	

	
	# BENCHMARK TODO QUITAR
	my $tiempo_final = new Benchmark;
	my $tiempo_total = timediff($tiempo_final, $tiempo_inicial);
#	print STDERR "leerConLibGDAL:",timestr($tiempo_total),"\n";
	
	# Devolvemos el chorizo de datos
	return @data;	
	
}






# return a character which identifies the GDAL datatype for Perl's pack function
sub get_type_char {
	my $datatype = shift;
	SWITCH: for ($datatype) {
		if ($_ == $gdalconst::GDT_Byte) { return 'C'; }
		if ($_ == $gdalconst::GDT_Int16) { return 's'; }
		if ($_ == $gdalconst::GDT_Int32) { return 'i'; }
		if ($_ == $gdalconst::GDT_Float32) { return 'f'; }
		if ($_ == $gdalconst::GDT_Float64) { return 'd'; }
		croak "unknown datatype: $datatype";
	}
}


# 
# getAvgMeteoInfoArea()
# Le pasamos una ventana rectangular y devuelve un dato promedio del area comprendida
# - (variable) Nombre variable del defs.pl
# - (xmin,xmax.ymin,ymax,proyeccion) Ventana a consultar
# - (fecha) fecha a consultar
# - (horiz) horizonte de la variable          
# Salida:
# - (resultado) Dato promedio del area comprendida
sub getAvgMeteoInfoArea()
{
	return  &media(&getMeteoInfoArea(@_));
}


# 
# getAvgMeteoInfoRadio()
# Le pasamos un punto y un radio y devuelve un dato promedio del area comprendida
# Entrada:
# - (variable) Nombre de la variable del defs.pl
# - (x,y,radio,proyeccion) punto y radio que queremos consultar
# - (fecha,horiz) fecha y horizonte de la consulta
# Salida:
# - (resultado) Dato promedio del area comprendida
# 
sub getAvgMeteoInfoRadio()
{
	my ($variable,$x,$y,$radio,$proyeccion,$fecha, $horiz) = @_ ;

	my $resultado = &media(&getMeteoInfoRadio($variable, $x, $y,$radio, $proyeccion,$fecha, $horiz));

	#print STDERR "getAvgMeteoInfoRadio: resultado=$resultado\n";
	
	#$resultado = sprintf ("%0.1f",$resultado) if (defined $resultado);

	return $resultado;
}



# 
# media()
# Calcula la media de los datos de una matriz.
# Entrada:
# - (@entrada) datos numericos de entrada
# Salida:
# - (media) La media de los datos
sub media()
{
	my @datos = @_;
	#print "Datos para hacer la media: @datos\n";
	my $contador =0;
	my $suma=0;
	my $resultado=undef;
	if (scalar @datos > 0)
	{
		foreach $i (@datos)
		{
			next if (not defined $i);
			$contador++;
			$suma += $i;
		}
		
		$resultado = $suma/$contador if ($contador > 0);
	}
	#print STDERR "media: DATOS: @datos SUMA: $suma CONTADOR: $contador MEDIA: $resultado\n";
	return $resultado;
}




# getMeteoInfoAreaDBF()
# Devuelve una matriz de datos del tipo CAMPO=VALOR que contienen los DBF
# Parametros de entrada:
# - (data_path,variable) Con estas dos variables se crea la ruta del fichero fisico a consultar.
# - (xmin,xmax,ymin,ymax) Ventana a consultar
# - (filtro) Campo para ignorar y no sacarlo por la salida (normalmente campo ID)
# - (factor) OBSOLETO este dato ya no se usa aqui.
# Salida:
# - (@valores) matriz con los datos del tipo CAMPO=VALOR
# - (valoresGeom) OBSOLETO
sub getMeteoInfoAreaDBF
{
	my ( $data_path, $variable, $xmin, $ymin,$xmax,$ymax, $filtro, $factor) = @_;
	my @valores;
	my $valoresGeom;

	my $shp_file = $variable.'.shp' ;
	my $command = "$ogrinfoturbo -al -spat " ;
	my $data_file = $data_path . $shp_file ;

	my $extent = "$xmin $ymin $xmax $ymax" ;

	# 20070108 Chequeo por si el DBF estuviera comprimido
	my $dbffile = $data_path.$variable.'.dbf';
	my $dbffilegz = $dbffile.'.gz';
	if (not -f $dbffile)
	{
		if (-f $dbffilegz)
		{
			`gzip -cd $dbffilegz >$dbffile`;
		}
	}

	# 20080821 Descartamos la información del polígono porque nadie la usa y ralentiza mucho.
	# TODO: Modificar la estructura de la función para que no devuelva ese parámetro.
	my $exec = $command . $extent . " " . $data_file . " |fgrep -v 'POLYGON ('" ;
	#print STDERR "EXEC: ($exec)\n" ;
	my $res = `$exec`;
	#print STDERR "res: $res\n";
	my @lines = split ("\n", $res);
	my $flag = 0;
	my $iid;
	my $nid = 0;
	foreach my $line(@lines )
	{
		if  ( $line  =~  /(^Feature Count:\s)(.*)/i )
		{
			#print "nº de regs:$2\n" ;
			$num_regs = $2 ;
		}
		if  ( $line  =~  /^(?:\s)+(.*)$/i )
		# las lineas con valores van precedidas por 2 espacios
		{
			my $resto = $1;
			if  ($resto =~ /(.*)\s(?:\(.*\))\s=\s(.*)/i)
			{
				#print "\t#$1#$2#$3<br>";
				$campo = $1;
				$valor = $2 ;
				# Aprender el primer campo, para detectar donde empieza un registro nuevo.
				if ($flag == 0) {
					$flag = 1;
					$iid = $campo;
				}
				# Si empieza un registro nuevo, metemos nuestro campo ID...
				if ($campo eq $iid) {
					$nid++;
					$id = $nid;
					push (@valores, "ID=$id");
				}
				# Prueba: ignorar los campos que no cumplan con el filtro.
				# Ignoramos los campos que se llamen 'ID'.
				#if ($campo ne 'ID' and $campo =~ /$filtro/i) {
					#print STDERR "CAMPO: ($campo) FILTRO: ($filtro)\n";
				if ($campo ne 'ID' and (not defined $filtro or  $campo =~ /$filtro/i))
				{
					# 20090109 Injertón. Si la variable es probabilidad de precipitación, no puede ser negativa.
					$valor=0 if ($variable =~ /precip/ and $valor < 0);

					# Si hemos recibido un factor, lo aplicamos al dato. Se usa para el cambio de unidades.
					# En ese caso se da por hecho que el campo es numérico.
					#$valor *= $factor if (defined $factor);

					push (@valores, "$campo=$valor");
				}
			}
		}
	}
	return (@valores , $valoresGeom);
}

# 
# getCampoDBF()
# Nos dice como se llamara el campo que queremos consultar de un DBF
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (horiz) Horizonte a consultar
# - (hez) Campo adicional que llevan algunas variables
# Salida:
# - (campo) String con el campo a consultar de un DBF
# 
sub getCampoDBF()
{
	my $bool_observacion = 0;
	my ($variable,$horiz,$hez)=@_;
#	print STDERR "getCampoDBF: VARIABLE: $variable HORIZ: $horiz HEZ $hez\n";
	my ($horiz_dia,$horiz_hora);
	if (defined $hez)
	{
		$horiz_hora=$hez;
	}
	if ($horiz =~ /^H(\d+)/)
	{
		$horiz_hora = sprintf "%02d", ($1 % 24);
		$horiz_dia = int($1 / 24);
	}
	elsif ($horiz =~ /^D(\d+)/)
	{
		$horiz_dia = $1;
	}
	elsif (($horiz =~ /.*-.*/) or ($variable =~ /^OBS.*/))
	{
		$bool_observacion = 1;
	}
	else 
	{
		#print STDERR "getCampoDBF: El horizonte no esta bien formado, revisar la llamada.\n";
		return undef;
	}

	
	if ($variable =~ /VIENTOHIRLAM/)
	{
		$horiz_hora += $horiz_dia*24;
		$horiz_hora= sprintf( "%02d" ,$horiz_hora);
		return 'MOD'.$horiz_hora;
	}
	return 'OBS' if ($variable =~ /NUMFOCOS/);
	
	# Hum Comb vivo
	return 'AFMC' if ($variable =~ /UAHAFMC/);
	return 'FMC' if ($variable =~ /UAHFMC/);

	if ($variable =~ /HAINES/ or $variable =~ /T850/)
	{
		if ($horiz_hora eq '00')
		{
			$horiz_hora = 24;
			if ($horiz_dia > 0){$horiz_dia -= 1;}
			#$horiz_dia = 'D'.$1-1 if ($horiz_dia =~ /D(.*)/);
		}
		if ($bool_observacion == 0)
		{
			return 'D'.$horiz_dia.'HA'.$horiz_hora;
		}
		else
		{
			# Solo hay haines a las 12
			return 'HA12';
		}
	}
	if ($variable =~ /MODVIENTODOM/)
	{
		if ($horiz_hora eq '00')
		{
			$horiz_hora = 24;
			if ($horiz_dia > 0){$horiz_dia -= 1;}
			#$horiz_dia = 'D'.$1-1 if ($horiz_dia =~ /D(.*)/);
		}
		if ($bool_observacion == 0)
		{
			return 'D'.$horiz_dia.'MOD'.$horiz_hora;
		}
		else
		{
			# Solo hay haines a las 12
			return 'MOD12';
		}
	}
	if ($variable =~ /DIRVIENTODOM/)
	{
		if ($horiz_hora eq '00')
		{
			$horiz_hora = 24;
			if ($horiz_dia > 0){$horiz_dia -= 1;}
			#$horiz_dia = 'D'.$1-1 if ($horiz_dia =~ /D(.*)/);
		}
		if ($bool_observacion == 0)
		{
			return 'D'.$horiz_dia.'DIR'.$horiz_hora;
		}
		else
		{
			return 'DIR12';
		}
	}
	
	return undef;
}
# 
# reproyecta()
# Se le pasa un punto en determinada proyeccion y devuelve el mismo par de coordenadas
# en otra proyeccion distinta.
# Parametros de entrada:
# - (x,y) Coordenada del punto
# - (proj_ini) Proyeccion que usa el punto 		
# - (proj_fin) Proyeccion a la que queremos transformar
# Salida:
# - (x,y) En la proyeccion nueva
sub reproyecta()
{
	my ($x,$y,$proj_ini,$proj_fin) = @_;

	# TODO: Falta validar las proyecciones
	if ($proj_ini eq 'latlon' or $proj_ini eq 'latlong'){$proj_ini='epsg:4326';}
	if ($proj_fin eq 'latlon' or $proj_fin eq 'latlong'){$proj_fin='epsg:4326';}

	if ($proj_ini ne $proj_fin)
	{
		#print STDERR "Se necesita una conversion de $proj_ini a $proj_fin\n";
		($x, $y,my $err) =split(' ', `echo $x $y |/usr/local/FWTools/bin_safe/cs2cs +init=$proj_ini +to +init=$proj_fin -f "%.16f"`);
	}
	
	return ($x,$y);
}

# 
# leerConOGR()
# Consulta un fichero DBF con OGRinfo y devuelve una matriz de valores
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (xmin,xmax.ymin,ymax,proyeccion) Ventana a consultar
# - (fecha) fecha a consultar
# - (horiz) horizonte de la variable          
# Salida:
# - @matriz_datos Celdas consultadas
sub leerConOGR()
{
	my ($variable, $xmin, $ymin,$xmax,$ymax, $proyeccion,$fecha, $horiz) = @_ ;
	#print STDERR "$variable\n";
	($variable, $hez) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	
	my $bool=0;
	my @datos=();
	my $data_file = &dameNombreDeDBF($variable,$fecha,$horiz);
	#print STDERR "leerConOGR: data_file=$data_file\n";
	if (not defined $data_file){return undef}
	if ($data_file =~ /(.*-)(.*)?\.(.*)/)
	{
		$parte1=$1;
		$parte2=$2;
	}
	@resultado_dbf=&getMeteoInfoAreaDBF($parte1, $parte2, $xmin, $ymin,$xmax,$ymax,$vars{$variable}{filtrodbf},$vars{$variable}{factor});
	#print STDERR "SACANDO EL CAMPO DE HAINES CON: ($variable,$horiz,$hez)\n";
	$campo_dbf=&getCampoDBF($variable,$horiz,$hez);
	#print STDERR "RESULTADO DBF: @resultado_dbf CAMPO: $campo_dbf hez=$hez\n";
	if (defined $campo_dbf)	
	{

		foreach $c (@resultado_dbf)
		{
			if (defined $c and $c =~ /(.*)=(.*)/)
			{
				my $value=$2;
				if ($campo_dbf eq $1)
				{
					#print STDERR "CAMPO DBF: $campo_dbf\n";
					push (@datos,$value);
					$bool=1;
				}
			}
		}
	}
	if ($bool==0){return undef;}

	return @datos;

}


# 
# leerConGDAL()
# Consulta un fichero raster con GDAL y devuelve una matriz de valores
# Entrada:
# - (xmin,xmax.ymin,ymax) Ventana a consultar
# - (data_file) ruta del fichero a consultar          
# Salida:
# - @matriz_datos Celdas consultadas
sub leerConGDAL()
{

	my ($xmin,$xmax,$ymin,$ymax,$data_file) = @_;
	
	# TODO Fabio Pruebas
	return &leerConLibGDAL($xmin,$xmax,$ymin,$ymax,$data_file);
	
	#print STDERR "leerConGDAL: data_file=$data_file\n";
	#print STDERR "leerConGDAL: $xmin,$xmax,$ymin,$ymax\n";
	
	my $inc_x = abs($xmax)-abs($xmin);
	my $inc_y = abs($ymax)-abs($ymin);
	$inc_x = sprintf("%.8f", abs($inc_x));
	$inc_y = sprintf("%.8f", abs($inc_y));
	#print STDERR "leerConGDAL: Tamanyo ventana x=$inc_x y=$inc_y\n";
	
	my @matriz_datos=();
	
	my ($resultado, $datos);
	my ($ncols, $nrows, $xllcorner, $yllcorner, $cellsize, $nodata);

	# Comprobamos la ventana
	my $pixel=undef;
	my $file_info=`/usr/local/FWTools/bin_safe/gdalinfo $data_file 2>/dev/null`;
	my @lines_info = split ("\n", $file_info);
	foreach $linea (@lines_info)
	{
		if ($linea =~ /Pixel Size = \((.*),(.*)\)/i)
		{
			$pixel = $1;	
			# TODO El tamanyo del pixel da dos valores
			#print STDERR "leerConGDAL: tamanyo del pixel=$1 $2\n";
		}
	}

	return undef if (not defined $pixel);
	#print STDERR "pixel=$pixel\n";
	
	# Comprobamos ventana
	if ($inc_x<$pixel){$xmax += $pixel;}
	if ($inc_y<$pixel){$ymax += $pixel;}
	
	
	if (! -r $data_file) {
		#print STDERR "El fichero raster $data_file no existe\n";	
		return undef;
	}
	my $TMPFILE="/tmp/GDAL.$$.$xmin-$ymin-$xmax-$ymax.txt";
	unlink $TMPFILE;
	my $extent = "-projwin $xmin $ymax $xmax $ymin";
	my $command = '/usr/local/FWTools/bin_safe/gdal_translate -of AAIgrid -b 1 ';
	my $exec = $command . $extent . " $data_file $TMPFILE";
	#print STDERR "EXEC: ($exec)\n" ;
	
	`$exec`;

	# Chapucilla. Si ha fallado gdal_translate quizás es por el bug que tiene con los rasters inversos que van de sur a norte (hirlam por ejemplo).
	# Reintentamos cambiando ymin e ymax.
	if ( ! -f $TMPFILE)
	{
		$extent = "-projwin $xmin $ymin $xmax $ymax";
		$exec = $command . $extent . " $data_file $TMPFILE";
		#print STDERR "EXEC2: ($exec)\n" ;
		`$exec`;
	}

	if (! -r $TMPFILE)
	{
		return undef;
	}
	my $res = `cat $TMPFILE`;
	unlink $TMPFILE;
	#print STDERR "\n$res\n";
	my @lines = split ("\n", $res);

	foreach my $line(@lines)
	{
		if ($line =~ /ncols(.*?)(\d+)/i)
		{
			$ncols = $2;
		}
		elsif ($line =~ /nrows(.*?)(\d+)/i)
		{
			$nrows = $2;
		}
		elsif ($line =~ /xllcorner(.*?)(\d+)/i) 
		{
			$xllcorner = $2;			
		}
		elsif ($line =~ /yllcorner(.*?)(\d+)/i)
		{
			$yllcorner = $2;
		}
		elsif ($line =~ /dx(.*?)(\d+)/i)
		{
			$cellsize = $2;
		}
		elsif ($line =~ /dy(.*?)(\d+)/i)
		{
			$cellsize = $2;
		}
		elsif ($line =~ /cellsize(.*?)(\d+)/i)
		{
			$cellsize = $2;
		}
		# TODO modificar esta regexp en todas las demas partes,
		# esta está bien ya que los nodatas pueden ser negativos
		# y hay que contar con el '-'
		elsif ($line =~ /NODATA_value(.*?)(-?\d+)/i)
		{
			$nodata = $2;	
			#print STDERR "NODATA: $nodata\n";
		}
		else 
		{
			my @datos = split (" ", $line);
			my $aux;
			foreach my $dato (@datos)
			{	
				$dato = defined $nodata ? ($dato == $nodata ? undef : $dato) : $dato;
				$dato *= $factor if (defined $factor);
				#print STDERR "LeerConGDAL: dato=$dato \n";
				push (@matriz_datos,$dato);
			}
		}
	}

	#my $numdata = scalar(@matriz_datos);
	#print STDERR  "Num Datos: $numdata\n"; 
	#print STDERR "getMeteoInfoArea: Matriz: @matriz_datos\n";

	
	return @matriz_datos;

}


# 
# getMeteoInfoArea()
# Retorna un array de valores, funciona (20090804, aun faltan algunas variables) para cualquier variable del meteosig
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (xmin,xmax.ymin,ymax,proyeccion) Ventana a consultar
# - (fecha) fecha a consultar
# - (horiz) horizonte de la variable          
# Salida:
# - @matriz_datos Celdas consultadas
# 

# Devuelve un array con los datos de las celdas que comprenden un area
# dicha area se la pasamos con $xmin, $ymin,$xmax,$ymax en una determinada
# proyeccion que tambien se la pasamos.
sub getMeteoInfoArea()
{
	# RECIBIMOS PARAMETROS
	my ($variable, $xmin, $ymin,$xmax,$ymax, $proyeccion,$fecha, $horiz) = @_ ;
#	print STDERR "getMeteoInfoArea: horiz=$horiz\n";

	
	# variables necesarias
	my @matriz_datos=();
	
	#my $factor=$vars{$variable}{factor};
	#print STDERR "mirando el factor: var: $variable factor: $factor\n";

	
	#print STDERR "getMeteoInfoArea: $xmin $xmax $ymin $ymax VARIABLE: $variable proyeccion usada: $proyeccion proyeccion_var: $proyeccion_var\n";
	($variable_limpia, $hez) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	$variable = $variable_limpia;
	# PROYECCION
	my $proyeccion_var=$vars{$variable}{proyeccion};
	if (!defined $proyeccion_var){$proyeccion_var='epsg:25830';}
	if (!defined $proyeccion){$proyeccion='epsg:25830';}
	($xmin,$ymin)=&reproyecta($xmin,$ymin,$proyeccion,$proyeccion_var);
	($xmax,$ymax)=&reproyecta($xmax,$ymax,$proyeccion,$proyeccion_var);
	
	# Volvemos a meter el campo de variable multiple
	if (defined $hez){	$variable=$variable.'_'.$hez; }

	# RECIBIMOS EL NOMBRE DEL FICHERO A CONSULTAR
	if (defined $vars{$variable_limpia}{raster})
	{
		$data_file = &dameNombreDeRaster($variable,$fecha,$horiz);
#		print STDERR $data_file . "\n";
		@matriz_datos = &leerConGDAL($xmin,$xmax,$ymin,$ymax,$data_file);
		if (defined $vars{$variable}{factor})
		{
			foreach my $dat (@matriz_datos)
			{
				
				$dat *= $vars{$variable}{factor} if (defined $dat);
			}
		}
		#print STDERR "getMeteoInfoArea: matriz_datos=@matriz_datos\n";
	}
	# SI NO HA ENCONTRADO UN RASTER ENTONCES BUSCA UN DBF
	else 
	{
		@matriz_datos = &leerConOGR($variable, $xmin, $ymin,$xmax,$ymax, $proyeccion,$fecha, $horiz);
		if (defined $vars{$variable}{factor})
		{
			foreach my $dat (@matriz_datos)
			{
				$dat *= $vars{$variable}{factor} if (defined $dat);
			}
		}
		#print STDERR "getMeteoInfoArea: matriz_datos=@matriz_datos\n";
	}
	return @matriz_datos;
}




# 
# dameRadioEnProyeccion()
# Cambia un segmento en una proyeccion a otra, sirve para cuando nos piden radios en otras proyecciones
# Entrada:
# - (x,y,proj_ini) El punto y la proyeccion de inicio
# - (radio_ini) Distancia en unidades de proj_ini
# - (proj_out) Nombre de la proyeccion de salida
# Salida:
# - (radio_fin) Distancia en unidades proj_fin
# 
sub dameRadioEnProyeccion()
{
	my ($x_in,$y_in,$proy_in,$proy_out,$radio_in) = @_;

	my ($x1, $y1,$err1) =split(' ', `echo $x_in $y_in |/usr/local/FWTools/bin_safe/cs2cs +init=$proy_in +to +init=$proy_out -f "%.16f"`);
	
	$x_in = $x_in + $radio_in;

	my ($x2, $y2,$err2) =split(' ', `echo $x_in $y_in |/usr/local/FWTools/bin_safe/cs2cs +init=$proy_in +to +init=$proy_out -f "%.16f"`);
	
	my $radio_out = $x2-$x1;

	return $radio_out;
}






# Fabio 20090508
# getMeteoInfoRadio()
# Retorna un array de valores pasandole un radio
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (x,y,proyeccion,radio) Ventana a consultar
# - (fecha) fecha a consultar
# - (horiz) horizonte de la variable          
# Salida:
# - @matriz_datos Celdas consultadas
# 
sub getMeteoInfoRadio()
{
	my ($variable,$x,$y,$radio,$proyeccion,$fecha, $horiz,$radio_units) = @_ ;

	# TODO radio_units contendra las unidades del radio 
	$radio_units = undef;
	
	# En qué proyección está la variable que queremos leer?
	my $proyeccion_var=$vars{$variable}{proyeccion} ? $vars{$variable}{proyeccion} : 'epsg:25830';
	# 20090727 PRG. TODO: Cambiar el defs.pl y poner siempre códigos EPSG. Esto debe fallar en mas sitios.
	$proyeccion='epsg:4258' if ($proyeccion eq 'latlon' or $proyeccion eq 'latlong');
	$proyeccion_var='epsg:4258' if ($proyeccion_var eq 'latlon' or $proyeccion_var eq 'latlong');

	# El radio debe estar en las mismas unidades que la variable (grados, metros, ...)
	$radio = &dameRadioEnProyeccion($x,$y,$proyeccion,$proyeccion_var,$radio);
	($x, $y) = &reproyecta($x,$y,$proyeccion,$proyeccion_var);
	
	
	# TODO: Validar que el radio recibido está en las unidades de la variable. Nos pueden pedir por error 1000 grados...
	# TODO: Cambiar este 250 por un $DEFAULT_RADIO que esté al principio de la librería.
	my $radio_var = $vars{$variable}{radio} ? $vars{$variable}{radio} : $DEFAULT_RADIO;

	# Filtro de seguridad: Si el radio es muy grande, caparlo.
	$radio = ($radio > $radio_var*100) ? $radio = $radio_var*100 : $radio;

	# Filtro de radio mínimo para que no falle gdal_translate, y para capas de puntos, que no encontrarían resultados.
	$radio = ($radio < $radio_var) ? $radio = $radio_var : $radio;
	
	#print STDERR "getMeteoInfoRadio: x=$x y=$y radio=$radio\n";

	#print STDERR "getMeteoInfoRadio: radio=$radio\n";
	my $xmin = ($x - $radio); # int ($x - $radio);
	my $xmax = ($x + $radio); # int ($x + $radio);
	my $ymin = ($y - $radio); # int ($y - $radio);
	my $ymax = ($y + $radio); # int ($y + $radio);
	my @res = &getMeteoInfoArea($variable, $xmin, $ymin,$xmax,$ymax, $proyeccion_var,$fecha, $horiz);
	#print STDERR "getMeteoInfoRadio: $xmin $xmax $ymin $ymax resultado=@res\n";
	return @res;
}

# Fabio 20090903
# getMeteoInfoRadioXY()
# Retorna un array de valores pasandole un radio X y un radio Y (Area rectangular)
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (x,y,proyeccion,radioX,radioY) Ventana a consultar
# - (fecha) fecha a consultar
# - (horiz) horizonte de la variable          
# Salida:
# - @matriz_datos Celdas consultadas
# 
sub getMeteoInfoRadioXY()
{
	my ($variable,$x,$y,$radioX,$radioY,$proyeccion,$fecha, $horiz,$radio_units) = @_ ;

	# TODO radio_units contendra las unidades del radio 
	$radio_units = undef;
	
	# En qué proyección está la variable que queremos leer?
	my $proyeccion_var=$vars{$variable}{proyeccion} ? $vars{$variable}{proyeccion} : 'epsg:25830';
	# 20090727 PRG. TODO: Cambiar el defs.pl y poner siempre códigos EPSG. Esto debe fallar en mas sitios.
	$proyeccion='epsg:4258' if ($proyeccion eq 'latlon' or $proyeccion eq 'latlong');
	$proyeccion_var='epsg:4258' if ($proyeccion_var eq 'latlon' or $proyeccion_var eq 'latlong');

	# El radio debe estar en las mismas unidades que la variable (grados, metros, ...)
	$radioX = &dameRadioEnProyeccion($x,$y,$proyeccion,$proyeccion_var,$radioX);
	$radioY = &dameRadioEnProyeccion($x,$y,$proyeccion,$proyeccion_var,$radioY);
	($x, $y) = &reproyecta($x,$y,$proyeccion,$proyeccion_var);
	
	
	# TODO: Validar que el radio recibido está en las unidades de la variable. Nos pueden pedir por error 1000 grados...
	my $radio_var = $vars{$variable}{radio} ? $vars{$variable}{radio} : $DEFAULT_RADIO;

	# Filtro de seguridad: Si el radio es muy grande, caparlo.
	$radioX = ($radioX > $radio_var*100) ? $radioX = $radio_var*100 : $radioX;
	$radioY = ($radioY > $radio_var*100) ? $radioY = $radio_var*100 : $radioY;

	# Filtro de radio mínimo para que no falle gdal_translate, y para capas de puntos, que no encontrarían resultados.
	$radioX = ($radioX < $radio_var) ? $radioX = $radio_var : $radioX;
	$radioY = ($radioY < $radio_var) ? $radioY = $radio_var : $radioY;
	
	#print STDERR "getMeteoInfoRadioXY: x=$x y=$y radio=$radio\n";

	print STDERR "getMeteoInfoRadioXY: radioX=$radioX   radioY=$radioY\n";
	my $xmin = ($x - $radioX); # int ($x - $radio);
	my $xmax = ($x + $radioX); # int ($x + $radio);
	my $ymin = ($y - $radioY); # int ($y - $radio);
	my $ymax = ($y + $radioY); # int ($y + $radio);
	my @res = &getMeteoInfoArea($variable, $xmin, $ymin,$xmax,$ymax, $proyeccion_var,$fecha, $horiz);
	print STDERR "getMeteoInfoRadioXY: $xmin $xmax $ymin $ymax resultado=@res\n";
	return @res;
}

# Fabio 20090508
# dameNombreDeDBF()
# Sirve para preguntarle por una variable y que nos de el nombre del fichero fisico a consultar
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (fecha) Fecha a consultar
# - (horiz) Horizonte a consultar
# Salida:
# - data_file Ruta del fichero fisico
# 
sub dameNombreDeDBF()
{
	my ($variable,$fecha,$horiz) =  @_;

	
	my $data_path="/var/www/meteosig/data/";

	#
	# Paso 1: Datos necesarios para poder construir el nombre del fichero
	#
	
	# PREFIJOS Y SUFIJOS DEL ARCHIVO DBF
	my $antes_de_variable='';
	my $despues_de_variable='';
	my $horizonte_horario=undef;
	my $horizonte_diario=undef;
	
	# Controlamos la pasada TODO lo mejor es meter este chequeo si la var tiene tipodato==3 (variables hirlam)
	my $pasada='';
	if ($fecha =~ /(\d{8})(\d{2})/)
	{
		$fecha=$1;
		$pasada=$2;
	}

	
	# MODOS
	my $modo = $variable =~ /^PRED/ ? "predicciones" : $variable =~ /^OBS/ ? "observaciones" : $variable =~ /^EST/ ? "estimaciones" : undef;
	# el climatologico usa solo YYYYMM como fecha
	if($variable =~ m/MENSUAL/ and $modo eq "observaciones") 
	{
		$modo='climatologico';
		if($fecha =~ /(\d{6})\d{2}/){$fecha=$1;}
		$fecha_filename = $fecha;	
	}
	# Ya sabemos el modo, seguimos formando la ruta del raster.
	$data_path.="$modo/$fecha/";


	# PREFIJOS Y SUFIJOS PARA FORMAR EL ARCHIVO
	#
	# tipodato == 3 //Variables hirlam
	# tipodato == 1 //Variables con rangos, los rangos son horas, ej: PRED_HAINES_06  (obsoleto)
	# tipodato == 4 //DBFs con la fecha al final
	#
	my $sufijo_var_defs = undef;
	($variable, $sufijo_var_defs) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	#print STDERR "Variable Multiple: $sufijo_var_defs\n" if (defined $sufijo_var_defs);
	$antes_de_variable = 'hirlam-' if(defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 3);
	$despues_de_variable="-p$sufijo_var_defs" if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 0);
	if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 1)
	{
		$despues_de_variable = $sufijo_var_defs;
		if ($horiz =~ /D(.*)/ ){$horiz=$1*24;}
		$horiz += $sufijo_var_defs;
	}
	$despues_de_variable = sprintf("-%02d", $sufijo_var_defs) if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 2);
	$despues_de_variable = sprintf("-%08d", $fecha) if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 4);
	
	# RESOLUCION
	my $resolucion = (defined $vars{$variable}{res}) ? $vars{$variable}{res} : 500;


	# FORMAR EL NOMBRE DEL FICHERO
	my $dbf_name = $modo.$resolucion.'-'.$antes_de_variable;
	$dbf_name .= $vars{$variable}{database}.$despues_de_variable.'.dbf';
	my $data_file = $data_path.$dbf_name;
	
	if (!-f $data_file)
	{
		#print STDERR "ERROR FORMANDO NOMBRE DEL DBF: $data_file\n";
		return undef;
	}
	else
	{
		return $data_file;
	}
	
	
}

# # Fabio 20090508
# Sirve para preguntarle por una variable y que nos de el nombre del fichero fisico a consultar
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (fecha) Fecha a consultar
# - (horiz) Horizonte a consultar
# Salida:
# - data_file Ruta del fichero fisico
sub dameNombreDeRaster()
{
	my ($variable,$fecha,$horiz) = @_;
#	print STDERR "dameNombreDeRaster: variable=$variable fecha=$fecha horiz=$horiz\n";
	my $pasada='';
	if ($fecha =~ /(\d{8})(\d{2})/)
	{
		$fecha=$1;
		$pasada=$2;
	}
	#print "dameNombreDeRaster: VARIABLE: $variable\n";
	my $data_path="/var/www/meteosig/data/";
	
	#
	# Paso 1: Datos necesarios para poder construir el nombre del fichero
	#
	
	# PREFIJOS Y SUFIJOS DEL ARCHIVO RASTER
	my $antes_de_variable=undef;
	my $despues_de_variable=undef;
	my $horizonte_horario=undef;
	my $horizonte_diario=undef;
	
	# FECHAS
	my $fecha_filename = $fecha.$pasada;
	#print STDERR "dameNombreDeRaster: fecha_filename=$fecha_filename\n";
	if (defined $vars{$variable}{'postfecha'})
	{
		$fecha_filename .= $vars{$variable}{'postfecha'};
	}
	my $fecha_directorio = $fecha;
	
	# MODOS
	my $modo = $variable =~ /^PRED/ ? "predicciones" : $variable =~ /^OBS/ ? "observaciones" : $variable =~ /^EST/ ? "estimaciones" : undef;
	# el climatologico usa solo YYYYMM como fecha
	if($variable =~ m/MENSUAL/ and $modo eq "observaciones") 
	{
		$modo='climatologico';
		if($fecha =~ /(\d{6})\d{2}/){$fecha=$1;}
		$fecha_filename = $fecha;	
	}
	# Ya sabemos el modo, seguimos formando la ruta del raster.
	$data_path.="$modo/$fecha/";


	
	# PREFIJOS Y SUFIJOS PARA FORMAR EL ARCHIVO
	#
	# tipodato == 3 //Variables hirlam
	# tipodato == 1 //Variables con rangos, los rangos son horas, ej: PRED_HAINES_06  (obsoleto)
	#
	my $sufijo_var_defs = undef;
	($variable, $sufijo_var_defs) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	#print STDERR "Variable Multiple: $sufijo_var_defs\n" if (defined $sufijo_var_defs);
	$despues_de_variable="-p$sufijo_var_defs" if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 0);
	if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 1)
	{
		$despues_de_variable = $sufijo_var_defs;
		if ($horiz =~ /D(.*)/ ){$horiz=$1*24;}
		$horiz += $sufijo_var_defs;
	}
	$despues_de_variable = sprintf("-%02d", $sufijo_var_defs) if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 2);
	$antes_de_variable = 'hirlam-' if(defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 3);
	

	# HORIZONTE
	my $h ='';
	$horiz =~ s/D//g;
	$horiz =~ s/H//g;
	#Por defecto la variable es diaria
	if (defined $vars{$variable}{'ambito'}) 
	{
		if ( $vars{$variable}{'ambito'} == 'horaria')
		{
			#Se agrega el -h para las horarias
			$h = sprintf("-h%02d",$horiz);
		}
		if ( $vars{$variable}{'ambito'} == 'semanal')
		{
			#print STDERR "Horizonte Semanal: $horiz\n";
		}
	}
	else
	{
		$h = "-d$horiz";
	}
	$h = '' if ($variable =~ /^(OBS|EST)/);

	# ISOTERMAS   (HAINES ALGUN DIA CUANDO SEA RASTER)
	if(defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 5)
	{
		$antes_de_variable = 'hirlam-';
		$h="-d$horiz"."h$sufijo_var_defs";
	}

	
	# RESOLUCION
	my $resolucion = (defined $vars{$variable}{res}) ? $vars{$variable}{res} : 500;


	# FORMAR EL NOMBRE DEL FICHERO
	my $raster_name=$modo.$resolucion.'-'.$antes_de_variable;
	$raster_name .= $vars{$variable}{variable}.$despues_de_variable.'-'.$fecha_filename.$h.'.'.$vars{$variable}{raster};
	my $data_file = $data_path.$raster_name;
	
	if (!-f $data_file)
	{
		#print STDERR "ERROR FORMANDO NOMBRE DEL RASTER: $data_file Sera un DBF?\n";
	}
	if (defined $vars{$variable}{raster}){return $data_file;} else {return undef;}	

}





#
# obtenerInformacion
# Devuelve los datos en un punto/area solicitado.
# Parámetros:
# - modo:	"observaciones|predicciones"
# - variable:	Una variable válida del array @vars. (PRED_TEMPMAX, OBS_TEMPMAX, ...)	
# - param:	Parámetro para las variables múltiples como precipitación o haines.
# - escala:	Junto con el punto central, define el área de donde queremos la información.
# - x e y:	X e Y en UTM30 del centro del área.
# - fecha:	Fecha pase de las predicciones, o fecha de la observación que queremos.
# - proyeccion: Sistema de coordenadas de la X y la Y.
#
sub obtenerInformacionSipro()
{
	my ($modo, $variable, $hor, $radio, $escala, $x, $y, $fecha, $proyeccion) = @_ ;

	# Directorio donde se encuentra el fichero
	my $resolution = (defined $vars{$variable}{res}) ? $vars{$variable}{res} : 500;
	my $data_path = "/var/www/meteosig/data/$modo/$fecha/${modo}$resolution-";
	$data_path .= 'hirlam-' if($resolution == 5000);

	# Controlamos el paso del tiempo
	if($hor != -1)
	{
		$hor = -1;
	}

	my (@valores, $valoresGeom);

	my $proyeccion_var=$vars{$variable}{proyeccion};

	#Si no estan definidas la proyecciones asumimos que estan en epsg:25830
	if (!defined $proyeccion_var){$proyeccion_var='epsg:25830';}
	if (!defined $proyeccion){$proyeccion='epsg:25830';}
	if ($proyeccion eq 'latlon' or $proyeccion eq 'latlong'){$proyeccion='epsg:4326';}
	if ($proyeccion_var eq 'latlon' or $proyeccion_var eq 'latlong'){$proyeccion_var='epsg:4326';}
	#print STDERR "Se ha llamado a obtenerInformacion con la x: $x y: $y proyeccion: $proyeccion\n";	
	if ($proyeccion	ne $proyeccion_var)
	{
		#print STDERR "Se necesita una conversion de $proyeccion a $proyeccion_var\n";
		#if (defined $vars{$variable}{proyeccion} and $vars{$variable}{proyeccion} eq 'latlon')
		#print STDERR "echo $x $y |/usr/local/FWTools/bin_safe/cs2cs +init=$proyeccion +to +init=$proyeccion_var);=";
		($x, $y,my $err) =split(' ', `echo $x $y |/usr/local/FWTools/bin_safe/cs2cs +init=$proyeccion +to +init=$proyeccion_var -f "%.16f"`);
	}
	# Si la variable es de tipo raster, utilizamos GDAL ...
       	if (defined $vars{$variable}{raster})
	{
		my $raster_name = sprintf("%s%02d.%s", $vars{$variable}{variable}.'-'.$fecha.'-h', $hor, $vars{$variable}{raster}); 
		#print STDERR "VARIABLE: ($variable) RASTERNAME: ($raster_name)\n";
		(@valores, $valoresGeom) = getPointInfoGDALOneHoriz ( $data_path, $raster_name, $x , $y , $radio, $vars{$variable}{factor} );
	}
	
	return (@valores, $valoresGeom);
}


# PARAMETROS
# $modo = [observaciones|predicciones]
# $variable = Variable del meteosig del tipo 'PRED_TEMPMAX'
# $x , $y = coordenadas
# $proyeccion = proyeccion de las coordenadas
# $fecha = tipo YYYYMMDD
# $horiz = horizonte
# Fabio 20090423 Funcion nueva que reemplazara a obtenerInformacion()
sub getMeteoInfoAntiguo()
{
	my ($variable, $x, $y, $proyeccion,$fecha, $horiz) = @_ ;

	my $data_path='';

	($variable, $sufijo_var_defs) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	# RECIBO EL NOMBRE DEL FICHERO A CONSULTAR
	my $data_file;
	if (defined $vars{$variable}{raster})
	{
		$data_file = &dameNombreDeRaster($variable,$fecha,$horiz);
	}
	else
	{
		$data_file = &dameNombreDeDBF($variable,$fecha,$horiz);
	}	
	
	#print STDERR "getMeteoInfo: CONSULTANDO EL FICHERO: $data_file\n";
	
#	($variable, $sufijo_var_defs) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	#
	# Paso 2: averiguar el punto y radio a consultar
	#
	my $proyeccion_var=$vars{$variable}{proyeccion};
	if (!defined $proyeccion_var){$proyeccion_var='epsg:25830';}
	if (!defined $proyeccion){$proyeccion='epsg:25830';}
	if ($proyeccion eq 'latlon' or $proyeccion eq 'latlong'){$proyeccion='epsg:4258';}
	if ($proyeccion_var eq 'latlon' or $proyeccion_var eq 'latlong'){$proyeccion_var='epsg:4258';}

	if ($proyeccion ne $proyeccion_var)
	{
		#print STDERR "Se necesita una conversion de $proyeccion a $proyeccion_var\n";
		($x, $y,my $err) =split(' ', `echo $x $y |/usr/local/FWTools/bin_safe/cs2cs +init=$proyeccion +to +init=$proyeccion_var -f "%.16f"`);
		$radio = $vars{$variable}{radio} ? $vars{$variable}{radio} : 0.025;
	}
	$radio = $vars{$variable}{radio} ? $vars{$variable}{radio} : 10;

	#
	# Paso 3: Consultar
	#

	# RASTER
	if (defined $vars{$variable}{raster})
	{
		# Nombre del raster que contiene la información.a
		$raster_name=$data_file;

		(@valores, $valoresGeom) = getPointInfoGDALOneHoriz ( $data_path, $raster_name, $x , $y , $radio, $vars{$variable}{factor} );
		my ($campo,$dato)=split( /=/, $valores[1]);
		#print "Fabio dato $dato\n";
		return $dato;
	}
	# DBF
	else
	{
		#TODO, con la mierda esta del datapath con parte del nombre del fichero, no funciona.
		#print STDERR "DATA_FILE del DBF: $data_file\n";
		if ($data_file =~ /(.*-)(.*)?\.(.*)/)
		{
			$parte1=$1;
			$parte2=$2;
		}
		#print STDERR "PARTE1: $parte1, PARTE2: $parte2\n";
		my @valor_bueno; #array pensando en albergar un solo valor 
		$horiz =~ s/D//g;
		$horiz = sprintf "%02d", $horiz;
		$data_path = $data_path.$modo.$resolucion.'-';
		my $shp_name =$vars{$variable}{database};
		#print  " &getPointInfo($data_path, $shp_name, $x , $y , $radio, $vars{$variable}{filtrodbf}, $vars{$variable}{factor});\n";
		#(@valores, $valoresGeom) = getPointInfo($data_path, $shp_name, $x , $y , $radio, $vars{$variable}{filtrodbf}, $vars{$variable}{factor});
		#print STDERR "getMeteoInfo: El horiz del dbf es :$horiz\n";
		(@valores, $valoresGeom) = getPointInfo($parte1, $parte2, $x , $y , $radio, $vars{$variable}{filtrodbf}, $vars{$variable}{factor});
		delete $valores[0];
		#print STDERR "getMeteoInfo: ESTO ES UN DBF CON VALORES: @valores \n";
		foreach $val (@valores)
		{
			if ($vars{$variable}{ambito} eq 'horaria')
			{
				my $horiz_hora = sprintf "%02d", ($horiz % 24);
				if ($horiz_hora eq '00')
				{
					$horiz_hora = 24;
					$horiz1 = $horiz - 24;
					#$horiz_dia = 'D'.$1-1 if ($horiz_dia =~ /D(.*)/);
				}
				my $horiz_dia = 'D'.int($horiz / 24);
				if (defined $horiz1){$horiz_dia = 'D'.int($horiz1 / 24);}
				#print STDERR "ESTO ES UN DBF CON VAL: $val horiz_hora: $horiz_hora  horiz_dia: $horiz_dia horiz: $horiz\n";
				#HAINES Y T850
				if ($val =~ /($horiz_dia)(.*)($horiz_hora)=(.*)/)
				{
					push (@valor_bueno,$4);
					#print STDERR "CAMPO DBF_horario: $val, VALOR BUENO: @valor_bueno\n";
					last;
				}
				#VIENTOHIRLAM
				elsif ($val =~ /MOD($horiz)=(.*)/)
				{
					push (@valor_bueno,$2);
					#print STDERR "CAMPO DBF viento hirlam: $val,horiz: $horiz VALOR BUENO: @valor_bueno\n";
					last;
				}
				
			}
			elsif ($val =~ /(.*)=(.*)/)
			{
				push (@valor_bueno,$2);
				#print STDERR "CAMPO DBF: $val, VALOR BUENO: @valor_bueno\n";
				last;
			}
		}
		$valor_bueno[0] =~ s/ //g;
		return (@valor_bueno, $valoresGeom);
	}	
	
	#print "Nombre del fichero a consultar: $data_path"."$raster_name\n";
	
}

#  Devuelve una lista de features contenidos en ese extent
sub extraerIDS
{
	my  ( $data_path, $variable, $x, $y , $radio) = @_;

	#my $user="cam";
	my $shp_file =$variable.".shp" ;
	my $command = "$ogrinfoturbo -al -spat " ;
	my $data_file = $data_path . $shp_file ;


	# abrimos un radio alrededor del punto pasado
	my $xmin = int ($x - $radio );
	my $xmax = int ($x + $radio );
	my $ymin = int ($y - $radio );
	my $ymax = int ($y + $radio );

	my $extent = "$xmin $ymin $xmax $ymax" ;

	my $exec = $command . $extent . " " . $data_file ." | grep OGRFeature" ;
	#print STDERR "EXEC: ($exec)<br>" ;
	my $res = `$exec`;

	my @lines = split ( "\n" ,  $res."\n"  );

	foreach my $line(@lines )
	{
		if  ( $line  =~  /(.*):(.*)/i )
	        {
			push (@ids , $2);
        	}
	}
	return @ids;
}

# usando el id y los dbf directamente, no info espacial

sub getPointInfoLigero
{
	my  ( $data_path, $variable, $ids) = @_;
	#my $user="cam";
	#   print $ids;
	my @aIDS = split(/:/,$ids);
	my @valores ;
 	foreach my $id(@aIDS )
 	{
		#print "$id<br>" ;
		my $shp_file =$variable.".shp" ;
	  	my $command = "$ogrinfo -al -fid $id" ;

	  	# PATH a los shapefiles.
	  	my $data_file = $data_path . $shp_file ;
	  	my $exec = $command . " " . $data_file ;
	  	#print STDERR "EXEC: ($exec)\n" ;
	  	# print "$exec\n";
	  	my $res = `$exec`;
	  	#print STDERR "FINEXEC\n";
	  	my @lines = split ( "\n" ,  $res  );

		my $flag = 0;
		my $iid;
		my $nid = 0;
		foreach my $line(@lines )
		{
			# las lineas con valores van precedidas por 2 espacios
			if  ( $line  =~  /^(\s)+(.*)/i )
			{
				$resto = $2;
# 				print "\t#$1#$2#<br>";
				if  ( $resto =~ /(.*)\s(\(.*\))\s=\s(.*)/i )
				{
# 					print "\t#$1#$2#$3<br>";
					$campo = $1;
					$valor = $3 ;
					if($flag == 0) {
						$flag = 1;
						$iid = $campo;
					}
					if($campo eq $iid) {
						$nid++;
						$id = $nid;
						push (@valores, "ID=$id");
					}
#   					print "$campo=$valor<br>";
	#				push (@campos , $campo );
					if($campo ne 'ID') {
						push (@valores  , "$campo=$valor" );
					}
				}
				if  ( $resto  =~  /^(POLYGON)\s+\(\((.*)\)\)/i )
				{
					#print "\t#$1#$2#<br>";
					my $geom = $2 ;
					#@aGeoPoints = split (/,/ , $geom );
					#print "#$geom#<br>";
					$valoresGeom{$id} = $geom ;
				}
			}
		}
 	}

	return ( @valores,$valoresGeom);
}

# TODO: Muy cutre devolver un array con todos los campos de todos los registros. Lo correcto sería devolver un array de hashes.
# 20080530 Regodón. Se añade un nuevo campo "filtro", para el caso de los DBF que contienen mas de una variable, como precipitación.
{
%geoInfoCache;
sub getPointInfo
{
	my ( $data_path, $variable, $x, $y , $radio, $filtro, $factor) = @_;
	my @valores;
	my $valoresGeom;

	if (defined $geoInfoCache{$data_path}{$variable}{$x}{$y}{$radio}{'valores'})
	{
		@valores = @{$geoInfoCache{$data_path}{$variable}{$x}{$y}{$radio}{'valores'}};
		$valoresGeom = %{$geoInfoCache{$data_path}{$variable}{$x}{$y}{$radio}{'valoresGeom'}};

		#print STDERR "CACHE!\n";
		return ( @valores, $valoresGeom);
	}

	#my $user="cam";
	my $shp_file = $variable.'.shp' ;
	my $command = "$ogrinfoturbo -al -spat " ;
	my $data_file = $data_path . $shp_file ;
	#print STDERR "Ruta del dbf: $data_file\n";
	# abrimos un radio alrededor del punto pasado
	my $xmin = int ($x - $radio );
	my $xmax = int ($x + $radio );
	my $ymin = int ($y - $radio );
	my $ymax = int ($y + $radio );
	my $extent = "$xmin $ymin $xmax $ymax" ;

	# 20070108 Chequeo por si el DBF estuviera comprimido
	my $dbffile = $data_path.$variable.'.dbf';
	my $dbffilegz = $dbffile.'.gz';
	if (not -f $dbffile)
	{
		if (-f $dbffilegz)
		{
			`gzip -cd $dbffilegz >$dbffile`;
		}
	}

	# 20080821 Descartamos la información del polígono porque nadie la usa y ralentiza mucho.
	# TODO: Modificar la estructura de la función para que no devuelva ese parámetro.
	my $exec = $command . $extent . " " . $data_file . " |fgrep -v 'POLYGON ('" ;
	#print STDERR "EXEC: ($exec)\n" ;
	my $res = `$exec`;
	#print "res: $res\n";
	my @lines = split ("\n", $res);
	my $flag = 0;
	my $iid;
	my $nid = 0;
	foreach my $line(@lines )
	{
		if  ( $line  =~  /(^Feature Count:\s)(.*)/i )
		{
			#print "nº de regs:$2\n" ;
			$num_regs = $2 ;
		}
		if  ( $line  =~  /^(?:\s)+(.*)$/i )
		# las lineas con valores van precedidas por 2 espacios
		{
			my $resto = $1;
			if  ($resto =~ /(.*)\s(?:\(.*\))\s=\s(.*)/i)
			{
				#print "\t#$1#$2#$3<br>";
				$campo = $1;
				$valor = $2 ;
				# Aprender el primer campo, para detectar donde empieza un registro nuevo.
				if ($flag == 0) {
					$flag = 1;
					$iid = $campo;
				}
				# Si empieza un registro nuevo, metemos nuestro campo ID...
				if ($campo eq $iid) {
					$nid++;
					$id = $nid;
					push (@valores, "ID=$id");
				}
				# Prueba: ignorar los campos que no cumplan con el filtro.
				# Ignoramos los campos que se llamen 'ID'.
				#if ($campo ne 'ID' and $campo =~ /$filtro/i) {
					#print STDERR "CAMPO: ($campo) FILTRO: ($filtro)\n";
				if ($campo ne 'ID' and (not defined $filtro or  $campo =~ /$filtro/i))
				{
					# 20090109 Injertón. Si la variable es probabilidad de precipitación, no puede ser negativa.
					$valor=0 if ($variable =~ /precip/ and $valor < 0);

					# Si hemos recibido un factor, lo aplicamos al dato. Se usa para el cambio de unidades.
					# En ese caso se da por hecho que el campo es numérico.
					$valor *= $factor if (defined $factor);

					push (@valores, "$campo=$valor");
				}
			}
			# TODO: Calcular el extent de la respuesta recibida. Qué pasa en las capas de líneas o puntos?
			#       Sería mejor devolver el mismo extent que nos han pedido?
			#if  ( $resto  =~  /^POLYGON\s+\(\((.*)\)\)/i )
			#{
				# Para que funcione debe estar asi
			#	$valoresGeom{"$id"} = $1 ;
				# Si está asi no funciona la herramienta de informacion en un punto
				# (quien lo puso que diga el porque aqui debajo)
				#$valoresGeom = "$xmin $ymin, $xmin $ymax, $xmax $ymax, $ymin $xmax, $xmin $ymin";
			#}
		}
	}

	#fin parseo
	@{$geoInfoCache{$data_path}{$variable}{$x}{$y}{$radio}{'valores'}} = @valores;
	%{$geoInfoCache{$data_path}{$variable}{$x}{$y}{$radio}{'valoresGeom'}} = $valoresGeom;
	#printf STDERR "GEOM: ($valoresGeom)\n";


	# Esto vuelve locos a otros programas, pues valoresGeom se mete como elementos de @valores.
	# ¿a qué programas?
	return (@valores , $valoresGeom);
	#return (@valores);
}
}


sub processGeom ()
{
	my ($geom ) = @_ ;
	#print "GEOM:$geom#<br>";
	#468709.572 4470693.450,469209.572 4470693.450,469209.572 4470193.450,468709.572 4470193.450,468709.572 4470693.450
	@aCoords = split ( ",", $geom );

	#print @aCoords[0]. "<br>";
	if (  $aCoords[0]=~  /(.*)\s(.*)/i )
	{
		$xmin = $1 ; $ymin = $2 ;
	}
	#print @aCoords[2]. "<br>";
	if (  $aCoords[2]=~  /(.*)\s(.*)/i )
	{
		$xmax = $1 ; $ymax = $2 ;
	}
	#print "Extent:$xmin#$ymin#$xmax#$ymax<br>" ;
	#my $sld = "Xmin: ". int ($xmin) ."<br>YMin: " . int($ymin) ."<br>Xmax: ". int ($xmax) ."<br>Ymax: ". int ($ymax);
	#return $sld ;
	return sprintf("<div style=\"text-align: center; border: solid red 0px;\">%d<div>%d <img src=\"/null.gif\" alt=\"\" title=\"\" style=\"vertical-align: middle; width: 30px; height: 30px; border: solid black 2px; margin: 5px;\"> %d</div>%d</div>", int($ymax), int ($xmin), int ($xmax), int($ymin));

}

# Obtiene el valor promedio en un area, para un horizonte dado
sub getAvgPointInfo()
{
	my ( $data_path, $variable, $x, $y , $radio, $hor) = @_;
	
	my $tot=0.0;
	my $numsamples=0;

	my ( @valores, $valoresGeom) = &getPointInfo($data_path, $variable, $x, $y , $radio);
	foreach my $tr (@valores)
	{
		my ($campo, $valor) = split(/=/, $tr, 2);
		# -999 significa NO DATA
		next if ($valor == -999);

		if ($campo =~ /^$hor/)
		{
			#print STDERR "VALOR: ($valor)\n";
			$numsamples++;
			$tot+=$valor;
		}
	}

	if ($numsamples>0)
	{
		return $tot/$numsamples;
	}
	return undef;
}

# Obtiene la moda en un area, para un horizonte dado
sub getModePointInfo()
{
	my ( $data_path, $variable, $x, $y , $radio, $hor, $nodata) = @_;
	
	#my $tot=0.0;
	#my $numsamples=0;
	my %valores;

	my ( @valores, $valoresGeom) = &getPointInfo($data_path, $variable, $x, $y , $radio);
	foreach my $tr (@valores)
	{
		my ($campo, $valor) = split(/=/, $tr);
		# -999 significa NO DATA
		next if ($valor == $nodata);

		if ($campo =~ /^$hor/)
		{
			# Redondear el valor para encontrar mejor la moda.
			$valor = sprintf("%.0f", $valor);

			$numsamples++;
			if (defined $valores{$valor})
			{
				$valores{$valor}++;
			}
			else
			{
				$valores{$valor}=1;
			}
		}
	}

	if ($numsamples>0)
	{
		#return $tot/$numsamples;
		# Buscar la moda
		my $mode;
		my $max=0;
		foreach my $k (sort { $a <=> $b } keys %valores)
		{
			#print STDERR "VALOR: $k ".$valores{$k}."/$numsamples\n";
			if ($valores{$k} > $max)
			{
				$mode = $k;
				$max = $valores{$k};
			}
		}
		return $mode;
	}
	return undef;
}

#utiles pra graficos
sub maxfactor
{
	my ( $max , $factor ) = @_ ;
	return 0 if (! defined $max ) ;
	my $decimales =0 ;
	$decimales  = $max - int ( $max ) ;
	my $resto = (  $max  %  $factor ) + $decimales  ;
	my $max500 = $max + ( $factor - $resto );
	return ( $max500 ) ;
}

sub maximo10
{
	#da el maximo multiplo de 10
	my @data = @_;
	my $cur =0 ;
	my $num  =0 ;
	foreach $num( @data  )
	{
		$cur = 0 if ( !defined ($cur)) ;
		$cur  = $num if ( $num > $cur ) ;
	}
	$cur = int ($cur) +1;
	print "<br>maximo valor ". $cur if ($debug );
	if ( ($cur%10) )
	{
		$cur = (( int ($cur / 10) +1 )+1)  * 10 ;
	}
	return  $cur  ;
}

sub generarImgError
{
	my ( $ancho,$alto) = @_;
	my $im = new GD::Image($ancho,$alto);
	 $white = $im->colorAllocate(255,255,255);
	 $blue = $im->colorAllocate(0,0,255);
 	$im->string(gdMediumBoldFont,2,10,"Datos no disponibles en ese punto",$blue);
	return $im;

}

sub generaOutDebug
{
	my ($ancho,$alto,$datosdebug) = @_;
        my $im = new GD::Image($ancho,$alto);
        $white = $im->colorAllocate(255,255,255);
        $blue = $im->colorAllocate(0,0,255);
        $im->string(gdMediumBoldFont,2,10,$datosdebug,$blue);
        return $im;
}

sub getPointInfoGDAL
{
	my ( $data_path, $variable, $x, $y , $radio, $factor) = @_;
	if ($radio > 1) {
		$radio = 250 if ($radio < 250); # Para que como mínimo coja una celda 
		$radio = 2500 if ($radio > 2500); # Para que como maximo de celdas 
	}
	# 20070516 Radio 0 para que funcione en los raster hirlam. 
	# TODO: Poder expresar el radio en grados?? Convertir
	# abrimos un radio alrededor del punto pasado
	my $xmin = $x - $radio;
	my $xmax = $x + $radio;
	# 20080710 Cambiado + y - porque aparentemente estaban al reves y ymin era mayor que ymax y fallaba gdal. (con nubosidad hirlam)
	my $ymin = $y - $radio;
	my $ymax = $y + $radio;
	my @valores = ();
	push (@valores, "ID=1");

	my $extent = "-projwin $xmin $ymin $xmax $ymax";

	my %horizonte;
	my ($ncols, $nrows, $xllcorner, $yllcorner, $cellsize, $nodata);
	# Averiguo la extensión del fichero raster (vrt, png, ...)
	$variable =~ /(.*)(\..*)$/; 
	my $prefijo = $1;
	my $extension = $2;

	# Bucle, "para todos los horizontes de la variable"
	#foreach my $k (0 .. 9)
	foreach my $k (split("\n",`ls $data_path*$prefijo*$extension`))
	{
		#my $raster_file = $variable;
		## Añadimos el horizonte de la variable ... 
		#if ($data_path =~ /predicciones/) { 
		#	$raster_file =~ s/$extension/-d$k$extension/;
		#}
		#my $data_file = $data_path . $raster_file;
		my $data_file = $k;
	       	$data_file =~ m/$data_path(?:.*)$prefijo(.*)$extension/;
		my $hor = uc($1); $hor=~ s/^-//g;
		# Si no existe el fichero raster, pasamos al siguiente horizonte ... 
		if (! -r $data_file) { 
			print STDERR "ERROR: No existe ($data_file)\n";
			next;
		}
#		my $command = '/usr/local/FWTools/bin_safe/gdal_translate -of AAIgrid ';
		my $command = '/usr/local/gis/bin/gdal_translate -of AAIgrid ';
		my $TMPFILE="/tmp/GDAL.$$.$x-$y.txt";
		unlink $TMPFILE;
		my $exec = $command . $extent . " $data_file $TMPFILE";
		#print "EXEC: ($exec)\n" ;

		`$exec`;

		# Chapucilla. Si ha fallado gdal_translate quizás es por el bug que tiene con los rasters inversos que van de sur a norte (hirlam por ejemplo).
		# Reintentamos cambiando ymin e ymax.
		if ( ! -f $TMPFILE)
		{
			$extent = "-projwin $xmin $ymax $xmax $ymin";
			$exec = $command . $extent . " $data_file $TMPFILE";
			#print STDERR "EXEC2: ($exec)\n" ;
			`$exec`;
		}

		my $res = `cat $TMPFILE`;
		unlink $TMPFILE;
		#`rm -f /tmp/GDAL.$x-$y.*`;
		#print "\n$res\n";
		my @lines = split ("\n", $res);

		# TODO: PArtir esto en dos bloques, lectura de cabecera y lectura de datos, para mas eficiencia.
		foreach my $line(@lines)
		{
			if ($line =~ /ncols(.*?)(\d+)/i)
			{
				$ncols = $2;
			}
			elsif ($line =~ /nrows(.*?)(\d+)/i)
			{
				$nrows = $2;
			}
			elsif ($line =~ /xllcorner(.*?)(\d+)/i) 
			{
				$xllcorner = $2;			
			}
			elsif ($line =~ /yllcorner(.*?)(\d+)/i)
			{
				$yllcorner = $2;
			}
			elsif ($line =~ /cellsize(.*?)(\d+)/i)
			{
				$cellsize = $2;
			}
			elsif ($line =~ /NODATA_value(.*?)(\d+)/i)
			{
				$nodata = $2;	
				#print STDERR "EL NODATA ES: $nodata\n";
			}
			else 
			{
				my @datos = split (" ", $line);
				my $aux;
				foreach my $dato (@datos)
				{	
					# Si hemos recibido un factor, lo aplicamos al dato. Se usa para el cambio de unidades.
					# En ese caso se da por echo que el campo es numérico.
					if (defined $nodata and $dato == $nodata)
					{
						#print STDERR "HAY UN NODATA: $dato\n";
					}
					$dato *= $factor if (defined $factor);

					push (@valores, "$hor=$dato");
				}
			}
		}
		# En el modo observaciones sólo se hace un horizonte, así que salimos  
		if ($data_path !~ /predicciones/) { 
			last;
		}
	}

	my $iid;
	my $nid = 0;


	#while ( $horizonte{0} =~ /=/ )
	#{
	#	$nid++;
	#	push (@valores, 'ID='.$nid);
	#	if ($data_path !~ /predicciones/) # Estamos en el modo observaciones
	#	{
	#		$horizonte{0} =~ s/ (.*?=\d+)//;
	#		my $aux = $1;
	#		$aux =~ s/D0/OBS/;
	#		push (@valores, $aux);
	#		next;
	#	}
	#	foreach my $k (0 .. $contador - 1) 
	#	{
	#		$horizonte{$k} =~ s/ (.*?=\d+)//;
	#		push (@valores, $1);	
	#	}
	#}



	#$yllcorner = $yllcorner + $nrows * $cellsize; # Cálculo de la coordenada geográfica Y superior
	#foreach my $id (0 .. ($nid-1))
	#{
	#	$xmin = $xllcorner + ($id % $ncols) * $cellsize; 
	#	$xmax = $xmin + $cellsize;
	#	$ymin = $yllcorner - sprintf("%d",($id / $nrows)) * $cellsize;
	#	$ymax = $ymin - $cellsize;
	#
	#	$iid = $id + 1;
	#	$valoresGeom{$iid} = "$xmin $ymin, $xmin $ymax, $xmax $ymax, $ymin $xmax";
	#}

	$ymin = $yllcorner;
	$ymax = $yllcorner + $nrows * $cellsize;
	$xmin = $xllcorner;
	$xmax = $xllcorner + $ncols * $cellsize;
	$valoresGeom{'1'} = "$xmin $ymin, $xmin $ymax, $xmax $ymax, $ymin $xmax, $xmin $ymin";

	#print STDERR "VALORES: (@valores)\n";

	#fin parseo
	return ( @valores,$valoresGeom);
}

sub getPointInfoGDALOneHoriz
{
	my ( $data_path, $raster_file, $x, $y , $radio, $factor) = @_;
	#print STDERR "($data_path)\n";
	if ($radio > 1) {
		$radio = 250 if ($radio < 250); # Para que como mínimo coja una celda 
		$radio = 2500 if ($radio > 2500); # Para que como maximo de celdas 
	}
	# abrimos un radio alrededor del punto pasado
	my $xmin = ($x - $radio); # int ($x - $radio);
	my $xmax = ($x + $radio); # int ($x + $radio);
	# 20080710 Cambiado + y - porque aparentemente estaban al reves y ymin era mayor que ymax y fallaba gdal. (con nubosidad hirlam)
	my $ymin = ($y - $radio); # int ($y - $radio);
	my $ymax = ($y + $radio); # int ($y + $radio);

	my $extent = "-projwin $xmin $ymin $xmax $ymax";

	my ($resultado, $datos);
	my ($ncols, $nrows, $xllcorner, $yllcorner, $cellsize, $nodata);
	# Averiguo el horizonte de la variable
	if ( $raster_file =~ /-d(\d)\....$/ )
	{
		$horizonte = 'D'.$1;
	}
	elsif ( $raster_file =~ /-h(\d)\....$/ )
	{
		$horizonte = 'H'.$1;
	}
	else {
		$horizonte = 'OBS';
	}
	
	my $data_file = $data_path . $raster_file;
	# Si no existe el fichero raster, no hace falta que continuemos ... 
	if (! -r $data_file) {
		#print STDERR "El fichero raster $data_file no existe\n";	
		return;
	}
	my $TMPFILE="/tmp/GDAL.$$.$x-$y.txt";
	unlink $TMPFILE;
	# 20091016 PRG. Cambiado porque en producción va muy lento el gdal_translate de las FWTools
	#my $command = '/usr/local/FWTools/bin_safe/gdal_translate -of AAIgrid -b 1 ';
	my $command = '/usr/local/gis/bin/gdal_translate -of AAIgrid -b 1 ';
	my $exec = $command . $extent . " $data_file $TMPFILE";
	#print STDERR "EXEC: ($exec)\n" ;

	`$exec`;

	# Chapucilla. Si ha fallado gdal_translate quizás es por el bug que tiene con los rasters inversos que van de sur a norte (hirlam por ejemplo).
	# Reintentamos cambiando ymin e ymax.
	if ( ! -f $TMPFILE)
	{
		$extent = "-projwin $xmin $ymax $xmax $ymin";
		$exec = $command . $extent . " $data_file $TMPFILE";
		#print STDERR "EXEC2: ($exec)\n" ;
		`$exec`;
	}

	return if (! -r $TMPFILE);
	my $res = `cat $TMPFILE`;
	unlink $TMPFILE;
	#print "\n$res\n";
	my @lines = split ("\n", $res);

	foreach my $line(@lines)
	{
		if ($line =~ /ncols(.*?)(\d+)/i)
		{
			$ncols = $2;
		}
		elsif ($line =~ /nrows(.*?)(\d+)/i)
		{
			$nrows = $2;
		}
		elsif ($line =~ /xllcorner(.*?)(\d+)/i) 
		{
			$xllcorner = $2;			
		}
		elsif ($line =~ /yllcorner(.*?)(\d+)/i)
		{
			$yllcorner = $2;
		}
		elsif ($line =~ /dx(.*?)(\d+)/i)
		{
			$cellsize = $2;
		}
		elsif ($line =~ /dy(.*?)(\d+)/i)
		{
			$cellsize = $2;
		}
		elsif ($line =~ /cellsize(.*?)(\d+)/i)
		{
			$cellsize = $2;
		}
		elsif ($line =~ /NODATA_value(.*?)(\d+)/i)
		{
			$nodata = $2;	
		}
		else 
		{
			my @datos = split (" ", $line);
			my $aux;
			foreach my $dato (@datos)
			{	
				# Si hemos recibido un factor, lo aplicamos al dato. Se usa para el cambio de unidades.
				# En ese caso se da por echo que el campo es numérico.
				$dato *= $factor if (defined $factor);

				#$aux = $horizonte.'='.$dato;
				$resultado .= " $horizonte=$dato";
			}
		}
	}

	my @valores;
	my $iid;
	my $nid = 0;

	while ( $resultado =~ /=/ )
	{
		$nid++;
		push (@valores, 'ID='.$nid);
		$resultado =~ s/ (.*?=-?\d+\.?\d*)//;
		push (@valores, $1);	
	}

	$yllcorner = $yllcorner + $nrows * $cellsize; # Cálculo de la coordenada geográfica Y superior
	foreach my $id (0 .. ($nid-1))
	{
		$xmin = $xllcorner + ($id % $ncols) * $cellsize; 
		$xmax = $xmin + $cellsize;
		$ymin = $yllcorner - sprintf("%d",($id / $nrows)) * $cellsize;
		$ymax = $ymin - $cellsize;
	
		$iid = $id + 1;
		$valoresGeom{$iid} = "$xmin $ymin, $xmin $ymax, $xmax $ymax, $ymin $xmax";
	}

	#fin parseo
	return ( @valores,$valoresGeom);
}

#
# obtenerInformacion
# Devuelve los datos en un punto/area solicitado.
# Parámetros:
# - modo:	"observaciones|predicciones"
# - variable:	Una variable válida del array @vars. (PRED_TEMPMAX, OBS_TEMPMAX, ...)	
# - param:	Parámetro para las variables múltiples como precipitación o haines.
# - escala:	Junto con el punto central, define el área de donde queremos la información.
# - x e y:	X e Y en UTM30 del centro del área.
# - fecha:	Fecha pase de las predicciones, o fecha de la observación que queremos.
# - proyeccion: Sistema de coordenadas de la X y la Y.
#
sub obtenerInformacion()
{
	my ($modo, $variable, $param, $escala, $x, $y, $fecha, $proyeccion, $dd) = @_ ;

	# Ver si es una variable múltiple
	my $d = undef;
	($variable, $d) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/); #if  ( $variable  =~  /(^[A-Z]+)(.*)/i );
	#$d = ('-' . $d) if ($d =~ /\d+/);
	$d="-p$d" if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 0);
	$d="-p$dd" if (defined $dd and defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 0);
	$d = $d   if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 1); # Haines necesita "12, 06, 18";
	$d = sprintf("-%2.2d", $d) if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 2); # Precipitacion y nieve
	$d="-$dd" if (defined $vars{$variable}{'tipodato'} and $vars{$variable}{'tipodato'} == 2);

	#print STDERR "Se ha llamado a obtenerInformacion con variable: $variable dd: $dd d: $d\n";	

	# Directorio donde se encuentra el fichero (raster o dbf)
	my $resolution = (defined $vars{$variable}{res}) ? $vars{$variable}{res} : 500;
	my $data_path = "/var/www/meteosig/data/$modo/$fecha/${modo}$resolution-";

	my (@valores, $valoresGeom, $radio);
	$radio = int (1 * $escala / 2);  # metros por pixel, en ppio usamos un pixel
	# 20080529 Paco Regodón. Parche para ignorar la escala, y obtener la información en un punto.
	$radio=10;
	# Fabio 20090302 A lo mejor estas dos lineas hay que borrarlas.
	$radio = $vars{$variable}{radio} ? $vars{$variable}{radio} : 10;
	#print STDERR "El radio es $radio\n";

	
	# Si la variable no está en utm30, convertir la X y la Y.
	# TODO: Esto está mal. Solo vale para variables en latitud/longitud. Mirar que pasa en el usuario ACA (utm31)
	# Fabio 20090302 Arreglando el TOD de la linea anterior
	#if (defined $vars{$variable}{proyeccion} and $vars{$variable}{proyeccion} ne 'utm30')
	my $proyeccion_var=$vars{$variable}{proyeccion};

	#Si no estan definidas la proyecciones asumimos que estan en epsg:25830
	if (!defined $proyeccion_var){$proyeccion_var='epsg:25830';}
	if (!defined $proyeccion){$proyeccion='epsg:25830';}
	if ($proyeccion eq 'latlon' or $proyeccion eq 'latlong'){$proyeccion='epsg:4258';}
	if ($proyeccion_var eq 'latlon' or $proyeccion_var eq 'latlong'){$proyeccion_var='epsg:4258';}
	#print STDERR "Se ha llamado a obtenerInformacion con la x: $x y: $y proyeccion: $proyeccion\n";	
	if ($proyeccion	ne $proyeccion_var)
	{
		#print STDERR "Se necesita una conversion de $proyeccion a $proyeccion_var\n";
		#if (defined $vars{$variable}{proyeccion} and $vars{$variable}{proyeccion} eq 'latlon')
		#print STDERR "echo $x $y |/usr/local/FWTools/bin_safe/cs2cs +init=$proyeccion +to +init=$proyeccion_var);=";
		($x, $y,my $err) =split(' ', `echo $x $y |/usr/local/FWTools/bin_safe/cs2cs +init=$proyeccion +to +init=$proyeccion_var -f "%.16f"`);
		$radio = $vars{$variable}{radio} ? $vars{$variable}{radio} : 0.025;
		#print STDERR "$x $y en $proyeccion_var \n";
	}
	# Si la variable es de tipo raster, utilizamos GDAL ...
       	if (defined $vars{$variable}{raster})
	{
		my $raster_name = $vars{$variable}{variable}.$d.$param.'-'.$fecha.'.'.$vars{$variable}{raster}; 
		#print STDERR "VARIABLE: ($variable) RASTERNAME: ($raster_name) PARAM: ($param)\n";
		if ($modo eq 'observaciones' or $modo eq 'climatologico')
		{
			(@valores, $valoresGeom) = getPointInfoGDALOneHoriz ( $data_path, $raster_name, $x , $y , $radio, $vars{$variable}{factor} );
		}
		else
		{
			#print STDERR "(\@valores, \$valoresGeom) = getPointInfoGDAL ( $data_path, $raster_name, $x , $y , $radio )\n";
			(@valores, $valoresGeom) = getPointInfoGDAL ( $data_path, $raster_name, $x , $y , $radio, $vars{$variable}{factor} );
			#print STDERR "valores: @valores\n";
		}
	}
	else { # Utilizamos 'ogrinfo' ... 
		my $shp_name = $vars{$variable}{database};
		#print STDERR "VARIABLE: ($variable) DBF: ($shp_name) FILTRO: (".$vars{$variable}{filtrodbf}.")\n"; 
		(@valores, $valoresGeom) = &getPointInfo($data_path, $shp_name, $x , $y , $radio, $vars{$variable}{filtrodbf}, $vars{$variable}{factor}); 
		#print STDERR "(\@valores, \$valoresGeom) = getPointInfo ( $data_path, $shp_name, $x , $y , $radio )\n";
	}
	
	return (@valores, $valoresGeom);
}





# 
# getMeteoInfo()
# Sirve para informacion en un punto, llama a las funciones con una ventana minima (radio=0) y devuelve un solo dato
# Entrada:
# - (variable) Nombre variable del defs.pl
# - (x,y,proyeccion) Punto a consultar
# - (fecha,horiz) fecha, horizonte a consultar
# Salida:
# - (res) Dato a mostrar en la pantalla de informacion en un punto del meteosig
# 
sub getMeteoInfo()
{
	my ($variable, $x, $y, $proyeccion,$fecha, $horiz) = @_ ;

	my $data_path='';

	my ($variable_limpia, $sufijo_var_defs) =  ($variable =~ /^([^_]*_[^_]*)(?:_(.*))?$/);
	
	# TODO falta controlar la pasada 
#	print STDERR "getMeteoInfo: fecha=$fecha variable= $variable\n";

	
	#my @resultado = &getMeteoInfoArea($variable,$x,$y,$x,$y,$proyeccion,$fecha, $horiz);
	#my $res = pop(@resultado);

	my $res = &getAvgMeteoInfoRadio($variable,$x,$y,0,$proyeccion,$fecha, $horiz);
	

	# aplicamos factor para la informacion en un punto.
	#$res *= $vars{$variable_limpia}{factor} if (defined $vars{$variable_limpia}{factor});
	
	return $res;
}




1;
