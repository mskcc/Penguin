import os
import sys

sampleID=sys.argv[1]
#sampleID="P-0060192-T01-IM7"

ID=sampleID.split('-')

ID[2]='N01'

ID_N='-'.join(ID)

print(ID_N)
