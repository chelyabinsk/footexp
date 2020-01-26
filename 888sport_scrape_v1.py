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


while(True):
    now = datetime.now() # current date and time
    # Download events JSON
    try:
        r = req.get(all_events_uri,headers=header)
    except:
        print("Too many events requests")
        time.sleep(20)
        continue
    
    if(r.status_code == 200):
        json = r.json()
             
        # Extract live event ids
        events = json["events"]
        
        c = 0
        for entry in events:
            event = entry["event"]
            
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
                if(bet["criterion"]["lifetime"] == "FULL_TIME"):
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
                live_data = entry["liveData"]
                scores = live_data["score"]
                live_clock = live_data["matchClock"]
                
                event_home_score = scores["home"]
                event_away_score = scores["away"]
                event_time = live_clock["minute"]
            else:
                event_home_score = ""
                event_away_score = ""
                event_time = ""

            print("{}:{},{}-{},{},{}".format(c,len(events),event_home_score,event_away_score,event_time,event_name))
            c += 1

            # Find general winning odds for currently active games            
            #print("{},{}".format(event_id,event_name))
            try:
                if(event_state == "STARTED"):
                    bets_r = req.get(bets_uri.format(event_id))
                else:
                    print("Waiting 1 minute")
                    time.sleep(60)
                    break
            except:
                print("Too many bets requests")
                time.sleep(20)
                break
                
            
            if(bets_r.status_code == 200):
                # Extract exact score odds
                bets_json = bets_r.json()
                
                betoffers_json = bets_json["betOffers"]
                
                for bet in betoffers_json:
                    bet_criterion = bet["criterion"]
                    
                    if(bet_criterion["label"] != "Correct Score"):
                        continue
                    else:
                        # Grab outcomes
                        outcomes = bet["outcomes"]
                        
                        # Initialise dictionary of outcomes
                        odds_outcome = {}
                        for i in range(20):
                            for j in range(20):
                                odds_outcome["{}-{}".format(i,j)] = ""
                                
                        for outcome in outcomes:
                            outcome_label = outcome["label"]
                            outcome_fraction = outcome["oddsFractional"]
                            odds_outcome[outcome_label] = outcome_fraction
           
                        # Create output line. Lazy solution
                        output_line = list(odds_outcome.values())
                        output_line.insert(0,event_time)
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
                        output_line.insert(0,now.strftime("%Y-%m-%dT%H:%M:%SZ"))
                        output_line.insert(0,event_id)
                        
                        # Check if outputfile exists
                        if not os.path.isfile('odds.csv'):
                            top_line = list(odds_outcome)
                            top_line.insert(0,"event_time")
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
                            
                            with open("odds.csv","w",newline='') as f:
                                wr = csv.writer(f)
                                wr.writerow(top_line)
            
                        with open("odds.csv","a",newline='') as f:
                                #wr = csv.writer(f)
                                #wr.writerow(output_line)
                                f.write(
                                        str(output_line).replace("[","").replace("]","").replace("'","").replace(" ","") + "\n"
                                        )
                            #print(output_line)
                        
            else:
                print("Failed to download bets JSON")
            #time.sleep(1)
    else:
        print("Failed to download events JSON")