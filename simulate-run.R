#specify strategy here, then run sim


source("simulate-functions.R")


#example:
stateDF[1:2,]
adjust.row(strategy = stateDF[1:2, ], increase.percent = .1, increase.var = "percent.pass")
adjust.row(strategy = stateDF[1:2, ], increase.percent = .2, increase.var = "percent.run")

#specify strategy:
strategyDF<-stateDF
# strategyDF[strategyDF$down%in% 1:2,]<-
  # adjust.row(strategyDF[strategyDF$down%in%1:2, ], increase.percent = .1, increase.var = "percent.pass")

#check strategy:
head(strategyDF)
head(stateDF)


####RUN SIMULATIONS#####

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
                            yards.from.own.goal = new.yfog 
                            , strategyDF = strategyDF
                            
    ) #can specify play_type here
    run.play$play.num <- play.num
    drive.store[[play.num]] <- run.play #add each play
    new.down <- run.play$new.down
    new.distance <- run.play$new.distance
    new.yfog <- run.play$new.yfog
    end.of.drive <- run.play$end.drive
    play.num <- play.num + 1
    drive.store[1:play.num]
  }
  drive.store<-rbindlist(drive.store)
  drive.store$sim.id <- i
  drive.store
  
  if (i %% 100 == 0){print(i)}
  all.drives.store[[i]] <- drive.store
}

#combine and save
all.drives.store<-rbindlist(all.drives.store)

write.csv(all.drives.store, file="Data/alldrives.csv", row.names = F)


# table(all.drives.store$play_type, all.drives.store$down)
# table(all.drives.store$play_type, all.drives.store$down)
# table(df.scrimmage$is.td.offense)
