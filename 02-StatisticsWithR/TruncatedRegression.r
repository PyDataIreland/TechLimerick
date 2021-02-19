
install.packages("truncreg")
require(foreign)
require(ggplot2)
require(truncreg)
require(boot)


dat <- read.dta("https://stats.idre.ucla.edu/stat/data/truncreg.dta")

summary(dat)
##        id            achiv        langscore          prog    
##  Min.   :  3.0   Min.   :41.0   Min.   :31.0   general : 40  
##  1st Qu.: 55.2   1st Qu.:47.0   1st Qu.:47.5   academic:101  
##  Median :102.5   Median :52.0   Median :56.0   vocation: 37  
##  Mean   :103.6   Mean   :54.2   Mean   :54.0                 
##  3rd Qu.:151.8   3rd Qu.:63.0   3rd Qu.:61.8                 
##  Max.   :200.0   Max.   :76.0   Max.   :67.0


# histogram of achiv coloured by program type
ggplot(dat, aes(achiv, fill = prog)) +
  geom_histogram(binwidth=3)



# boxplot of achiv by program type
ggplot(dat, aes(prog, achiv)) +
  geom_boxplot() +
  geom_jitter()

ggplot(dat, aes(x = langscore, y = achiv)) +
  geom_point() +
  stat_smooth(method = "loess") +
  facet_grid(. ~ prog, margins=TRUE)


# boxplot of achiv by program type
ggplot(dat, aes(prog, achiv)) +
  geom_boxplot() +
  geom_jitter()

m <- truncreg(achiv ~ langscore + prog, data = dat, point = 40, direction = "left")

summary(m)

# update old model dropping prog
m2 <- update(m, . ~ . - prog)

pchisq(-2 * (logLik(m2) - logLik(m)), df = 2, lower.tail = FALSE)
## 'log Lik.' 0.0252 (df=3)

# create mean centered langscore to use later
dat <- within(dat, {mlangscore <- langscore - mean(langscore)})

malt <- truncreg(achiv ~ 0 + mlangscore + prog, data = dat, point = 40)
summary(malt)


f <- function(data, i) {
  require(truncreg)
  m <- truncreg(formula = achiv ~ langscore + prog, data = data[i, ], point = 40)
  as.vector(t(summary(m)$coefficients[, 1:2]))
}

set.seed(10)

(res <- boot(dat, f, R = 1200, parallel = "snow", ncpus = 4))
## 



# basic parameter estimates with percentile and bias adjusted CIs
parms <- t(sapply(c(1, 3, 5, 7, 9), function(i) {
    out <- boot.ci(res, index = c(i, i + 1), type = c("perc", "bca"))
    with(out, c(Est = t0, pLL = percent[4], pUL = percent[5], bcaLL = bca[4],
        bcaLL = bca[5]))
}))

# add row names
row.names(parms) <- names(coef(m))
# print results
parms
##                 Est    pLL    pUL   bcaLL  bcaLL
## (Intercept)  11.299 -1.258 22.297 -3.7231 21.320
## langscore     0.713  0.539  0.916  0.5508  0.944
## progacademic  4.063  0.058  8.011  0.0842  8.043
## progvocation -1.144 -6.805  4.277 -6.8436  4.250
## sigma         8.754  7.674  9.792  7.8896 10.110



dat$yhat <- fitted(m)

# correlation
(r <- with(dat, cor(achiv, yhat)))
## [1] 0.552
# rough variance accounted for
r^2
## [1] 0.305




