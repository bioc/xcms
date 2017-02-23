% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/do_groupChromPeaks-functions.R
\name{do_groupPeaks_mzClust}
\alias{do_groupPeaks_mzClust}
\title{Core API function for peak grouping using mzClust}
\usage{
do_groupPeaks_mzClust(peaks, sampleGroups, ppm = 20, absMz = 0,
  minFraction = 0.5, minSamples = 1)
}
\arguments{
\item{peaks}{A \code{matrix} or \code{data.frame} with the mz values and
retention times of the identified chromatographic peaks in all samples of an
experiment. Required columns are \code{"mz"}, \code{"rt"} and
\code{"sample"}. The latter should contain \code{numeric} values representing
the index of the sample in which the peak was found.}

\item{sampleGroups}{A vector of the same length than samples defining the
sample group assignments (i.e. which samples belong to which sample group).}

\item{ppm}{\code{numeric(1)} representing the relative mz error for the
clustering/grouping (in parts per million).}

\item{absMz}{\code{numeric(1)} representing the absolute mz error for the
clustering.}

\item{minFraction}{\code{numeric(1)} defining the minimum fraction of samples
in at least one sample group in which the peaks have to be present to be
considered as a peak group (feature).}

\item{minSamples}{\code{numeric(1)} with the minimum number of samples in at
least one sample group in which the peaks have to be detected to be
considered a peak group (feature).}
}
\value{
A \code{list} with elements \code{"featureDefinitions"} and
\code{"peakIndex"}. \code{"featureDefinitions"} is a \code{matrix}, each row
representing an (mz-rt) feature (i.e. peak group) with columns:
\describe{
\item{"mzmed"}{median of the peaks' apex mz values.}
\item{"mzmin"}{smallest mz value of all peaks' apex within the feature.}
\item{"mzmax"}{largest mz value of all peaks' apex within the feature.}
\item{"rtmed"}{always \code{-1}.}
\item{"rtmin"}{always \code{-1}.}
\item{"rtmax"}{always \code{-1}.}
\item{"npeaks"}{the total number of peaks assigned to the feature.
Note that this number can be larger than the total number of samples, since
multiple peaks from the same sample could be assigned to a group.}
}
\code{"peakIndex"} is a \code{list} with the indices of all peaks in a
peak group in the \code{peaks} input matrix.
}
\description{
The \code{do_groupPeaks_mzClust} function performs high
resolution correspondence on single spectra samples.
}
\references{
Saira A. Kazmi, Samiran Ghosh, Dong-Guk Shin, Dennis W. Hill
and David F. Grant\cr \emph{Alignment of high resolution mass spectra:
development of a heuristic approach for metabolomics}.\cr Metabolomics,
Vol. 2, No. 2, 75-83 (2006)
}
\seealso{
Other core peak grouping algorithms: \code{\link{do_groupChromPeaks_density}},
  \code{\link{do_groupChromPeaks_nearest}}
}
