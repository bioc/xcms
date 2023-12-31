% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/XcmsExperiment.R,
%   R/methods-XCMSnExp.R
\name{chromPeakSpectra}
\alias{chromPeakSpectra}
\alias{chromPeakSpectra,XcmsExperiment-method}
\alias{chromPeakSpectra,XCMSnExp-method}
\title{Extract spectra associated with chromatographic peaks}
\usage{
chromPeakSpectra(object, ...)

\S4method{chromPeakSpectra}{XcmsExperiment}(
  object,
  method = c("all", "closest_rt", "closest_mz", "largest_tic", "largest_bpi"),
  msLevel = 2L,
  expandRt = 0,
  expandMz = 0,
  ppm = 0,
  skipFilled = FALSE,
  peaks = character(),
  return.type = c("Spectra", "List"),
  BPPARAM = bpparam()
)

\S4method{chromPeakSpectra}{XCMSnExp}(
  object,
  msLevel = 2L,
  expandRt = 0,
  expandMz = 0,
  ppm = 0,
  method = c("all", "closest_rt", "closest_mz", "signal", "largest_tic", "largest_bpi"),
  skipFilled = FALSE,
  return.type = c("Spectra", "MSpectra", "List", "list"),
  peaks = character()
)
}
\arguments{
\item{object}{\link{XcmsExperiment} or \link{XCMSnExp} object with identified
chromatographic peaks for which spectra should be returned.}

\item{...}{ignored.}

\item{method}{\code{character(1)} specifying which spectra to include in the
result. Defaults to \code{method = "all"}. See function description for
details.}

\item{msLevel}{\code{integer(1)} defining the MS level of the spectra that
should be returned.}

\item{expandRt}{\code{numeric(1)} to expand the retention time range of each
peak by a constant value on each side.}

\item{expandMz}{\code{numeric(1)} to expand the m/z range of each peak by a
constant value on each side.}

\item{ppm}{\code{numeric(1)} to expand the m/z range of each peak (on each side)
by a value dependent on the peak's m/z.}

\item{skipFilled}{\code{logical(1)} whether spectra for filled-in peaks should
be reported or not.}

\item{peaks}{\code{character}, \code{logical} or \code{integer} allowing to specify a
subset of chromatographic peaks in \code{chromPeaks} for which spectra should
be returned (providing either their ID, a logical vector same length
than \code{nrow(chromPeaks(x))} or their index in \code{chromPeaks(x)}). This
parameter overrides \code{skipFilled}.}

\item{return.type}{\code{character(1)} defining the type of result object that
should be returned.}

\item{BPPARAM}{parallel processing setup. Defaults to \code{\link[=bpparam]{bpparam()}}.}
}
\value{
parameter \code{return.type} allow to specify the type of the returned object:
\itemize{
\item \code{return.type = "Spectra"} (default): a \code{Spectra} object (defined in the
\code{Spectra} package). The result contains all spectra for all peaks.
Metadata column \code{"peak_id"} provides the ID of the respective peak
(i.e. its rowname in \code{\link[=chromPeaks]{chromPeaks()}}.
\item \code{return.type = "List"}: \code{List} of length equal to the number of
chromatographic peaks is returned, each element being a \code{Spectra} with
the spectra for one chromatographic peak.
}

For backward compatibility options \code{"MSpectra"} and \code{"list"} are also
supported but are not suggested.
\itemize{
\item \code{return.type = "MSpectra"} (deprecated): a \link{MSpectra} object with elements being
\linkS4class{Spectrum} objects. The result objects contains all spectra
for all peaks. Metadata column \code{"peak_id"} provides the ID of the
respective peak (i.e. its rowname in \code{\link[=chromPeaks]{chromPeaks()}}).
\item \code{return.type = "list"}: \code{list} of \code{list}s that are either of length
0 or contain \linkS4class{Spectrum2} object(s) within the m/z-rt range. The
length of the list matches the number of peaks.
}
}
\description{
Extract (MS1 or MS2) spectra from an \link{XcmsExperiment} or \link{XCMSnExp} object
for identified chromatographic peaks. To return spectra for selected
chromatographic peaks, their \emph{peak ID} (i.e., row name in the \code{chromPeaks}
matrix) can be provided with parameter \code{peaks}.
For \code{msLevel = 1L} (only supported for \code{return.type = "Spectra"} or
\code{return.type = "List"}) MS1 spectra within the retention time boundaries
(in the file in which the peak was detected) are returned. For
\code{msLevel = 2L} MS2 spectra are returned for a chromatographic
peak if their precursor m/z is within the retention time and m/z range of
the chromatographic peak. Parameter \code{method} allows to define whether all
or a single spectrum should be returned:
\itemize{
\item \code{method = "all"}: (default): return all spectra for each chromatographic
peak.
\item \code{method = "closest_rt"}: return the spectrum with the retention time
closest to the peak's retention time (at apex).
\item \code{method = "closest_mz"}: return the spectrum with the precursor m/z
closest to the peaks's m/z (at apex); only supported for \code{msLevel > 1}.
\item \code{method = "largest_tic"}: return the spectrum with the largest total
signal (sum of peaks intensities).
\item \code{method = "largest_bpi"}: return the spectrum with the largest peak
intensity (maximal peak intensity).
\item \code{method = "signal"}: only for \code{object} being a \code{XCMSnExp}: return the
spectrum with the sum of intensities most similar to the peak's apex
signal (\code{"maxo"}); only supported for \code{msLevel = 2L}.
}

Parameter \code{return.type} allows to specify the \emph{type} of the result object.
With \code{return.type = "Spectra"} (the default) a \link{Spectra} object with all
matching spectra is returned. The spectra variable \code{"peak_id"} of the
returned \code{Spectra} contains the ID of the chromatographic peak (i.e., the
rowname of the peak in the \code{chromPeaks} matrix) for each spectrum.
With \code{return.type = "Spectra"} a \code{List} of \code{Spectra} is returned. The
length of the list is equal to the number of rows of \code{chromPeaks}. Each
element of the list contains thus a \code{Spectra} with all spectra for one
chromatographic peak (or a \code{Spectra} of length 0 if no spectrum was found
for the respective chromatographic peak).

See also the \emph{LC-MS/MS data analysis} vignette for more details and examples.
}
\examples{

## Read a file with DDA LC-MS/MS data
library(MsExperiment)
fl <- system.file("TripleTOF-SWATH/PestMix1_DDA.mzML", package = "msdata")

dda <- readMsExperiment(fl)

## Perform MS1 peak detection
dda <- findChromPeaks(dda, CentWaveParam(peakwidth = c(5, 15),
    prefilter = c(5, 1000)))

## Return all MS2 spectro for each chromatographic peaks as a Spectra object
ms2_sps <- chromPeakSpectra(dda)
ms2_sps

## spectra variable *peak_id* contain the row names of the peaks in the
## chromPeak matrix and allow thus to map chromatographic peaks to the
## returned MS2 spectra
ms2_sps$peak_id
chromPeaks(dda)

## Alternatively, return the result as a List of Spectra objects. This list
## is parallel to chromPeaks hence the mapping between chromatographic peaks
## and MS2 spectra is easier.
ms2_sps <- chromPeakSpectra(dda, return.type = "List")
names(ms2_sps)
rownames(chromPeaks(dda))
ms2_sps[[1L]]

## Parameter `msLevel` allows to define from which MS level spectra should
## be returned. By default `msLevel = 2L` but with `msLevel = 1L` all
## MS1 spectra with a retention time within the retention time range of
## a chromatographic peak can be returned. Alternatively, selected
## spectra can be returned by specifying the selection criteria/method
## with the `method` parameter. Below we extract for each chromatographic
## peak the MS1 spectra with a retention time closest to the
## chromatographic peak's apex position. Alternatively it would also be
## possible to select the spectrum with the highest total signal or
## highest (maximal) intensity.
ms1_sps <- chromPeakSpectra(dda, msLevel = 1L, method = "closest_rt")
ms1_sps

## Parameter peaks would allow to extract spectra for specific peaks only.
## Peaks can be defined with parameter `peaks` which can be either an
## `integer` with the index of the peak in the `chromPeaks` matrix or a
## `character` with its rowname in `chromPeaks`.
chromPeakSpectra(dda, msLevel = 1L, method = "closest_rt", peaks = c(3, 5))
}
\author{
Johannes Rainer
}
