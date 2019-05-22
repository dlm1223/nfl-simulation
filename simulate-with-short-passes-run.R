
#source to prepare data, then here can adjust file

####SPECIFY STRATEGY#####

source("simulate-with-short-passes-functions.R")


sack.param<-2

#assume sack rate on long throws=twice that of short throws
if("percent.sack"%in% colnames(stateDF)){
  total<-(stateDF$percent.short.pass+sack.param*stateDF$percent.long.pass)
  stateDF$percent.short.pass<-stateDF$percent.short.pass+stateDF$percent.sack*stateDF$percent.short.pass/total
  stateDF$percent.long.pass<-stateDF$percent.long.pass+stateDF$percent.sack*sack.param*stateDF$percent.long.pass/total
  head(stateDF, 10)
  stateDF$percent.sack<-NULL
  stateDF[is.na(stateDF)]<-0
}

#example:
stateDF[1:5,]

head(stateDF)

summary(rowSums(stateDF[, grepl("percent", colnames(stateDF))&!grepl("sack",colnames(stateDF) )], na.rm=T)) #should be all 1's

stateDF[1:2, ]
adjust.row(strategy = stateDF[1:2, ], increase.percent = .1, increase.var = "percent.long.pass")
adjust.row(strategy = stateDF[1:2, ], increase.percent = .2, increase.var = "percent.short.pass")

#specify strategy, or leave default
strategyDF<-stateDF
# strategyDF[strategyDF$down%in% 1:2,]<-
  # adjust.row(strategyDF[strategyDF$down%in% 1:2, ], increase.percent = .1, increase.var = "percent.short.pass")

#check strategy:
head(strategyDF)
head(stateDF)
table(strategyDF$ydstogo.bin)


####RUN SIMULATION#####

n.sims <- 10000  #how many drives to simulate
all.drives.store <- list();length(all.drives.store)<-n.sims
yfog.start <- 25

for (i in 1:n.sims){
  #i<-i+1
  
  #initialize drive
  drive.store <- list()
  length(drive.store)<-40  #no drive is ever gonna be more than 40 plays
  new.down <- 1
  new.distance <- 10
  new.yfog <- yfog.start
  end.of.drive <- FALSE
  play.num <- 1
  
  #simulate until absorbing state
  while (!end.of.drive){
    run.play <- sample.play(df.scrimmage=df.scrimmage,
                            stateDF=stateDF,
                            down = new.down, 
                            yards.to.go = new.distance, 
                            yards.from.own.goal = new.yfog,
                            strategyDF = strategyDF, 
                            sack.param=sack.param
                            
    ) #can specify play_type here
    run.play$play.num <- play.num
    drive.store[[play.num]] <- run.play #add each play
    new.down <- run.play$new.down
    new.distance <- run.play$new.distance
    new.yfog <- run.play$new.yfog
    end.of.drive <- run.play$end.drive
    play.num <- play.num + 1
    drive.store[1:(play.num-1)]
  }
  drive.store<-rbindlist(drive.store)
  drive.store$sim.id <- i
  drive.store
  
  if (i %% 100 == 0){print(i)}
  all.drives.store[[i]] <- drive.store
}

#combine and save
all.drives.store<-rbindlist(all.drives.store)

write.csv(all.drives.store, file="Data/alldrives_withshortpasses.csv", row.names = F)

