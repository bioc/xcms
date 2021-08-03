% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods-group-features.R
\name{groupFeatures-abundance-correlation}
\alias{groupFeatures-abundance-correlation}
\alias{groupFeatures,XCMSnExp,AbundanceSimilarityParam-method}
\title{Compounding/feature grouping based on similarity of abundances across samples}
\usage{
\S4method{groupFeatures}{XCMSnExp,AbundanceSimilarityParam}(
  object,
  param,
  msLevel = 1L,
  method = c("medret", "maxint", "sum"),
  value = "into",
  intensity = "into",
  filled = TRUE,
  ...
)
}
\arguments{
\item{object}{\code{\link[=XCMSnExp]{XCMSnExp()}} object containing also correspondence results.}

\item{param}{\code{AbudanceSimilarityParam} object with the settings for the
method. See \code{\link[=AbundanceSimilarityParam]{AbundanceSimilarityParam()}} for details on the grouping
method and its parameters.}

\item{msLevel}{\code{integer(1)} defining the MS level on which the features
should be grouped.}

\item{method}{\code{character(1)} passed to the \code{featureValues} call. See
\code{\link[=featureValues]{featureValues()}} for details. Defaults to \code{method = "medret"}.}

\item{value}{\code{character(1)} passed to the \code{featureValues} call. See
\code{\link[=featureValues]{featureValues()}} for details. Defaults to \code{value = "into"}.}

\item{intensity}{\code{character(1)} passed to the \code{featureValues} call. See
\code{\link[=featureValues]{featureValues()}} for details. Defaults to \code{intensity = "into"}.}

\item{filled}{\code{logical(1)} whether filled-in values should be included in
the correlation analysis. Defaults to \code{filled = TRUE}.}

\item{...}{additional parameters passed to the \code{groupFeatures} method for
\code{matrix}.}
}
\value{
input \code{XCMSnExp} with feature group definitions added to a column
\code{"feature_group"} in its \code{featureDefinitions} data frame.
}
\description{
Features from the same originating compound are expected to have similar
intensities across samples. This method this groups features based on
similarity of abundances (i.e. \emph{feature values}) across samples.
See also \code{\link[=AbundanceSimilarityParam]{AbundanceSimilarityParam()}} for additional information and details.

This help page lists parameters specific for \code{xcms} result objects (i.e. the
\code{\link[=XCMSnExp]{XCMSnExp()}} object). Documentation of the parameters for the similarity
calculation is available in the \code{\link[=AbundanceSimilarityParam]{AbundanceSimilarityParam()}} help page in
the \code{MsFeatures} package.
}
\examples{

library(MsFeatures)
## Load a test data set with detected peaks
data(faahko_sub)
## Update the path to the files for the local system
dirname(faahko_sub) <- system.file("cdf/KO", package = "faahKO")

## Disable parallel processing for this example
register(SerialParam())

## Group chromatographic peaks across samples
xodg <- groupChromPeaks(faahko_sub, param = PeakDensityParam(sampleGroups = rep(1, 3)))

## Group features based on correlation of feature values (integrated
## peak area) across samples. Note that there are many missing values
## in the feature value which influence grouping of features in the present
## data set.
xodg_grp <- groupFeatures(xodg,
    param = AbundanceSimilarityParam(threshold = 0.8))
table(featureDefinitions(xodg_grp)$feature_group)

## Group based on the maximal peak intensity per feature
xodg_grp <- groupFeatures(xodg,
    param = AbundanceSimilarityParam(threshold = 0.8, value = "maxo"))
table(featureDefinitions(xodg_grp)$feature_group)
}
\seealso{
feature-grouping for a general overview.

Other feature grouping methods: 
\code{\link{groupFeatures-eic-similarity}},
\code{\link{groupFeatures-similar-rtime}}
}
\author{
Johannes Rainer
}
\concept{feature grouping methods}