% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/method-filterFeatures.R
\name{BlankFlag}
\alias{BlankFlag}
\alias{filterFeatures,XcmsResult,BlankFlag-method}
\alias{filterFeatures,SummarizedExperiment,BlankFlag-method}
\title{Flag features based on the intensity in blank samples}
\usage{
BlankFlag(
  threshold = 2,
  blankIndex = integer(),
  qcIndex = integer(),
  na.rm = TRUE
)

\S4method{filterFeatures}{XcmsResult,BlankFlag}(object, filter, ...)

\S4method{filterFeatures}{SummarizedExperiment,BlankFlag}(object, filter, assay = 1)
}
\arguments{
\item{threshold}{`numeric` indicates the minimum difference
required between the mean abundance of a feature in samples compared to the
mean abundance of the same feature in blanks for it to not be considered a
possible contaminant. For example, the default threshold of 2 signifies that
the mean abundance of the features in samples has to be at least twice the
mean abundance in blanks for it to not be flagged as a possible contaminant.}

\item{blankIndex}{`integer` (or `logical`) vector corresponding to the
indices of blank samples.}

\item{qcIndex}{`integer` (or `logical`) vector corresponding to the
indices of quality control (QC) samples.}

\item{na.rm}{`logical` indicates whether missing values (`NA`) should be
removed prior to the calculations.}

\item{object}{\code{XcmsExperiment} or \code{SummarizedExperiment}. For an
\code{XcmsExperiment} object, the \code{featureValues(object)} will be evaluated, and
for \code{Summarizedesxperiment} the \code{assay(object, assay)}. The object will be
filtered.}

\item{filter}{The parameter object selecting and configuring the type of
filtering. It can be one of the following classes: \code{\link{RsdFilter}},
\code{\link{DratioFilter}}, \code{\link{PercentMissingFilter}} or \code{\link{BlankFlag}}.}

\item{...}{Optional parameters. For \code{object} being an \code{XcmsExperiment}:
parameters for the \code{\link[=featureValues]{featureValues()}} call.}

\item{assay}{For filtering of \code{SummarizedExperiment} objects only. Indicates
which assay the filtering will be based on. Note that the features for the
entire object will be removed, but the computations are performed on a single
assay. Default is 1, which means the first assay of the \code{object} will
be evaluated.}
}
\value{
For `BlankFlag`: a `BlankFlag` class. `filterFeatures` returns
the input object with an added column in the features metadata called
`possible_contaminants` with a logical value for each feature. This is added
to `featureDefinitions` for `XcmsExperiment` objects and `rowData` for
`SummarizedExperiment` objects.
}
\description{
The `BlankFlag` class and method enable users to flag features of an
`XcmsExperiment` or `SummarizedExperiment` object based on the relationship
between the intensity of a feature in blanks compared to the intensity in the
samples.

This class and method are part of the possible dispatch of the
generic function `filterFeatures`. Features *below* (`<`) the user-input
threshold will be flagged by calling the `filterFeatures` function. This
means that an extra column will be created in `featureDefinitions` or
`rowData` called `possible_contaminants` with a logical value for each
feature.
}
\seealso{
Other Filter features in xcms: 
\code{\link{DratioFilter}},
\code{\link{PercentMissingFilter}},
\code{\link{RsdFilter}}
}
\author{
Philippine Louail
}
\concept{Filter features in xcms}
