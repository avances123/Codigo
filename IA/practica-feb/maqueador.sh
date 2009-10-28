#!/bin/bash
clp=ontologia.clp
pont=ontologia.pont
pins=ontologia.pins
cat $pont > $clp
for i in $(seq 1 6);do echo "" >> $clp;done
echo ";+  INSTANCIAS DE LA ONTOLOGIA" >> $clp
echo "(definstances INSTANCIAS" >> $clp
cat $pins | sed 's/^/\t/'  >> $clp
echo ")"  >> $clp
