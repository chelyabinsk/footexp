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

while(True):
    
    # Open the odds file
    with open('H:\\betting\\footexp\\BP Model 1\\odds.csv', 'r') as f:
        reader = csv.reader(f)
        odds = list(reader)
        
        
    with open('H:\\betting\\footexp\\BP Model 1\\odds.csv','r') as file_in:
        with open("H:\\betting\\footexp\\BP Model 1\\tmp.csv","w") as tmp_file:
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
                    #print(line[1],round(tdelta.total_seconds()/60))
                    #print(line[1])
                    if(tdelta.total_seconds()/60 < 2):
                        if(active_ids == []):
                            active_ids.append([event_id,event_time])
                        elif(not [event_id,event_time] in active_ids):
                            active_ids.append([event_id,event_time])
                            
                    # See if current odds fit the model
                    if(event_time <= 93):
                        if((draw_odds <= eval(model[event_time][3]) and draw_odds >= eval(model[event_time][2])) or
                           (home_odds <= eval(model[event_time][3]) and home_odds >= eval(model[event_time][2])) or
                           (away_odds <= eval(model[event_time][3]) and away_odds >= eval(model[event_time][2]))
                           ):
                            try:
                                #print(event_id,c)
                                trends_hist[event_id].append(event_time)
                            except KeyError:
                                trends_hist[event_id] = [event_time]
                                #print(trends_hist)
                    
                    if(tdelta.total_seconds()/60 < 60):
                        tmp_file.write(line_)
                else:
                    tmp_file.write("event_id,current_time,event_starttimestamp,event_state,outcome_home,outcome_draw,outcome_away,outcome_unexpectedOddsTrend,outcome_startingOdds,event_home_score,event_away_score,event_time\n")
                c += 1
    #print(trends_hist)
    #print(active_ids)
    
    uniq_ids = []

    for act_id in active_ids:
        try:
            if(act_id[1] < 55 and act_id[1] > -1):
                keys = list(dict.fromkeys(trends_hist[act_id[0]]))
                keys.sort()
                if(act_id[1] <= max(keys)):
                    if(not act_id[0] in uniq_ids):
                        uniq_ids.append(act_id[0])
                    #print(act_id[0],keys,act_id[1])           
        except:
            pass
    print(uniq_ids)
    # Remove file
    os.remove("odds.csv")
    # Rename the file
    os.rename("tmp.csv","odds.csv")
    
    time.sleep(10)            
    #break