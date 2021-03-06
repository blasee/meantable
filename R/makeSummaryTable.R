#' Constructs a table of summary statistics for post-hoc tests of pairwise differences between means
#' from a linear (mixed) model
#'
#' This function takes the contents of either the list generated by the \code{predictmeans} function
#' in the \code{predictmeans} package or the list generated by \code{predictparallel.asreml}
#' function in the \code{asremlPlus} package to generate a dataframe which summarises the results
#' of all pairwise comparisons of means for the \code{modelterm} provided to the \code{predictmeans}
#' function.
#'
#' Note: \code{predictparallel.asreml} requires an object of class \code{asreml} containing
#' the results of a fitted mixed model generated by the \code{asreml} function in the
#' commercial \code{R} package \code{asreml}.
#'
#' @param pm is a list generated by the \code{predictmeans} function. \code{predictmeans} takes as
#' its first argument the results of a fitted model using any of \code{lm}, \code{aov},
#' \code{glm}, \code{lme} or \code{lmer}.
#' @param model.term (only required if input table of predicted values is generated by
#' \code{predictparallel.asreml} function in the \code{asremlPlus} package) name, in "quotes",
#' of main effect or interaction (e.g. \code{A}, \code{A:B}) for which predicted means were
#'  calculated by either \code{predictmeans} or \code{asremlPlus}. \code{modelterm} must be
#'  given exactly as it appears in the ANOVA table.
#' @param wald.tab (only required if input table of predicted values is generated by
#' \code{predictparallel.asreml} function in the \code{asremlPlus} package) table of incremental
#' or conditional F statistics generated by \code{asreml}'s \code{wald} function.
#' @param alpha (only required if input table of predicted values is generated by
#' \code{predictparallel.asreml} function in the \code{asremlPlus} package) level of significance
#' at which to perform post-hoc tests.
#' @param digits integer vector of length 2 indicating the number of decimal places to be used
#' for the output values of \code{Difference} -- \code{upr} (first integer in vector, default 3)
#' and for the \code{p}-values (second integer in vector, default 4).
#' @param eps user-defined tolerance level (default \code{NULL}) for dealing with floating-point
#'  errors which erroneously yield non-zero differences between pairs of means.
#' @return A dataframe containing:
#' @return \code{Comparison} character string of the names of the two groups' means being compared
#' @return \code{Difference} value the difference between the pair of means
#' @return \code{SED} standard error of the difference between the pair of means
#' @return \code{t} t-statistic
#' @return \code{LSD} least significant difference calculated at the \eqn{\alpha}
#' level of significance. The value of \eqn{\alpha} is defined in the \code{predictmeans} function
#' @return \code{lwr} lower 100 \eqn{\times (1-\alpha)}\% confidence limit of the difference
#' @return \code{upr} upper 95\% confidence limit of the difference
#' @return \code{p} p-value
#' @author Katya Ruggiero
#' @details This function generates a dataframe with as many rows as there are pairwise comparisons of means
#' and columns containg the comparison description, the difference between the pair of means,
#' the standard error of the difference, the least significant difference, the t-statistics, lower
#' and upper pairwise confidence limits and p-value.
#' @seealso \code{\link[predictmeans]{predictmeans}}, \link{makeComparisonNames}
#' @author Kathy Ruggiero
#' @importFrom stats qt
#' @export
#' @examples
#' library(predictmeans)
#' library(nlme)
#' Oats$nitro <- factor(Oats$nitro)
#' fm <- lme(yield ~ nitro*Variety, random=~1|Block/Variety, data=Oats)
#' # library(lme4)
#' # fm <- lmer(yield ~ nitro*Variety+(1|Block/Variety), data=Oats)
#' pm <- predictmeans(fm, "nitro:Variety", pairwise=TRUE, plot=FALSE)
#' makeSummaryTable(pm)
#'
#' # The following example requires the commercial \code{R} package \code{asreml}
#' # to run.
#' # library(asreml)
#' # library(asremlPlus)
#' # oats.asr <- asreml(yield ~ nitro*Variety, random = ~Block/Variety, data=Oats)
#' # oats.wld <- wald(oats.asr, denDF = "default", ssType = "conditional", maxiter = 1)$Wald
#' # oats.ppasr <- predictparallel.asreml(classify = "nitro:Variety",
#' #    asreml.obj=oats.asr, wald.tab = oats.wld,
#' #    tables = "none")
#' # oats.tab <- makeSummaryTable(oats.ppasr, model.term = "nitro:Variety",
#' #    wald.tab = oats.wld, alpha = 0.05)
#'

makeSummaryTable <- function(pm, model.term, wald.tab, alpha, digits=c(3,4), eps=NULL){

  if(length(pm)==6){

    if(class(pm)=="alldiffs"){

      if(missing(model.term) | missing(wald.tab) | missing(alpha))
        stop("model.term, wald.tab, and/or alpha missing.")

      # get denominator df
      keep <- row.names(wald.tab) == model.term
      denDF <- wald.tab$denDF[keep]

      # store pairwise differences and SEDs
      LSD.mat  <- qt(1-alpha/2, denDF) * pm$sed
      if(!is.null(eps)) pm$differences[abs(pm$differences) < eps] <- 0
      LSD.mat[upper.tri(LSD.mat)] <- pm$differences[upper.tri(pm$differences)]
      pVal.mat <- pm$p.differences
      t.stat <- pm$differences/pm$sed
      pVal.mat[upper.tri(pVal.mat)] <- t.stat[upper.tri(t.stat)]

    }
    else {

      # Extract Pairwise LSDs and Pairwise p-values matrices from pm
      LSD.mat  <- pm[[5]]
      pVal.mat <- pm[[6]]

    }

  }
  else if(length(pm)==5){

    pVal.mat <- pm[[5]]
    LSD.mat  <- matrix(0, nrow = nrow(pVal.mat), ncol = ncol(pVal.mat))
    LSD.mat[lower.tri(LSD.mat)] <- pm[[4]][3]
    meandiffs.mat <- outer(pm[[1]], pm[[1]], "-")
    LSD.mat[upper.tri(LSD.mat)] <- meandiffs.mat[upper.tri(meandiffs.mat)]

  } else {
    stop("Error in predictmeans or alldiffs list.")
  }

  # Get names of comparisons
  compNames <- makeComparisonNames(pVal.mat)

  # Extract all info and put in dataframe
  diffs  <- t(LSD.mat)[lower.tri(t(LSD.mat))]
  lsds   <- LSD.mat[lower.tri(LSD.mat)]
  tstats <- t(pVal.mat)[lower.tri(t(pVal.mat))]
  if (class(pm) == "alldiffs") seds <- pm$sed[lower.tri(pm$sed)]
  else{

    signifLevel <- attr(pm[[4]],"Significant level")
    denDF       <- attr(pm[[4]],"Degree of freedom")
    seds        <- lsds/qt(1 - signifLevel/2, denDF)
  }
  lwr    <- diffs-lsds
  upr    <- diffs+lsds
  pvals  <- pVal.mat[lower.tri(pVal.mat)]
  results.df <- data.frame(Comparison=compNames,
                           Difference=round(diffs,digits[1]),
                           SED=round(seds,digits[1]),
                           LSD=round(lsds,digits[1]),
                           lwr=round(lwr,digits[1]),
                           upr=round(upr,digits[1]),
                           t=round(tstats,digits[1]),
                           p=round(pvals,digits[2]))

  # Return dataframe of summary stats
  results.df

}
