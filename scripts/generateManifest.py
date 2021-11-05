import os
import sys
import pandas as pd

regString=sys.argv[1]
sampleTrackerFilePath=sys.argv[2]
outputManifestPath=sys.argv[3]

df = pd.read_excel(sampleTrackerFilePath, engine='openpyxl')
df3=df[df.iloc[:,0].str.contains(regString)==True]
df3.to_csv(outputManifestPath, sep='\t', index=False)
