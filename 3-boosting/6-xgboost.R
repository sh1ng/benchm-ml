library(readr)
library(ROCR)
library(xgboost)
library(parallel)
library(Matrix)

set.seed(123)

d_train <- read_csv("train-10m.csv")
d_test <- read_csv("test.csv")


system.time({
  X_train_test <- sparse.model.matrix(dep_delayed_15min ~ .-1, data = rbind(d_train, d_test))
  n1 <- nrow(d_train)
  n2 <- nrow(d_test)
  X_train <- X_train_test[1:n1,]
  X_test <- X_train_test[(n1+1):(n1+n2),]
})
dim(X_train)

dxgb_train <- xgb.DMatrix(data = X_train, label = ifelse(d_train$dep_delayed_15min=='Y',1,0))
dxgb_test  <- xgb.DMatrix(data = X_test,  label = ifelse(d_test$dep_delayed_15min =='Y',1,0))

rm(X_train, d_train)



system.time({
n_proc <- detectCores()
md <- xgb.train(data = dxgb_train, nthread = n_proc, 
                 objective = "binary:logistic", nround = 100, 
                 max_depth = 10, eta = 0.1, subsample = 1.0,
                 min_child_weight = 10)
})



system.time({
  phat <- predict(md, newdata = X_test)
})
rocr_pred <- prediction(phat, d_test$dep_delayed_15min)
performance(rocr_pred, "auc")


