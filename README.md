# Diabetes Progression Regression

Final project for **SDS 301: Modern Regression Analysis**. (SDU University)

We study which physiological and biochemical factors drive diabetes progression one year after baseline, and build an interpretable multiple linear regression model to explain and predict it.

## Dataset

The classic Diabetes dataset (Efron et al., 2004; also available in scikit-learn): 442 patients, 10 standardised baseline predictors and a quantitative target, disease progression after one year.

| Variable | Description |
|---|---|
| `age`, `sex` | Patient age and sex (standardised) |
| `bmi` | Body mass index |
| `bp` | Mean arterial blood pressure |
| `s1`–`s6` | Blood serum measurements |
| `target` | Disease progression one year after baseline |

## Method

1. **EDA:** histograms, boxplots, scatterplots, correlation matrix.
2. **Candidate models:** full model, EDA-based model (`bmi`, `bp`, `s3`, `s5`, `s6`) and bidirectional stepwise AIC model.
3. **Diagnostics:** residual plots, Shapiro–Wilk test, Breusch–Pagan test, VIF, Cook's distance (threshold 4/n, 23 influential observations).
4. **Sensitivity analysis:** refitting without influential observations and a log-transformed response (not retained).
5. **Validation:** 10-fold cross-validation.

## Results

| Model | Adj. R² | AIC | RMSE |
|---|---|---|---|
| Full | 0.5066 | 4795.99 | 53.48 |
| EDA-based | 0.4859 | 4809.23 | 54.90 |
| **Stepwise (final)** | **0.5082** | **4790.60** | 53.63 |

**Final model** (stepwise AIC, fitted on the full dataset): `target ~ sex + bmi + bp + s1 + s2 + s5`

| Predictor | Beta | 95% CI | p-value |
|---|---|---|---|
| Intercept | 152 | [147, 157] | < 0.001 |
| sex | -227 | [-344, -109] | < 0.001 |
| bmi | 530 | [401, 659] | < 0.001 |
| bp | 327 | [204, 450] | < 0.001 |
| s1 | -758 | [-1073, -443] | < 0.001 |
| s2 | 539 | [250, 827] | < 0.001 |
| s5 | 804 | [647, 962] | < 0.001 |

BMI, blood pressure and serum measure `s5` are the strongest positive predictors. The final model explains about 51% of the variance in progression.

Models fitted without influential observations show better fit, but they are treated as a sensitivity analysis only: those patients may be clinically valid, and removing them could bias the results.

## Repository contents

| File | Description |
|---|---|
| `diabetes_regression.R` | Full analysis script: EDA, models, diagnostics, cross-validation |
| `diabetes_regression_report.html` | Rendered R Markdown report with code and plots (download and open in a browser) |
| `SDS301_final_project.pdf` | Final written report |
| `Diabetes.csv` | Dataset |

## How to run

```r
install.packages(c("readr", "ggplot2", "corrplot", "MASS", "lmtest",
                   "car", "Metrics", "caret", "dplyr"))
# set the working directory to this repository folder, then:
source("diabetes_regression.R")
```

The script reads `Diabetes.csv` from the working directory and saves histogram, scatter and box plots to `hist_plots/`, `scatter_plots/` and `box_plots/`.

## Limitations

- Observational data: the results show associations, not causal effects.
- Mild heteroskedasticity remains (Breusch–Pagan p < 0.01).
- About half of the variance is unexplained: lifestyle, genetic and treatment data are not available.

## Team

Kosbay Assylzhan, Arailym Azatkyzy, Bolatkazy Togzhan, Zhasmina Mussamatova

*Developed at Suleyman Demirel University (SDU).*
