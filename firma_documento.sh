#!/bin/bash
html_firma=$2
documento=$1
destino=$3
hoja_firmada=$4


ahora=`date +%s`
firma="/tmp/firma_${ahora}.pdf"
format=`pdftk $documento dump_data_utf8 | grep -A 3 "PageMediaNumber: ${hoja_firmada}" | grep 'Dimensions' | cut -d ' ' -f 2,3`
#echo $format
#exit 1

if [ "$format" == "612 792" ]
then
    format='Letter'
else
    format='A4'
fi

wkhtmltopdf -s $format $html_firma $firma
#exit 1

pages=`pdftk ${documento} dump_data_annots | grep NumberOfPages | cut -d ' ' -f 2`
hoja_firmada=$4




#Validaciones
if [ -z "$documento" ]
then
    echo "ERROR 1: debe especificar el documento a firmar."
    exit 1
fi

if [ ! -f "$documento" ]
then
    echo "ERROR 2: debe existir el documento a firmar."
    exit 1
fi

if [ -z "$firma" ]
then
    echo "ERROR 3: debe especificar la firma para indexar al documento."
    exit 1
fi

if [ ! -f "$firma" ]
then
    echo "ERROR 4: debe existir el documento con la firma."
    exit 1
fi


if [ -z "$destino" ]
then
    echo "ERROR 5: debe especificar el archivo de destino para el documento firmado."
    exit 1
fi

if [ -z "$hoja_firmada" ]
then
    echo "ERROR 6: debe especificar la página del archivo origen a firmar."
    exit 1
fi


#es_numero='^-?[0-9]+([.][0-9]+)?$'
#if ! [[ $hoja_firmada =~ $es_numero ]]
#then
#   echo "ERROR: el parámetro para la página debe ser número" 
#   exit 1
#fi

if [ -z "$hoja_firmada"  ]
then
    echo "ERROR 7: debe especificar la página del archivo origen a firmar."
    exit 1
fi

ext_doc=`echo $documento | cut -d '.' -f 2`
ext_fir=`echo $firma | cut -d '.' -f 2`
ext_dest=`echo $destino | cut -d '.' -f 2`

if [ "$ext_doc" != 'pdf' ]
then
    echo "ERROR 8: el documento a firmar debe ser un archivo PDF."
    exit 1
fi

if [ "$ext_fir" != 'pdf' ]
then
    echo "ERROR 9: la firma debe ser un archivo PDF."
    exit 1
fi

if [ "$ext_dest" != 'pdf' ]
then
    echo "ERROR 10: el archivo de destino debe ser un archivo PDF."
    exit 1
fi

#Marca para que no se pisen subidas
marca=`date +%s`
paginaOrigenMarcada="/tmp/pag_${marca}"
paginaMarcada="/tmp/pag_firmada_${marca}"

#Si el parámetro de las hojas a firmar tiene -
if [[ $hoja_firmada =~ "-" ]]
then
    es_numero='^-?[0-9]+([-][0-9]+)?$'
    var1=`echo $hoja_firmada | cut -d '-' -f 1`
    var2=`echo $hoja_firmada | cut -d '-' -f 2`
    if [[ ( $var2 -gt $pages ) ||  ( $var1 -lt 1)  ||  ( $var2 -lt 1 ) ||  ( $var1 -gt $var2 ) || ! ( $hoja_firmada =~ $es_numero ) ]]
    then
        echo "ERROR 11: El rango de páginas a firmar del PDF no es correcto."
        exit 1
    else
        pi=`expr $var1 - 1`
        pf=`expr $var2 + 1`
        pdftk A=$documento cat A$var1-$var2 output ${paginaOrigenMarcada}.pdf
        pdftk ${paginaOrigenMarcada}.pdf stamp $firma output ${paginaMarcada}.pdf
        rm ${paginaOrigenMarcada}.pdf
        if [ "$var1" != 1 ]
        then
            if [ "$var2" == "$pages" ]
            then
                pdftk A=$documento B=${paginaMarcada}.pdf cat A1-$pi B output $destino
            else
                pdftk A=$documento B=${paginaMarcada}.pdf cat A1-$pi B A$pf-end output $destino
            fi
        else
            if [ "$var2" == "$pages" ]
            then
                pdftk A=$documento B=${paginaMarcada}.pdf cat B output $destino
            else
                pdftk A=$documento B=${paginaMarcada}.pdf cat B A$pf-end output $destino
            fi
        fi
    fi  
#Si el parámetro de las hojas a firmar tiene ,
elif [[ $hoja_firmada =~ "," ]]
then
    IFS=',' read -r -a paginas <<< "$hoja_firmada"
    pages_mas=`expr $pages + 1`
    directorioRecurso="/tmp/recurso_${marca}"
    mkdir $directorioRecurso
    contador=1
    contador_array=0
    while [ $contador -lt $pages_mas ]
    do
        numero=`printf "%02d" $contador`
        pdftk A=$documento cat A$contador-$contador output ${paginaOrigenMarcada}_${numero}.pdf
        if [ "${paginas[contador_array]}" == $contador ]
        then
                pdftk $firma stamp ${paginaOrigenMarcada}_${numero}.pdf output ${paginaOrigenMarcada}_${numero}_firmada.pdf
                mv ${paginaOrigenMarcada}_${numero}_firmada.pdf $directorioRecurso
                rm ${paginaOrigenMarcada}_${numero}.pdf
                let contador_array=contador_array+1
                let contador=contador+1
        else
                mv ${paginaOrigenMarcada}_${numero}.pdf $directorioRecurso
                let contador=contador+1
        fi
        echo $numero
    done
    cd $directorioRecurso
    pdftk *.pdf cat output $destino
    cd ..
    rm -f $directorioRecurso
#Si el parámetro de hojas es un solo número   
else
    if [[ ( $hoja_firmada -gt $pages ) || ( $hoja_firmada -lt 1 )]]
    then
        echo "ERROR 12: La página que desea firmar del PDF no es válida."
        exit 1
    else
        #Saca la hoja del archivo origen y la junta con la firma     
        pdftk A=$documento cat A$hoja_firmada-$hoja_firmada output ${paginaOrigenMarcada}.pdf
        pdftk $firma background ${paginaOrigenMarcada}.pdf output ${paginaMarcada}.pdf
        #rm /tmp/pag2.pdf
        if [ "$pages" -gt 2 ]
        then
            if [ "$hoja_firmada" == 1 ]
            then
                pdftk A=$documento B=${paginaMarcada}.pdf cat B A2-end output $destino
            elif [ "$hoja_firmada" == 2 ]
            then
                pdftk A=$documento B=${paginaMarcada}.pdf cat A1-1 B A3-end output $destino
            else
                var=`expr $hoja_firmada + 1`
                var2=`expr $hoja_firmada - 1`
                if [ "$hoja_firmada" == "$pages" ]
                then                    
                    pdftk A=$documento B=${paginaMarcada}.pdf cat A1-$var2 B output $destino
                elif [ "$hoja_firmada" -lt "$pages" ]
                then
                    pdftk A=$documento B=${paginaMarcada}.pdf cat A1-$var2 B A$var-end output $destino
                fi
            fi
        elif [ "$pages" == 2 ]
        then
            if [ "$hoja_firmada" == 1 ]
            then
                pdftk A=$documento B=${paginaMarcada}.pdf cat B A2-2 output $destino
            else
                pdftk A=$documento B=${paginaMarcada}.pdf cat A1-1 B output $destino
            fi
        else
        pdftk B=${paginaMarcada}.pdf cat B output $destino
        fi
    fi
fi
rm -f $firma  ${paginaMarcada}.pdf ${paginaOrigenMarcada}.pdf #$html_firma