# -*- coding: utf-8 -*-
"""
Script to identify matches that fit the BP model

Assuming that the scraper script is already running
"""

import csv
from datetime import datetime
import os
import time
import pandas as pd

# Open model file
model = pd.read_csv("bp_model.csv") 
    
    
now = datetime.now() # current date and time
FMT = "%Y-%m-%dT%H:%M:%SZ"


#path = "/home/pirate/Documents/GITHUB/footexp/BP Model 1"
path = "H:/betting/footexp/BP Model 1"

while(True):
    now = datetime.now() # current date and time
    current_time = now.strftime(FMT)
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
                        tmp_file.write("{},{},{},{},{},{},{},{},{},{},{},{}".format(
                            line[0],line[1],line[2],line[3],home_odds,
                            draw_odds,away_odds,
                            line[7],line[8],line[9],line[10],line[11]
                            )
                                       )
                else:
                    tmp_file.write("event_id,current_time,event_starttimestamp,event_state,outcome_home,outcome_draw,outcome_away,outcome_unexpectedOddsTrend,outcome_startingOdds,event_home_score,event_away_score,event_time\n")
                c += 1
                
    #time.sleep(10)

    # Open dataframe
    data = pd.read_csv("tmp.csv") 
    
    # Excract individual ids
    unique_ids = data.event_id.unique()
    
    for uid in unique_ids:
        tmp_dat = data[data.event_id == uid]#.event_time.max()
        last_time = tmp_dat.event_time.max()
        # Don't bother looking at matches after the 70th minute
        if(last_time > 70):
            continue
        else:
            # Check if this match fits the desired trend
            is_valid = True
            times = list(tmp_dat["event_time"])
            draw_odds = list(tmp_dat["outcome_draw"])
            i=1
            for i in range(1,tmp_dat.event_id.count()):
                row_time = times[i]
                if(row_time == 0):
                    continue
                #print(row_time,draw_odds[i],model[model.t == row_time].l_25)
                if(draw_odds[i]<=model[model.t == row_time].l_25.values and
                   draw_odds[i]>=model[model.t == row_time].l_75.values*0.9 and
                   is_valid == True
                   ):
                    pass  # All is good so far
                    #print(row_time,draw_odds[i],1)
                else:
                    is_valid = False
                    #print(row_time,draw_odds[i],0)
                # Check that draw odds didn't jump too high up
                if(i < tmp_dat.event_id.count()-1):
                    if(draw_odds[i+1] - draw_odds[i] > 0.1):
                        is_valid = False
                        #print(draw_odds[i])
        # Check if suitable for bet
        if(is_valid == True and row_time > 45 and draw_odds[i] <= 1.5 and draw_odds[i] > 1):
            with open("results.csv","a") as f:
                f.write("{},{},{},{}\n".format(uid,row_time,draw_odds[i],True in tmp_dat.outcome_unexpectedOddsTrend.values))
                print(uid,row_time,draw_odds[i])
    # Remove file
    #os.remove("odds.csv")
    # Rename the file
    #os.rename("tmp.csv","odds.csv")
    
    time.sleep(1)
    
    