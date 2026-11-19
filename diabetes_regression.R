# 1. SETUP & DATA LOADING


library(readr)
library(ggplot2)
library(corrplot)
library(MASS)
library(lmtest)
library(car)
library(Metrics)
library(caret)
library(dplyr)

df <- readr::read_csv("C:\\Users\\Arailym\\Downloads\\archive (9)\\Diabetes.csv")

# 2. BASIC DATA CHECK


str(df)
summary(df)
sapply(df, function(x) sum(is.na(x)))


# 3. EDA

# Target distribution
library(ggplot2)

out_dir <- "hist_plots"
if (!dir.exists(out_dir)) dir.create(out_dir)

vars <- names(df)

for (v in vars) {
  p <- ggplot(df, aes_string(x = v)) +
    geom_histogram(bins = 30, fill = "skyblue", color = "black") +
    theme_minimal() +
    labs(title = paste("Histogram of", v), x = v, y = "Count")
  
  ggsave(filename = file.path(out_dir, paste0("hist_", v, ".png")),
         plot = p, width = 6, height = 4, dpi = 300)
}

message("Saved histograms to: ", normalizePath(out_dir))

# Correlation matrix
cor_mat <- round(cor(df), 2)
corrplot(cor_mat,
         method = "color",
         type = "upper",
         addCoef.col = "black",
         tl.col = "black",
         tl.srt = 45,
         diag = FALSE)

# Scatterplots (predictors vs target)
out_dir <- "scatter_plots"
if (!dir.exists(out_dir)) dir.create(out_dir)

predictors <- names(df)[names(df) != "target"]

for (v in predictors) {
  p <- ggplot(df, aes_string(x = v, y = "target")) +
    geom_point(alpha = 0.6) +
    geom_smooth(method = "lm", se = TRUE, color = "red") +
    theme_minimal() +
    labs(title = paste("Target vs", v), x = v, y = "Target")
  
  ggsave(filename = file.path(out_dir, paste0("scatter_", v, ".png")),
         plot = p, width = 6, height = 4, dpi = 300)
}
message("Saved plots to: ", normalizePath(out_dir))


out_dir <- "box_plots"
if (!dir.exists(out_dir)) dir.create(out_dir)

vars <- names(df)

for (v in vars) {
  p <- ggplot(df, aes_string(y = v)) +
    geom_boxplot(fill = "orange", color = "black") +
    theme_minimal() +
    labs(title = paste("Boxplot of", v), y = v)
  
  ggsave(filename = file.path(out_dir, paste0("box_", v, ".png")),
         plot = p, width = 6, height = 4, dpi = 300)
}

message("Saved boxplots to: ", normalizePath(out_dir))

# 4. INITIAL MODELING
# Full model
model_full <- lm(
  target ~ age + sex + bmi + bp + s1 + s2 + s3 + s4 + s5 + s6,
  data = df
)

# EDA-based model
model_eda <- lm(
  target ~ bmi + bp + s3 + s5 + s6,
  data = df
)

# Stepwise (AIC)
model_step <- stepAIC(model_full, direction = "both", trace = FALSE)

# Model comparison
summary(model_full)$adj.r.squared
summary(model_eda)$adj.r.squared
summary(model_step)$adj.r.squared

AIC(model_full, model_eda, model_step)

rmse(df$target, predict(model_full, df))
rmse(df$target, predict(model_eda, df))
rmse(df$target, predict(model_step, df))

# 5. DIAGNOSTICS (INITIAL STEPWISE MODEL)


par(mfrow = c(2, 2))
plot(model_step)
par(mfrow = c(1, 1))

# Normality
shapiro.test(residuals(model_step))

# Heteroskedasticity
bptest(model_step)

# Multicollinearity
vif(model_full)
vif(model_step)

# Influential observations (Cook's distance)
cooksD <- cooks.distance(model_step)
cutoff <- 4 / nrow(df)
influential_obs <- which(cooksD > cutoff)
length(influential_obs)


# 6. DATA CLEANING (REMOVE INFLUENTIAL OBS)
df_clean <- df[-influential_obs, ]

nrow(df)
nrow(df_clean)

#lot-transformation
model_log <- lm(log(target) ~ ., data = df_clean)
bptest(model_log)
shapiro.test(residuals(model_log))
summary(model_log)$adj.r.squared

# 7. RE-FIT MODELS ON CLEANED DATA

# Full model (clean)
model_full_clean <- lm(target ~ ., data = df_clean)

# Stepwise on cleaned data
model_step_clean <- stepAIC(
  model_full_clean,
  direction = "both",
  trace = FALSE
)

summary(model_step_clean)
formula(model_step_clean)
confint(model_step_clean)
# 8. FINAL DIAGNOSTICS
par(mfrow = c(2, 2))
plot(model_step_clean)
par(mfrow = c(1, 1))

shapiro.test(residuals(model_step_clean))
bptest(model_step_clean)
vif(model_step_clean)

# 9. CROSS-VALIDATION (FINAL MODEL)
set.seed(123)

train_control <- trainControl(method = "cv", number = 10)

cv_model <- train(
  formula(model_step_clean),
  data = df_clean,
  method = "lm",
  trControl = train_control
)

cv_model
cv_model$results

cv_model_step<- train(
  formula(model_step),
  data = df,
  method = "lm",
  trControl = train_control
)
cv_model_step

# Stepwise model on full data
model_step <- stepAIC(model_full, direction = "both", trace = FALSE)
formula(model_step)
summary(model_step)
confint(model_step)


# Extract coefficients
coef_summary <- summary(model_step)$coefficients

# Extract confidence intervals
ci <- confint(model_step)

# Combine into one table
final_table <- data.frame(
  Characteristic = rownames(coef_summary),
  Beta = round(coef_summary[, "Estimate"], 0),
  CI_Lower = round(ci[, 1], 0),
  CI_Upper = round(ci[, 2], 0),
  p_value = coef_summary[, "Pr(>|t|)"]
)

# Pretty p-values
final_table$p_value <- ifelse(
  final_table$p_value < 0.001,
  "< 0.001",
  round(final_table$p_value, 3)
)

final_table
summary(model_step)$adj.r.squared

