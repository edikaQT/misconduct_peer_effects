###########################################################
#  R CODE TO IDENTIFY WHO CHANGED PEERS IN GIVEN QUARTERS 
#  Lag1 & Lag2
#  Lag1 & Lag3
###########################################################
#
# 280117
# using data from stata:
# 270117 Data for R to see impact of changes in peers and LM v12.dta
###########################################################

library(foreign)
library(zoo)
library(data.table)
library(tidyr)
library(data.table)
library(rlist)

wd_location_STATA_files <- as.character("C:/Users/edika/Desktop/key backup/Crime/Crime old data/Met_data/complaints_and_sickness/stata files/210117 final do and files/2018_output_folder")

setwd(wd_location_STATA_files)


mydata <- read.dta("270117 Data for R to see impact of changes in peers and LM.dta")


head(mydata, 100)
head(mydata)
mydata$timeq2 <- format(mydata$timeq_text, format = "%y%q")
format(mydata$timeq2)

table(mydata$timeq2)


mydata <- as.data.frame(mydata)
mydata <- mydata[c("GUID", "LinemanagerGUIDRef_right", "timeq2")]


# Vector of line managers (LM) and time
#--------------------------------------

unique_LM<- unique(mydata$LinemanagerGUIDRef_right) 
unique_timeq2 <-unique(mydata$timeq2) #  "2011q2" to "2015q1"
# (note that data starts from 2011q2. When we merged the workforce data, misconduct data and performance data, 
# the performance data started from 2011q2 and is available until 2015q1)
head(unique_LM)

# note that we have the first cell in unique_LM empty 

# Creating a list of LM
#----------------------------

unique_LM_list <- as.list(unique_LM)
head(unique_LM_list)

l_time <- function(list, vector) {
  list(list,vector)
}

# Creating a lists of list(LM, timeq) 
#--------------------------------------

unique_LM_list2 <- lapply(unique_LM_list, function(i) {
  l_time(i,unique_timeq2)
} )

head(unique_LM_list2) 


unique_LM_list2v2 <-unique_LM_list2[2:length(unique_LM_list2)]
# We eliminated the LM that was empty
head(unique_LM_list2v2 )

# selecting obs with the same LM and quarter
#---------------------------------------------------
subset2 <- function(value_time, unique_LM, mydata) {
  mydata[ which(mydata$LinemanagerGUIDRef_right==unique_LM 
                & mydata$timeq2 ==value_time), ]
}

subset_LM2 <- function(unique_LM, unique_timeq2, mydata) {
  # imputs are: a LM, a vector of quarters and the data
  lapply(unique_timeq2, function(i) {subset2(value_time=i, 
                                             unique_LM=unique_LM, mydata=mydata)})
}


#_______________________________________________________________________________
#
#
#   Example of the output of the function 'subset_LM2' for the first 20 LM
#
#
#_______________________________________________________________________________
#
#
system.time(unique_LM_list3 <- lapply(unique_LM_list2v2[c(1:20)], function(i) {
 #print(which(match(unique_LM,i[[1]])==1)) #printing the LM (there are about 11077)
  subset_LM2(unique_LM=i[[1]],unique_timeq2= i[[2]], mydata=mydata)
} ))
# imputs are: a LM, a vector of quarters and the data


# reducing the time using 7 cores
library(parallel)

# Calculate the number of cores
no_cores <- detectCores() - 1

# Initiate cluster
cl <- makeCluster(no_cores)
clusterExport(cl, "subset_LM2")
clusterExport(cl, "subset2")
clusterExport(cl, "mydata")
clusterExport(cl, "unique_LM")

system.time(unique_LM_list3_parallel<- parLapply(cl, unique_LM_list2v2[c(1:20)], function(i) {
  #print(which(match(unique_LM,i[[1]])==1)) #printing the LM (there are about 11077)
  subset_LM2(unique_LM=i[[1]],unique_timeq2= i[[2]], mydata=mydata)
} ))

summary(unique_LM_list3)
summary(unique_LM_list3_parallel)

unique_LM_list3[[1]] #the employeeds for the first LM on each of 16 quarters
summary(unique_LM_list3[[3]]) #the employees to the third LM on each of 16 quarters
unique_LM_list3[[3]][[1]] #the employees to the third LM during 2011q2
unique_LM_list3_parallel[[3]][[1]] #the employees to the third LM during 2011q2
#
#_______________________________________________________________________________



system.time(unique_LM_list3<- parLapply(cl, unique_LM_list2v2, function(i) {
  #print(which(match(unique_LM,i[[1]])==1)) #printing the LM 
  subset_LM2(unique_LM=i[[1]],unique_timeq2= i[[2]], mydata=mydata)
} ))


summary(unique_LM_list3)
summary(unique_LM_list3[[3]])
summary(unique_LM_list3[[3]][[1]]) 

summary(unique_LM_list3[[3]][[10]]) 
# there could be cases of LM without employees for some few quarters


# Finding peers: For each employee under a LM in quarter x, list all his peers
#-------------------------------------------------------------------------------
# function 'emp' has as imput a LM containing 16 lists with their employees 
# the output is a list with 16 lists, one for each quarter
# each of these lists has a list of GUIDs (each GUID has a vector with the GUIDS's peers)

emp <- function (employee_time_list) {
  
  GUIDS <- list()
  for (i in 1:length(employee_time_list)) {
    
    #lenght is 16
    GUIDS[[i]] <- list()
    if (length(employee_time_list[[i]]$GUID>0)) {
      for (j in 1:length(employee_time_list[[i]]$GUID)) {
        GUIDS[[i]][[j]] <- list()
        GUIDS[[i]][[j]]$timeq <- employee_time_list[[i]]$timeq2[1]
        GUIDS[[i]][[j]]$GUID  <- employee_time_list[[i]]$GUID[j]
        GUIDS[[i]][[j]]$peer <- employee_time_list[[i]]$GUID[-j]
      }
      
    }
  }
  GUIDS
}




#example of output
unique_LM_list3[[3]][[1]]
summary(unique_LM_list3[[3]][[1]]$GUID) #the third LM has 9 employees in 2011q2
summary ( emp(unique_LM_list3[[3]]) ) #see that the third LM has 9 or more employees in all the 16 quarters
emp(unique_LM_list3[[3]])[[1]] ##see the 9 employees in 2011q2 and his peers


unique_LM_list3[[2]][[8]]
summary ( emp(unique_LM_list3[[2]]) ) #but the second LM has employees on two quarters only, 2013q1 and 2013q2


#
# applying funtion 'emp' to find peers. 
#

unique_LM_list5 <- lapply(unique_LM_list3, function(i) {
  emp(employee_time_list=i)})



(unique_LM_list5[[1]][[1]]) #for first LM, list for first timeq, lis(time, GUID, peers)
(unique_LM_list5[[1]][[2]]) #for first LM, list for second timeq, lis(time, GUID, peers)



list_big <-unique_LM_list5

# Arraging the list, we will create a new list with GUID X quarter elements
# --------------------------------------------------------------------------

n<-unlist(unlist(list_big,recursive = FALSE ), recursive=FALSE)
summary(n)
head(n)
#in n, we have timeq, GUID and GUID's peers (we lost the LM but we only care about the peers)
#in n, we have 609596 GUID X quarter (showing their peers on that quarter). All these peers were arranged from 11076 LM
(mydata[LinemanagerGUIDRef_right!="",.(GUID)])


# Arraging the list, now we will create a list with GUID elements (quarters and peers will be listed inside each GUID)
#--------------------------------------------------------------------
# arranged_n <- list.group(n, GUID) # we could do this process by using 'list.group' but it would take many hours, so we will split the process
# in 609 spets, each time for 1000 elements. However, we will not have one GUID with all the quarters, but many GUID with subset of the quarters.
# So the following lines will correct this problem and place for each GUID a list of quarters and peers. It will give us the same outcome
# we could have obtained using list.group(n, GUID) but in less than an hour

arranged_n <- list()
for (i in 1:609) {
 print( i*1000-999)
 print(i*1000)
  arranged_n[[i]]<- list.group(n[(i*1000-999):(i*1000)], GUID)  
  
}
arranged_n[[610]]<- list.group(n[(610*1000-999):(length(n))], GUID)  


arranged_n2<- unlist(arranged_n,recursive=FALSE) 
guid_with_repetitions<- (as.data.table(summary(arranged_n2)))[V2=="Length"] 
guid_with_repetitions[, order:=seq_along(V1)]
guid_with_repetitions[, id := .GRP, by=V1] #
guid_with_repetitions<-guid_with_repetitions[order(id)] 

mydata<-as.data.table(mydata)
guids_my_data<-unique(mydata[LinemanagerGUIDRef_right!="",.(GUID)]) 

#example of GUID with quarters split:

guid_with_repetitions[,.N, by=.(id)][N>3] 
guid_with_repetitions[id==49458]

#solving the problem of repeated GUIDs. Placing for each GUID a list of quarters and peers

new_list_no_repetitions<-list()

for(id_select in 1:max(guid_with_repetitions$id)) {

select<- guid_with_repetitions[id==id_select, .(order)]$order
summary(select_list<-arranged_n2[select])
summary(select_list)
select_list2<- unlist(select_list,recursive=FALSE) 
summary(select_list2)
names(select_list2) <-  NULL
new_list_no_repetitions[[id_select]]<-select_list2
names(new_list_no_repetitions)[id_select] <-  names(select_list[1])
summary(new_list_no_repetitions)
print(id_select)

}

summary(new_list_no_repetitions) 


#example of output
summary(new_list_no_repetitions[1:10]) 
#Length Class  Mode
#0000e096-3280-4d71-82bf-285154a1bf59  5     -none- list
#00019ed6-4ed3-485f-afb1-be18c270efd3  1     -none- list
#0003066c-1d14-40ea-8bc0-2b0d44059991 13     -none- list
#0004c5e7-05fe-4aa4-bb8d-e494bb42ed47 11     -none- list
#0005a6b2-0a52-421d-b82f-e39a87049840 14     -none- list
#015f8d68-eb20-438f-ada0-795928dd4ef2  5     -none- list
#025f8a8c-46d4-43b1-a293-6288d08048a0 11     -none- list
#05380569-8e1a-44f1-8de7-fa8d12cbebf7  8     -none- list
#08c5c203-3177-4940-be45-0b041481a4da  8     -none- list
#0a68b7bf-b03b-438e-91ad-f03dc54ecba9 15     -none- list

(new_list_no_repetitions[[1]][[1]]) 
#for GUID=0000e096-3280-4d71-82bf-285154a1bf59, we have a list of (1) the quarter (first quarter), (2) the GUID code, (3) the peers


#check the output with the raw data
mydata<-as.data.table(mydata)
mydata[GUID=="0000e096-3280-4d71-82bf-285154a1bf59"]


#counting the number of peers
new_list_no_repetitions2<-lapply(new_list_no_repetitions, function(i) {list.update(i, number_peer=length(peer)) })
head(new_list_no_repetitions2)

new_list_no_repetitions3<-lapply(new_list_no_repetitions2, function(i) {
  lapply(i, function(j) {list(j)})
  
})

#new_list_no_repetition3 has a list of list
summary(new_list_no_repetitions2[[1]])
summary(new_list_no_repetitions3[[1]]) #so each quarter has a list
summary(new_list_no_repetitions3[[1]][[1]])

new_list_no_repetitions3[[1]][[1]]


#function to change the names of the lists with quarters. Now 2012q3 will be renamed as 'y2012q3'
names_l <-function(list_j, list_h){
  
  names(list_j)=sprintf("y%s", list_h$timeq)
  list_j
}





#updating the names
new_list_no_repetitions3_names<- lapply(new_list_no_repetitions3, function(j) {lapply(seq_along(1:length(j))  , function(i) {
  names_l(list_j=j[[i]], list_h=j[[i]][[1]] )}) }  )


summary(new_list_no_repetitions3_names[[15949]]) 
new_list_no_repetitions3_names[[15949]]
new_list_no_repetitions3_names[[15949]][[1]]
        


#function that gets the number of common peers during two given quarters
#-------------------------------------------------------------------------------

common_peer <- function(p1,p2,list_a) {
  a<-unlist(list_a,recursive = FALSE )
  
  all <- list(a[[p1]]$peer,
              a[[p2]]$peer)
  
  common <-list.common(all)
  number_common <-length(common) #vector
  number_period<-length(a[[p1]]$peer)
  list <- list(common=common, number_common=number_common, number_period=number_period)
}

#if we are in 2015q1
#2015q1 lag0
#2014q4 lag1
#2014q3 lag2
#2014q2 lag3


#--------------
#lag1 & lag2
#--------------

summary(results_2015q1)

data_set<-new_list_no_repetitions3_names




results_2015q1<-lapply(data_set, function(i) {common_peer(p1="y2014q4",
                                                     p2="y2014q3",
                                                     list_a=i) })

results_2014q4<-lapply(data_set, function(i) {common_peer(p1="y2014q3",
                                                     p2="y2014q2", 
                                                     list_a=i) })

results_2014q3<-lapply(data_set, function(i) {common_peer(p1="y2014q2",
                                                     p2="y2014q1",
                                                     list_a=i) })

results_2014q2<-lapply(data_set, function(i) {common_peer(p1="y2014q1",
                                                     p2="y2013q4",
                                                     list_a=i) })

results_2014q1<-lapply(data_set, function(i) {common_peer(p1="y2013q4",
                                                     p2="y2013q3",
                                                     list_a=i) })

results_2013q4<-lapply(data_set, function(i) {common_peer(p1="y2013q3",
                                                     p2="y2013q2",
                                                     list_a=i) })

results_2013q3<-lapply(data_set, function(i) {common_peer(p1="y2013q2",
                                                     p2="y2013q1",
                                                     list_a=i) })

results_2013q2<-lapply(data_set, function(i) {common_peer(p1="y2013q1",
                                                     p2="y2012q4",
                                                     list_a=i) })

results_2013q1<-lapply(data_set, function(i) {common_peer(p1="y2012q4",
                                                     p2="y2012q3",
                                                     list_a=i) })

results_2012q4<-lapply(data_set, function(i) {common_peer(p1="y2012q3",
                                                     p2="y2012q2",
                                                     list_a=i) })

results_2012q3<-lapply(data_set, function(i) {common_peer(p1="y2012q2",
                                                     p2="y2012q1",
                                                     list_a=i) })

results_2012q2<-lapply(data_set, function(i) {common_peer(p1="y2012q1",
                                                     p2="y2011q4",
                                                     list_a=i) })

results_2012q1<-lapply(data_set, function(i) {common_peer(p1="y2011q4",
                                                     p2="y2011q3",
                                                     list_a=i) })

results_2011q4<-lapply(data_set, function(i) {common_peer(p1="y2011q3",
                                                     p2="y2011q2",
                                                     list_a=i) })



library(data.table)

results_2015q1v2 <- lapply(results_2015q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q4v2 <- lapply(results_2014q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q3v2 <- lapply(results_2014q3, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q2v2 <- lapply(results_2014q2, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q1v2 <- lapply(results_2014q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q4v2 <- lapply(results_2013q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q3v2 <- lapply(results_2013q3, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q2v2 <- lapply(results_2013q2, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q1v2 <- lapply(results_2013q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q4v2 <- lapply(results_2012q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q3v2 <- lapply(results_2012q3, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q2v2 <- lapply(results_2012q2, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q1v2 <- lapply(results_2012q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2011q4v2 <- lapply(results_2011q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})


data2015q1<-cbind(  rbindlist(results_2015q1v2, fill=TRUE), timeq="2015q1",GUID=  names(results_2015q1v2))
data2014q4<-cbind(  rbindlist(results_2014q4v2, fill=TRUE), timeq="2014q4",GUID=  names(results_2014q4v2))
data2014q3<-cbind(  rbindlist(results_2014q3v2, fill=TRUE), timeq="2014q3",GUID=  names(results_2014q3v2))
data2014q2<-cbind(  rbindlist(results_2014q2v2, fill=TRUE), timeq="2014q2",GUID=  names(results_2014q2v2))
data2014q1<-cbind(  rbindlist(results_2014q1v2, fill=TRUE), timeq="2014q1",GUID=  names(results_2014q1v2))
data2013q4<-cbind(  rbindlist(results_2013q4v2, fill=TRUE), timeq="2013q4",GUID=  names(results_2013q4v2))
data2013q3<-cbind(  rbindlist(results_2013q3v2, fill=TRUE), timeq="2013q3",GUID=  names(results_2013q3v2))
data2013q2<-cbind(  rbindlist(results_2013q2v2, fill=TRUE), timeq="2013q2",GUID=  names(results_2013q2v2))
data2013q1<-cbind(  rbindlist(results_2013q1v2, fill=TRUE), timeq="2013q1",GUID=  names(results_2013q1v2))
data2012q4<-cbind(  rbindlist(results_2012q4v2, fill=TRUE), timeq="2012q4",GUID=  names(results_2012q4v2))
data2012q3<-cbind(  rbindlist(results_2012q3v2, fill=TRUE), timeq="2012q3",GUID=  names(results_2012q3v2))
data2012q2<-cbind(  rbindlist(results_2012q2v2, fill=TRUE), timeq="2012q2",GUID=  names(results_2012q2v2))
data2012q1<-cbind(  rbindlist(results_2012q1v2, fill=TRUE), timeq="2012q1",GUID=  names(results_2012q1v2))
data2011q4<-cbind(  rbindlist(results_2011q4v2, fill=TRUE), timeq="2011q4",GUID=  names(results_2011q4v2))

data_all <- rbind( data2015q1,
                   data2014q4,
                   data2014q3,
                   data2014q2,
                   data2014q1,
                   data2013q4,
                   data2013q3,
                   data2013q2,
                   data2013q1,
                   data2012q4,
                   data2012q3,
                   data2012q2,
                   data2012q1,
                   data2011q4
)
data_all 

summary(data_all)
data_all[,.N, by=.(GUID, timeq)][N>1] #checking that we have no duplicates

data_all[GUID=="015f8d68-eb20-438f-ada0-795928dd4ef2"]

setwd(wd_location_STATA_files)

write.csv(data_all, file= "140217 Who changes peerv2_l1andl2.csv") 

#----------------
#lag1 & lag3
#----------------


results_2015q1<-lapply(data_set, function(i) {common_peer(p1="y2014q4",
                                                     p2="y2014q2",
                                                     list_a=i) })

results_2014q4<-lapply(data_set, function(i) {common_peer(p1="y2014q3",
                                                     p2="y2014q1", 
                                                     list_a=i) })

results_2014q3<-lapply(data_set, function(i) {common_peer(p1="y2014q2",
                                                     p2="y2013q4",
                                                     list_a=i) })

results_2014q2<-lapply(data_set, function(i) {common_peer(p1="y2014q1",
                                                     p2="y2013q3",
                                                     list_a=i) })

results_2014q1<-lapply(data_set, function(i) {common_peer(p1="y2013q4",
                                                     p2="y2013q2",
                                                     list_a=i) })

results_2013q4<-lapply(data_set, function(i) {common_peer(p1="y2013q3",
                                                     p2="y2013q1",
                                                     list_a=i) })

results_2013q3<-lapply(data_set, function(i) {common_peer(p1="y2013q2",
                                                     p2="y2012q4",
                                                     list_a=i) })

results_2013q2<-lapply(data_set, function(i) {common_peer(p1="y2013q1",
                                                     p2="y2012q3",
                                                     list_a=i) })

results_2013q1<-lapply(data_set, function(i) {common_peer(p1="y2012q4",
                                                     p2="y2012q2",
                                                     list_a=i) })

results_2012q4<-lapply(data_set, function(i) {common_peer(p1="y2012q3",
                                                     p2="y2012q1",
                                                     list_a=i) })

results_2012q3<-lapply(data_set, function(i) {common_peer(p1="y2012q2",
                                                     p2="y2011q4",
                                                     list_a=i) })

results_2012q2<-lapply(data_set, function(i) {common_peer(p1="y2012q1",
                                                     p2="y2011q3",
                                                     list_a=i) })

results_2012q1<-lapply(data_set, function(i) {common_peer(p1="y2011q4",
                                                     p2="y2011q2",
                                                     list_a=i) })



library(data.table)

results_2015q1v2 <- lapply(results_2015q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q4v2 <- lapply(results_2014q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q3v2 <- lapply(results_2014q3, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q2v2 <- lapply(results_2014q2, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2014q1v2 <- lapply(results_2014q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q4v2 <- lapply(results_2013q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q3v2 <- lapply(results_2013q3, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q2v2 <- lapply(results_2013q2, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2013q1v2 <- lapply(results_2013q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q4v2 <- lapply(results_2012q4, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q3v2 <- lapply(results_2012q3, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q2v2 <- lapply(results_2012q2, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})
results_2012q1v2 <- lapply(results_2012q1, function(i) {as.data.frame (cbind(number_common=i$number_common, number_period=i$number_period))})


data2015q1<-cbind(  rbindlist(results_2015q1v2, fill=TRUE), timeq="2015q1",GUID=  names(results_2015q1v2))
data2014q4<-cbind(  rbindlist(results_2014q4v2, fill=TRUE), timeq="2014q4",GUID=  names(results_2014q4v2))
data2014q3<-cbind(  rbindlist(results_2014q3v2, fill=TRUE), timeq="2014q3",GUID=  names(results_2014q3v2))
data2014q2<-cbind(  rbindlist(results_2014q2v2, fill=TRUE), timeq="2014q2",GUID=  names(results_2014q2v2))
data2014q1<-cbind(  rbindlist(results_2014q1v2, fill=TRUE), timeq="2014q1",GUID=  names(results_2014q1v2))
data2013q4<-cbind(  rbindlist(results_2013q4v2, fill=TRUE), timeq="2013q4",GUID=  names(results_2013q4v2))
data2013q3<-cbind(  rbindlist(results_2013q3v2, fill=TRUE), timeq="2013q3",GUID=  names(results_2013q3v2))
data2013q2<-cbind(  rbindlist(results_2013q2v2, fill=TRUE), timeq="2013q2",GUID=  names(results_2013q2v2))
data2013q1<-cbind(  rbindlist(results_2013q1v2, fill=TRUE), timeq="2013q1",GUID=  names(results_2013q1v2))
data2012q4<-cbind(  rbindlist(results_2012q4v2, fill=TRUE), timeq="2012q4",GUID=  names(results_2012q4v2))
data2012q3<-cbind(  rbindlist(results_2012q3v2, fill=TRUE), timeq="2012q3",GUID=  names(results_2012q3v2))
data2012q2<-cbind(  rbindlist(results_2012q2v2, fill=TRUE), timeq="2012q2",GUID=  names(results_2012q2v2))
data2012q1<-cbind(  rbindlist(results_2012q1v2, fill=TRUE), timeq="2012q1",GUID=  names(results_2012q1v2))

data_all <- rbind( data2015q1,
                   data2014q4,
                   data2014q3,
                   data2014q2,
                   data2014q1,
                   data2013q4,
                   data2013q3,
                   data2013q2,
                   data2013q1,
                   data2012q4,
                   data2012q3,
                   data2012q2,
                   data2012q1
)
data_all 


write.csv(data_all, file= "140217 Who changes peerv2_l1andl3.csv") 


