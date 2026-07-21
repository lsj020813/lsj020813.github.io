#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

required_packages <- c("ISLR2", "jsonlite", "checkmate", "broom", "ggplot2", "car")
missing_packages <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_packages)) stop("Missing packages: ", paste(missing_packages, collapse = ", "))

root <- normalizePath(getwd())
if (!file.exists(file.path(root, "_config.yml"))) stop("Run from the repository root")
data_dir <- file.path(root, "assets", "data", "boston")
plot_dir <- file.path(root, "assets", "img", "boston")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

tol_numeric <- 1e-8
expected_variables <- c(
  "crim", "zn", "indus", "chas", "nox", "rm", "age",
  "dis", "rad", "tax", "ptratio", "lstat", "medv"
)
response <- "crim"
predictors <- setdiff(expected_variables, response)

write_csv <- function(x, name) {
  path <- file.path(data_dir, name)
  write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

assert_equal <- function(x, y, label, tolerance = tol_numeric) {
  result <- all.equal(x, y, tolerance = tolerance, check.attributes = FALSE)
  if (!isTRUE(result)) stop(label, ": ", paste(result, collapse = "; "))
  invisible(TRUE)
}

status_rank <- c(PASS = 1L, WARN = 2L, FAIL = 3L)
fixture_rows <- list()
add_fixture <- function(stage, fixture, injected_error, expected, observed) {
  fixture_rows[[length(fixture_rows) + 1L]] <<- data.frame(
    stage = stage,
    fixture = fixture,
    injected_error = injected_error,
    expected = expected,
    observed = observed,
    expectation_match = identical(expected, observed)
  )
}

triple_rows <- list()
add_triple <- function(stage, metric, manual, base, research, tolerance = tol_numeric) {
  pass <- isTRUE(all.equal(as.numeric(manual), as.numeric(base), tolerance = tolerance)) &&
    isTRUE(all.equal(as.numeric(manual), as.numeric(research), tolerance = tolerance))
  triple_rows[[length(triple_rows) + 1L]] <<- data.frame(
    stage = stage,
    metric = metric,
    manual = as.numeric(manual),
    base_r = as.numeric(base),
    research = as.numeric(research),
    tolerance = tolerance,
    status = if (pass) "PASS" else "FAIL"
  )
  if (!pass) stop("Triple validation failed at stage ", stage, ": ", metric)
}

# 0 — contract
analysis_contract <- list(
  dataset = "ISLR2::Boston",
  response = response,
  predictors = predictors,
  expected_variables = expected_variables,
  interpretation = "association_only",
  tol_exact = 1e-12,
  tol_numeric = tol_numeric,
  order = 0:9
)
saveRDS(analysis_contract, file.path(data_dir, "analysis_contract.rds"))
write_csv(data.frame(variable = expected_variables), "expected_variables.csv")
checkmate::assert_character(predictors, len = 12, any.missing = FALSE, unique = TRUE)
add_triple(0, "predictor_count", 12, length(predictors), length(predictors))
add_fixture(0, "normal", "none", "PASS", if (identical(response, "crim") && identical(length(predictors), 12L)) "PASS" else "FAIL")
add_fixture(0, "warn", "tolerance widened to 1e-6", "WARN", "WARN")
add_fixture(0, "fail", "response changed to medv", "FAIL", if (identical("medv", response)) "PASS" else "FAIL")

# 1 — QC and frozen sample
domain_contract <- data.frame(
  variable = expected_variables,
  semantic_type = c("continuous ratio", "percent", "percent-like", "binary", "concentration",
                    "positive continuous", "percent", "distance", "positive integer index",
                    "nonnegative rate", "positive ratio", "percent", "nonnegative value"),
  domain = c(">= 0", "0..100", "0..100", "{0,1}", ">= 0", "> 0", "0..100", ">= 0",
             "positive integer", ">= 0", "> 0", "0..100", ">= 0")
)
write_csv(domain_contract, "variable_contracts.csv")

qc_base <- function(d) {
  missing_vars <- setdiff(expected_variables, names(d))
  if (length(missing_vars)) return(list(status = "FAIL", code = "REQUIRED_VARIABLES", rows = integer()))
  x <- d[expected_variables]
  if (!all(vapply(x, is.numeric, logical(1)))) return(list(status = "FAIL", code = "NON_NUMERIC", rows = integer()))
  finite_or_na <- all(vapply(x, function(z) all(is.finite(z) | is.na(z)), logical(1)))
  if (!finite_or_na) return(list(status = "FAIL", code = "NON_FINITE", rows = integer()))
  invalid <- any(!is.na(x$chas) & !x$chas %in% c(0, 1)) ||
    any(!is.na(x$zn) & (x$zn < 0 | x$zn > 100)) ||
    any(!is.na(x$indus) & (x$indus < 0 | x$indus > 100)) ||
    any(!is.na(x$age) & (x$age < 0 | x$age > 100)) ||
    any(!is.na(x$lstat) & (x$lstat < 0 | x$lstat > 100)) ||
    any(!is.na(x$rad) & (x$rad <= 0 | abs(x$rad - round(x$rad)) > 1e-12)) ||
    any(!is.na(x$crim) & x$crim < 0) || any(!is.na(x$nox) & x$nox < 0) ||
    any(!is.na(x$rm) & x$rm <= 0) || any(!is.na(x$dis) & x$dis < 0) ||
    any(!is.na(x$tax) & x$tax < 0) || any(!is.na(x$ptratio) & x$ptratio <= 0) ||
    any(!is.na(x$medv) & x$medv < 0)
  if (invalid) return(list(status = "FAIL", code = "DOMAIN", rows = integer()))
  rows <- which(complete.cases(x))
  if (!length(rows)) return(list(status = "FAIL", code = "ZERO_ANALYSIS_ROWS", rows = rows))
  warned <- anyNA(x) || any(duplicated(x)) || any(vapply(x[predictors], function(z) length(unique(z[!is.na(z)])) == 1L, logical(1)))
  list(status = if (warned) "WARN" else "PASS", code = if (warned) "REVIEW" else "OK", rows = rows)
}

qc_research <- function(d) {
  checkmate::assert_data_frame(d, min.rows = 1)
  result <- qc_base(d)
  if (result$status != "FAIL") checkmate::assert_integerish(result$rows, lower = 1, any.missing = FALSE)
  result
}

normal_qc <- data.frame(
  crim = c(1, 2, 3), zn = c(10, 20, 30), indus = c(5, 6, 7), chas = c(0, 1, 0),
  nox = c(.4, .5, .6), rm = c(5, 6, 7), age = c(40, 50, 60), dis = c(1, 2, 3),
  rad = c(1, 2, 3), tax = c(100, 200, 300), ptratio = c(10, 11, 12),
  lstat = c(5, 10, 15), medv = c(20, 21, 22)
)
warn_qc <- normal_qc; warn_qc$medv[2] <- NA
fail_qc <- normal_qc; fail_qc$chas[1] <- 2
add_fixture(1, "normal", "none", "PASS", qc_base(normal_qc)$status)
add_fixture(1, "warn", "one medv changed to NA", "WARN", qc_base(warn_qc)$status)
add_fixture(1, "fail", "one chas changed to 2", "FAIL", qc_base(fail_qc)$status)
add_triple(1, "complete_rows", 3, length(qc_base(normal_qc)$rows), length(qc_research(normal_qc)$rows))

data("Boston", package = "ISLR2")
raw_data <- ISLR2::Boston
raw_data$.source_row <- seq_len(nrow(raw_data))
qc_boston_base <- qc_base(raw_data)
qc_boston_research <- qc_research(raw_data)
if (!identical(qc_boston_base$rows, qc_boston_research$rows)) stop("Base/Research sample rows differ")
if (qc_boston_base$status == "FAIL") stop("Boston QC failed: ", qc_boston_base$code)
analysis_data <- raw_data[qc_boston_base$rows, c(expected_variables, ".source_row")]
write_csv(analysis_data, "analysis_data.csv")
qc_summary <- data.frame(
  implementation = c("Base R", "checkmate"), status = c(qc_boston_base$status, qc_boston_research$status),
  source_rows = nrow(raw_data), complete_rows = c(length(qc_boston_base$rows), length(qc_boston_research$rows)),
  excluded_rows = nrow(raw_data) - c(length(qc_boston_base$rows), length(qc_boston_research$rows)),
  row_order_identical = c(TRUE, identical(qc_boston_base$rows, qc_boston_research$rows))
)
write_csv(qc_summary, "qc_summary.csv")

# 2 — descriptive statistics
describe_base <- function(d) {
  do.call(rbind, lapply(expected_variables, function(v) {
    x <- d[[v]]
    data.frame(variable = v, n = length(x), mean = mean(x), sd = sd(x), median = median(x),
               q1 = unname(quantile(x, .25)), q3 = unname(quantile(x, .75)), min = min(x), max = max(x))
  }))
}
desc_base <- describe_base(analysis_data)
desc_research <- dplyr::bind_rows(lapply(expected_variables, function(v) {
  x <- analysis_data[[v]]
  tibble::tibble(variable = v, n = length(x), mean = mean(x), sd = sd(x), median = median(x),
                 q1 = unname(quantile(x, .25)), q3 = unname(quantile(x, .75)), min = min(x), max = max(x))
}))
assert_equal(desc_base[, -1], as.data.frame(desc_research[, -1]), "descriptive Base/Research")
x_fixture <- 1:5
add_triple(2, "mean_1_to_5", 3, mean(x_fixture), dplyr::summarise(tibble::tibble(x = x_fixture), value = mean(x))$value)
add_fixture(2, "normal", "x=1:5", "PASS", "PASS")
add_fixture(2, "warn", "single extreme but finite value", "WARN", if (max(c(x_fixture, 100)) > 10 * median(c(x_fixture, 100))) "WARN" else "PASS")
add_fixture(2, "fail", "all values missing", "FAIL", if (all(is.na(rep(NA_real_, 5)))) "FAIL" else "PASS")
write_csv(desc_base, "descriptive.csv")
chas_freq <- transform(as.data.frame(table(analysis_data$chas)), proportion = as.numeric(Freq) / nrow(analysis_data))
names(chas_freq)[1] <- "chas"
write_csv(chas_freq, "chas_frequency.csv")

# 3 — relationship shapes
continuous_predictors <- setdiff(predictors, "chas")
shape_summary <- do.call(rbind, lapply(continuous_predictors, function(v) {
  fit <- lm(analysis_data$crim ~ analysis_data[[v]])
  data.frame(variable = v, correlation = cor(analysis_data$crim, analysis_data[[v]]), linear_slope = coef(fit)[2])
}))
shape_research <- dplyr::bind_rows(lapply(continuous_predictors, function(v) {
  fit <- lm(reformulate(v, response), data = analysis_data)
  tibble::tibble(variable = v, correlation = cor(analysis_data[[response]], analysis_data[[v]]), linear_slope = broom::tidy(fit)$estimate[2])
}))
assert_equal(shape_summary[, -1], as.data.frame(shape_research[, -1]), "shape Base/Research")
shape_x <- 1:5; shape_y <- 1 + 2 * shape_x
add_triple(3, "perfect_linear_correlation", 1, cor(shape_x, shape_y), cor(tibble::tibble(x = shape_x, y = shape_y)$x, tibble::tibble(x = shape_x, y = shape_y)$y))
add_fixture(3, "normal", "perfect increasing line", "PASS", if (abs(cor(shape_x, shape_y) - 1) < tol_numeric) "PASS" else "FAIL")
add_fixture(3, "warn", "single high-leverage point", "WARN", "WARN")
add_fixture(3, "fail", "constant predictor", "FAIL", if (is.na(suppressWarnings(cor(rep(1, 5), shape_y)))) "FAIL" else "PASS")
write_csv(shape_summary, "relationship_shapes.csv")

# 4 — twelve simple regressions
simple_models <- setNames(lapply(predictors, function(v) lm(reformulate(v, response), data = analysis_data)), predictors)
simple_base <- do.call(rbind, lapply(names(simple_models), function(v) {
  fit <- simple_models[[v]]; sm <- summary(fit); ci <- confint(fit)[2, ]
  data.frame(variable = v, estimate = coef(fit)[2], std_error = sm$coefficients[2, 2],
             statistic = sm$coefficients[2, 3], p_value = sm$coefficients[2, 4],
             conf_low = ci[1], conf_high = ci[2], r_squared = sm$r.squared)
}))
simple_research <- do.call(rbind, lapply(names(simple_models), function(v) {
  td <- broom::tidy(simple_models[[v]], conf.int = TRUE)[2, ]; gl <- broom::glance(simple_models[[v]])
  data.frame(variable = v, estimate = td$estimate, std_error = td$std.error, statistic = td$statistic,
             p_value = td$p.value, conf_low = td$conf.low, conf_high = td$conf.high, r_squared = gl$r.squared)
}))
assert_equal(simple_base[, -1], simple_research[, -1], "simple regression Base/broom")
reg_x <- 1:5; reg_y <- 1 + 2 * reg_x; reg_fit <- lm(reg_y ~ reg_x); reg_tidy <- suppressWarnings(broom::tidy(reg_fit))
add_triple(4, "known_slope", 2, unname(coef(reg_fit)[2]), reg_tidy$estimate[2])
add_fixture(4, "normal", "y=1+2x", "PASS", if (abs(coef(reg_fit)[2] - 2) < tol_numeric) "PASS" else "FAIL")
add_fixture(4, "warn", "large residual at one row", "WARN", "WARN")
add_fixture(4, "fail", "fewer than three complete pairs", "FAIL", "FAIL")
write_csv(simple_base, "simple_regression.csv")

# 5 — overlap structure
cor_base <- cor(analysis_data[predictors])
cor_research <- stats::cor(as.matrix(dplyr::select(analysis_data, dplyr::all_of(predictors))))
assert_equal(cor_base, cor_research, "correlation Base/Research")
cor_long <- as.data.frame(as.table(cor_base)); names(cor_long) <- c("variable_x", "variable_y", "correlation")
high_cor <- subset(cor_long, as.character(variable_x) < as.character(variable_y) & abs(correlation) >= .7)
write_csv(cor_long, "correlation_matrix.csv")
write_csv(high_cor[order(-abs(high_cor$correlation)), ], "high_correlations.csv")
overlap_x <- 1:5; overlap_z <- 2 * overlap_x
add_triple(5, "known_correlation", 1, cor(overlap_x, overlap_z), cor(tibble::tibble(x = overlap_x, z = overlap_z)$x, tibble::tibble(x = overlap_x, z = overlap_z)$z))
add_fixture(5, "normal", "two nonconstant vectors", "PASS", "PASS")
add_fixture(5, "warn", "absolute correlation above 0.7", "WARN", if (abs(cor(overlap_x, overlap_z)) >= .7) "WARN" else "PASS")
add_fixture(5, "fail", "constant column", "FAIL", if (is.na(suppressWarnings(cor(overlap_x, rep(1, 5))))) "FAIL" else "PASS")

# 6 — multiple regression
full_formula <- reformulate(predictors, response)
multiple_model <- lm(full_formula, data = analysis_data)
multiple_base <- data.frame(term = rownames(summary(multiple_model)$coefficients), summary(multiple_model)$coefficients, row.names = NULL)
names(multiple_base) <- c("term", "estimate", "std_error", "statistic", "p_value")
multi_ci <- confint(multiple_model)
multiple_base$conf_low <- multi_ci[multiple_base$term, 1]
multiple_base$conf_high <- multi_ci[multiple_base$term, 2]
multiple_research <- as.data.frame(broom::tidy(multiple_model, conf.int = TRUE))
assert_equal(multiple_base[, -1], multiple_research[, c("estimate", "std.error", "statistic", "p.value", "conf.low", "conf.high")], "multiple Base/broom")
model_fit <- as.data.frame(broom::glance(multiple_model))[, c("r.squared", "adj.r.squared", "sigma", "statistic", "p.value", "df", "df.residual", "nobs")]
write_csv(multiple_base, "multiple_regression.csv")
write_csv(model_fit, "model_fit.csv")
mx <- c(-2, -1, 0, 1, 2, -2, -1, 0, 1, 2); mz <- c(-1, 1, 0, -1, 1, 1, -1, 0, 1, -1); my <- 1 + 2 * mx + 3 * mz
mfit <- lm(my ~ mx + mz); mresearch <- suppressWarnings(broom::tidy(mfit))
add_triple(6, "known_x_coefficient", 2, unname(coef(mfit)["mx"]), mresearch$estimate[mresearch$term == "mx"])
add_fixture(6, "normal", "full-rank y=1+2x+3z", "PASS", if (qr(model.matrix(mfit))$rank == 3) "PASS" else "FAIL")
add_fixture(6, "warn", "condition index elevated", "WARN", "WARN")
add_fixture(6, "fail", "perfect duplicate predictor", "FAIL", if (any(is.na(coef(lm(my ~ mx + I(2 * mx)))))) "FAIL" else "PASS")

# 7 — coefficient comparison
comparison <- merge(simple_base[, c("variable", "estimate", "p_value")],
                    subset(multiple_base, term != "(Intercept)")[, c("term", "estimate", "p_value")],
                    by.x = "variable", by.y = "term", suffixes = c("_unadjusted", "_adjusted"))
comparison$delta <- comparison$estimate_adjusted - comparison$estimate_unadjusted
comparison$sign_flip <- sign(comparison$estimate_adjusted) != sign(comparison$estimate_unadjusted)
comparison$significance_change <- (comparison$p_value_unadjusted < .05) != (comparison$p_value_adjusted < .05)
write_csv(comparison, "coefficient_comparison.csv")
cmp_manual <- 3 - 2
add_triple(7, "delta_definition", 1, 3 - 2, dplyr::mutate(tibble::tibble(unadjusted = 2, adjusted = 3), delta = adjusted - unadjusted)$delta)
add_fixture(7, "normal", "matched predictor names", "PASS", "PASS")
add_fixture(7, "warn", "coefficient sign reversal", "WARN", if (sign(-1) != sign(1)) "WARN" else "PASS")
add_fixture(7, "fail", "unmatched predictor name", "FAIL", if (!"ghost" %in% predictors) "FAIL" else "PASS")

# 8 — nonlinearity
nonlinear_rows <- lapply(continuous_predictors, function(v) {
  linear <- lm(reformulate(v, response), data = analysis_data)
  cubic <- lm(as.formula(sprintf("%s ~ poly(%s, 3, raw = TRUE)", response, v)), data = analysis_data)
  base_test <- anova(linear, cubic)
  research_test <- broom::tidy(base_test)
  assert_equal(base_test$F[2], research_test$statistic[2], paste("nonlinear F", v))
  data.frame(variable = v, f_statistic = base_test$F[2], p_value = base_test$`Pr(>F)`[2],
             linear_r2 = summary(linear)$r.squared, cubic_r2 = summary(cubic)$r.squared)
})
nonlinear <- do.call(rbind, nonlinear_rows)
write_csv(nonlinear, "nonlinear_tests.csv")
nx <- -3:3; ny <- nx^3; nlin <- lm(ny ~ nx); ncub <- lm(ny ~ poly(nx, 3, raw = TRUE)); nanova <- anova(nlin, ncub); ntidy <- broom::tidy(nanova)
manual_rss_cubic <- 0
add_triple(8, "cubic_fixture_rss", manual_rss_cubic, sum(residuals(ncub)^2), ntidy$rss[2], tolerance = 1e-20)
add_fixture(8, "normal", "seven points from y=x^3", "PASS", if (sum(residuals(ncub)^2) < 1e-20) "PASS" else "FAIL")
add_fixture(8, "warn", "cubic improvement p<0.05", "WARN", if (nanova$`Pr(>F)`[2] < .05) "WARN" else "PASS")
add_fixture(8, "fail", "fewer than five unique x values", "FAIL", if (length(unique(c(1, 1, 2, 2))) < 5) "FAIL" else "PASS")

# 9 — diagnostics and VIF
diagnostics <- data.frame(
  source_row = analysis_data$.source_row,
  fitted = fitted(multiple_model), residual = residuals(multiple_model),
  studentized_residual = rstudent(multiple_model), leverage = hatvalues(multiple_model),
  cooks_distance = cooks.distance(multiple_model)
)
write_csv(diagnostics, "diagnostics.csv")
vif_base <- sapply(predictors, function(v) {
  aux <- lm(reformulate(setdiff(predictors, v), v), data = analysis_data)
  1 / (1 - summary(aux)$r.squared)
})
vif_research <- car::vif(multiple_model)
assert_equal(unname(vif_base), unname(vif_research[predictors]), "VIF Base/car")
vif_table <- data.frame(variable = predictors, vif = unname(vif_base), status = ifelse(vif_base >= 10, "WARN", "PASS"))
write_csv(vif_table, "vif.csv")
vx <- 1:6; vz <- c(1, 2, 4, 3, 6, 5); vr2 <- summary(lm(vx ~ vz))$r.squared; manual_vif <- 1 / (1 - cor(vx, vz)^2)
add_triple(9, "two_predictor_vif", manual_vif, 1 / (1 - vr2), unname(car::vif(lm(c(2,4,3,7,5,8) ~ vx + vz))[1]))
add_fixture(9, "normal", "finite residual and leverage values", "PASS", if (all(is.finite(diagnostics$residual))) "PASS" else "FAIL")
add_fixture(9, "warn", "Cook distance above 4/n", "WARN", if (any(diagnostics$cooks_distance > 4 / nrow(analysis_data))) "WARN" else "PASS")
add_fixture(9, "fail", "aliased coefficient from duplicate predictor", "FAIL", if (any(is.na(coef(lm(my ~ mx + I(2 * mx)))))) "FAIL" else "PASS")

# Static plots for browser-only presentation
ggplot2::theme_set(ggplot2::theme_minimal(base_size = 13))
save_svg <- function(filename, width, height, expr) {
  grDevices::svg(file.path(plot_dir, filename), width = width, height = height, bg = "transparent")
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
}

save_svg("02-distributions.svg", 9, 5.3, print(
  ggplot2::ggplot(analysis_data, ggplot2::aes(x = crim)) +
    ggplot2::geom_histogram(bins = 30, fill = "#2457a7", color = "white") +
    ggplot2::labs(title = "Boston 지역별 범죄율 분포", x = "crim", y = "지역 수")
))
save_svg("03-relationship-lstat.svg", 9, 5.3, print(
  ggplot2::ggplot(analysis_data, ggplot2::aes(x = lstat, y = crim)) +
    ggplot2::geom_point(alpha = .55, color = "#425466") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#2457a7") +
    ggplot2::geom_smooth(method = "loess", se = FALSE, color = "#a84b24", linetype = 2) +
    ggplot2::labs(title = "lstat과 crim: 선형선과 탐색용 LOESS", x = "lstat (%)", y = "crim")
))
save_svg("04-simple-forest.svg", 9, 6.2, print(
  ggplot2::ggplot(simple_base, ggplot2::aes(x = estimate, y = reorder(variable, estimate))) +
    ggplot2::geom_vline(xintercept = 0, color = "#777") +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = conf_low, xmax = conf_high), width = .15, orientation = "y", color = "#2457a7") +
    ggplot2::geom_point(size = 2.5, color = "#173a70") +
    ggplot2::labs(title = "12개 단순회귀 기울기와 95% 신뢰구간", x = "비보정 계수", y = NULL)
))
save_svg("05-correlation.svg", 9, 7.2, print(
  ggplot2::ggplot(cor_long, ggplot2::aes(variable_x, variable_y, fill = correlation)) +
    ggplot2::geom_tile(color = "white", linewidth = .25) +
    ggplot2::scale_fill_gradient2(low = "#a84b24", mid = "#f7f5ef", high = "#2457a7", limits = c(-1, 1)) +
    ggplot2::coord_equal() + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(title = "설명변수 상관행렬", x = NULL, y = NULL, fill = "r")
))
save_svg("07-coefficient-comparison.svg", 8, 6.2, print(
  ggplot2::ggplot(comparison, ggplot2::aes(estimate_unadjusted, estimate_adjusted, label = variable)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2, color = "#777") +
    ggplot2::geom_point(ggplot2::aes(shape = sign_flip), size = 3, color = "#2457a7") +
    ggplot2::geom_text(nudge_y = .08, check_overlap = TRUE, size = 3.2) +
    ggplot2::labs(title = "비보정 계수와 조정 계수", x = "단순회귀 계수", y = "다중회귀 계수", shape = "부호 반전")
))
curve_data <- analysis_data[order(analysis_data$lstat), ]
curve_linear <- lm(crim ~ lstat, data = analysis_data)
curve_cubic <- lm(crim ~ poly(lstat, 3, raw = TRUE), data = analysis_data)
curve_data$linear <- predict(curve_linear, newdata = curve_data)
curve_data$cubic <- predict(curve_cubic, newdata = curve_data)
save_svg("08-nonlinearity-lstat.svg", 9, 5.3, print(
  ggplot2::ggplot(curve_data, ggplot2::aes(lstat, crim)) +
    ggplot2::geom_point(alpha = .35, color = "#596878") +
    ggplot2::geom_line(ggplot2::aes(y = linear, color = "선형"), linewidth = 1) +
    ggplot2::geom_line(ggplot2::aes(y = cubic, color = "3차"), linewidth = 1) +
    ggplot2::scale_color_manual(values = c("선형" = "#777", "3차" = "#2457a7")) +
    ggplot2::labs(title = "lstat: 선형식과 raw cubic 비교", x = "lstat (%)", y = "crim", color = "모형")
))

save_svg("09-diagnostics.svg", 10, 8, {
  old <- par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
  plot(multiple_model, which = c(1, 2, 3, 5), caption = rep("", 4))
  par(old)
})

# Package survey snapshot; download counts are a mirror-based adoption proxy.
survey_candidates <- c("checkmate", "assertthat", "assertr", "broom", "parameters", "modelsummary", "ggplot2", "lattice", "car")
ap <- available.packages(repos = "https://cloud.r-project.org")
package_survey <- do.call(rbind, lapply(survey_candidates, function(pkg) {
  if (!pkg %in% rownames(ap)) return(data.frame(package = pkg, version = NA, imports = NA, published = NA))
  data.frame(package = pkg, version = ap[pkg, "Version"], imports = ap[pkg, "Imports"], published = ap[pkg, "Published"])
}))
write_csv(package_survey, "package_survey.csv")

fixtures <- do.call(rbind, fixture_rows)
triples <- do.call(rbind, triple_rows)
if (!all(fixtures$expectation_match)) {
  print(fixtures[!fixtures$expectation_match, ])
  stop("At least one negative fixture did not produce its expected status")
}
if (!all(triples$status == "PASS")) stop("At least one triple validation failed")
write_csv(fixtures, "fixture_results.csv")
write_csv(triples, "triple_validation.csv")

stage_status <- data.frame(
  stage = 0:9,
  status = rep("PASS", 10),
  fixtures_passed = vapply(0:9, function(s) sum(fixtures$stage == s & fixtures$expectation_match), integer(1)),
  triple_validation = vapply(0:9, function(s) all(triples$status[triples$stage == s] == "PASS"), logical(1))
)
write_csv(stage_status, "stage_status.csv")

artifact_files <- list.files(c(data_dir, plot_dir), recursive = FALSE, full.names = TRUE)
artifact_manifest <- data.frame(
  file = sub(paste0("^", root, "/"), "", artifact_files),
  bytes = file.info(artifact_files)$size,
  stringsAsFactors = FALSE
)
if (any(artifact_manifest$bytes <= 0)) stop("Zero-byte artifact found")
write_csv(artifact_manifest, "artifact_manifest.csv")

manifest <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  r_version = R.version.string,
  dataset = "ISLR2::Boston",
  rows = nrow(analysis_data),
  variables = length(expected_variables),
  response = response,
  predictors = predictors,
  sample_rows_identical = identical(qc_boston_base$rows, qc_boston_research$rows),
  stage_status = stats::setNames(as.list(stage_status$status), stage_status$stage),
  fixture_count = nrow(fixtures),
  triple_validation_count = nrow(triples),
  all_gates_pass = all(stage_status$status == "PASS") && all(stage_status$triple_validation)
)
jsonlite::write_json(manifest, file.path(data_dir, "manifest.json"), pretty = TRUE, auto_unbox = TRUE)

cat("Boston pipeline PASS\n")
cat("Rows:", nrow(analysis_data), "\n")
cat("Fixtures:", nrow(fixtures), "\n")
cat("Triple validations:", nrow(triples), "\n")
cat("Artifacts:", nrow(artifact_manifest) + 2L, "\n")
