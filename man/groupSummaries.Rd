% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/groupSummaries.R
\name{groupSummaries}
\alias{groupSummaries}
\title{A wrapper function for \code{tapply} which returns a dataframe}
\usage{
groupSummaries(data, y, factors, FUN)
}
\arguments{
\item{data}{a dataframe}

\item{y}{a data vector in \code{data}}

\item{factors}{vector of one or more factor names (character strings)}

\item{FUN}{the function to be applied, or NULL. In the case of functions like '+', '%*%', etc.,
the function name must be backquoted or quoted. If FUN is NULL, tapply returns a vector which can
be used to subscript the multi-way array tapply normally produces.}
}
\value{
a dataframe, including a column for each factor in \code{factors} and a column for each
value returned by \code{FUN} when applied to \code{y}
}
\description{
Applies a function to each group of values within each unique combination of factor levels, but
returns a dataframe rather than the multi-way array returned by \code{tapply}.
}
\details{
This function computes the mean and standard error of the observations in a vector.
NAs are removed before the calculations are performed.
}
\examples{
data(splitBlockData)

# For each unique combination of the levels of Disease and Organ:

# 1. Calculate means and their SEs
groupSummaries(splitBlockData, y="logAUC", factors=c("Disease", "Organ"), FUN=meanse)
# 2. Get quartiles
groupSummaries(splitBlockData, y="logAUC", factors=c("Disease", "Organ"),
  FUN=function(x)quantile(x, probs=c(0.25, 0.5, 0.75)))
}
\seealso{
\code{\link{meanse}}, \code{\link{tapply}}
}
