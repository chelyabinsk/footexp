# -*- coding: utf-8 -*-
"""
Hello
"""

import requests as req
from datetime import datetime
import os.path
import csv
import time


# Current events URI
uri = "https://eu-offering.kambicdn.org/offering/v2018/888uk/event/live/open?lang=en_GB&market=UK"
# Current bets offers URI for some event id. can change type of output detail. Type=3 gives home_score - away_score bets
bets_uri = "https://eu-offering.kambicdn.org/offering/v2018/888uk/betoffer/event/{}?lang=en_GB&market=UK&includeParticipants=false&type=3"
"""
OT_ONE - Home wins
OT_X   - Draw
OT_TWO - Away wins
"""

# All football events URI 
all_events_uri = "https://eu-offering.kambicdn.org/offering/v2018/888uk/listView/football.json?lang=en_GB&market=UK&client_id=1&channel_id=1"

# Spoof headers
header = {
"Host": "eu-offering.kambicdn.org",
"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:60.0) Gecko/20100101 Firefox/60.0",
"Accept": "application/json, text/plain, */*",
"Accept-Language": "en-GB,en;q=0.5",
"Accept-Encoding": "gzip, deflate, br",
"Referer": "https://www.888sport.com",
"Origin": "https://www.888sport.com",
"Connection": "keep-alive"
}

wait_time = 27
outputfile = "odds.csv"


while(True):
    now = datetime.now() # current date and time
    FMT = "%Y-%m-%dT%H:%M:%SZ"
    current_time = now.strftime(FMT)
    # Download events JSON
    try:
        r = req.get(all_events_uri,headers=header)
    except:
        print("Too many events requests")
        time.sleep(10)
        continue
    
    if(r.status_code == 200):
        try:
            json = r.json()
        except:
            continue
             
        # Extract live event ids
        try:
            events = json["events"]
        except:
            continue
        c = 0
        for entry in events:
            try:
                event = entry["event"]
            except:
                continue
            
            # Sometimes event doesn't have any bet offers
            try:
                bet_list = entry["betOffers"]  
            except:
                bet_list = []
            
            event_id = event["id"]
            event_name = event["name"]
            event_sport = event["sport"]
            event_state = event["state"]
            event_starttimestamp = event["start"]
            outcome_home = ""
            outcome_draw = ""
            outcome_away = ""
            outcome_unexpectedOddsTrend = ""
            outcome_startingOdds = ""

            # Grab odds for score at the full time
            if(bet_list != []):
                bet = bet_list[-1]   # Grab the last entry. I assume that's the latest data [?]
                if(bet["criterion"]["label"] == "Full Time"):
                    if(bet["outcomes"][0]["status"] == "OPEN"):
                        outcome_home = bet["outcomes"][0]["oddsFractional"]
                    if(bet["outcomes"][1]["status"] == "OPEN"):
                        outcome_draw = bet["outcomes"][1]["oddsFractional"]
                    if(bet["outcomes"][2]["status"] == "OPEN"):
                        outcome_away = bet["outcomes"][2]["oddsFractional"]
                    try:
                        outcome_unexpectedOddsTrend = bet["oddsStats"]["unexpectedOddsTrend"]
                        outcome_startingOdds = bet["oddsStats"]["startingOddsFractional"]
                    except:
                        pass                 

                 
            # If event is live, grab score, and time
            if(event_state == "STARTED"):
                try:
                    live_data = entry["liveData"]
                    scores = live_data["score"]
                    live_clock = live_data["matchClock"]
                except:
                    continue
                    #scores = ""
                    #live_clock = ""
                    
                try:
                    event_home_score = scores["home"]
                    event_away_score = scores["away"]
                    event_time = live_clock["minute"]
                except:
                    event_home_score = ""
                    event_away_score = ""
                    event_time = ""            
            else:
                event_home_score = ""
                event_away_score = ""
                event_time = ""
            
            # Only write to file events that will start in a hour or already started
            tdelta = datetime.strptime(event_starttimestamp, FMT) - datetime.strptime(current_time, FMT)
                
            if(event_state == "STARTED"):                                  
                #print("{} --- {} ---- {}".format(current_time,event_starttimestamp,tdelta))
                print("{}|{}-{} ({}) --- {},{},{} --- {}".format(c,event_away_score,event_home_score,event_time,
                      outcome_away,outcome_draw,outcome_home,
                      event_name
                                                            ))
                c += 1
                output_line = [event_time]
                output_line.insert(0,event_away_score)
                output_line.insert(0,event_home_score)
                
                output_line.insert(0,outcome_startingOdds)
                output_line.insert(0,outcome_unexpectedOddsTrend)
                
                output_line.insert(0,outcome_away)
                output_line.insert(0,outcome_draw)
                output_line.insert(0,outcome_home)
                
                output_line.insert(0,event_state)
                #output_line.insert(0,event_name)
                output_line.insert(0,event_starttimestamp)
                output_line.insert(0,current_time)
                output_line.insert(0,event_id)
                
                # Check if outputfile exists
                if not os.path.isfile('odds.csv'):
                    top_line = ["event_time"]
                    top_line.insert(0,"event_away_score")
                    top_line.insert(0,"event_home_score")
                
                
                    top_line.insert(0,"outcome_startingOdds")
                    top_line.insert(0,"outcome_unexpectedOddsTrend")
                
                    top_line.insert(0,"outcome_away")
                    top_line.insert(0,"outcome_draw")
                    top_line.insert(0,"outcome_home")
                
                    top_line.insert(0,"event_state")
                    #top_line.insert(0,"event_name")
                    top_line.insert(0,"event_starttimestamp")
                    top_line.insert(0,"current_time")
                    top_line.insert(0,"event_id")
                    
                    with open(outputfile,"w",newline='') as f:
                        wr = csv.writer(f)
                        wr.writerow(top_line)
                
                with open(outputfile,"a",newline='') as f:
                        #wr = csv.writer(f)
                        #wr.writerow(output_line)
                        f.write(
                                str(output_line).replace("[","").replace("]","").replace("'","").replace(" ","") + "\n"
                                )
                    #print(output_line)

    else:                
        print("Failed to download events JSON")

    print("Wait {} seconds. {}".format(wait_time,current_time))
    time.sleep(wait_time)
   
