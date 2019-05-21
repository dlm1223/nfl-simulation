# provide a strategyDF to run a strategy (i.e. percent run/pass/punt/FG) different than the observed strategy in the stateDF data:

# splits pass-attempts into long and short attempts
#sacks attributed to long vs short throws based on number of long/short throws in given state


library(data.table)
library(reshape2)
library(lubridate) 
library(plyr)
library(dplyr)
library(ggplot2)
# library(dd) 
# library(beeswarm)  
# library(gganimate) 
# library(ggridges)
options(scipen = 99)
options(stringsAsFactors = F)


#download files from github
scrapr.download<-function(year){
  print(year)
  file.read <- paste0("https://raw.githubusercontent.com/ryurko/nflscrapR-data/master/play_by_play_data/regular_season/reg_pbp_",year,".csv")
  df.scrapr.temp <- suppressMessages(fread(file.read))
  write.csv(df.scrapr.temp, file=paste0("Data/reg_pbp_",year,".csv"), row.names=F)
}
# lapply(2011:2018, scrapr.download) #uncomment this to download data--run oncee


#read files from local folder, only use some of the columns
scrapr.read <- function(year){
  print(year)
  file.read <- paste0("Data/reg_pbp_",year,".csv")
  df.scrapr.temp <- fread(file.read)
  
  df.scrapr.1 <- df.scrapr.temp%>%
    data.frame() %>% 
    select(home_team, game_date, play_id, game_id, drive, desc,qtr, half_seconds_remaining, game_seconds_remaining, 
           down, ydstogo, yardline_100, play_type, yards_gained,
           #play outcomes
           fourth_down_failed, interception,touchdown, pass_touchdown, rush_touchdown, 
           penalty, penalty_yards,penalty_team, penalty_type,
           fumbled_1_team, fumble_recovery_1_team,
           pass_attempt, rush_attempt, field_goal_attempt, punt_attempt,
           
           # pass_attempt, rush_attempt, 
           posteam,posteam_score, defteam_score, posteam_score_post,defteam_score_post,score_differential,score_differential_post,
           
           #other stats
           air_yards, ep,  epa) 
  return(df.scrapr.1)
}

#run once:
# scrapr.plays <- rbindlist(lapply(2011:2018, scrapr.read))
# write_csv(scrapr.plays,"Data/scrapr_plays.csv")


##FILTER/CLEAN DATA######
scrapr.plays<-fread("Data/scrapr_plays.csv")

#use plays run in one possession games, outside of the last two minutes of each half, and not including OT (teams change in OT ex: kick on 2nd down)
# also drop two-point conversions and extra points
# table(scrapr.plays$penalty_type[scrapr.plays$play_type=="no_play"& !grepl("No Play", scrapr.plays$desc)])
# scrapr.plays[scrapr.plays$penalty_type=="Defensive Holding", 1:20]


# duplicated plays:
scrapr.plays<-scrapr.plays[!(scrapr.plays$game_id=="2017101509"& scrapr.plays$play_id==837)&
                             !(scrapr.plays$game_id=="2017112302"& scrapr.plays$play_id==3763), ]

#plays that were challenged and reversed have 2 plays in description. just keep the reversed part of the play
scrapr.plays$desc[grepl("REVERSED", scrapr.plays$desc)]<-sapply(strsplit(scrapr.plays$desc[grepl("REVERSED", scrapr.plays$desc)], "REVERSED"), `[[`, 2)

df.scrimmage<-scrapr.plays %>%
  filter(play_type %in% c("field_goal", "pass", "run", "punt"),!(half_seconds_remaining < 60*2),qtr<=4, !(qtr==4& half_seconds_remaining<60*5) ) %>% 
  mutate(is.two.point = grepl("TWO-POINT CONVERSION", desc), 
         is.fumble = !is.na(fumble_recovery_1_team), 
         is.punt=(play_type=='punt'),
         is.fg=(play_type=='field_goal'),
         is.sack = grepl("sacked", desc), 
         is.safety=grepl("SAFETY", desc)& !is.punt& !is.fg, #as stated before, 
         is.turnover = (interception)| (is.fumble & fumble_recovery_1_team!=posteam& fumbled_1_team==posteam) , 
         is.td.offense = rush_touchdown|pass_touchdown, 
         is.turnover.downs=as.logical(fourth_down_failed)& !is.turnover& !is.safety& !is.punt,
         yfog = 100 - yardline_100) %>% 
  filter(abs(score_differential) <= 8, !is.two.point, 
         !is.na(yards_gained))%>% #2 games in 2013 has missing data
  data.table()


#6 absorbing states: fg, punt, turnover, offenseTD, safety, turnover.on.downs
df.scrimmage <- df.scrimmage[, `:=`(end.drive=c(rep(F, length(game_date)-1), T), 
                                    start.drive=c(T, rep(F, length(game_date)-1))
), by=c( "drive","game_id")]

colMeans(df.scrimmage[df.scrimmage$end.drive==T& df.scrimmage$qtr%in% c(1,3), c("is.punt", "is.fg", "is.turnover", "is.td.offense", "is.safety", "is.turnover.downs")])
colMeans(df.scrimmage[df.scrimmage$end.drive==F& df.scrimmage$qtr%in% c(1:4), c("is.punt", "is.fg", "is.turnover", "is.td.offense", "is.safety", "is.turnover.downs")])

#these should all come out to 1, but errors with penalties are occuring on~.8% of drives
table(rowSums(df.scrimmage[df.scrimmage$end.drive==T& df.scrimmage$qtr%in% c(1,3), c("is.punt", "is.fg", "is.turnover", "is.td.offense", "is.safety", "is.turnover.downs")]))

#how do drives end? .7% drives are getting lose due to penalty-coding errors i.e. last play is being coded as no_play
colMeans(df.scrimmage[df.scrimmage$end.drive==T& df.scrimmage$qtr%in% c(1,3), c("is.punt", "is.fg", "is.turnover", "is.td.offense", "is.safety", "is.turnover.downs")])

#drives that didn't have an "absorbing state", need to fix coding for plays with penalties which I will do
df.scrimmage[df.scrimmage$end.drive==T & df.scrimmage$qtr%in% c(1,3)&rowSums(df.scrimmage[, c("is.punt", "is.fg", "is.turnover", "is.td.offense", "is.safety", "is.turnover.downs")])==0,c("game_id", "drive") ]

df.scrimmage<-data.frame(df.scrimmage)

#clean data 
#impute air_yards
df.scrimmage$air_yards[which(is.na(df.scrimmage$air_yards)& grepl("deep", df.scrimmage$desc)& df.scrimmage$play_type=='pass')]<-15
df.scrimmage$air_yards[which(is.na(df.scrimmage$air_yards)& grepl("short", df.scrimmage$desc)& df.scrimmage$play_type=='pass')]<-7

#punt return safety..not bothering with this right now..just treating it as punt
df.scrimmage$is.safety[df.scrimmage$desc=='(:59) (Punt formation) L.Cooke punts 47 yards to TEN 7, Center-M.Overton. C.Batson MUFFS catch, touched at TEN 7, and recovers at TEN 1. C.Batson tackled in End Zone for -1 yards, SAFETY (L.Jacobs).']<-F

#define game states by binning data
df.scrimmage$ydstogo.bin<-cut(df.scrimmage$ydstogo, breaks=c(0, 2, 6,9 ,11, 100), include.lowest = F, 
                              labels = c("1-2", "3-6", "7-9", "10-11", "12+"))
df.scrimmage$yfog.bin<-cut(df.scrimmage$yfog, c(seq(0, 95, 5), 97.5, 100), include.lowest = T)

#stateDF 
stateDF<-expand.grid(down=1:4, ydstogo.bin=unique(df.scrimmage$ydstogo.bin), yfog.bin=unique(df.scrimmage$yfog.bin), stringsAsFactors = F)
stateDF$State.ID<-1:nrow(stateDF)


#merge stateDF to df.scrimmage to look at play-stats based on game-state
df.scrimmage<-merge(df.scrimmage[, !colnames(df.scrimmage)%in% "State.ID"], stateDF, by=c("down","ydstogo.bin","yfog.bin" ), sort=F)
freqs<-data.table(df.scrimmage)[,list(freq=length(play_type),
                                      percent.pass=mean(play_type=="pass", na.rm=T), 
                                      percent.run=mean(play_type=="run", na.rm=T), 
                                      percent.punt=mean(play_type=="punt", na.rm=T), 
                                      percent.field_goal=mean(play_type=="field_goal", na.rm=T) 
) ,by="State.ID"]

stateDF<-merge(stateDF, freqs,by="State.ID", sort = F, all.x=T )
head(stateDF[which(stateDF$freq>=100& stateDF$down==3& stateDF$ydstogo.bin=="1-2"),], 50)
stateDF[is.na(stateDF)]<-0
stateDF<-stateDF[!stateDF$freq==0,]

table(stateDF$freq>=100) # a lot of the game states dont happen that frequently, like 1st and "1-3" from midfield
length(unique(df.scrimmage$game_id))

table(df.scrimmage$play_type, df.scrimmage$down)


###SIMULATE DRIVES FUNCTION#######

#function to get state given current down, field positiion
getState<-function(stateDF=stateDF,down, yards.to.go, yards.from.own.goal){
  
  stateDF$State.ID[stateDF$down==down&
                     stateDF$ydstogo.bin== cut(yards.to.go, breaks=c(0, 2, 6,9 ,11, 100), include.lowest = F, 
                                               labels = c("1-2", "3-6", "7-9", "10-11", "12+")) & 
                     stateDF$yfog.bin== cut(yards.from.own.goal, breaks=c(seq(0, 95, 5), 97.5, 100), include.lowest = T) ]
  
  
}


#provide data and parameters to sample.play function 
sample.play <- function(df.scrimmage=df.scrimmage, stateDF=stateDF, down, yards.to.go, yards.from.own.goal,
                        strategyDF=data.frame()) {
  #down<-2;yards.to.go<-3;yards.from.own.goal<-55;play_type<-c() ;#can uncomment to do a test case
  
  
  down.original <- down
  
  #get stateID of current game.state
  stateID<-getState(stateDF=stateDF,down=down, yards.to.go = yards.to.go, yards.from.own.goal = yards.from.own.goal)
  
  #stateDF$freq should be the same nrow(data.RP)
  stateDF[stateDF$State.ID==stateID,]
  data.RP<-df.scrimmage[df.scrimmage$State.ID==stateID,]
  

  #below samples according to strategyDF than stateDF
  #ex stateDF for state-1 : pass 30%, rush 30%, punt 40% (observed percentages)
  # strategyDF for state-1 : pass=40, rush=20%, punt=30% (desired percentages)
  if(nrow(strategyDF)>0){
    strategy<-strategyDF[strategyDF$State.ID==stateID,]
    strategy
    
    #set sample.weights so that i will pick plays according to my strategyDF, divide by n.play.type makes it so that sampling will coordinate w. strategy
    data.RP$sample.prob[data.RP$play_type=="pass"]<-strategy$percent.pass/sum(data.RP$play_type=="pass")
    data.RP$sample.prob[data.RP$play_type=="run"]<-strategy$percent.run/sum(data.RP$play_type=="run")
    data.RP$sample.prob[data.RP$play_type=="punt"]<-strategy$percent.punt/sum(data.RP$play_type=="punt")
    data.RP$sample.prob[data.RP$play_type=="field_goal"]<-strategy$percent.field_goal/sum(data.RP$play_type=="field_goal")
    sum(data.RP$sample.prob) #should sum to 1
    
    sim.RP <- sample_n(data.RP, 1, weight = data.RP$sample.prob)
    
    #can check here that proportions line up with strategy: 
    #prop.table(table(data.RP$play_type))  #actual data
    # prop.table(table(sample_n(data.RP, 10000, weight = data.RP$sample.prob, replace = T)$play_type)) #weighted-sample
    
  } else{
    
    #sample a play from filtered data
    sim.RP <- sample_n(data.RP, 1)
    
  }
  
  yards_gained <- sim.RP$yards_gained
  new.yfog <- yards.from.own.goal + yards_gained
  
  #add play result
  new.down <- ifelse(yards_gained >= yards.to.go, 1, down.original + 1)
  new.distance <- ifelse(yards_gained >= yards.to.go & new.yfog <= 90, 10, 
                         ifelse(yards_gained >= yards.to.go & new.yfog > 90, 100-new.yfog, 
                                yards.to.go - yards_gained))
  if (new.distance <= 0){new.distance <- 1} 
  if (new.yfog >= 100){new.yfog <- 99}
  if (new.yfog < 1){new.yfog <- 1}
  
  keep.drive <- data.frame(down.original, yards.to.go, yards.from.own.goal, 
                           yards_gained, new.yfog, new.down, new.distance, 
                           
                           #store play-result-stats
                           is.safety=sim.RP$is.safety,
                           is.turnover = sim.RP$is.turnover, 
                           is.td.offense = sim.RP$is.td.offense, 
                           is.turnover.downs=(new.down > 4)& !sim.RP$is.turnover & !sim.RP$is.safety & !sim.RP$is.td.offense & !sim.RP$play_type%in% c("field_goal", "punt"),
                           is.punt=sim.RP$is.punt,
                           is.fg=sim.RP$is.fg,
                           
                           is.sack=sim.RP$is.sack, 
                           desc = sim.RP$desc,
                           air_yards=sim.RP$air_yards,
                           epa=sim.RP$epa,
                           ep=sim.RP$ep,
                           play_type=sim.RP$play_type,
                           State.ID=sim.RP$State.ID,
                           
                           #how can a drive end:
                           end.drive = new.down > 4 | sim.RP$is.turnover| sim.RP$is.safety | sim.RP$is.td.offense | sim.RP$play_type%in% c("field_goal", "punt"))
  return(keep.drive)
}  


####SPECIFY STRATEGY#####

#ex: "increase.percent=.1, increase.var=percent.run" means increase runs by 10%, and will decrease the rest of the actions in given state proportionally
adjust.row<-function(strategy,  increase.percent,increase.var){
  #strategy<-stateDF[1:3,]
  
  #i'm not adjusting if increase.var has low frequency ex: 4th and 20 I'm not going to increase percent.run
  bool<-strategy[, increase.var]>.02
  
  #decrease non-increase.var cols proportionally  
  cols<-setdiff(colnames(strategy[bool, grepl("percent", colnames(strategy))]), increase.var)
  strategy[bool, cols]<- strategy[bool, cols]-increase.percent* strategy[bool, cols]/(1-strategy[bool, increase.var])
  
  #increase.var just gets +increase.percent
  strategy[bool, increase.var]<-strategy[bool, increase.var]+increase.percent
  
  strategy[, grepl("percent", colnames(strategy))][strategy[, grepl("percent", colnames(strategy))]>1]<-1
  strategy[, grepl("percent", colnames(strategy))][strategy[, grepl("percent", colnames(strategy))]<0]<-0
  strategy
}



