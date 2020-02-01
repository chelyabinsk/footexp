# -*- coding: utf-8 -*-
"""
Script to identify matches that fit the BP model

Assuming that the scraper script is already running
"""

import csv
from datetime import datetime
import os
import time


# Open model file
with open('bp_model.csv', 'r') as f:
    reader = csv.reader(f)
    model = list(reader)[1:]
    
    
now = datetime.now() # current date and time
FMT = "%Y-%m-%dT%H:%M:%SZ"
current_time = now.strftime(FMT)

path = "/home/pirate/Documents/GITHUB/footexp/BP Model 1"

while(True):
    
    # Open the odds file
    with open(path+'/odds.csv', 'r') as f:
        reader = csv.reader(f)
        odds = list(reader)
        
        
    with open(path+'/odds.csv','r') as file_in:
        with open(path+"/tmp.csv","w") as tmp_file:
            c = 1
            trends_hist = {}
            active_ids = [] # List of ids of the active matches
            for line_ in file_in:
                line = line_.split(",")
                if(c>1):
                    # Convert strings into numbers
                    event_id = eval(line[0])
                    if(line[11] == "" or line[11]=="\n"):
                        event_time = 0
                    else:
                        event_time = eval(line[11])
                    if(line[4]==""):
                        home_odds = 0
                    elif(line[4] == "Evens"):
                        home_odds = 1
                    else:
                        home_odds =eval(line[4])
                    if(line[5]==""):
                        draw_odds = 0
                    elif(line[5] == "Evens"):
                        draw_odds = 1
                    else:
                        draw_odds = eval(line[5])
                    if(line[6]==""):
                        away_odds = 0
                    elif(line[6] == "Evens"):
                        away_odds = 1
                    else:
                        away_odds = eval(line[6])
                    
                    #print("{} {} {}".format(event_id,event_time,draw_odds))
                    
                    # Check if a  new entry
                    event_scrapetimestamp = line[1]
                    tdelta = datetime.strptime(current_time, FMT) - datetime.strptime(event_scrapetimestamp, FMT) 
                            
                    
                    # Only keep data from the last 60 minutes
                    if(tdelta.total_seconds()/60 < 60):
                        #tmp_file.write("""{},{},{},{},{},{}\n
                        #                """.format(event_id,current_time,event_starttimestamp,event_state,outcome_home,outcome_draw,outcome_away,outcome_unexpectedOddsTrend,outcome_startingOdds,event_home_score,event_away_score,event_time)
                        #tmp_file.write(line_)
                        tmp_file.write("{},{},{},{},{},{},{},{},{},{},{},{}\n".format(
                            line[0],line[1],line[2],line[3],round(home_odds,4),
                            round(draw_odds,4),round(away_odds,4),
                            line[7],line[8],line[9],line[10],line[11]
                            )
                                       )
                else:
                    tmp_file.write("event_id,current_time,event_starttimestamp,event_state,outcome_home,outcome_draw,outcome_away,outcome_unexpectedOddsTrend,outcome_startingOdds,event_home_score,event_away_score,event_time\n")
                c += 1
    # Remove file
    #os.remove("odds.csv")
    # Rename the file
    #os.rename("tmp.csv","odds.csv")
    
    #time.sleep(10)

    # Open dataframe
    import pandas as pd
    data = pd.read_csv("tmp.csv") 
# Preview the first 5 lines of the loaded data 
    data.head()
    data_ = data.sort_values(by=['event_id','event_id'])
    
    break
